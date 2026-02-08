#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDir>
#include <QQuickStyle>

#include "src/backend/NavigationBackend.h"
#include "src/backend/GlobalReceiver.h"
#include "src/backend/GlobalTransmitter.h"
#include "src/backend/SettingsBackend.h"
#include "src/backend/LoggerBackend.h"
#include "src/backend/TerminalBackend.h"
#include "src/backend/CameraFramesBackend.h"
#include "src/backend/LogBackupBackend.h"

static void loadAppFonts()
{
    // These paths match qt_add_qml_module resource layout: :/qt/qml/<URI>/<path>
    // URI is HMI_Mk1, and your files are src/fonts/...
    const QString regular  = QStringLiteral(":/qt/qml/HMI_Mk1/src/fonts/UniversalSans.ttf");
    const QString display  = QStringLiteral(":/qt/qml/HMI_Mk1/src/fonts/UniversalSansDisplay.ttf");

    QFontDatabase::addApplicationFont(regular);
    QFontDatabase::addApplicationFont(display);

    // Use the family name as defined inside the font file.
    // If the family name differs, this will still usually work after addApplicationFont,
    // but you can also query QFontDatabase::applicationFontFamilies(id).
    // Use the family name as defined inside the TTF (query with applicationFontFamilies(id) if needed).
    // For a heavier body text, add e.g. UniversalSans-SemiBold.ttf to RESOURCES and load it here,
    // then use Font.DemiBold or Font.Medium in Theme / default font.
    QGuiApplication::setFont(QFont(QStringLiteral("Universal Sans"), 16));
}

int main(int argc, char *argv[])
{
    // Optional: on Jetson/Ubuntu touch, set QT_IM_MODULE=qtvirtualkeyboard
    // (if Qt6VirtualKeyboard is installed) so an on-screen keyboard appears for text fields

    QGuiApplication app(argc, argv);

    // Use a style that supports control customization (background, contentItem)
    QQuickStyle::setStyle("Material");

    loadAppFonts();

    QQmlApplicationEngine engine;

    auto* navBackend = new NavigationBackend(&engine);
    auto* txBackend  = new GlobalTransmitter(&engine);
    auto* settingsBackend = new SettingsBackend(&engine);

    // Connect settings backend to other backends
    settingsBackend->setGlobalTransmitter(txBackend);
    settingsBackend->setNavigationBackend(navBackend);

    // Apply initial settings from QSettings to backends
    settingsBackend->applyInitialSettings();

    engine.rootContext()->setContextProperty("NavigationBackend", navBackend);
    engine.rootContext()->setContextProperty("GlobalTx", txBackend);
    engine.rootContext()->setContextProperty("SettingsBackend", settingsBackend);
    auto* loggerBackend = new LoggerBackend(&engine);
    engine.rootContext()->setContextProperty("LoggerBackend", loggerBackend);
    auto* logBackupBackend = new LogBackupBackend(&engine);
    logBackupBackend->setLoggerBackend(loggerBackend);
    logBackupBackend->setSettingsBackend(settingsBackend);
    engine.rootContext()->setContextProperty("LogBackupBackend", logBackupBackend);
    QObject::connect(loggerBackend, &LoggerBackend::recordingSaved, &engine, [logBackupBackend, settingsBackend]() {
        if (settingsBackend->autoBackupLogs())
            logBackupBackend->startBackup();
    });
    engine.rootContext()->setContextProperty("TerminalBackend", new TerminalBackend(&engine));

    QObject::connect(navBackend->globalReceiver(), &GlobalReceiver::canBatchReceived,
                     loggerBackend, &LoggerBackend::onCanBatch);

    auto* cameraFramesBackend = new CameraFramesBackend(&engine);
    cameraFramesBackend->addImageProviderTo(&engine);
    engine.rootContext()->setContextProperty("CameraFramesBackend", cameraFramesBackend);
    QObject::connect(navBackend->globalReceiver(), &GlobalReceiver::cameraBatchReceived,
                     cameraFramesBackend, &CameraFramesBackend::onCameraBatch);

    // Cross-platform maps directory:
    // On Linux you used /home/hmi/HMI/maps/. On Windows, use a local "maps" folder next to the exe.
    const QString mapsDir = QDir(QCoreApplication::applicationDirPath()).filePath("maps");
    engine.rootContext()->setContextProperty("HMIMapsDirUrl", QUrl::fromLocalFile(mapsDir + QDir::separator()));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
        );

    engine.loadFromModule("HMI_Mk1", "Main");

    return app.exec();
}
