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

// Example for a second parallel stream
// bool GlobalReceiver::listenPerception(quint16 port)
// {
//     if (m_servers.contains(port)) return true;
//     auto* srv = new QTcpServer(this);
//     if (!srv->listen(QHostAddress::Any, port)) {
//         qWarning() << "[GlobalReceiver] Failed to listen on port" << port << srv->errorString();
//         srv->deleteLater();
//         return false;
//     }
//     m_servers.insert(port, srv);
//     m_portKinds.insert(port, StreamKind::Perception);
//     connect(srv, &QTcpServer::newConnection, this, &GlobalReceiver::onNewConnection);
//     qInfo() << "[GlobalReceiver] Listening Perception on" << port;
//     return true;
// }

void GlobalReceiver::onNewConnection()
{
    auto* srv = qobject_cast<QTcpServer*>(sender());
    if (!srv) return;
    const quint16 port = srv->serverPort();

    while (srv->hasPendingConnections()) {
        QTcpSocket* s = srv->nextPendingConnection();
        auto* st = new ConnState{ s, QByteArray() };
        m_conns.insert(s, st);

        connect(s, &QTcpSocket::readyRead, this, &GlobalReceiver::onReadyRead);
        connect(s, &QTcpSocket::disconnected, this, &GlobalReceiver::onDisconnected);

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

    while (tryPopFrame(st->buffer, frame)) {
        processFrame(port, frame);
        frame.clear();
    }
}

void GlobalReceiver::onDisconnected()
{
    auto* s = qobject_cast<QTcpSocket*>(sender());
    if (!s) return;
    if (m_conns.contains(s)) {
        delete m_conns.take(s);
    }
    s->deleteLater();
}

// 4-byte big-endian length prefix framing
bool GlobalReceiver::tryPopFrame(QByteArray& buf, QByteArray& frame)
{
    if (buf.size() < 4) return false;
    const quint32 beLen = qFromBigEndian<quint32>(reinterpret_cast<const uchar*>(buf.constData()));
    if (buf.size() < 4 + static_cast<int>(beLen)) return false;

    frame = buf.mid(4, static_cast<int>(beLen));
    buf.remove(0, 4 + static_cast<int>(beLen));
    return true;
}

void GlobalReceiver::processFrame(quint16 port, const QByteArray& payload)
{
    const auto kind = m_portKinds.value(port, StreamKind::Controls); // default

    switch (kind) {
    case StreamKind::Controls: {
        emit controlsRaw(payload);

        Navigation nav;
        if (!nav.ParseFromArray(payload.constData(), payload.size())) {
            qWarning() << "[GlobalReceiver] Controls: failed to parse Navigation message";
            return;
        }
        emit controlsMessage(nav);
        break;
    }
        // case StreamKind::Perception: {
        //     emit perceptionRaw(payload);
        //     Perception p;
        //     if (!p.ParseFromArray(payload.constData(), payload.size())) {
        //         qWarning() << "[GlobalReceiver] Perception: failed to parse Perception";
        //         return;
        //     }
        //     emit perceptionMessage(p);
        //     break;
        // }
    }
}
