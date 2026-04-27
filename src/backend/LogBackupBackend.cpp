#include "LogBackupBackend.h"
#include "LoggerBackend.h"
#include "SettingsBackend.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QAuthenticator>
#include <QUrl>
#include <QSet>
#include <algorithm>
#include <QDebug>

LogBackupBackend::LogBackupBackend(QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    connect(m_nam, &QNetworkAccessManager::authenticationRequired,
            this, &LogBackupBackend::onAuthenticationRequired);
}

void LogBackupBackend::onAuthenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator)
{
    Q_UNUSED(reply);
    if (!m_username.isEmpty() || !m_password.isEmpty()) {
        authenticator->setUser(m_username);
        authenticator->setPassword(m_password);
    }
}

QByteArray LogBackupBackend::basicAuthHeader(const QString& user, const QString& pass)
{
    // RFC 2617: credentials in ISO-8859-1; QtWebDAV uses toLocal8Bit()
    const QByteArray cred = (user + QLatin1Char(':') + pass).toLatin1().toBase64();
    return "Basic " + cred;
}

QStringList LogBackupBackend::collectFilesRecursive(const QString& dirPath, const QString& prefix)
{
    QStringList out;
    QDir dir(dirPath);
    if (!dir.exists())
        return out;
    const auto entries = dir.entryList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot);
    for (const QString& name : entries) {
        const QString fullPath = dir.absoluteFilePath(name);
        const QString relPath = prefix.isEmpty() ? name : (prefix + QLatin1Char('/') + name);
        if (QFileInfo(fullPath).isDir())
            out.append(collectFilesRecursive(fullPath, relPath));
        else
            out.append(relPath);
    }
    return out;
}

QStringList LogBackupBackend::collectDirsForFiles(const QStringList& relativePaths)
{
    QSet<QString> dirs;
    for (const QString& path : relativePaths) {
        const int lastSlash = path.lastIndexOf(QLatin1Char('/'));
        if (lastSlash > 0)
            dirs.insert(path.left(lastSlash));
        else if (lastSlash == 0)
            dirs.insert(QString());
    }
    QStringList list = dirs.values();
    std::sort(list.begin(), list.end(), [](const QString& a, const QString& b) {
        return a.count(QLatin1Char('/')) < b.count(QLatin1Char('/'));
    });
    return list;
}

void LogBackupBackend::startBackup()
{
    if (m_backupInProgress || !m_logger || !m_settings) {
        m_lastBackupMessage = m_backupInProgress ? tr("Backup already in progress.")
                                                 : tr("Logger or settings not available.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    startBackupImpl(m_logger->logsRootPath(), QStringLiteral("logs"));
}

void LogBackupBackend::startBackupFolder(const QString& localDirPath, const QString& remoteSubdir)
{
    if (m_backupInProgress || !m_settings) {
        m_lastBackupMessage = m_backupInProgress ? tr("Backup already in progress.")
                                                 : tr("Settings not available.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    const QString localRoot = QDir(localDirPath).canonicalPath();
    if (localRoot.isEmpty() || !QDir(localRoot).exists()) {
        m_lastBackupMessage = tr("Logs directory not found.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    QString sub = remoteSubdir.trimmed();
    while (sub.startsWith(QLatin1Char('/')))
        sub.remove(0, 1);
    while (sub.endsWith(QLatin1Char('/')))
        sub.chop(1);
    if (sub.isEmpty()) {
        m_lastBackupMessage = tr("Remote folder is invalid.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    startBackupImpl(localRoot, QStringLiteral("logs/") + sub);
}

void LogBackupBackend::startBackupImpl(const QString& localRootPath, const QString& remoteRootPath)
{
    m_logsRootPath = localRootPath;
    m_remoteRootPath = remoteRootPath;

    if (m_logsRootPath.isEmpty() || !QDir(m_logsRootPath).exists()) {
        m_lastBackupMessage = tr("Logs directory not found.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    QString base = m_settings->webdavServerUrl().trimmed();
    if (base.isEmpty()) {
        m_lastBackupMessage = tr("WebDAV server URL is not set.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }
    while (base.endsWith(QLatin1Char('/')))
        base.chop(1);
    QUrl baseUrl = QUrl::fromUserInput(base);
    if (!baseUrl.isValid() || !baseUrl.scheme().startsWith(QLatin1String("http"))) {
        m_lastBackupMessage = tr("WebDAV server URL is invalid.");
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }
    m_baseUrl = base;

    m_username = m_settings->webdavUsername();
    m_password = m_settings->webdavPassword();

    m_pendingFiles = collectFilesRecursive(m_logsRootPath, QString());
    if (m_pendingFiles.isEmpty()) {
        m_lastBackupMessage = tr("No log files to upload.");
        emit lastBackupMessageChanged();
        emit backupFinished(true, m_lastBackupMessage);
        return;
    }

    QStringList relDirs = collectDirsForFiles(m_pendingFiles);
    m_pendingDirs = QStringList(m_remoteRootPath);
    for (const QString& d : relDirs) {
        if (!d.isEmpty())
            m_pendingDirs.append(m_remoteRootPath + QLatin1Char('/') + d);
    }
    m_nextDirIndex = 0;
    m_nextFileIndex = 0;

    m_backupInProgress = true;
    m_lastBackupMessage = tr("Backing up…");
    emit backupInProgressChanged();
    emit lastBackupMessageChanged();

    processNext();
}

void LogBackupBackend::onRequestFinished()
{
    if (!m_currentReply)
        return;

    QNetworkReply* reply = m_currentReply;
    m_currentReply = nullptr;

    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray body = reply->readAll();
    const QString requestUrl = reply->url().toString(QUrl::RemoveUserInfo);
    reply->deleteLater();

    qDebug() << "[LogBackup] Response:" << status << requestUrl;

    // 2xx success; 201 Created (MKCOL); 204 No Content; 405 = collection exists; 409 = conflict (exists)
    const bool ok = (status >= 200 && status < 300) || status == 201 || status == 204
                    || status == 405 || status == 409;

    if (!ok) {
        QString err;
        if (status == 0 || reply->error() != QNetworkReply::NoError)
            err = reply->errorString();
        else if (!body.isEmpty())
            err = QString::fromUtf8(body).trimmed();
        else
            err = QStringLiteral("HTTP %1").arg(status);
        if (status == 301 || status == 302 || status == 307 || status == 308)
            err = tr("Server redirected (HTTP %1). Use the final URL in settings.").arg(status) + QLatin1String(" ") + err;
        m_backupInProgress = false;
        m_lastBackupMessage = tr("Backup failed: %1 (HTTP %2)").arg(err).arg(status);
        qWarning() << "[LogBackup] Backup failed:" << m_lastBackupMessage << "body:" << body;
        emit backupInProgressChanged();
        emit lastBackupMessageChanged();
        emit backupFinished(false, m_lastBackupMessage);
        return;
    }

    processNext();
}

void LogBackupBackend::processNext()
{
    if (m_nextDirIndex < m_pendingDirs.size()) {
        const QString path = m_pendingDirs.at(m_nextDirIndex);
        m_nextDirIndex++;
        // Append path to base (resolved() would replace last segment when base has no trailing slash)
        const QString fullUrl = m_baseUrl + QLatin1Char('/') + path;
        QUrl url(fullUrl);
        qDebug() << "[LogBackup] MKCOL" << url.toString(QUrl::RemoveUserInfo);
        QNetworkRequest req(url);
        req.setRawHeader("Authorization", basicAuthHeader(m_username, m_password));
        req.setHeader(QNetworkRequest::ContentLengthHeader, 0);
        m_currentReply = m_nam->sendCustomRequest(req, "MKCOL", QByteArray());
        connect(m_currentReply, &QNetworkReply::finished, this, &LogBackupBackend::onRequestFinished);
        return;
    }

    if (m_nextFileIndex < m_pendingFiles.size()) {
        const QString relPath = m_pendingFiles.at(m_nextFileIndex);
        m_nextFileIndex++;
        const QString remotePath = m_remoteRootPath + QLatin1Char('/') + relPath;
        const QString localPath = QDir(m_logsRootPath).absoluteFilePath(relPath);
        QFile file(localPath);
        if (!file.open(QIODevice::ReadOnly)) {
            m_backupInProgress = false;
            m_lastBackupMessage = tr("Could not open file: %1").arg(localPath);
            emit backupInProgressChanged();
            emit lastBackupMessageChanged();
            emit backupFinished(false, m_lastBackupMessage);
            return;
        }
        QByteArray data = file.readAll();
        file.close();

        const QString fullUrl = m_baseUrl + QLatin1Char('/') + remotePath;
        QUrl url(fullUrl);
        qDebug() << "[LogBackup] PUT" << url.toString(QUrl::RemoveUserInfo);
        QNetworkRequest req(url);
        req.setRawHeader("Authorization", basicAuthHeader(m_username, m_password));
        req.setHeader(QNetworkRequest::ContentLengthHeader, data.size());
        req.setHeader(QNetworkRequest::ContentTypeHeader, QByteArrayLiteral("application/octet-stream"));
        m_currentReply = m_nam->put(req, data);
        connect(m_currentReply, &QNetworkReply::finished, this, &LogBackupBackend::onRequestFinished);
        return;
    }

    m_backupInProgress = false;
    m_lastBackupMessage = tr("Backup completed successfully.");
    emit backupInProgressChanged();
    emit lastBackupMessageChanged();
    emit backupFinished(true, m_lastBackupMessage);
}
