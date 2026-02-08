#include "CameraFramesBackend.h"
#include "../proto/HMI_RX_CONTROLS.pb.h"
#include <QQmlEngine>
#include <QByteArray>

// --- CameraImageProvider (same module as backend) ---

CameraImageProvider::CameraImageProvider(CameraFramesBackend* backend)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_backend(backend)
{
}

QImage CameraImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    // URL may be "cam0?v=123" -> use path only
    QString cameraId = id;
    const int q = cameraId.indexOf(QLatin1Char('?'));
    if (q >= 0)
        cameraId = cameraId.left(q);

    if (!m_backend)
        return QImage();

    QImage img = m_backend->frameImage(cameraId);
    if (size)
        *size = img.size();
    if (!img.isNull() && requestedSize.isValid())
        img = img.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    return img;
}

// --- CameraFramesBackend ---

CameraFramesBackend::CameraFramesBackend(QObject* parent)
    : QObject(parent)
{
}

CameraFramesBackend::~CameraFramesBackend()
{
    if (m_engine)
        m_engine->removeImageProvider(QStringLiteral("camera"));
}

void CameraFramesBackend::addImageProviderTo(QQmlEngine* engine)
{
    if (!engine || m_imageProvider)
        return;
    m_engine = engine;
    m_imageProvider = std::make_unique<CameraImageProvider>(this);
    engine->addImageProvider(QStringLiteral("camera"), m_imageProvider.get());
}

QImage CameraFramesBackend::frameImage(const QString& cameraId) const
{
    QMutexLocker lock(&m_mutex);
    auto it = m_frames.constFind(cameraId);
    if (it == m_frames.constEnd())
        return QImage();
    return it.value().copy();
}

void CameraFramesBackend::onCameraBatch(const vehicle_msgs::CameraBatch& batch)
{
    QMutexLocker lock(&m_mutex);
    for (int i = 0; i < batch.frames_size(); ++i) {
        const auto& frame = batch.frames(i);
        const std::string& cameraId = frame.camera_id();
        const std::string& jpegData = frame.jpeg_data();
        if (cameraId.empty() || jpegData.empty())
            continue;
        QImage img = QImage::fromData(
            QByteArray::fromRawData(jpegData.data(), static_cast<int>(jpegData.size())),
            "JPEG"
        );
        if (!img.isNull())
            m_frames.insert(QString::fromStdString(cameraId), img);
    }
    lock.unlock();

    ++m_frameVersion;
    emit frameVersionChanged();
}
