#pragma once

#include <QObject>
#include <QStringList>
#include "../proto/HMI_RX_CAN.pb.h"

class QFile;

class LoggerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList logFileNames READ logFileNames NOTIFY logFileNamesChanged)
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY isPausedChanged)
    // Bus filter: bus_id 0=HS, 1=CE, 2=SC, 3=LS; when set, only those buses are logged
    Q_PROPERTY(bool canHS READ canHS WRITE setCanHS NOTIFY canHSChanged)
    Q_PROPERTY(bool canCE READ canCE WRITE setCanCE NOTIFY canCEChanged)
    Q_PROPERTY(bool canSC READ canSC WRITE setCanSC NOTIFY canSCChanged)
    Q_PROPERTY(bool canLS READ canLS WRITE setCanLS NOTIFY canLSChanged)

public:
    explicit LoggerBackend(QObject* parent = nullptr);

    QStringList logFileNames() const { return m_logFileNames; }
    bool isRecording() const { return m_recording; }
    bool isPaused() const { return m_paused; }
    bool canHS() const { return m_canHS; }
    void setCanHS(bool v);
    bool canCE() const { return m_canCE; }
    void setCanCE(bool v);
    bool canSC() const { return m_canSC; }
    void setCanSC(bool v);
    bool canLS() const { return m_canLS; }
    void setCanLS(bool v);

    Q_INVOKABLE QString logsRootPath() const;
    Q_INVOKABLE void refreshLogList();
    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void pauseRecording();
    Q_INVOKABLE void resumeRecording();
    Q_INVOKABLE void discardRecording();
    Q_INVOKABLE void saveRecording();

public slots:
    void onCanBatch(const can_stream::CanBatch& batch);

signals:
    void logFileNamesChanged();
    void isRecordingChanged();
    void recordingSaved();
    void isPausedChanged();
    void canHSChanged();
    void canCEChanged();
    void canSCChanged();
    void canLSChanged();

private:
    void loadBusSelection();
    void saveBusSelection() const;
    bool shouldLogBusId(quint32 busId) const;
    QString resolveLogsDir() const;
    QString currentRecordingPath() const;
    void closeAndRemoveCurrentFile();
    static QString dataToHex(const std::string& data);

    QStringList m_logFileNames;
    bool m_recording = false;
    bool m_paused = false;
    QFile* m_logFile = nullptr;
    QString m_currentLogPath;
    bool m_canHS = true;
    bool m_canCE = true;
    bool m_canSC = true;
    bool m_canLS = true;
};
