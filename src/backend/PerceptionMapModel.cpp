#include "PerceptionMapModel.h"

PerceptionMapModel::PerceptionMapModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int PerceptionMapModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_objects.size();
}

QVariant PerceptionMapModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_objects.size())
        return QVariant();
    const MapObject& o = m_objects.at(index.row());
    switch (role) {
    case LatitudeRole:
        return o.latitude;
    case LongitudeRole:
        return o.longitude;
    case ObjectTypeIdRole:
        return o.objectTypeId;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PerceptionMapModel::roleNames() const
{
    return {
        { LatitudeRole, "latitude" },
        { LongitudeRole, "longitude" },
        { ObjectTypeIdRole, "objectTypeId" }
    };
}

void PerceptionMapModel::setObjects(const QVariantList& objects)
{
    if (m_objects.isEmpty() && objects.isEmpty())
        return;
    beginResetModel();
    m_objects.clear();
    m_objects.reserve(objects.size());
    for (const QVariant& v : objects) {
        QVariantMap m = v.toMap();
        MapObject o;
        o.latitude = m.value("latitude").toDouble();
        o.longitude = m.value("longitude").toDouble();
        o.objectTypeId = m.value("objectTypeId").toInt();
        m_objects.append(o);
    }
    endResetModel();
}

QVariantMap PerceptionMapModel::getRow(int index) const
{
    QVariantMap out;
    if (index < 0 || index >= m_objects.size())
        return out;
    const MapObject& o = m_objects.at(index);
    out.insert("latitude", o.latitude);
    out.insert("longitude", o.longitude);
    out.insert("objectTypeId", o.objectTypeId);
    return out;
}
