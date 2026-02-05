#pragma once

#include <QObject>
#include <QVector>
#include <QPointF>
#include <QVariant>
#include <QString>

#include "HMI_RX_CONTROLS.pb.h"   // Navigation

class GlobalReceiver;

class NavigationBackend : public QObject {
    Q_OBJECT

    Q_PROPERTY(double  currentLat    READ currentLat    NOTIFY updated)
    Q_PROPERTY(double  currentLon    READ currentLon    NOTIFY updated)
    Q_PROPERTY(double  headingDeg    READ headingDeg    NOTIFY updated)
    Q_PROPERTY(int     safetyStates  READ safetyStates  NOTIFY safetyStatesChanged)
    Q_PROPERTY(QString fsmStateText  READ fsmStateText  NOTIFY safetyStatesChanged)

public:
    explicit NavigationBackend(QObject* parent = nullptr);

    double currentLat() const { return m_currentLat; }
    double currentLon() const { return m_currentLon; }
    double headingDeg() const { return m_headingDeg; }

    int safetyStates() const { return m_safetyStates; }
    QString fsmStateText() const;

    Q_INVOKABLE QVariantList waypointPath() const;

signals:
    void updated();
    void waypointsUpdated();
    void safetyStatesChanged();

public slots:
    void onControlsMessage(const Navigation& msg);

private:
    GlobalReceiver* m_rx = nullptr;

    double m_currentLat = 0.0;
    double m_currentLon = 0.0;
    double m_headingDeg = 0.0;

    int m_safetyStates = 0;

    QVector<QPointF> m_waypoints;  // (lat, lon)
};
