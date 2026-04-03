#include "NavigationBackend.h"
#include "GlobalReceiver.h"

// Qt Positioning header (install Qt Positioning if missing)
#include <QGeoCoordinate>
#include <cmath>

NavigationBackend::NavigationBackend(QObject* parent)
    : QObject(parent)
{
    m_rx = new GlobalReceiver(this);
    // Listeners started via applyRxPorts() from SettingsBackend::applyNetworkSettings()

    connect(m_rx, &GlobalReceiver::controlsMessage,
            this, &NavigationBackend::onControlsMessage);
    connect(m_rx, &GlobalReceiver::controlsStateReceived,
            this, &NavigationBackend::onControlsState);

    // LAN icon follows GlobalReceiver connection state
    connect(m_rx, &GlobalReceiver::lanConnectedChanged, this, [this](bool on){
        setLanOn(on);
    });

    // CAN icon: on when logger port (6003) has connection and has received data
    connect(m_rx, &GlobalReceiver::canLoggerActiveChanged,
            this, &NavigationBackend::onCanLoggerActiveChanged);

    // GNSS: go OFF if we stop receiving pose updates for a short time
    m_gnssTimeoutTimer.setInterval(m_gnssTimeout);
    m_gnssTimeoutTimer.setSingleShot(true);
    connect(&m_gnssTimeoutTimer, &QTimer::timeout, this, [this](){
        setGnssOn(false);
    });

    // Engagement / FSM: treat silent Navigation (0x01) stream as disengaged (same window as GNSS)
    m_navigationStackTimeoutTimer.setInterval(m_gnssTimeout);
    m_navigationStackTimeoutTimer.setSingleShot(true);
    connect(&m_navigationStackTimeoutTimer, &QTimer::timeout,
            this, &NavigationBackend::onNavigationStackTimeout);

    m_controlsStackTimeoutTimer.setInterval(m_gnssTimeout);
    m_controlsStackTimeoutTimer.setSingleShot(true);
    connect(&m_controlsStackTimeoutTimer, &QTimer::timeout,
            this, &NavigationBackend::onControlsStackTimeout);
}

namespace {
QString maneuverTypeFromInstruction(const std::string& raw)
{
    // Publisher may send "STRAIGHT", "LEFT", "RIGHT", or "LEFT, 12.3 m" — use first segment.
    const QString head = QString::fromStdString(raw).section(QLatin1Char(','), 0, 0).trimmed().toUpper();
    if (head.startsWith(QLatin1String("LEFT")))
        return QStringLiteral("left");
    if (head.startsWith(QLatin1String("RIGHT")))
        return QStringLiteral("right");
    return QStringLiteral("straight");
}
} // namespace

void NavigationBackend::markControlsStackFresh()
{
    m_controlsStackTimeoutTimer.start();
    const bool first = !m_controlsEverReceived;
    if (first) {
        m_controlsEverReceived = true;
        emit controlsEverReceivedChanged();
    }
    if (!m_controlsStackFresh) {
        m_controlsStackFresh = true;
        emit controlsStackFreshChanged();
    }
}

void NavigationBackend::onControlsStackTimeout()
{
    if (!m_controlsEverReceived || !m_controlsStackFresh)
        return;
    m_controlsStackFresh = false;
    emit controlsStackFreshChanged();
}

void NavigationBackend::onControlsState(const vehicle_msgs::Controls& msg)
{
    // Keep-alive for type 0x03 even when maneuver fields are unchanged (early return below).
    markControlsStackFresh();

    const QString kind = maneuverTypeFromInstruction(msg.next_instruction());
    const float d = msg.next_distance_m();
    const bool finite = std::isfinite(static_cast<double>(d)) && d >= 0.f && d < 1e7f;
    const int meters = finite ? qBound(0, static_cast<int>(std::lround(static_cast<double>(d))), 999999) : -1;

    const bool distValid = finite;
    if (kind == m_nextManeuverType && distValid == m_nextManeuverDistanceValid
        && (!distValid || meters == m_nextManeuverDistanceM)) {
        return;
    }

    m_nextManeuverType = kind;
    m_nextManeuverDistanceValid = distValid;
    m_nextManeuverDistanceM = distValid ? meters : -1;
    emit nextManeuverChanged();
}

void NavigationBackend::markNavigationStackFresh()
{
    m_navigationStackTimeoutTimer.start();
    if (!m_navigationStackFresh) {
        m_navigationStackFresh = true;
        emit navigationStackFreshChanged();
    }
}

void NavigationBackend::onNavigationStackTimeout()
{
    if (!m_navigationStackFresh)
        return;
    m_navigationStackFresh = false;
    emit navigationStackFreshChanged();

    // Drop stale safety so FSM / icons match disengaged UI
    if (m_safetyStates != 0) {
        m_safetyStates = 0;
        emit safetyStatesChanged();
    }
    setAutoOn(false);
}

void NavigationBackend::onControlsMessage(const vehicle_msgs::Navigation& msg)
{
    markNavigationStackFresh();

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

    // Auto / autonomy icon: on for any stack state except disengaged defaults (0, 9, 10).
    // Matches Main.qml right-panel engagement (not only state 8 "AV ACTIVE").
    const bool autonomyIndicated = (m_safetyStates != 0 && m_safetyStates != 2 && m_safetyStates != 9 && m_safetyStates != 10);
    setAutoOn(autonomyIndicated);

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

void NavigationBackend::applyRxPorts(int controlsPort, int perceptionPort, int loggerPort)
{
    if (m_rx) {
        m_rx->listenControls(static_cast<quint16>(controlsPort));
        m_rx->listenPerception(static_cast<quint16>(perceptionPort));
        m_rx->listenLogger(static_cast<quint16>(loggerPort));
    }
}

void NavigationBackend::onCanLoggerActiveChanged(bool active)
{
    if (m_canLoggerOn == active) return;
    m_canLoggerOn = active;
    emit canLoggerOnChanged();
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
    m_navigationStackTimeoutTimer.setInterval(timeout);
    m_controlsStackTimeoutTimer.setInterval(timeout);
    emit gnssTimeoutChanged();
}
