#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QHash>
#include <QByteArray>
#include <QPointer>

#include "../proto/HMI_RX_CONTROLS.pb.h"   // Navigation

// If/when you generate PERCEPTION, uncomment:
// #include "../proto/HMI_RX_PERCEPTION.pb.h"  // Perception

class GlobalReceiver : public QObject
{
    Q_OBJECT
public:
    explicit GlobalReceiver(QObject* parent = nullptr);

    // Add a listening port dedicated to the CONTROLS stream
    bool listenControls(quint16 port = 5001);

    // Example API for a second stream (PERCEPTION) – keep commented for now
    // bool listenPerception(quint16 port = 5002);

signals:
    // Raw payloads (already deframed by length prefix)
    void controlsRaw(const QByteArray& payload);
    // Typed message
    void controlsMessage(const Navigation& msg);

    // Future:
    // void perceptionRaw(const QByteArray& payload);
    // void perceptionMessage(const Perception& msg);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onDisconnected();

private:
    struct ConnState {
        QPointer<QTcpSocket> sock;
        QByteArray buffer;
    };

    // One QTcpServer per port
    QHash<quint16, QPointer<QTcpServer>> m_servers;
    // Per-socket parse buffers
    QHash<QTcpSocket*, ConnState*> m_conns;

    // framing: 4-byte big-endian length prefix
    static bool tryPopFrame(QByteArray& buf, QByteArray& frame);

    // Which stream does this port represent?
    enum class StreamKind { Controls /*, Perception*/ };
    QHash<quint16, StreamKind> m_portKinds;

    void processFrame(quint16 port, const QByteArray& payload);
};
