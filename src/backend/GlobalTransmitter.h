#pragma once

#include <QObject>
#include <QTcpSocket>
#include <QPointer>
#include <QTimer>
#include <QByteArray>
#include <QString>

// TX protobuf for HMI -> vehicle side commands
// Adjust the include path / filename to match your generated files.
#include "../proto/HMI_TX_CONTROLS.pb.h"   // HMITxMessage

// If/when you add more TX streams, e.g. PerceptionTx, uncomment and extend:
// #include "../proto/HMI_TX_PERCEPTION.pb.h"  // PerceptionTx

class GlobalTransmitter : public QObject
{
    Q_OBJECT

    // Basic connection status for QML / frontend
    Q_PROPERTY(bool hmiConnected  READ hmiConnected  NOTIFY hmiConnectionChanged)
    Q_PROPERTY(bool hmiConnecting READ hmiConnecting NOTIFY hmiConnectionChanged)
    Q_PROPERTY(QString hmiLastError READ hmiLastError NOTIFY hmiLastErrorChanged)

public:
    explicit GlobalTransmitter(QObject* parent = nullptr);
    ~GlobalTransmitter() override;

    // --- HMI TX channel (port 6001) ---

    // Host for the HMI TX stream, default "127.0.0.1".
    void setHmiHost(const QString& host);
    QString hmiHost() const { return m_hmi.host; }

    void setHmiPort(quint16 port);
    quint16 hmiPort() const { return m_hmi.port; }

    // Start (or restart) the background connection logic.
    Q_INVOKABLE void reconnectHmi();
    Q_INVOKABLE void disconnectHmi();

    // High-level QML-friendly API: build + send a HMITxMessage.
    // engageStatus: 0 = DISENGAGE, 1 = ENGAGE, 2 = DISABLED
    // targetDestination: e.g. "A", "B", "C"
    Q_INVOKABLE void sendEngageCommand(int engageStatus,
                                       const QString& targetDestination);

    // Lower-level C++ API: send a pre-built HMITxMessage.
    void send(const HMITxMessage& msg);

    // Connection status accessors for QML
    bool hmiConnected() const;
    bool hmiConnecting() const;
    QString hmiLastError() const { return m_hmi.lastError; }

signals:
    void hmiConnectionChanged();
    void hmiLastErrorChanged(const QString& error);

    // Emitted whenever a HMITxMessage is successfully serialized + queued
    // on the socket (useful for logging in the UI if desired).
    void hmiMessageSent(const HMITxMessage& msg);

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketError(QAbstractSocket::SocketError);
    void onReconnectTimeout();

private:
    struct TxChannel {
        QString host;
        quint16 port = 0;
        QPointer<QTcpSocket> socket;
        QTimer* reconnectTimer = nullptr;
        bool connecting = false;
        QString lastError;
    };

    // Single TX channel for now: HMI -> remote, port 6001.
    TxChannel m_hmi;

    void ensureSocket(TxChannel& ch);
    void startReconnectTimer(TxChannel& ch);
    void stopReconnectTimer(TxChannel& ch);

    void connectChannel(TxChannel& ch);
    void sendFrame(TxChannel& ch, const QByteArray& payload);

    // If/when you add more TX ports (each with its own proto type),
    // add more TxChannel members and mirror the pattern used for m_hmi:
    //
    // TxChannel m_perceptionTx;
    //
    // Then add public Q_INVOKABLE helper(s) similar to sendEngageCommand()
    // that build the appropriate protobuf and call sendFrame().
};
