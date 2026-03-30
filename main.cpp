#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>
#include <QtQml/qqml.h>

#include "theoryController.h"



int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<TheoryController>("App.Theory", 1, 0, "TheoryController");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    QString exeDir = QCoreApplication::applicationDirPath();
    QString projectRoot = QDir(exeDir + "/../..").absolutePath();
    QString qmlPath = projectRoot + "/qml/Main.qml";

    engine.load(QUrl::fromLocalFile(qmlPath));

    return app.exec();
}
