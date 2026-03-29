#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QHash>
#include <QByteArray>
#include <QPointer>

#include "../proto/HMI_RX_CONTROLS.pb.h"   // Navigation
#include "../proto/HMI_RX_CAN.pb.h"       // can_stream::CanBatch
#include "../proto/HMI_RX_PERCEPTION.pb.h"  // hmi::perception::v1::PerceptionFrame

class GlobalReceiver : public QObject
{
    Q_OBJECT
public:
    explicit GlobalReceiver(QObject* parent = nullptr);

    // Add a listening port dedicated to the CONTROLS stream
    bool listenControls(quint16 port = 5001);

    // Perception stream (4-byte big-endian length prefix, PerceptionFrame)
    bool listenPerception(quint16 port = 6002);

    // Logger stream: CAN batches, 32-bit LE length prefix
    bool listenLogger(quint16 port = 6003);

signals:
    // Raw payloads (already deframed by length prefix)
    void controlsRaw(const QByteArray& payload);
    // Typed message (Controls port: 0x01 Navigation, 0x02 CameraBatch, 0x03 Controls)
    void controlsMessage(const vehicle_msgs::Navigation& msg);
    void cameraBatchReceived(const vehicle_msgs::CameraBatch& batch);
    void controlsStateReceived(const vehicle_msgs::Controls& msg);

    void lanConnectedChanged(bool connected);

    // CAN logger stream (CanBatch, 32-bit LE length prefix from TX)
    void canBatchReceived(const can_stream::CanBatch& batch);

    // CAN status icon: true when port 6003 has a connection and has received data
    void canLoggerActiveChanged(bool active);

    // Perception stream (port 6002, PerceptionFrame)
    void perceptionFrameReceived(const hmi::perception::v1::PerceptionFrame& frame);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onDisconnected();

private:
    struct ConnState {
        QPointer<QTcpSocket> sock;
        QByteArray buffer;
        quint16 port = 0;
    };

    // One QTcpServer per port
    QHash<quint16, QPointer<QTcpServer>> m_servers;
    // Per-socket parse buffers
    QHash<QTcpSocket*, ConnState*> m_conns;

    // Framing: Controls = 4-byte big-endian; Logger = 4-byte little-endian (per TX spec)
    bool tryPopFrame(quint16 port, QByteArray& buf, QByteArray& frame);

    // Which stream does this port represent?
    enum class StreamKind { Controls, Logger, Perception };
    QHash<quint16, StreamKind> m_portKinds;

    void processFrame(quint16 port, const QByteArray& payload);

    bool hasLoggerConnection() const;
    void updateCanLoggerActive();

    bool m_lanConnected = false;
    bool m_loggerHasData = false;
    bool m_canLoggerActive = false;

    void setLanConnected(bool v) {
        if (m_lanConnected == v) return;
        m_lanConnected = v;
        emit lanConnectedChanged(m_lanConnected);
    }
};
