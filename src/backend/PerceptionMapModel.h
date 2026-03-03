#pragma once

#include <QAbstractListModel>

class PerceptionMapModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role {
        LatitudeRole = Qt::UserRole + 1,
        LongitudeRole,
        ObjectTypeIdRole
    };

    explicit PerceptionMapModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    /// Replace all rows with the given list (each item: latitude, longitude, objectTypeId)
    Q_INVOKABLE void setObjects(const QVariantList& objects);

    /// Get row as a map with keys latitude, longitude, objectTypeId (for QML when model iteration fails)
    Q_INVOKABLE QVariantMap getRow(int index) const;

private:
    struct MapObject {
        double latitude = 0;
        double longitude = 0;
        int objectTypeId = 0;
    };
    QVector<MapObject> m_objects;
};
