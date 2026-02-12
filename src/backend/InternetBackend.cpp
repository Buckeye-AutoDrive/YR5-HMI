#include "InternetBackend.h"
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTimer>
#include <QUrl>

// Lightweight connectivity check; works on Jetson/Ubuntu and Windows
static const char kConnectivityUrl[] = "https://connectivitycheck.gstatic.com/generate_204";
static const int kCheckIntervalMs = 30000;   // 30 s
static const int kFirstCheckDelayMs = 2000;  // 2 s after startup
static const int kRequestTimeoutMs = 5000;  // 5 s

InternetBackend::InternetBackend(QObject* parent)
    : QObject(parent)
{
    m_net = new QNetworkAccessManager(this);
    m_timer = new QTimer(this);
    m_timer->setInterval(kCheckIntervalMs);
    m_timer->setSingleShot(false);
    connect(m_timer, &QTimer::timeout, this, &InternetBackend::checkConnectivity);

    QTimer::singleShot(kFirstCheckDelayMs, this, &InternetBackend::checkConnectivity);
    m_timer->start();
}

InternetBackend::~InternetBackend()
{
    if (m_pendingReply) {
        m_pendingReply->abort();
        m_pendingReply->deleteLater();
        m_pendingReply = nullptr;
    }
}

void InternetBackend::setInternetOn(bool on)
{
    if (m_internetOn == on) return;
    m_internetOn = on;
    emit internetOnChanged();
}

void InternetBackend::checkConnectivity()
{
    if (m_pendingReply) {
        m_pendingReply->abort();
        m_pendingReply->deleteLater();
        m_pendingReply = nullptr;
    }

    QNetworkRequest req(QUrl(QString::fromUtf8(kConnectivityUrl)));
    req.setTransferTimeout(kRequestTimeoutMs);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    m_pendingReply = m_net->get(req);
    connect(m_pendingReply, &QNetworkReply::finished, this, &InternetBackend::onReplyFinished);
}

void InternetBackend::onReplyFinished()
{
    if (!m_pendingReply) return;

    const bool ok = (m_pendingReply->error() == QNetworkReply::NoError);
    m_pendingReply->deleteLater();
    m_pendingReply = nullptr;

    setInternetOn(ok);
}
