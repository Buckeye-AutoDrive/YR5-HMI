#include "LoggerBackend.h"
#include <QDir>
#include <QCoreApplication>
#include <QDebug>
#include <QDateTime>
#include <QFile>
#include <QSettings>
#include <QTextStream>
#include <algorithm>

static const char kLoggerGroup[] = "logger";

void LoggerBackend::loadBusSelection()
{
    QSettings s(QStringLiteral("OSU"), QStringLiteral("HMI_Mk1"));
    s.beginGroup(kLoggerGroup);
    m_canHS = s.value("canHS", true).toBool();
    m_canCE = s.value("canCE", true).toBool();
    m_canSC = s.value("canSC", true).toBool();
    m_canLS = s.value("canLS", true).toBool();
    s.endGroup();
}

void LoggerBackend::saveBusSelection() const
{
    QSettings s(QStringLiteral("OSU"), QStringLiteral("HMI_Mk1"));
    s.beginGroup(kLoggerGroup);
    s.setValue("canHS", m_canHS);
    s.setValue("canCE", m_canCE);
    s.setValue("canSC", m_canSC);
    s.setValue("canLS", m_canLS);
    s.endGroup();
    s.sync();
}

LoggerBackend::LoggerBackend(QObject* parent)
    : QObject(parent)
{
    loadBusSelection();
    refreshLogList();
}

QString LoggerBackend::resolveLogsDir() const
{
    const QDir appDir(QCoreApplication::applicationDirPath());
    const QDir currentDir(QDir::currentPath());

    // 1) Deployed: exe dir / logs / CAN
    QString path = appDir.absoluteFilePath("logs/CAN");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 2) In-tree dev: exe in build/Config so ../src/logs/CAN
    path = appDir.absoluteFilePath("../src/logs/CAN");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 3) In-tree dev: exe in build/Config (e.g. build/MSYS2_UCRT64-Debug) so ../../src/logs/CAN
    path = appDir.absoluteFilePath("../../src/logs/CAN");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 4) Run from project root: currentPath()/src/logs/CAN
    path = currentDir.absoluteFilePath("src/logs/CAN");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    return appDir.absoluteFilePath("logs/CAN");
}

QString LoggerBackend::logsRootPath() const
{
    QDir d(resolveLogsDir());
    if (!d.cdUp())
        return d.absolutePath();
    return d.absolutePath();
}

QString LoggerBackend::currentRecordingPath() const
{
    const QString dirPath = resolveLogsDir();
    QDir dir(dirPath);
    if (!dir.exists())
        dir.mkpath(".");
    const QString fileName = QDateTime::currentDateTime().toString("MM-dd-yyyy_HH-mm-ss") + ".csv";
    return dir.absoluteFilePath(fileName);
}

QString LoggerBackend::dataToHex(const std::string& data)
{
    if (data.empty()) return QString();
    QByteArray ba(data.data(), static_cast<int>(data.size()));
    return QString::fromLatin1(ba.toHex(' ').constData());
}

void LoggerBackend::closeAndRemoveCurrentFile()
{
    if (m_logFile) {
        m_logFile->close();
        m_logFile->deleteLater();
        m_logFile = nullptr;
    }
    if (!m_currentLogPath.isEmpty()) {
        QFile::remove(m_currentLogPath);
        m_currentLogPath.clear();
    }
}

void LoggerBackend::startRecording()
{
    if (m_recording) return;
    closeAndRemoveCurrentFile();
    m_currentLogPath = currentRecordingPath();
    m_logFile = new QFile(m_currentLogPath, this);
    if (!m_logFile->open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "LoggerBackend: failed to open" << m_currentLogPath << m_logFile->errorString();
        m_logFile->deleteLater();
        m_logFile = nullptr;
        m_currentLogPath.clear();
        return;
    }
    QTextStream out(m_logFile);
    out << "bus_id,can_id,is_extended,is_rtr,ts_ns,dlc,data_hex\n";
    m_logFile->flush();
    m_recording = true;
    m_paused = false;
    emit isRecordingChanged();
    emit isPausedChanged();
}

void LoggerBackend::pauseRecording()
{
    if (!m_recording || m_paused) return;
    m_paused = true;
    emit isPausedChanged();
}

void LoggerBackend::resumeRecording()
{
    if (!m_recording || !m_paused) return;
    m_paused = false;
    emit isPausedChanged();
}

void LoggerBackend::discardRecording()
{
    if (!m_recording) return;
    closeAndRemoveCurrentFile();
    m_recording = false;
    m_paused = false;
    emit isRecordingChanged();
    emit isPausedChanged();
}

void LoggerBackend::saveRecording()
{
    if (!m_recording) return;
    if (m_logFile) {
        m_logFile->close();
        m_logFile->deleteLater();
        m_logFile = nullptr;
    }
    m_currentLogPath.clear();
    m_recording = false;
    m_paused = false;
    emit isRecordingChanged();
    emit isPausedChanged();
    refreshLogList();
    emit recordingSaved();
}

bool LoggerBackend::shouldLogBusId(quint32 busId) const
{
    switch (busId) {
    case 0: return m_canHS;
    case 1: return m_canCE;
    case 2: return m_canSC;
    case 3: return m_canLS;
    default: return false;
    }
}

void LoggerBackend::setCanHS(bool v) { if (m_canHS == v) return; m_canHS = v; saveBusSelection(); emit canHSChanged(); }
void LoggerBackend::setCanCE(bool v) { if (m_canCE == v) return; m_canCE = v; saveBusSelection(); emit canCEChanged(); }
void LoggerBackend::setCanSC(bool v) { if (m_canSC == v) return; m_canSC = v; saveBusSelection(); emit canSCChanged(); }
void LoggerBackend::setCanLS(bool v) { if (m_canLS == v) return; m_canLS = v; saveBusSelection(); emit canLSChanged(); }

void LoggerBackend::onCanBatch(const can_stream::CanBatch& batch)
{
    if (!m_recording || m_paused || !m_logFile || !m_logFile->isOpen()) return;
    QTextStream out(m_logFile);
    for (int i = 0; i < batch.events_size(); ++i) {
        const can_stream::CanEvent& e = batch.events(i);
        if (!shouldLogBusId(static_cast<quint32>(e.bus_id())))
            continue;
        out << e.bus_id() << ","
            << e.can_id() << ","
            << (e.is_extended() ? "1" : "0") << ","
            << (e.is_rtr() ? "1" : "0") << ","
            << e.ts_ns() << ","
            << e.dlc() << ","
            << dataToHex(e.data()) << "\n";
    }
    m_logFile->flush();
}

void LoggerBackend::refreshLogList()
{
    const QString dirPath = resolveLogsDir();
    QDir dir(dirPath);
    if (!dir.exists()) {
        qDebug() << "LoggerBackend: logs dir does not exist:" << dirPath;
        if (!m_logFileNames.isEmpty()) {
            m_logFileNames.clear();
            emit logFileNamesChanged();
        }
        return;
    }

    QStringList entries = dir.entryList(QStringList() << "*.csv", QDir::Files, QDir::Name);
    qDebug() << "LoggerBackend: resolved dir" << dirPath << "found" << entries.size() << "csv files";
    // Sort descending so most recent first (MM-DD-YYYY_HH-MM-SS.csv sorts lexicographically = chronological)
    std::sort(entries.begin(), entries.end(), std::greater<QString>());

    if (entries != m_logFileNames) {
        m_logFileNames = entries;
        emit logFileNamesChanged();
    }
}
