#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

class LoggerBackend;
class SettingsBackend;
class QAuthenticator;
class QNetworkAccessManager;
class QNetworkReply;

class LogBackupBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool backupInProgress READ backupInProgress NOTIFY backupInProgressChanged)
    Q_PROPERTY(QString lastBackupMessage READ lastBackupMessage NOTIFY lastBackupMessageChanged)

public:
    explicit LogBackupBackend(QObject* parent = nullptr);

    bool backupInProgress() const { return m_backupInProgress; }
    QString lastBackupMessage() const { return m_lastBackupMessage; }

    void setLoggerBackend(LoggerBackend* logger) { m_logger = logger; }
    void setSettingsBackend(SettingsBackend* settings) { m_settings = settings; }

    Q_INVOKABLE void startBackup();
    // Upload the contents of localDirPath to base/logs/<remoteSubdir>/...
    Q_INVOKABLE void startBackupFolder(const QString& localDirPath, const QString& remoteSubdir);

signals:
    void backupInProgressChanged();
    void lastBackupMessageChanged();
    void backupFinished(bool success, const QString& message);

private slots:
    void onRequestFinished();
    void onAuthenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator);

private:
    void processNext();
    void startBackupImpl(const QString& localRootPath, const QString& remoteRootPath);
    static QStringList collectFilesRecursive(const QString& dirPath, const QString& prefix);
    static QStringList collectDirsForFiles(const QStringList& relativePaths);
    static QByteArray basicAuthHeader(const QString& user, const QString& pass);

    LoggerBackend* m_logger = nullptr;
    SettingsBackend* m_settings = nullptr;
    QNetworkAccessManager* m_nam = nullptr;
    QNetworkReply* m_currentReply = nullptr;

    bool m_backupInProgress = false;
    QString m_lastBackupMessage;

    QStringList m_pendingDirs;
    QStringList m_pendingFiles;
    QString m_logsRootPath;
    QString m_baseUrl;
    QString m_remoteRootPath; // e.g. "logs" or "logs/Intel"
    QString m_username;
    QString m_password;
    int m_nextDirIndex = 0;
    int m_nextFileIndex = 0;
};
