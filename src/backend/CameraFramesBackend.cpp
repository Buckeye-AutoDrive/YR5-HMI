#include "CameraFramesBackend.h"
#include "../proto/HMI_RX_CONTROLS.pb.h"
#include <QQmlEngine>
#include <QByteArray>
#include <QBuffer>
#include <QImageReader>
#include <QDebug>
#include <QUrl>

// --- CameraImageProvider (same module as backend) ---

CameraImageProvider::CameraImageProvider(CameraFramesBackend* backend)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_backend(backend)
{
}

QImage CameraImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    QString cameraId = id;

    // Decode any %-escaped characters first
    cameraId = QUrl::fromPercentEncoding(cameraId.toUtf8());

    // Remove query if present
    const int q = cameraId.indexOf(QLatin1Char('?'));
    if (q >= 0)
        cameraId = cameraId.left(q);

    // Remove leading slash if present
    while (cameraId.startsWith(QLatin1Char('/')))
        cameraId.remove(0, 1);

    qInfo() << "[CameraImageProvider] request id =" << id
            << "normalized =" << cameraId;

    if (!m_backend) {
        qWarning() << "[CameraImageProvider] backend is null";
        return QImage();
    }

    QImage img = m_backend->frameImage(cameraId);

    if (size)
        *size = img.size();

    if (!img.isNull() && requestedSize.isValid())
        img = img.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    if (img.isNull()) {
        qWarning() << "[CameraImageProvider] requestImage failed for" << cameraId;
    } else {
        qInfo() << "[CameraImageProvider] served" << cameraId
                << "size =" << img.size();
    }

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

    qInfo() << "[CameraFramesBackend] image provider registered as image://camera/";
}

QImage CameraFramesBackend::frameImage(const QString& cameraId) const
{
    QMutexLocker lock(&m_mutex);
    auto it = m_frames.constFind(cameraId);
    if (it == m_frames.constEnd()) {
        qWarning() << "[CameraFramesBackend] no stored frame for" << cameraId;
        return QImage();
    }
    return it.value().copy();
}

void CameraFramesBackend::onCameraBatch(const vehicle_msgs::CameraBatch& batch)
{
    qInfo() << "[CameraFramesBackend] batch received:"
            << "frames =" << batch.frames_size()
            << "timestamp =" << batch.timestamp();

    QMutexLocker lock(&m_mutex);

    for (int i = 0; i < batch.frames_size(); ++i) {
        const auto& frame = batch.frames(i);
        const QString cameraId = QString::fromStdString(frame.camera_id());
        const std::string& jpegData = frame.jpeg_data();

        qInfo() << "[CameraFramesBackend] frame" << i
                << "cameraId =" << cameraId
                << "jpeg bytes =" << static_cast<qint64>(jpegData.size());

        if (cameraId.isEmpty() || jpegData.empty()) {
            qWarning() << "[CameraFramesBackend] skipping empty cameraId or jpegData";
            continue;
        }

        // Make a real QByteArray copy instead of fromRawData()
        QByteArray bytes(jpegData.data(), static_cast<int>(jpegData.size()));

        QImage img = QImage::fromData(bytes, "JPEG");
        if (img.isNull()) {
            qWarning() << "[CameraFramesBackend] JPEG decode with explicit format failed for"
                       << cameraId << "- trying auto-detect";
            img = QImage::fromData(bytes);
        }

        if (img.isNull()) {
            qWarning() << "[CameraFramesBackend] image decode failed for"
                       << cameraId
                       << "bytes =" << bytes.size();
            continue;
        }

        qInfo() << "[CameraFramesBackend] decoded"
                << cameraId
                << "size =" << img.size()
                << "format =" << img.format();

        m_frames.insert(cameraId, img);
        qInfo() << "[CameraFramesBackend] stored frame for" << cameraId;
    }

    lock.unlock();

    ++m_frameVersion;
    emit frameVersionChanged();
    qInfo() << "[CameraFramesBackend] frameVersion =" << m_frameVersion;
}
