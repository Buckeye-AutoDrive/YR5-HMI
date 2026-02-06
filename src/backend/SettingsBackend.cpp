#include "SettingsBackend.h"
#include "GlobalTransmitter.h"
#include "NavigationBackend.h"
#include "GlobalReceiver.h"
#include <QSettings>
#include <QHostAddress>
#include <QDebug>

SettingsBackend::SettingsBackend(QObject* parent)
    : QObject(parent)
    , m_settings(new QSettings("OSU", "HMI_Mk1", this))
    , m_txHost("192.168.69.10")
    , m_txPort(6001)
    , m_rxPort(5001)
    , m_gnssTimeout(1200)
    , m_defaultZoom(19)
    , m_followVehicle(true)
    , m_leftCameraUrl("rtsp://192.168.1.231:8554/cam1")
    , m_centerCameraUrl("rtsp://192.168.1.231:8554/cam0")
    , m_bumperCameraUrl("rtsp://192.168.1.231:8554/cam2")
    , m_rightCameraUrl("rtsp://192.168.1.231:8554/cam2")
{
    loadSettings();
}

void SettingsBackend::setTxHost(const QString& host)
{
    if (m_txHost == host) return;
    if (!validateHost(host)) {
        emit settingsError("Invalid host address format");
        return;
    }
    m_txHost = host;
    emit txHostChanged();
}

void SettingsBackend::setTxPort(int port)
{
    if (m_txPort == port) return;
    if (!validatePort(port)) {
        emit settingsError("Port must be between 1 and 65535");
        return;
    }
    m_txPort = port;
    emit txPortChanged();
}

void SettingsBackend::setRxPort(int port)
{
    if (m_rxPort == port) return;
    if (!validatePort(port)) {
        emit settingsError("Port must be between 1 and 65535");
        return;
    }
    m_rxPort = port;
    emit rxPortChanged();
}

void SettingsBackend::setGnssTimeout(int timeout)
{
    if (m_gnssTimeout == timeout) return;
    if (timeout < 100 || timeout > 10000) {
        emit settingsError("GNSS timeout must be between 100 and 10000 ms");
        return;
    }
    m_gnssTimeout = timeout;
    emit gnssTimeoutChanged();
}

void SettingsBackend::setDefaultZoom(int zoom)
{
    if (m_defaultZoom == zoom) return;
    if (zoom < 1 || zoom > 20) {
        emit settingsError("Zoom level must be between 1 and 20");
        return;
    }
    m_defaultZoom = zoom;
    emit defaultZoomChanged();
}

void SettingsBackend::setFollowVehicle(bool follow)
{
    if (m_followVehicle == follow) return;
    m_followVehicle = follow;
    emit followVehicleChanged();
}

void SettingsBackend::setThemeDark(bool dark)
{
    if (m_themeDark == dark) return;
    m_themeDark = dark;
    emit themeDarkChanged();
}

void SettingsBackend::setLeftCameraUrl(const QString& url)
{
    if (m_leftCameraUrl == url) return;
    m_leftCameraUrl = url;
    emit leftCameraUrlChanged();
}

void SettingsBackend::setCenterCameraUrl(const QString& url)
{
    if (m_centerCameraUrl == url) return;
    m_centerCameraUrl = url;
    emit centerCameraUrlChanged();
}

void SettingsBackend::setBumperCameraUrl(const QString& url)
{
    if (m_bumperCameraUrl == url) return;
    m_bumperCameraUrl = url;
    emit bumperCameraUrlChanged();
}

void SettingsBackend::setRightCameraUrl(const QString& url)
{
    if (m_rightCameraUrl == url) return;
    m_rightCameraUrl = url;
    emit rightCameraUrlChanged();
}

void SettingsBackend::loadSettings()
{
    m_settings->beginGroup("network");
    m_txHost = m_settings->value("txHost", "192.168.69.10").toString();
    m_txPort = m_settings->value("txPort", 6001).toInt();
    m_rxPort = m_settings->value("rxPort", 5001).toInt();
    m_gnssTimeout = m_settings->value("gnssTimeout", 1200).toInt();
    m_settings->endGroup();

    m_settings->beginGroup("map");
    m_defaultZoom = m_settings->value("defaultZoom", 19).toInt();
    m_followVehicle = m_settings->value("followVehicle", true).toBool();
    m_settings->endGroup();

    m_settings->beginGroup("theme");
    m_themeDark = m_settings->value("dark", true).toBool();
    m_settings->endGroup();

    m_settings->beginGroup("cameras");
    m_leftCameraUrl = m_settings->value("leftUrl", "rtsp://192.168.1.231:8554/cam1").toString();
    m_centerCameraUrl = m_settings->value("centerUrl", "rtsp://192.168.1.231:8554/cam0").toString();
    m_bumperCameraUrl = m_settings->value("bumperUrl", "rtsp://192.168.1.231:8554/cam2").toString();
    m_rightCameraUrl = m_settings->value("rightUrl", "rtsp://192.168.1.231:8554/cam2").toString();
    m_settings->endGroup();

    // Emit all changed signals
    emit txHostChanged();
    emit txPortChanged();
    emit rxPortChanged();
    emit gnssTimeoutChanged();
    emit defaultZoomChanged();
    emit followVehicleChanged();
    emit themeDarkChanged();
    emit leftCameraUrlChanged();
    emit centerCameraUrlChanged();
    emit bumperCameraUrlChanged();
    emit rightCameraUrlChanged();
}

void SettingsBackend::saveSettings()
{
    if (!validateSettings()) {
        return;
    }

    m_settings->beginGroup("network");
    m_settings->setValue("txHost", m_txHost);
    m_settings->setValue("txPort", m_txPort);
    m_settings->setValue("rxPort", m_rxPort);
    m_settings->setValue("gnssTimeout", m_gnssTimeout);
    m_settings->endGroup();

    m_settings->beginGroup("map");
    m_settings->setValue("defaultZoom", m_defaultZoom);
    m_settings->setValue("followVehicle", m_followVehicle);
    m_settings->endGroup();

    m_settings->beginGroup("theme");
    m_settings->setValue("dark", m_themeDark);
    m_settings->endGroup();

    m_settings->beginGroup("cameras");
    m_settings->setValue("leftUrl", m_leftCameraUrl);
    m_settings->setValue("centerUrl", m_centerCameraUrl);
    m_settings->setValue("bumperUrl", m_bumperCameraUrl);
    m_settings->setValue("rightUrl", m_rightCameraUrl);
    m_settings->endGroup();

    m_settings->sync();

    // Apply network settings immediately
    applyNetworkSettings();

    emit settingsSaved();
}

void SettingsBackend::resetToDefaults()
{
    m_txHost = "192.168.69.10";
    m_txPort = 6001;
    m_rxPort = 5001;
    m_gnssTimeout = 1200;
    m_defaultZoom = 19;
    m_followVehicle = true;
    m_themeDark = true;
    m_leftCameraUrl = "rtsp://192.168.1.231:8554/cam1";
    m_centerCameraUrl = "rtsp://192.168.1.231:8554/cam0";
    m_bumperCameraUrl = "rtsp://192.168.1.231:8554/cam2";
    m_rightCameraUrl = "rtsp://192.168.1.231:8554/cam2";

    emit txHostChanged();
    emit txPortChanged();
    emit rxPortChanged();
    emit gnssTimeoutChanged();
    emit defaultZoomChanged();
    emit followVehicleChanged();
    emit themeDarkChanged();
    emit leftCameraUrlChanged();
    emit centerCameraUrlChanged();
    emit bumperCameraUrlChanged();
    emit rightCameraUrlChanged();
}

bool SettingsBackend::validateSettings()
{
    if (!validateHost(m_txHost)) {
        emit settingsError("Invalid TX host address");
        return false;
    }
    if (!validatePort(m_txPort)) {
        emit settingsError("Invalid TX port (must be 1-65535)");
        return false;
    }
    if (!validatePort(m_rxPort)) {
        emit settingsError("Invalid RX port (must be 1-65535)");
        return false;
    }
    if (m_gnssTimeout < 100 || m_gnssTimeout > 10000) {
        emit settingsError("GNSS timeout must be between 100 and 10000 ms");
        return false;
    }
    if (m_defaultZoom < 1 || m_defaultZoom > 20) {
        emit settingsError("Zoom level must be between 1 and 20");
        return false;
    }
    return true;
}

void SettingsBackend::applyNetworkSettings()
{
    // Apply TX settings
    if (m_tx) {
        m_tx->setHmiHost(m_txHost);
        m_tx->setHmiPort(static_cast<quint16>(m_txPort));
        m_tx->reconnectHmi();
    }

    // Apply GNSS timeout to NavigationBackend
    if (m_nav) {
        m_nav->setGnssTimeout(m_gnssTimeout);
    }

    // Note: RX port change requires restarting the receiver
    // This would require NavigationBackend to recreate GlobalReceiver
    // For now, RX port changes require app restart to take effect
}

bool SettingsBackend::validatePort(int port)
{
    return port >= 1 && port <= 65535;
}

bool SettingsBackend::validateHost(const QString& host)
{
    if (host.isEmpty()) return false;
    QHostAddress addr;
    return addr.setAddress(host);
}

void SettingsBackend::applyInitialSettings()
{
    // Apply loaded settings to backends after they're connected
    applyNetworkSettings();
}
