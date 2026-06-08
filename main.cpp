#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QUrl>
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
        Qt::QueuedConnection
        );

    const QString exeDir = QCoreApplication::applicationDirPath();

    QString qmlPath = QDir(exeDir).absoluteFilePath("qml/Main.qml");

    if (!QFile::exists(qmlPath)) {
        qmlPath = QDir(exeDir).absoluteFilePath("../../qml/Main.qml");
    }

    qmlPath = QDir::cleanPath(qmlPath);

    engine.load(QUrl::fromLocalFile(qmlPath));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
