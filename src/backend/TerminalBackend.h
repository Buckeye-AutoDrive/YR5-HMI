#pragma once

#include <QObject>
#include <QProcess>

class TerminalBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)

public:
    explicit TerminalBackend(QObject* parent = nullptr);
    ~TerminalBackend() override;

    QString output() const { return m_output; }

    Q_INVOKABLE void sendCommand(const QString& command);
    Q_INVOKABLE void sendCtrlC();
    Q_INVOKABLE void sendEnter();
    Q_INVOKABLE void runSshIntel();
    Q_INVOKABLE void clearOutput();

signals:
    void outputChanged();

private slots:
    void onReadyRead();
    void onProcessError(QProcess::ProcessError error);

private:
    void ensureProcessRunning();
    void appendOutput(const QString& text);

    QProcess m_process;
    QString m_output;
    bool m_waitingForSshPassword = false;
};
