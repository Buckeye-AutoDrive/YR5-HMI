#include "NavigationBackend.h"
#include "GlobalReceiver.h"

// Qt Positioning header (install Qt Positioning if missing)
#include <QGeoCoordinate>

NavigationBackend::NavigationBackend(QObject* parent)
    : QObject(parent)
{
    m_rx = new GlobalReceiver(this);

    // Listen for HMI_RX_CONTROLS on port 5001
    m_rx->listenControls(5001);

    connect(m_rx, &GlobalReceiver::controlsMessage,
            this, &NavigationBackend::onControlsMessage);

    // LAN icon follows GlobalReceiver connection state
    connect(m_rx, &GlobalReceiver::lanConnectedChanged, this, [this](bool on){
        setLanOn(on);
    });

    // GNSS: go OFF if we stop receiving pose updates for a short time
    m_gnssTimeoutTimer.setInterval(m_gnssTimeout);
    m_gnssTimeoutTimer.setSingleShot(true);
    connect(&m_gnssTimeoutTimer, &QTimer::timeout, this, [this](){
        setGnssOn(false);
    });
}

void NavigationBackend::onControlsMessage(const Navigation& msg)
{
    // ---- Vehicle pose (always update) ----
    m_currentLat  = msg.current_lat();
    m_currentLon  = msg.current_lon();
    m_headingDeg  = msg.heading_deg();

    // GNSS ON while messages keep arriving
    setGnssOn(true);
    m_gnssTimeoutTimer.start();

    // ---- FSM / safety state ----
    const int newSafety = msg.safety_states();
    if (newSafety != m_safetyStates) {
        m_safetyStates = newSafety;
        emit safetyStatesChanged();
    }

    // AUTO ON when AV ACTIVE (state 8)
    setAutoOn(m_safetyStates == 8);

    // Notify pose/UI update (10 Hz etc.)
    emit updated();

    // ---- Waypoints (ALWAYS refresh) ----
    m_waypoints.clear();
    m_waypoints.reserve(msg.waypoints_size());

    for (const auto& wp : msg.waypoints()) {
        m_waypoints.push_back(QPointF(wp.lat(), wp.lon()));
    }

    // Always notify QML, even if unchanged or empty
    emit waypointsUpdated();
}


QVariantList NavigationBackend::waypointPath() const
{
    QVariantList out;
    out.reserve(m_waypoints.size());

    for (const auto& p : m_waypoints) {
        out.push_back(QVariant::fromValue(QGeoCoordinate(p.x(), p.y())));
    }
    return out;
}

QString NavigationBackend::fsmStateText() const
{
    switch (m_safetyStates) {
        case 0:  return "DEFAULT";
        case 1:  return "STARTUP";
        case 2:  return "PASSIVE MODE";
        case 3:  return "ACTIVATION CONDITION";
        case 4:  return "BRAKE ACTIVATION";
        case 5:  return "WAIT BRAKE RELEASE";
        case 6:  return "STEER ACTIVATION";
        case 7:  return "PROPULSION ACTIVATION";
        case 8:  return "AV ACTIVE";
        case 9:  return "DEACTIVATION";
        case 10: return "ACTIVATION FAILURE";
        default: return QString("STATE_%1").arg(m_safetyStates);
    }
}

void NavigationBackend::setGnssTimeout(int timeout)
{
    if (m_gnssTimeout == timeout) return;
    if (timeout < 100 || timeout > 10000) return; // Validate range
    
    m_gnssTimeout = timeout;
    m_gnssTimeoutTimer.setInterval(timeout);
    emit gnssTimeoutChanged();
}
