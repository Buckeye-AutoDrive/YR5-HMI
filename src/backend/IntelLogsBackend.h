#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QUdpSocket>
#include <QDateTime>
#include <QStringList>

class IntelLogsModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        MessageRole = Qt::UserRole + 1,
        TimeRole
    };

    explicit IntelLogsModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void appendLog(QString message, const QDateTime& ts);
    void clear();
    QString dumpText() const;

private:
    struct Row {
        QString message;
        QString timeHHMM;
    };
    QVector<Row> m_rows;
    int m_maxRows = 500;
};

class IntelLogsBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* model READ model CONSTANT)
    Q_PROPERTY(QStringList logFileNames READ logFileNames NOTIFY logFileNamesChanged)
    Q_PROPERTY(QString logsDir READ logsDir NOTIFY logsDirChanged)

public:
    explicit IntelLogsBackend(QObject* parent = nullptr);

    QObject* model() { return &m_model; }
    QStringList logFileNames() const { return m_logFileNames; }
    QString logsDir() const { return m_logsDir; }

    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE QString saveLogs();
    Q_INVOKABLE void refreshLogList();

private slots:
    void onReadyRead();

signals:
    void logFileNamesChanged();
    void logsDirChanged();

private:
    QString resolveLogsDir() const;
    QString currentLogPath() const;

    IntelLogsModel m_model;
    QUdpSocket m_sock;
    QString m_logsDir;
    QStringList m_logFileNames;
};

