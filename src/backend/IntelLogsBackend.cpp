#include "IntelLogsBackend.h"

#include <QHostAddress>
#include <QTime>

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

// ---- IntelLogsBackend ----

IntelLogsBackend::IntelLogsBackend(QObject* parent)
    : QObject(parent)
{
    // Listen on all interfaces, port 6969.
    m_sock.bind(QHostAddress::AnyIPv4, 6969, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint);
    connect(&m_sock, &QUdpSocket::readyRead, this, &IntelLogsBackend::onReadyRead);
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

