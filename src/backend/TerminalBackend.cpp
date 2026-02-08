#include "TerminalBackend.h"
#include <QOperatingSystemVersion>
#include <QRegularExpression>

TerminalBackend::TerminalBackend(QObject* parent)
    : QObject(parent)
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_process, &QProcess::readyReadStandardOutput, this, &TerminalBackend::onReadyRead);
    connect(&m_process, &QProcess::errorOccurred, this, &TerminalBackend::onProcessError);
    ensureProcessRunning();
}

TerminalBackend::~TerminalBackend()
{
    if (m_process.state() != QProcess::NotRunning) {
        m_process.terminate();
        m_process.waitForFinished(500);
        if (m_process.state() != QProcess::NotRunning)
            m_process.kill();
    }
}

void TerminalBackend::ensureProcessRunning()
{
    if (m_process.state() != QProcess::NotRunning)
        return;

    #if defined(Q_OS_WIN)
        m_process.start("cmd.exe");
        appendOutput("[terminal] cmd.exe started\r\n");
    #else
        // Jetson/Ubuntu priority: bash interactive
        m_process.start("/bin/bash", {"-i"});
        appendOutput("[terminal] /bin/bash -i started\r\n");
    #endif
}

void TerminalBackend::appendOutput(const QString& text)
{
    m_output += text;
    emit outputChanged();
}

void TerminalBackend::sendCommand(const QString& command)
{
    ensureProcessRunning();
    if (m_process.state() == QProcess::NotRunning)
        return;

    appendOutput(QString("$ %1\n").arg(command));
    m_process.write(command.toUtf8());
    m_process.write("\n");
}

void TerminalBackend::sendCtrlC()
{
    ensureProcessRunning();
    if (m_process.state() == QProcess::NotRunning)
        return;

    m_process.write(QByteArray(1, 0x03)); // Ctrl+C
}

void TerminalBackend::sendEnter()
{
    ensureProcessRunning();
    if (m_process.state() == QProcess::NotRunning)
        return;

    m_process.write("\n");
}

void TerminalBackend::runSshIntel()
{
    m_waitingForSshPassword = true;
    sendCommand("ssh autodrive@192.168.69.10");
}

void TerminalBackend::clearOutput()
{
    m_output.clear();
    emit outputChanged();
}

void TerminalBackend::onReadyRead()
{
    const QString data = QString::fromLocal8Bit(m_process.readAll());
    if (!data.isEmpty())
        appendOutput(data);

    if (m_waitingForSshPassword) {
        const QRegularExpression re("password", QRegularExpression::CaseInsensitiveOption);
        if (re.match(data).hasMatch()) {
            m_process.write("autodrive\n");
            m_waitingForSshPassword = false;
        }
    }
}

void TerminalBackend::onProcessError(QProcess::ProcessError error)
{
    Q_UNUSED(error);
    appendOutput("[terminal] process error\r\n");
}
