#include "PerceptionBackend.h"
#include "PerceptionMapModel.h"
#include "../proto/HMI_RX_PERCEPTION.pb.h"

PerceptionBackend::PerceptionBackend(QObject* parent)
    : QObject(parent)
    , m_mapModel(new PerceptionMapModel(this))
{
}

QObject* PerceptionBackend::mapObjectsModel() const
{
    return m_mapModel;
}

void PerceptionBackend::onPerceptionFrameReceived(const hmi::perception::v1::PerceptionFrame& frame)
{
    QVariantList signs;
    QVariantList objects;
    signs.reserve(static_cast<int>(frame.objects_size()));
    objects.reserve(static_cast<int>(frame.objects_size()));

    for (int i = 0; i < frame.objects_size(); ++i) {
        const auto& obj = frame.objects(i);
        if (!obj.has_coord_abs())
            continue;
        const auto& coord = obj.coord_abs();
        double lat = static_cast<double>(coord.latitude());
        double lon = static_cast<double>(coord.longitude());
        int objectTypeId = obj.object_type_id();

        // Traffic signs (type 9) go only to trafficSigns overlay, not to map markers
        // Map markers: only non–traffic-sign objects (types 1–8)
        if (objectTypeId != 9) {
            QVariantMap objEntry;
            objEntry.insert("latitude", lat);
            objEntry.insert("longitude", lon);
            objEntry.insert("objectTypeId", objectTypeId);
            objects.append(objEntry);
        }

        // Type 9 → trafficSigns for the overlay
        if (objectTypeId == 9) {
            int signTypeId = 0;
            int speedLimit = -1;
            if (obj.traffic_sign_data_size() >= 1)
                signTypeId = obj.traffic_sign_data(0);
            if (obj.traffic_sign_data_size() >= 2)
                speedLimit = obj.traffic_sign_data(1);
            QVariantMap signEntry;
            signEntry.insert("latitude", lat);
            signEntry.insert("longitude", lon);
            signEntry.insert("signTypeId", signTypeId);
            signEntry.insert("speedLimit", speedLimit);
            signs.append(signEntry);
        }
    }

    if (signs.size() != m_trafficSigns.size() || signs != m_trafficSigns) {
        m_trafficSigns = signs;
        emit trafficSignsChanged();
    }
    if (objects.size() != m_perceptionObjects.size() || objects != m_perceptionObjects) {
        m_perceptionObjects = objects;
        emit perceptionObjectsChanged();
    }
    m_mapModel->setObjects(objects);
    int n = objects.size();
    if (n != m_mapObjectCount) {
        m_mapObjectCount = n;
        emit mapObjectCountChanged();
    }
}
