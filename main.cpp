#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDir>

#include "src/backend/NavigationBackend.h"
#include "src/backend/GlobalTransmitter.h"

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
    QGuiApplication::setFont(QFont(QStringLiteral("Universal Sans"), 16));
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    loadAppFonts();

    QQmlApplicationEngine engine;

    auto* navBackend = new NavigationBackend(&engine);
    auto* txBackend  = new GlobalTransmitter(&engine);

    engine.rootContext()->setContextProperty("NavigationBackend", navBackend);
    engine.rootContext()->setContextProperty("GlobalTx", txBackend);

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
