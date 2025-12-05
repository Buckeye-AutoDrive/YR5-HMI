#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "src/backend/NavigationBackend.h"
#include "src/backend/GlobalTransmitter.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    auto* navBackend = new NavigationBackend(&engine);
    auto* txBackend  = new GlobalTransmitter(&engine);

    engine.rootContext()->setContextProperty("NavigationBackend", navBackend);
    engine.rootContext()->setContextProperty("GlobalTx", txBackend);

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
