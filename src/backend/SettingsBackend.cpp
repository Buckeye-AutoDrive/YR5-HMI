#include "SettingsBackend.h"
#include "GlobalTransmitter.h"
#include "NavigationBackend.h"
#include "GlobalReceiver.h"
#include <QSettings>
#include <QHostAddress>
#include <QDebug>
#include <QFile>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDir>
#include <QFileInfo>

SettingsBackend::SettingsBackend(QObject* parent)
    : QObject(parent)
    , m_settings(new QSettings("OSU", "HMI_Mk1", this))
    , m_txHost("192.168.69.10")
    , m_txPort(6001)
    , m_rxPort(5001)
    , m_rxPortPerception(6002)
    , m_rxPortLogger(6003)
    , m_gnssTimeout(1200)
    , m_defaultZoom(19)
    , m_followVehicle(true)
    , m_leftCameraUrl("rtsp://192.168.1.231:8554/cam1")
    , m_centerCameraUrl("rtsp://192.168.1.231:8554/cam0")
    , m_bumperCameraUrl("rtsp://192.168.1.231:8554/cam2")
    , m_rightCameraUrl("rtsp://192.168.1.231:8554/cam2")
{
    m_localSourcePath = QStringLiteral("/home/hmi/YR5-HMI");
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

void SettingsBackend::setRxPortPerception(int port)
{
    if (m_rxPortPerception == port) return;
    if (!validatePort(port)) {
        emit settingsError("Port must be between 1 and 65535");
        return;
    }
    m_rxPortPerception = port;
    emit rxPortPerceptionChanged();
}

void SettingsBackend::setRxPortLogger(int port)
{
    if (m_rxPortLogger == port) return;
    if (!validatePort(port)) {
        emit settingsError("Port must be between 1 and 65535");
        return;
    }
    m_rxPortLogger = port;
    emit rxPortLoggerChanged();
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

void SettingsBackend::setMap3dEnabled(bool enabled)
{
    if (m_map3dEnabled == enabled) return;
    m_map3dEnabled = enabled;
    emit map3dEnabledChanged();
}

void SettingsBackend::setThemeDark(bool dark)
{
    if (m_themeDark == dark) return;
    m_themeDark = dark;
    emit themeDarkChanged();
}

void SettingsBackend::setAutoBackupLogs(bool v)
{
    if (m_autoBackupLogs == v) return;
    m_autoBackupLogs = v;
    emit autoBackupLogsChanged();
}

void SettingsBackend::setWebdavServerUrl(const QString& v)
{
    if (m_webdavServerUrl == v) return;
    m_webdavServerUrl = v;
    emit webdavServerUrlChanged();
}

void SettingsBackend::setWebdavUsername(const QString& v)
{
    if (m_webdavUsername == v) return;
    m_webdavUsername = v;
    emit webdavUsernameChanged();
}

void SettingsBackend::setWebdavPassword(const QString& v)
{
    if (m_webdavPassword == v) return;
    m_webdavPassword = v;
    emit webdavPasswordChanged();
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

void SettingsBackend::setUseRtspStream(bool use)
{
    if (m_useRtspStream == use) return;
    m_useRtspStream = use;
    emit useRtspStreamChanged();
}

void SettingsBackend::setRightCameraUrl(const QString& url)
{
    if (m_rightCameraUrl == url) return;
    m_rightCameraUrl = url;
    emit rightCameraUrlChanged();
}

void SettingsBackend::setUserConfigEnabled(bool enabled)
{
    if (m_userConfigEnabled == enabled) return;
    m_userConfigEnabled = enabled;
    emit userConfigEnabledChanged();
}

void SettingsBackend::setLocalSourcePath(const QString& path)
{
    QString p = path.trimmed();
    while (p.endsWith(QLatin1Char('/')))
        p.chop(1);
    if (m_localSourcePath == p) return;
    m_localSourcePath = p;
    emit localSourcePathChanged();
}

void SettingsBackend::setTerminalButton1Label(const QString& v) { if (m_terminalButton1Label == v) return; m_terminalButton1Label = v; emit terminalButton1LabelChanged(); }
void SettingsBackend::setTerminalButton1Command(const QString& v) { if (m_terminalButton1Command == v) return; m_terminalButton1Command = v; emit terminalButton1CommandChanged(); }
void SettingsBackend::setTerminalButton2Label(const QString& v) { if (m_terminalButton2Label == v) return; m_terminalButton2Label = v; emit terminalButton2LabelChanged(); }
void SettingsBackend::setTerminalButton2Command(const QString& v) { if (m_terminalButton2Command == v) return; m_terminalButton2Command = v; emit terminalButton2CommandChanged(); }
void SettingsBackend::setTerminalButton3Label(const QString& v) { if (m_terminalButton3Label == v) return; m_terminalButton3Label = v; emit terminalButton3LabelChanged(); }
void SettingsBackend::setTerminalButton3Command(const QString& v) { if (m_terminalButton3Command == v) return; m_terminalButton3Command = v; emit terminalButton3CommandChanged(); }
void SettingsBackend::setTerminalButton4Label(const QString& v) { if (m_terminalButton4Label == v) return; m_terminalButton4Label = v; emit terminalButton4LabelChanged(); }
void SettingsBackend::setTerminalButton4Command(const QString& v) { if (m_terminalButton4Command == v) return; m_terminalButton4Command = v; emit terminalButton4CommandChanged(); }

void SettingsBackend::loadSettings()
{
    m_settings->beginGroup("network");
    m_txHost = m_settings->value("txHost", "192.168.69.10").toString();
    m_txPort = m_settings->value("txPort", 6001).toInt();
    m_rxPort = m_settings->value("rxPort", 5001).toInt();
    m_rxPortPerception = m_settings->value("rxPortPerception", 6002).toInt();
    m_rxPortLogger = m_settings->value("rxPortLogger", 6003).toInt();
    m_gnssTimeout = m_settings->value("gnssTimeout", 1200).toInt();
    m_settings->endGroup();

    m_settings->beginGroup("map");
    m_defaultZoom = m_settings->value("defaultZoom", 19).toInt();
    m_followVehicle = m_settings->value("followVehicle", true).toBool();
    m_map3dEnabled = m_settings->value("map3dEnabled", false).toBool();
    m_settings->endGroup();

    m_settings->beginGroup("theme");
    m_themeDark = m_settings->value("dark", true).toBool();
    m_settings->endGroup();

    m_settings->beginGroup("dataLogger");
    m_autoBackupLogs = m_settings->value("autoBackupLogs", false).toBool();
    m_webdavServerUrl = m_settings->value("webdavServerUrl", "https://webdav.calpardo.com/AutoDrive/HMI").toString();
    m_webdavUsername = m_settings->value("webdavUsername", "hmidav").toString();
    m_webdavPassword = m_settings->value("webdavPassword", "hmilogger123*").toString();
    m_settings->endGroup();

    m_settings->beginGroup("terminal");
    m_terminalButton1Label = m_settings->value("button1Label", "ipconfig").toString();
    m_terminalButton1Command = m_settings->value("button1Command", "ifconfig").toString();
    m_terminalButton2Label = m_settings->value("button2Label", "ssh intel").toString();
    m_terminalButton2Command = m_settings->value("button2Command", "ssh autodrive@192.168.69.10").toString();
    m_terminalButton3Label = m_settings->value("button3Label", "top").toString();
    m_terminalButton3Command = m_settings->value("button3Command", "top").toString();
    m_terminalButton4Label = m_settings->value("button4Label", "ls").toString();
    m_terminalButton4Command = m_settings->value("button4Command", "ls").toString();
    m_settings->endGroup();

    m_settings->beginGroup("cameras");
    m_useRtspStream = m_settings->value("useRtspStream", true).toBool();
    m_leftCameraUrl = m_settings->value("leftUrl", "rtsp://192.168.1.231:8554/cam1").toString();
    m_centerCameraUrl = m_settings->value("centerUrl", "rtsp://192.168.1.231:8554/cam0").toString();
    m_bumperCameraUrl = m_settings->value("bumperUrl", "rtsp://192.168.1.231:8554/cam2").toString();
    m_rightCameraUrl = m_settings->value("rightUrl", "rtsp://192.168.1.231:8554/cam2").toString();
    m_settings->endGroup();

    m_settings->beginGroup("userConfig");
    m_userConfigEnabled = m_settings->value("enabled", true).toBool();
    m_localSourcePath = m_settings->value("localSourcePath", QStringLiteral("/home/hmi/YR5-HMI")).toString();
    while (m_localSourcePath.endsWith(QLatin1Char('/')))
        m_localSourcePath.chop(1);
    m_settings->endGroup();

    // Emit all changed signals
    emit txHostChanged();
    emit txPortChanged();
    emit rxPortChanged();
    emit rxPortPerceptionChanged();
    emit rxPortLoggerChanged();
    emit gnssTimeoutChanged();
    emit defaultZoomChanged();
    emit followVehicleChanged();
    emit map3dEnabledChanged();
    emit themeDarkChanged();
    emit autoBackupLogsChanged();
    emit webdavServerUrlChanged();
    emit webdavUsernameChanged();
    emit webdavPasswordChanged();
    emit terminalButton1LabelChanged();
    emit terminalButton1CommandChanged();
    emit terminalButton2LabelChanged();
    emit terminalButton2CommandChanged();
    emit terminalButton3LabelChanged();
    emit terminalButton3CommandChanged();
    emit terminalButton4LabelChanged();
    emit terminalButton4CommandChanged();
    emit useRtspStreamChanged();
    emit leftCameraUrlChanged();
    emit centerCameraUrlChanged();
    emit bumperCameraUrlChanged();
    emit rightCameraUrlChanged();
    emit userConfigEnabledChanged();
    emit localSourcePathChanged();

#if defined(Q_OS_LINUX)
    if (m_userConfigEnabled && !m_localSourcePath.isEmpty()) {
        const QString configPath = m_localSourcePath + QLatin1String("/user-config.json");
        loadFromUserConfigFile(configPath);
        emit userConfigEnabledChanged();
        emit localSourcePathChanged();
    }
#endif
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
    m_settings->setValue("rxPortPerception", m_rxPortPerception);
    m_settings->setValue("rxPortLogger", m_rxPortLogger);
    m_settings->setValue("gnssTimeout", m_gnssTimeout);
    m_settings->endGroup();

    m_settings->beginGroup("map");
    m_settings->setValue("defaultZoom", m_defaultZoom);
    m_settings->setValue("followVehicle", m_followVehicle);
    m_settings->setValue("map3dEnabled", m_map3dEnabled);
    m_settings->endGroup();

    m_settings->beginGroup("theme");
    m_settings->setValue("dark", m_themeDark);
    m_settings->endGroup();

    m_settings->beginGroup("dataLogger");
    m_settings->setValue("autoBackupLogs", m_autoBackupLogs);
    m_settings->setValue("webdavServerUrl", m_webdavServerUrl);
    m_settings->setValue("webdavUsername", m_webdavUsername);
    m_settings->setValue("webdavPassword", m_webdavPassword);
    m_settings->endGroup();

    m_settings->beginGroup("terminal");
    m_settings->setValue("button1Label", m_terminalButton1Label);
    m_settings->setValue("button1Command", m_terminalButton1Command);
    m_settings->setValue("button2Label", m_terminalButton2Label);
    m_settings->setValue("button2Command", m_terminalButton2Command);
    m_settings->setValue("button3Label", m_terminalButton3Label);
    m_settings->setValue("button3Command", m_terminalButton3Command);
    m_settings->setValue("button4Label", m_terminalButton4Label);
    m_settings->setValue("button4Command", m_terminalButton4Command);
    m_settings->endGroup();

    m_settings->beginGroup("cameras");
    m_settings->setValue("useRtspStream", m_useRtspStream);
    m_settings->setValue("leftUrl", m_leftCameraUrl);
    m_settings->setValue("centerUrl", m_centerCameraUrl);
    m_settings->setValue("bumperUrl", m_bumperCameraUrl);
    m_settings->setValue("rightUrl", m_rightCameraUrl);
    m_settings->endGroup();

    m_settings->beginGroup("userConfig");
    m_settings->setValue("enabled", m_userConfigEnabled);
    m_settings->setValue("localSourcePath", m_localSourcePath);
    m_settings->endGroup();

    m_settings->sync();

#if defined(Q_OS_LINUX)
    if (m_userConfigEnabled && !m_localSourcePath.isEmpty()) {
        const QString configPath = m_localSourcePath + QLatin1String("/user-config.json");
        saveToUserConfigFile(configPath);
    }
#endif

    // Apply network settings immediately
    applyNetworkSettings();

    emit settingsSaved();
}

void SettingsBackend::resetToDefaults()
{
    m_txHost = "192.168.69.10";
    m_txPort = 6001;
    m_rxPort = 5001;
    m_rxPortPerception = 6002;
    m_rxPortLogger = 6003;
    m_gnssTimeout = 1200;
    m_defaultZoom = 19;
    m_followVehicle = true;
    m_map3dEnabled = false;
    m_themeDark = true;
    m_autoBackupLogs = false;
    m_webdavServerUrl = "https://webdav.calpardo.com/AutoDrive/HMI";
    m_webdavUsername = "hmidav";
    m_webdavPassword = "hmilogger123*";
    m_terminalButton1Label = "ipconfig";
    m_terminalButton1Command = "ifconfig";
    m_terminalButton2Label = "ssh intel";
    m_terminalButton2Command = "ssh autodrive@192.168.69.10";
    m_terminalButton3Label = "top";
    m_terminalButton3Command = "top";
    m_terminalButton4Label = "ls";
    m_terminalButton4Command = "ls";
    m_useRtspStream = true;
    m_leftCameraUrl = "rtsp://192.168.1.231:8554/cam1";
    m_centerCameraUrl = "rtsp://192.168.1.231:8554/cam0";
    m_bumperCameraUrl = "rtsp://192.168.1.231:8554/cam2";
    m_rightCameraUrl = "rtsp://192.168.1.231:8554/cam2";
    m_userConfigEnabled = true;
    m_localSourcePath = QStringLiteral("/home/hmi/YR5-HMI");

    emit txHostChanged();
    emit txPortChanged();
    emit rxPortChanged();
    emit rxPortPerceptionChanged();
    emit rxPortLoggerChanged();
    emit gnssTimeoutChanged();
    emit defaultZoomChanged();
    emit followVehicleChanged();
    emit map3dEnabledChanged();
    emit themeDarkChanged();
    emit autoBackupLogsChanged();
    emit webdavServerUrlChanged();
    emit webdavUsernameChanged();
    emit webdavPasswordChanged();
    emit terminalButton1LabelChanged();
    emit terminalButton1CommandChanged();
    emit terminalButton2LabelChanged();
    emit terminalButton2CommandChanged();
    emit terminalButton3LabelChanged();
    emit terminalButton3CommandChanged();
    emit terminalButton4LabelChanged();
    emit terminalButton4CommandChanged();
    emit useRtspStreamChanged();
    emit leftCameraUrlChanged();
    emit centerCameraUrlChanged();
    emit bumperCameraUrlChanged();
    emit rightCameraUrlChanged();
    emit userConfigEnabledChanged();
    emit localSourcePathChanged();
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
    if (!validatePort(m_rxPortPerception)) {
        emit settingsError("Invalid RX port perception (must be 1-65535)");
        return false;
    }
    if (!validatePort(m_rxPortLogger)) {
        emit settingsError("Invalid RX port logger (must be 1-65535)");
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

    // Apply GNSS timeout and RX ports to NavigationBackend
    if (m_nav) {
        m_nav->setGnssTimeout(m_gnssTimeout);
        m_nav->applyRxPorts(m_rxPort, m_rxPortPerception, m_rxPortLogger);
    }

    // Note: Further RX port changes take effect on next apply (e.g. Save in Settings)
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

void SettingsBackend::loadFromUserConfigFile(const QString& path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QByteArray data = f.readAll();
    f.close();

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
        return;

    QJsonObject o = doc.object();

    auto str = [&o](const char* key) -> QString {
        if (!o.contains(key)) return QString();
        return o.value(key).toString();
    };
    auto num = [&o](const char* key, int def) -> int {
        if (!o.contains(key)) return def;
        return o.value(key).toInt(def);
    };
    auto bol = [&o](const char* key, bool def) -> bool {
        if (!o.contains(key)) return def;
        return o.value(key).toBool(def);
    };

    if (o.contains("txHost")) m_txHost = str("txHost");
    if (o.contains("txPort")) m_txPort = num("txPort", m_txPort);
    if (o.contains("rxPort")) m_rxPort = num("rxPort", m_rxPort);
    if (o.contains("rxPortPerception")) m_rxPortPerception = num("rxPortPerception", m_rxPortPerception);
    if (o.contains("rxPortLogger")) m_rxPortLogger = num("rxPortLogger", m_rxPortLogger);
    if (o.contains("gnssTimeout")) m_gnssTimeout = num("gnssTimeout", m_gnssTimeout);
    if (o.contains("defaultZoom")) m_defaultZoom = num("defaultZoom", m_defaultZoom);
    if (o.contains("followVehicle")) m_followVehicle = bol("followVehicle", m_followVehicle);
    if (o.contains("map3dEnabled")) m_map3dEnabled = bol("map3dEnabled", m_map3dEnabled);
    if (o.contains("themeDark")) m_themeDark = bol("themeDark", m_themeDark);
    if (o.contains("autoBackupLogs")) m_autoBackupLogs = bol("autoBackupLogs", m_autoBackupLogs);
    if (o.contains("webdavServerUrl")) m_webdavServerUrl = str("webdavServerUrl");
    if (o.contains("webdavUsername")) m_webdavUsername = str("webdavUsername");
    if (o.contains("webdavPassword")) m_webdavPassword = str("webdavPassword");
    if (o.contains("terminalButton1Label")) m_terminalButton1Label = str("terminalButton1Label");
    if (o.contains("terminalButton1Command")) m_terminalButton1Command = str("terminalButton1Command");
    if (o.contains("terminalButton2Label")) m_terminalButton2Label = str("terminalButton2Label");
    if (o.contains("terminalButton2Command")) m_terminalButton2Command = str("terminalButton2Command");
    if (o.contains("terminalButton3Label")) m_terminalButton3Label = str("terminalButton3Label");
    if (o.contains("terminalButton3Command")) m_terminalButton3Command = str("terminalButton3Command");
    if (o.contains("terminalButton4Label")) m_terminalButton4Label = str("terminalButton4Label");
    if (o.contains("terminalButton4Command")) m_terminalButton4Command = str("terminalButton4Command");
    if (o.contains("useRtspStream")) m_useRtspStream = bol("useRtspStream", m_useRtspStream);
    if (o.contains("leftCameraUrl")) m_leftCameraUrl = str("leftCameraUrl");
    if (o.contains("centerCameraUrl")) m_centerCameraUrl = str("centerCameraUrl");
    if (o.contains("bumperCameraUrl")) m_bumperCameraUrl = str("bumperCameraUrl");
    if (o.contains("rightCameraUrl")) m_rightCameraUrl = str("rightCameraUrl");
    if (o.contains("userConfigEnabled")) m_userConfigEnabled = bol("userConfigEnabled", m_userConfigEnabled);
    if (o.contains("localSourcePath")) {
        QString p = str("localSourcePath").trimmed();
        while (p.endsWith(QLatin1Char('/'))) p.chop(1);
        if (!p.isEmpty()) m_localSourcePath = p;
    }
    // Backwards compat: old JSON may have userConfigPath (full path to file); treat as directory
    if (o.contains("userConfigPath")) {
        QString p = str("userConfigPath").trimmed();
        if (!p.isEmpty()) {
            if (p.endsWith(QLatin1String("/user-config.json")))
                p.chop(20);
            else if (p.endsWith(QLatin1String("user-config.json")))
                p.chop(19);
            while (p.endsWith(QLatin1Char('/'))) p.chop(1);
            if (!p.isEmpty()) m_localSourcePath = p;
        }
    }

    emit txHostChanged();
    emit txPortChanged();
    emit rxPortChanged();
    emit rxPortPerceptionChanged();
    emit rxPortLoggerChanged();
    emit gnssTimeoutChanged();
    emit defaultZoomChanged();
    emit followVehicleChanged();
    emit map3dEnabledChanged();
    emit themeDarkChanged();
    emit autoBackupLogsChanged();
    emit webdavServerUrlChanged();
    emit webdavUsernameChanged();
    emit webdavPasswordChanged();
    emit terminalButton1LabelChanged();
    emit terminalButton1CommandChanged();
    emit terminalButton2LabelChanged();
    emit terminalButton2CommandChanged();
    emit terminalButton3LabelChanged();
    emit terminalButton3CommandChanged();
    emit terminalButton4LabelChanged();
    emit terminalButton4CommandChanged();
    emit useRtspStreamChanged();
    emit leftCameraUrlChanged();
    emit centerCameraUrlChanged();
    emit bumperCameraUrlChanged();
    emit rightCameraUrlChanged();
}

void SettingsBackend::saveToUserConfigFile(const QString& path)
{
    if (path.isEmpty()) return;

    QFileInfo fi(path);
    QDir dir = fi.absoluteDir();
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        qWarning() << "SettingsBackend: could not create directory for" << path;
        return;
    }

    QJsonObject o;
    o.insert(QStringLiteral("txHost"), m_txHost);
    o.insert(QStringLiteral("txPort"), m_txPort);
    o.insert(QStringLiteral("rxPort"), m_rxPort);
    o.insert(QStringLiteral("rxPortPerception"), m_rxPortPerception);
    o.insert(QStringLiteral("rxPortLogger"), m_rxPortLogger);
    o.insert(QStringLiteral("gnssTimeout"), m_gnssTimeout);
    o.insert(QStringLiteral("defaultZoom"), m_defaultZoom);
    o.insert(QStringLiteral("followVehicle"), m_followVehicle);
    o.insert(QStringLiteral("map3dEnabled"), m_map3dEnabled);
    o.insert(QStringLiteral("themeDark"), m_themeDark);
    o.insert(QStringLiteral("autoBackupLogs"), m_autoBackupLogs);
    o.insert(QStringLiteral("webdavServerUrl"), m_webdavServerUrl);
    o.insert(QStringLiteral("webdavUsername"), m_webdavUsername);
    o.insert(QStringLiteral("webdavPassword"), m_webdavPassword);
    o.insert(QStringLiteral("terminalButton1Label"), m_terminalButton1Label);
    o.insert(QStringLiteral("terminalButton1Command"), m_terminalButton1Command);
    o.insert(QStringLiteral("terminalButton2Label"), m_terminalButton2Label);
    o.insert(QStringLiteral("terminalButton2Command"), m_terminalButton2Command);
    o.insert(QStringLiteral("terminalButton3Label"), m_terminalButton3Label);
    o.insert(QStringLiteral("terminalButton3Command"), m_terminalButton3Command);
    o.insert(QStringLiteral("terminalButton4Label"), m_terminalButton4Label);
    o.insert(QStringLiteral("terminalButton4Command"), m_terminalButton4Command);
    o.insert(QStringLiteral("useRtspStream"), m_useRtspStream);
    o.insert(QStringLiteral("leftCameraUrl"), m_leftCameraUrl);
    o.insert(QStringLiteral("centerCameraUrl"), m_centerCameraUrl);
    o.insert(QStringLiteral("bumperCameraUrl"), m_bumperCameraUrl);
    o.insert(QStringLiteral("rightCameraUrl"), m_rightCameraUrl);
    o.insert(QStringLiteral("userConfigEnabled"), m_userConfigEnabled);
    o.insert(QStringLiteral("localSourcePath"), m_localSourcePath);

    QSaveFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "SettingsBackend: could not write" << path << f.errorString();
        return;
    }
    f.write(QJsonDocument(o).toJson(QJsonDocument::Indented));
    if (!f.commit()) {
        qWarning() << "SettingsBackend: could not commit" << path << f.errorString();
    }
}
