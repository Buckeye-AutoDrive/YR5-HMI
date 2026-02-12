#pragma once

#include <QObject>

class QNetworkAccessManager;
class QNetworkReply;
class QTimer;

class InternetBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool internetOn READ internetOn NOTIFY internetOnChanged)

public:
    explicit InternetBackend(QObject* parent = nullptr);
    ~InternetBackend() override;

    bool internetOn() const { return m_internetOn; }

signals:
    void internetOnChanged();

private slots:
    void checkConnectivity();
    void onReplyFinished();

private:
    QNetworkAccessManager* m_net = nullptr;
    QTimer* m_timer = nullptr;
    QNetworkReply* m_pendingReply = nullptr;
    bool m_internetOn = false;

    void setInternetOn(bool on);
};
