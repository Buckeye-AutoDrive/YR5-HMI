#pragma once

#include <QObject>
#include <QVariantList>

namespace hmi {
namespace perception {
namespace v1 {
class PerceptionFrame;
}
}
}

class PerceptionMapModel;

class PerceptionBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList trafficSigns READ trafficSigns NOTIFY trafficSignsChanged)
    Q_PROPERTY(QVariantList perceptionObjects READ perceptionObjects NOTIFY perceptionObjectsChanged)
    /// List model for map markers (object_type_id 1–8). Use as Repeater model.
    Q_PROPERTY(QObject* mapObjectsModel READ mapObjectsModel CONSTANT)
    Q_PROPERTY(int mapObjectCount READ mapObjectCount NOTIFY mapObjectCountChanged)

public:
    explicit PerceptionBackend(QObject* parent = nullptr);

    QVariantList trafficSigns() const { return m_trafficSigns; }
    QVariantList perceptionObjects() const { return m_perceptionObjects; }
    QObject* mapObjectsModel() const;
    int mapObjectCount() const { return m_mapObjectCount; }

signals:
    void trafficSignsChanged();
    void perceptionObjectsChanged();
    void mapObjectCountChanged();

public slots:
    void onPerceptionFrameReceived(const hmi::perception::v1::PerceptionFrame& frame);

private:
    QVariantList m_trafficSigns;
    QVariantList m_perceptionObjects;
    PerceptionMapModel* m_mapModel = nullptr;
    int m_mapObjectCount = 0;
};
