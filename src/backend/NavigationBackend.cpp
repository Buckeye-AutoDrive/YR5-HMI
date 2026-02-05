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
}

void NavigationBackend::onControlsMessage(const Navigation& msg)
{
    // ---- Vehicle pose (always update) ----
    m_currentLat  = msg.current_lat();
    m_currentLon  = msg.current_lon();
    m_headingDeg  = msg.heading_deg();

    // ---- FSM / safety state ----
    const int newSafety = msg.safety_states();
    if (newSafety != m_safetyStates) {
        m_safetyStates = newSafety;
        emit safetyStatesChanged();
    }

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
        case 0:  return "STATE_0";
        case 1:  return "STATE_STARTUP";
        case 2:  return "STATE_PASSIVE_MODE";
        case 3:  return "STATE_ACTIVATION_CONDITION";
        case 4:  return "STATE_BRAKE_ACTIVATION";
        case 5:  return "STATE_WAIT_BRAKE_RELEASE";
        case 6:  return "STATE_STEER_ACTIVATION";
        case 7:  return "STATE_PROPULSION_ACTIVATION";
        case 8:  return "STATE_AV";
        case 9:  return "STATE_DEACTIVATION";
        case 10: return "STATE_ACTIVATION_FAILURE";
        default: return QString("STATE_%1").arg(m_safetyStates);
    }
}
