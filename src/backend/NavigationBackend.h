#pragma once

#include <QObject>
#include <QVector>
#include <QPointF>
#include <QVariant>

// Include the generated protobuf header
#include "HMI_RX_CONTROLS.pb.h"

// Forward declare GlobalReceiver
class GlobalReceiver;

class NavigationBackend : public QObject {
    Q_OBJECT

    Q_PROPERTY(double currentLat  READ currentLat  NOTIFY updated)
    Q_PROPERTY(double currentLon  READ currentLon  NOTIFY updated)
    Q_PROPERTY(double headingDeg  READ headingDeg  NOTIFY updated)

public:
    explicit NavigationBackend(QObject* parent = nullptr);

    double currentLat()  const { return m_currentLat; }
    double currentLon()  const { return m_currentLon; }
    double headingDeg()  const { return m_headingDeg; }

    // QML-friendly waypoint list
    Q_INVOKABLE QVariantList waypointPath() const;

signals:
    void updated();
    void waypointsUpdated();

public slots:
    void onControlsMessage(const Navigation& msg);

private:
    GlobalReceiver* m_rx = nullptr;

    double m_currentLat = 0.0;
    double m_currentLon = 0.0;
    double m_headingDeg = 0.0;

    QVector<QPointF> m_waypoints;  // (lat, lon)
};
