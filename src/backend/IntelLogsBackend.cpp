#include "IntelLogsBackend.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QHostAddress>
#include <QTextStream>
#include <algorithm>

// ---- IntelLogsModel ----

IntelLogsModel::IntelLogsModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int IntelLogsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_rows.size();
}

QVariant IntelLogsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size())
        return {};

    const Row& r = m_rows.at(index.row());
    switch (role) {
    case MessageRole:
        return r.message;
    case TimeRole:
        return r.timeHHMM;
    default:
        return {};
    }
}

QHash<int, QByteArray> IntelLogsModel::roleNames() const
{
    return {
        { MessageRole, "message" },
        { TimeRole, "time" },
    };
}

void IntelLogsModel::appendLog(QString message, const QDateTime& ts)
{
    message = message.trimmed();
    if (message.isEmpty())
        return;

    const QString hhmm = ts.time().toString(QStringLiteral("HH:mm"));

    // Drop oldest if at capacity.
    if (m_rows.size() >= m_maxRows) {
        beginRemoveRows(QModelIndex(), 0, 0);
        m_rows.remove(0);
        endRemoveRows();
    }

    const int row = m_rows.size();
    beginInsertRows(QModelIndex(), row, row);
    m_rows.push_back(Row{message, hhmm});
    endInsertRows();
}

void IntelLogsModel::clear()
{
    if (m_rows.isEmpty())
        return;
    beginResetModel();
    m_rows.clear();
    endResetModel();
}

QString IntelLogsModel::dumpText() const
{
    QString out;
    out.reserve(m_rows.size() * 64);
    for (const Row& r : m_rows) {
        out += QLatin1Char('[');
        out += r.timeHHMM;
        out += QLatin1String("] ");
        out += r.message;
        out += QLatin1Char('\n');
    }
    return out;
}

// ---- IntelLogsBackend ----

IntelLogsBackend::IntelLogsBackend(QObject* parent)
    : QObject(parent)
{
    m_logsDir = resolveLogsDir();
    emit logsDirChanged();
    refreshLogList();

    // Listen on all interfaces, port 6969.
    m_sock.bind(QHostAddress::AnyIPv4, 6969, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint);
    connect(&m_sock, &QUdpSocket::readyRead, this, &IntelLogsBackend::onReadyRead);
}

QString IntelLogsBackend::resolveLogsDir() const
{
    const QDir appDir(QCoreApplication::applicationDirPath());
    const QDir currentDir(QDir::currentPath());

    // 1) Deployed: exe dir / logs / intel
    QString path = appDir.absoluteFilePath("logs/intel");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 2) In-tree dev: exe in build/Config so ../src/logs/intel
    path = appDir.absoluteFilePath("../src/logs/intel");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 3) In-tree dev: exe in build/Config (e.g. build/MSYS2_UCRT64-Debug) so ../../src/logs/intel
    path = appDir.absoluteFilePath("../../src/logs/intel");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    // 4) Run from project root: currentPath()/src/logs/intel
    path = currentDir.absoluteFilePath("src/logs/intel");
    if (QDir(path).exists())
        return QDir(path).canonicalPath();

    return appDir.absoluteFilePath("logs/intel");
}

QString IntelLogsBackend::currentLogPath() const
{
    QDir dir(m_logsDir);
    if (!dir.exists())
        dir.mkpath(".");
    // Requested: MM-DD-YYYY_HH_MM_SS
    const QString fileName = QDateTime::currentDateTime().toString("MM-dd-yyyy_HH_mm_ss") + ".log";
    return dir.absoluteFilePath(fileName);
}

void IntelLogsBackend::clearLogs()
{
    m_model.clear();
}

QString IntelLogsBackend::saveLogs()
{
    const QString path = currentLogPath();
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
        return QString();

    QTextStream out(&f);
    out << m_model.dumpText();
    f.flush();
    f.close();

    refreshLogList();
    return path;
}

void IntelLogsBackend::refreshLogList()
{
    QDir dir(m_logsDir);
    if (!dir.exists()) {
        if (!m_logFileNames.isEmpty()) {
            m_logFileNames.clear();
            emit logFileNamesChanged();
        }
        return;
    }

    QStringList entries = dir.entryList(QStringList() << "*.log", QDir::Files, QDir::Name);
    // Sort descending so newest first
    std::sort(entries.begin(), entries.end(), std::greater<QString>());

    if (entries != m_logFileNames) {
        m_logFileNames = entries;
        emit logFileNamesChanged();
    }
}

void IntelLogsBackend::onReadyRead()
{
    while (m_sock.hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(static_cast<int>(m_sock.pendingDatagramSize()));
        QHostAddress sender;
        quint16 senderPort = 0;
        const qint64 n = m_sock.readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);
        if (n <= 0)
            continue;
        datagram.truncate(static_cast<int>(n));

        // Interpret as UTF-8 string.
        const QString msg = QString::fromUtf8(datagram);
        m_model.appendLog(msg, QDateTime::currentDateTime());
    }
}

