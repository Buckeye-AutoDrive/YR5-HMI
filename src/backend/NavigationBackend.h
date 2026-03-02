#pragma once

#include <QObject>
#include <QVector>
#include <QPointF>
#include <QVariant>
#include <QString>
#include <QTimer>

#include "HMI_RX_CONTROLS.pb.h"   // Navigation

class GlobalReceiver;

class NavigationBackend : public QObject {
    Q_OBJECT

    Q_PROPERTY(double  currentLat    READ currentLat    NOTIFY updated)
    Q_PROPERTY(double  currentLon    READ currentLon    NOTIFY updated)
    Q_PROPERTY(double  headingDeg    READ headingDeg    NOTIFY updated)
    Q_PROPERTY(int     safetyStates  READ safetyStates  NOTIFY safetyStatesChanged)
    Q_PROPERTY(QString fsmStateText  READ fsmStateText  NOTIFY safetyStatesChanged)
    Q_PROPERTY(bool    gnssOn        READ gnssOn         NOTIFY gnssOnChanged)
    Q_PROPERTY(bool    lanOn         READ lanOn          NOTIFY lanOnChanged)
    Q_PROPERTY(bool    canLoggerOn   READ canLoggerOn    NOTIFY canLoggerOnChanged)
    Q_PROPERTY(bool    autoOn        READ autoOn         NOTIFY autoOnChanged)
    Q_PROPERTY(int     gnssTimeout   READ gnssTimeout    WRITE setGnssTimeout NOTIFY gnssTimeoutChanged)

public:
    explicit NavigationBackend(QObject* parent = nullptr);

    double currentLat() const { return m_currentLat; }
    double currentLon() const { return m_currentLon; }
    double headingDeg() const { return m_headingDeg; }

    int safetyStates() const { return m_safetyStates; }
    QString fsmStateText() const;

    bool gnssOn() const { return m_gnssOn; }
    bool lanOn()  const { return m_lanOn; }
    bool canLoggerOn() const { return m_canLoggerOn; }
    bool autoOn() const { return m_autoOn; }
    int gnssTimeout() const { return m_gnssTimeout; }
    void setGnssTimeout(int timeout);

    Q_INVOKABLE QVariantList waypointPath() const;

    // So that main can connect canBatchReceived and settings can apply RX ports
    GlobalReceiver* globalReceiver() const { return m_rx; }
    void applyRxPorts(int controlsPort, int perceptionPort, int loggerPort);

signals:
    void updated();
    void waypointsUpdated();
    void safetyStatesChanged();
    void gnssOnChanged();
    void lanOnChanged();
    void canLoggerOnChanged();
    void autoOnChanged();
    void gnssTimeoutChanged();

public slots:
    void onControlsMessage(const vehicle_msgs::Navigation& msg);

private slots:
    void onCanLoggerActiveChanged(bool active);

private:
    void setGnssOn(bool v) { if (m_gnssOn==v) return; m_gnssOn=v; emit gnssOnChanged(); }
    void setLanOn(bool v)  { if (m_lanOn==v)  return; m_lanOn=v;  emit lanOnChanged(); }
    void setAutoOn(bool v) { if (m_autoOn==v) return; m_autoOn=v; emit autoOnChanged(); }

    GlobalReceiver* m_rx = nullptr;

    double m_currentLat = 0.0;
    double m_currentLon = 0.0;
    double m_headingDeg = 0.0;

    int m_safetyStates = 0;

    QVector<QPointF> m_waypoints;  // (lat, lon)

    bool m_gnssOn = false;
    bool m_lanOn  = false;
    bool m_canLoggerOn = false;
    bool m_autoOn = false;

    int m_gnssTimeout = 1200;
    QTimer m_gnssTimeoutTimer;
};
