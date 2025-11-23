#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

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
