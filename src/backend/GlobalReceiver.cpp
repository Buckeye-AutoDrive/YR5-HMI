#include "GlobalReceiver.h"
#include <QHostAddress>
#include <QtEndian>
#include <QDebug>

GlobalReceiver::GlobalReceiver(QObject* parent) : QObject(parent) {}

// === PUBLIC API ===
bool GlobalReceiver::listenControls(quint16 port)
{
    if (m_servers.contains(port)) return true; // already listening

    auto* srv = new QTcpServer(this);
    if (!srv->listen(QHostAddress::Any, port)) {
        qWarning() << "[GlobalReceiver] Failed to listen on port" << port << srv->errorString();
        srv->deleteLater();
        return false;
    }
    m_servers.insert(port, srv);
    m_portKinds.insert(port, StreamKind::Controls);

    connect(srv, &QTcpServer::newConnection, this, &GlobalReceiver::onNewConnection);
    qInfo() << "[GlobalReceiver] Listening Controls on" << port;
    return true;
}

bool GlobalReceiver::listenPerception(quint16 port)
{
    if (m_servers.contains(port)) return true;

    auto* srv = new QTcpServer(this);
    if (!srv->listen(QHostAddress::Any, port)) {
        qWarning() << "[GlobalReceiver] Failed to listen on port" << port << srv->errorString();
        srv->deleteLater();
        return false;
    }
    m_servers.insert(port, srv);
    m_portKinds.insert(port, StreamKind::Perception);
    connect(srv, &QTcpServer::newConnection, this, &GlobalReceiver::onNewConnection);
    qInfo() << "[GlobalReceiver] Listening Perception on" << port;
    return true;
}

bool GlobalReceiver::listenLogger(quint16 port)
{
    if (m_servers.contains(port)) return true;
    auto* srv = new QTcpServer(this);
    if (!srv->listen(QHostAddress::Any, port)) {
        qWarning() << "[GlobalReceiver] Failed to listen on port" << port << srv->errorString();
        srv->deleteLater();
        return false;
    }
    m_servers.insert(port, srv);
    m_portKinds.insert(port, StreamKind::Logger);
    connect(srv, &QTcpServer::newConnection, this, &GlobalReceiver::onNewConnection);
    qInfo() << "[GlobalReceiver] Listening Logger (CAN) on" << port;
    return true;
}

void GlobalReceiver::onNewConnection()
{
    auto* srv = qobject_cast<QTcpServer*>(sender());
    if (!srv) return;
    const quint16 port = srv->serverPort();

    while (srv->hasPendingConnections()) {
        QTcpSocket* s = srv->nextPendingConnection();
        auto* st = new ConnState{ s, QByteArray(), port };
        m_conns.insert(s, st);

        connect(s, &QTcpSocket::readyRead, this, &GlobalReceiver::onReadyRead);
        connect(s, &QTcpSocket::disconnected, this, &GlobalReceiver::onDisconnected);

        // LAN ON when a connection is accepted
        setLanConnected(true);

        updateCanLoggerActive();

        qInfo() << "[GlobalReceiver] Accepted connection on port" << port
                << "from" << s->peerAddress().toString() << ":" << s->peerPort();
    }
}

void GlobalReceiver::onReadyRead()
{
    auto* s = qobject_cast<QTcpSocket*>(sender());
    if (!s || !m_conns.contains(s)) return;

    ConnState* st = m_conns.value(s);
    st->buffer += s->readAll();

    QByteArray frame;
    const quint16 port = s->localPort();

    while (tryPopFrame(st->port, st->buffer, frame)) {
        processFrame(st->port, frame);
        frame.clear();
    }
}

void GlobalReceiver::onDisconnected()
{
    auto* s = qobject_cast<QTcpSocket*>(sender());
    if (!s) return;
    if (m_conns.contains(s)) {
        ConnState* st = m_conns.value(s);
        const bool wasLogger = (m_portKinds.value(st->port, StreamKind::Controls) == StreamKind::Logger);
        delete m_conns.take(s);
        if (wasLogger && !hasLoggerConnection())
            m_loggerHasData = false;
        updateCanLoggerActive();
    }

    // LAN OFF when no active sockets remain
    if (m_conns.isEmpty())
        setLanConnected(false);

    s->deleteLater();
}

// Framing: Controls = 4-byte big-endian; Logger = 4-byte little-endian (TX sends LE length prefix)
bool GlobalReceiver::tryPopFrame(quint16 port, QByteArray& buf, QByteArray& frame)
{
    if (buf.size() < 4) return false;
    const StreamKind kind = m_portKinds.value(port, StreamKind::Controls);
    quint32 len;
    if (kind == StreamKind::Logger) {
        len = qFromLittleEndian<quint32>(reinterpret_cast<const uchar*>(buf.constData()));
    } else {
        len = qFromBigEndian<quint32>(reinterpret_cast<const uchar*>(buf.constData()));
    }
    if (buf.size() < 4 + static_cast<int>(len)) return false;

    frame = buf.mid(4, static_cast<int>(len));
    buf.remove(0, 4 + static_cast<int>(len));
    return true;
}

bool GlobalReceiver::hasLoggerConnection() const
{
    for (ConnState* st : m_conns.values()) {
        if (st && m_portKinds.value(st->port, StreamKind::Controls) == StreamKind::Logger)
            return true;
    }
    return false;
}

void GlobalReceiver::updateCanLoggerActive()
{
    const bool active = hasLoggerConnection() && m_loggerHasData;
    if (active != m_canLoggerActive) {
        m_canLoggerActive = active;
        emit canLoggerActiveChanged(active);
    }
}

void GlobalReceiver::processFrame(quint16 port, const QByteArray& payload)
{
    const auto kind = m_portKinds.value(port, StreamKind::Controls);

    switch (kind) {
    case StreamKind::Controls: {
        emit controlsRaw(payload);
        if (payload.size() < 1) return;
        const quint8 type = static_cast<quint8>(payload[0]);
        const QByteArray body = payload.mid(1);
        if (type == 0x01) {
            vehicle_msgs::Navigation nav;
            if (!nav.ParseFromArray(body.constData(), body.size())) {
                qWarning() << "[GlobalReceiver] Controls: failed to parse Navigation message";
                return;
            }
            emit controlsMessage(nav);
        } else if (type == 0x02) {
            vehicle_msgs::CameraBatch batch;
            if (!batch.ParseFromArray(body.constData(), body.size())) {
                qWarning() << "[GlobalReceiver] Controls: failed to parse CameraBatch message";
                return;
            }
            emit cameraBatchReceived(batch);
        } else {
            qWarning() << "[GlobalReceiver] Controls: unknown message type" << type;
        }
        break;
    }
    case StreamKind::Logger: {
        can_stream::CanBatch batch;
        if (!batch.ParseFromArray(payload.constData(), payload.size())) {
            qWarning() << "[GlobalReceiver] Logger: failed to parse CanBatch";
            return;
        }
        m_loggerHasData = true;
        updateCanLoggerActive();
        emit canBatchReceived(batch);
        break;
    }
    case StreamKind::Perception: {
        hmi::perception::v1::PerceptionFrame frame;
        if (!frame.ParseFromArray(payload.constData(), payload.size())) {
            qWarning() << "[GlobalReceiver] Perception: failed to parse PerceptionFrame";
            return;
        }
        emit perceptionFrameReceived(frame);
        break;
    }
    default:
        break;
    }
}
