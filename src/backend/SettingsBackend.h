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
    Q_PROPERTY(int gnssTimeout READ gnssTimeout WRITE setGnssTimeout NOTIFY gnssTimeoutChanged)

    // Map Settings
    Q_PROPERTY(int defaultZoom READ defaultZoom WRITE setDefaultZoom NOTIFY defaultZoomChanged)
    Q_PROPERTY(bool followVehicle READ followVehicle WRITE setFollowVehicle NOTIFY followVehicleChanged)

    // Theme (dark = true, light = false; map and camera feeds are unchanged)
    Q_PROPERTY(bool themeDark READ themeDark WRITE setThemeDark NOTIFY themeDarkChanged)

    // Camera Settings
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
    int gnssTimeout() const { return m_gnssTimeout; }
    void setGnssTimeout(int timeout);

    // Map Settings
    int defaultZoom() const { return m_defaultZoom; }
    void setDefaultZoom(int zoom);
    bool followVehicle() const { return m_followVehicle; }
    void setFollowVehicle(bool follow);

    // Theme
    bool themeDark() const { return m_themeDark; }
    void setThemeDark(bool dark);

    // Camera Settings
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
    void gnssTimeoutChanged();
    void defaultZoomChanged();
    void followVehicleChanged();
    void themeDarkChanged();
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
    int m_gnssTimeout;

    // Map Settings
    int m_defaultZoom;
    bool m_followVehicle;

    // Theme
    bool m_themeDark = true;

    // Camera Settings
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
};
