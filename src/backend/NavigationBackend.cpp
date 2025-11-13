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
    // Update current fix
    m_currentLat  = msg.current_lat();
    m_currentLon  = msg.current_lon();
    m_headingDeg  = msg.heading_deg();

    emit updated();

    // Update waypoint list
    if (msg.waypoints_size() > 0)
    {
        m_waypoints.clear();
        m_waypoints.reserve(msg.waypoints_size());

        for (const auto& wp : msg.waypoints()) {
            m_waypoints.push_back(QPointF(wp.lat(), wp.lon()));
        }

        emit waypointsUpdated();
    }
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
