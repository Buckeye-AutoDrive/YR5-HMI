#pragma once

#include <QObject>
#include <QImage>
#include <QMap>
#include <QMutex>
#include <QQuickImageProvider>
#include <memory>

class QQmlEngine;

namespace vehicle_msgs {
class CameraBatch;
}

class CameraFramesBackend;

// Image provider used by the engine; lives in same file as the backend.
class CameraImageProvider : public QQuickImageProvider
{
public:
    explicit CameraImageProvider(CameraFramesBackend* backend);

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

private:
    CameraFramesBackend* m_backend = nullptr;
};

class CameraFramesBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int frameVersion READ frameVersion NOTIFY frameVersionChanged)

public:
    explicit CameraFramesBackend(QObject* parent = nullptr);
    ~CameraFramesBackend() override;

    int frameVersion() const { return m_frameVersion; }

    // Register our image provider with the engine (backend owns the provider).
    void addImageProviderTo(QQmlEngine* engine);

    // Used by CameraImageProvider (may be called from scene graph thread).
    QImage frameImage(const QString& cameraId) const;

public slots:
    void onCameraBatch(const vehicle_msgs::CameraBatch& batch);

signals:
    void frameVersionChanged();

private:
    mutable QMutex m_mutex;
    QMap<QString, QImage> m_frames;
    int m_frameVersion = 0;

    std::unique_ptr<CameraImageProvider> m_imageProvider;
    QQmlEngine* m_engine = nullptr;
};
