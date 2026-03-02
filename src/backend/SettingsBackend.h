#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

class GlobalTransmitter;
class NavigationBackend;
class GlobalReceiver;

class SettingsBackend : public QObject
{
    Q_OBJECT

    // Network Settings
    Q_PROPERTY(QString txHost READ txHost WRITE setTxHost NOTIFY txHostChanged)
    Q_PROPERTY(int txPort READ txPort WRITE setTxPort NOTIFY txPortChanged)
    Q_PROPERTY(int rxPort READ rxPort WRITE setRxPort NOTIFY rxPortChanged)
    Q_PROPERTY(int rxPortPerception READ rxPortPerception WRITE setRxPortPerception NOTIFY rxPortPerceptionChanged)
    Q_PROPERTY(int rxPortLogger READ rxPortLogger WRITE setRxPortLogger NOTIFY rxPortLoggerChanged)
    Q_PROPERTY(int gnssTimeout READ gnssTimeout WRITE setGnssTimeout NOTIFY gnssTimeoutChanged)

    // Map Settings
    Q_PROPERTY(int defaultZoom READ defaultZoom WRITE setDefaultZoom NOTIFY defaultZoomChanged)
    Q_PROPERTY(bool followVehicle READ followVehicle WRITE setFollowVehicle NOTIFY followVehicleChanged)
    Q_PROPERTY(bool map3dEnabled READ map3dEnabled WRITE setMap3dEnabled NOTIFY map3dEnabledChanged)

    // Theme (dark = true, light = false; map and camera feeds are unchanged)
    Q_PROPERTY(bool themeDark READ themeDark WRITE setThemeDark NOTIFY themeDarkChanged)

    // Data Logger (WebDAV backup)
    Q_PROPERTY(bool autoBackupLogs READ autoBackupLogs WRITE setAutoBackupLogs NOTIFY autoBackupLogsChanged)
    Q_PROPERTY(QString webdavServerUrl READ webdavServerUrl WRITE setWebdavServerUrl NOTIFY webdavServerUrlChanged)
    Q_PROPERTY(QString webdavUsername READ webdavUsername WRITE setWebdavUsername NOTIFY webdavUsernameChanged)
    Q_PROPERTY(QString webdavPassword READ webdavPassword WRITE setWebdavPassword NOTIFY webdavPasswordChanged)

    // Terminal (first 4 buttons: label + command each)
    Q_PROPERTY(QString terminalButton1Label READ terminalButton1Label WRITE setTerminalButton1Label NOTIFY terminalButton1LabelChanged)
    Q_PROPERTY(QString terminalButton1Command READ terminalButton1Command WRITE setTerminalButton1Command NOTIFY terminalButton1CommandChanged)
    Q_PROPERTY(QString terminalButton2Label READ terminalButton2Label WRITE setTerminalButton2Label NOTIFY terminalButton2LabelChanged)
    Q_PROPERTY(QString terminalButton2Command READ terminalButton2Command WRITE setTerminalButton2Command NOTIFY terminalButton2CommandChanged)
    Q_PROPERTY(QString terminalButton3Label READ terminalButton3Label WRITE setTerminalButton3Label NOTIFY terminalButton3LabelChanged)
    Q_PROPERTY(QString terminalButton3Command READ terminalButton3Command WRITE setTerminalButton3Command NOTIFY terminalButton3CommandChanged)
    Q_PROPERTY(QString terminalButton4Label READ terminalButton4Label WRITE setTerminalButton4Label NOTIFY terminalButton4LabelChanged)
    Q_PROPERTY(QString terminalButton4Command READ terminalButton4Command WRITE setTerminalButton4Command NOTIFY terminalButton4CommandChanged)

    // Linux only: local source directory (maps from path+/maps/, user config from path+/user-config.json)
    Q_PROPERTY(bool userConfigEnabled READ userConfigEnabled WRITE setUserConfigEnabled NOTIFY userConfigEnabledChanged)
    Q_PROPERTY(QString localSourcePath READ localSourcePath WRITE setLocalSourcePath NOTIFY localSourcePathChanged)

    // Camera Settings
    Q_PROPERTY(bool useRtspStream READ useRtspStream WRITE setUseRtspStream NOTIFY useRtspStreamChanged)
    Q_PROPERTY(QString leftCameraUrl READ leftCameraUrl WRITE setLeftCameraUrl NOTIFY leftCameraUrlChanged)
    Q_PROPERTY(QString centerCameraUrl READ centerCameraUrl WRITE setCenterCameraUrl NOTIFY centerCameraUrlChanged)
    Q_PROPERTY(QString bumperCameraUrl READ bumperCameraUrl WRITE setBumperCameraUrl NOTIFY bumperCameraUrlChanged)
    Q_PROPERTY(QString rightCameraUrl READ rightCameraUrl WRITE setRightCameraUrl NOTIFY rightCameraUrlChanged)

public:
    explicit SettingsBackend(QObject* parent = nullptr);

    // Network Settings
    QString txHost() const { return m_txHost; }
    void setTxHost(const QString& host);
    int txPort() const { return m_txPort; }
    void setTxPort(int port);
    int rxPort() const { return m_rxPort; }
    void setRxPort(int port);
    int rxPortPerception() const { return m_rxPortPerception; }
    void setRxPortPerception(int port);
    int rxPortLogger() const { return m_rxPortLogger; }
    void setRxPortLogger(int port);
    int gnssTimeout() const { return m_gnssTimeout; }
    void setGnssTimeout(int timeout);

    // Map Settings
    int defaultZoom() const { return m_defaultZoom; }
    void setDefaultZoom(int zoom);
    bool followVehicle() const { return m_followVehicle; }
    void setFollowVehicle(bool follow);
    bool map3dEnabled() const { return m_map3dEnabled; }
    void setMap3dEnabled(bool enabled);

    // Theme
    bool themeDark() const { return m_themeDark; }
    void setThemeDark(bool dark);

    // Data Logger
    bool autoBackupLogs() const { return m_autoBackupLogs; }
    void setAutoBackupLogs(bool v);
    QString webdavServerUrl() const { return m_webdavServerUrl; }
    void setWebdavServerUrl(const QString& v);
    QString webdavUsername() const { return m_webdavUsername; }
    void setWebdavUsername(const QString& v);
    QString webdavPassword() const { return m_webdavPassword; }
    void setWebdavPassword(const QString& v);

    // Terminal buttons (first 4)
    QString terminalButton1Label() const { return m_terminalButton1Label; }
    void setTerminalButton1Label(const QString& v);
    QString terminalButton1Command() const { return m_terminalButton1Command; }
    void setTerminalButton1Command(const QString& v);
    QString terminalButton2Label() const { return m_terminalButton2Label; }
    void setTerminalButton2Label(const QString& v);
    QString terminalButton2Command() const { return m_terminalButton2Command; }
    void setTerminalButton2Command(const QString& v);
    QString terminalButton3Label() const { return m_terminalButton3Label; }
    void setTerminalButton3Label(const QString& v);
    QString terminalButton3Command() const { return m_terminalButton3Command; }
    void setTerminalButton3Command(const QString& v);
    QString terminalButton4Label() const { return m_terminalButton4Label; }
    void setTerminalButton4Label(const QString& v);
    QString terminalButton4Command() const { return m_terminalButton4Command; }
    void setTerminalButton4Command(const QString& v);

    bool userConfigEnabled() const { return m_userConfigEnabled; }
    void setUserConfigEnabled(bool enabled);
    QString localSourcePath() const { return m_localSourcePath; }
    void setLocalSourcePath(const QString& path);

    // Camera Settings
    bool useRtspStream() const { return m_useRtspStream; }
    void setUseRtspStream(bool use);
    QString leftCameraUrl() const { return m_leftCameraUrl; }
    void setLeftCameraUrl(const QString& url);
    QString centerCameraUrl() const { return m_centerCameraUrl; }
    void setCenterCameraUrl(const QString& url);
    QString bumperCameraUrl() const { return m_bumperCameraUrl; }
    void setBumperCameraUrl(const QString& url);
    QString rightCameraUrl() const { return m_rightCameraUrl; }
    void setRightCameraUrl(const QString& url);

    // Backend references (set after construction)
    void setGlobalTransmitter(GlobalTransmitter* tx) { m_tx = tx; }
    void setNavigationBackend(NavigationBackend* nav) { m_nav = nav; }
    void setGlobalReceiver(GlobalReceiver* rx) { m_rx = rx; }

public slots:
    Q_INVOKABLE void loadSettings();
    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void resetToDefaults();
    Q_INVOKABLE bool validateSettings();
    Q_INVOKABLE void applyInitialSettings();

signals:
    void txHostChanged();
    void txPortChanged();
    void rxPortChanged();
    void rxPortPerceptionChanged();
    void rxPortLoggerChanged();
    void gnssTimeoutChanged();
    void defaultZoomChanged();
    void followVehicleChanged();
    void map3dEnabledChanged();
    void themeDarkChanged();
    void autoBackupLogsChanged();
    void webdavServerUrlChanged();
    void webdavUsernameChanged();
    void webdavPasswordChanged();
    void terminalButton1LabelChanged();
    void terminalButton1CommandChanged();
    void terminalButton2LabelChanged();
    void terminalButton2CommandChanged();
    void terminalButton3LabelChanged();
    void terminalButton3CommandChanged();
    void terminalButton4LabelChanged();
    void terminalButton4CommandChanged();
    void userConfigEnabledChanged();
    void localSourcePathChanged();
    void useRtspStreamChanged();
    void leftCameraUrlChanged();
    void centerCameraUrlChanged();
    void bumperCameraUrlChanged();
    void rightCameraUrlChanged();
    void settingsSaved();
    void settingsError(const QString& error);

private:
    QSettings* m_settings;

    // Network Settings
    QString m_txHost;
    int m_txPort;
    int m_rxPort;
    int m_rxPortPerception;  // default 6002; TX side not ready yet, so not started by default
    int m_rxPortLogger;      // default 6003 for CAN logger stream
    int m_gnssTimeout;

    // Map Settings
    int m_defaultZoom;
    bool m_followVehicle;
    bool m_map3dEnabled = false;

    // Theme
    bool m_themeDark = true;

    // Data Logger
    bool m_autoBackupLogs = false;
    QString m_webdavServerUrl;
    QString m_webdavUsername;
    QString m_webdavPassword;

    // Terminal (first 4 buttons)
    QString m_terminalButton1Label;
    QString m_terminalButton1Command;
    QString m_terminalButton2Label;
    QString m_terminalButton2Command;
    QString m_terminalButton3Label;
    QString m_terminalButton3Command;
    QString m_terminalButton4Label;
    QString m_terminalButton4Command;

    bool m_userConfigEnabled = true;
    QString m_localSourcePath;

    // Camera Settings
    bool m_useRtspStream = true;
    QString m_leftCameraUrl;
    QString m_centerCameraUrl;
    QString m_bumperCameraUrl;
    QString m_rightCameraUrl;

    // Backend references
    GlobalTransmitter* m_tx = nullptr;
    NavigationBackend* m_nav = nullptr;
    GlobalReceiver* m_rx = nullptr;

    void applyNetworkSettings();
    bool validatePort(int port);
    bool validateHost(const QString& host);

    void loadFromUserConfigFile(const QString& path);
    void saveToUserConfigFile(const QString& path);
};
