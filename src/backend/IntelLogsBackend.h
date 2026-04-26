#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QDateTime>

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

public:
    explicit IntelLogsBackend(QObject* parent = nullptr);

    QObject* model() { return &m_model; }

private slots:
    void onReadyRead();

private:
    IntelLogsModel m_model;
    QUdpSocket m_sock;
};

