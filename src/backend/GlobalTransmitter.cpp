#include "GlobalTransmitter.h"

#include <QHostAddress>
#include <QtEndian>
#include <QDebug>
#include <QAbstractSocket>
#include <cstring>

GlobalTransmitter::GlobalTransmitter(QObject* parent)
    : QObject(parent)
{
    // Set up default HMI TX channel: localhost:6001
    m_hmi.host = QStringLiteral("10.42.0.1");
    m_hmi.port = 6001;

    m_hmi.reconnectTimer = new QTimer(this);
    m_hmi.reconnectTimer->setInterval(3000);      // 3s backoff
    m_hmi.reconnectTimer->setSingleShot(true);
    connect(m_hmi.reconnectTimer, &QTimer::timeout,
            this, &GlobalTransmitter::onReconnectTimeout);

    // Kick off the initial connection attempt
    connectChannel(m_hmi);
}

GlobalTransmitter::~GlobalTransmitter()
{
    if (m_hmi.socket) {
        m_hmi.socket->disconnect(this);
        m_hmi.socket->disconnectFromHost();
        m_hmi.socket->deleteLater();
    }
}

// --- Public API: configuration / control ---

void GlobalTransmitter::setHmiHost(const QString& host)
{
    if (host == m_hmi.host)
        return;
    m_hmi.host = host;
    reconnectHmi();
}

void GlobalTransmitter::setHmiPort(quint16 port)
{
    if (port == m_hmi.port)
        return;
    m_hmi.port = port;
    reconnectHmi();
}

void GlobalTransmitter::reconnectHmi()
{
    stopReconnectTimer(m_hmi);

    if (m_hmi.socket) {
        m_hmi.socket->abort();
    }

    connectChannel(m_hmi);
}

void GlobalTransmitter::disconnectHmi()
{
    stopReconnectTimer(m_hmi);

    if (m_hmi.socket) {
        m_hmi.socket->disconnectFromHost();
    }
}

// --- Public API: sending messages ---

void GlobalTransmitter::sendEngageCommand(int engageStatus,
                                          const QString& targetDestination)
{
    HMITxMessage msg;
    msg.set_engage_status(engageStatus);
    msg.set_target_destination(targetDestination.toStdString());
    send(msg);
}

void GlobalTransmitter::send(const HMITxMessage& msg)
{
    // Serialize protobuf
    std::string payloadStd;
    if (!msg.SerializeToString(&payloadStd)) {
        qWarning() << "[GlobalTransmitter] Failed to serialize HMITxMessage";
        return;
    }

    QByteArray payload = QByteArray::fromStdString(payloadStd);
    sendFrame(m_hmi, payload);

    emit hmiMessageSent(msg);
}

// --- Status accessors ---

bool GlobalTransmitter::hmiConnected() const
{
    return m_hmi.socket &&
           m_hmi.socket->state() == QAbstractSocket::ConnectedState;
}

bool GlobalTransmitter::hmiConnecting() const
{
    return m_hmi.socket &&
           (m_hmi.socket->state() == QAbstractSocket::ConnectingState ||
            m_hmi.connecting);
}

// --- Internal helpers ---

void GlobalTransmitter::ensureSocket(TxChannel& ch)
{
    if (ch.socket)
        return;

    auto* sock = new QTcpSocket(this);
    ch.socket = sock;

    // All TX channels share these handlers. We only have one channel for now,
    // but the pattern makes it easy to extend later.
    connect(sock, &QTcpSocket::connected,
            this, &GlobalTransmitter::onSocketConnected);
    connect(sock, &QTcpSocket::disconnected,
            this, &GlobalTransmitter::onSocketDisconnected);
    connect(sock,
            QOverload<QAbstractSocket::SocketError>::of(&QTcpSocket::errorOccurred),
            this, &GlobalTransmitter::onSocketError);
}

void GlobalTransmitter::startReconnectTimer(TxChannel& ch)
{
    if (!ch.reconnectTimer)
        return;

    if (!ch.reconnectTimer->isActive())
        ch.reconnectTimer->start();
}

void GlobalTransmitter::stopReconnectTimer(TxChannel& ch)
{
    if (ch.reconnectTimer && ch.reconnectTimer->isActive())
        ch.reconnectTimer->stop();
}

void GlobalTransmitter::connectChannel(TxChannel& ch)
{
    ensureSocket(ch);

    if (!ch.socket)
        return;

    if (ch.socket->state() == QAbstractSocket::ConnectedState ||
        ch.socket->state() == QAbstractSocket::ConnectingState) {
        return; // already in flight
    }

    ch.connecting = true;
    ch.lastError.clear();

    QHostAddress addr;
    if (!addr.setAddress(ch.host)) {
        // Not a numeric IP; let QTcpSocket resolve it as a hostname
        ch.socket->connectToHost(ch.host, ch.port);
    } else {
        ch.socket->connectToHost(addr, ch.port);
    }

    emit hmiConnectionChanged();
}

void GlobalTransmitter::sendFrame(TxChannel& ch, const QByteArray& payload)
{
    if (!ch.socket ||
        ch.socket->state() != QAbstractSocket::ConnectedState) {
        qWarning() << "[GlobalTransmitter] TX channel not connected, dropping frame";
        // Optionally trigger reconnect attempt:
        connectChannel(ch);
        return;
    }

    QByteArray frame;
    frame.resize(4 + payload.size());

    // 4-byte big-endian length prefix to match GlobalReceiver framing.
    const quint32 len = static_cast<quint32>(payload.size());
    qToBigEndian(len, reinterpret_cast<uchar*>(frame.data()));

    // Copy payload
    std::memcpy(frame.data() + 4, payload.constData(),
                static_cast<size_t>(payload.size()));

    const qint64 written = ch.socket->write(frame);
    if (written != frame.size()) {
        qWarning() << "[GlobalTransmitter] Failed to write entire frame"
                   << "expected" << frame.size() << "wrote" << written;
    }

    // Let Qt flush it asynchronously; no waitForBytesWritten() here.
}

// --- Slots for socket events ---

void GlobalTransmitter::onSocketConnected()
{
    // We only have one channel today (m_hmi). If you add more channels later,
    // you can check sender() and update the right TxChannel.
    m_hmi.connecting = false;
    m_hmi.lastError.clear();

    qInfo() << "[GlobalTransmitter] Connected to"
            << m_hmi.host << ":" << m_hmi.port;

    stopReconnectTimer(m_hmi);
    emit hmiConnectionChanged();
    emit hmiLastErrorChanged(QString());
}

void GlobalTransmitter::onSocketDisconnected()
{
    m_hmi.connecting = false;

    qWarning() << "[GlobalTransmitter] Disconnected from"
               << m_hmi.host << ":" << m_hmi.port;

    emit hmiConnectionChanged();

    // Schedule a reconnect attempt
    startReconnectTimer(m_hmi);
}

void GlobalTransmitter::onSocketError(QAbstractSocket::SocketError)
{
    if (!m_hmi.socket)
        return;

    m_hmi.connecting = false;
    m_hmi.lastError = m_hmi.socket->errorString();

    qWarning() << "[GlobalTransmitter] Socket error:"
               << m_hmi.lastError;

    emit hmiConnectionChanged();
    emit hmiLastErrorChanged(m_hmi.lastError);

    // Try again after a delay
    startReconnectTimer(m_hmi);
}

void GlobalTransmitter::onReconnectTimeout()
{
    // For now we only have one channel, so always reconnect m_hmi.
    qInfo() << "[GlobalTransmitter] Reconnect timeout, retrying connection to"
            << m_hmi.host << ":" << m_hmi.port;

    connectChannel(m_hmi);
}
