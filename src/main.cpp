#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QtWebEngineQuick>

#include "address.h"
#include "graphics.h"
#include "instance.h"
#include "widevine.h"

int main(int argc, char *argv[])
{
    // The engine reads its switches once, while starting. So this comes before everything else.
    const QString cdm = widevine::find();
    if (!cdm.isEmpty() && !cdm.contains(QLatin1Char(' '))) {
        QByteArray flags = qgetenv("QTWEBENGINE_CHROMIUM_FLAGS");
        flags += " --widevine-path=" + cdm.toLocal8Bit();
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", flags.trimmed());
    }

    graphics::prepare();

    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("velum"));
    app.setOrganizationName(QStringLiteral("velum"));
    app.setApplicationVersion(QStringLiteral(VELUM_VERSION));
    app.setDesktopFileName(QStringLiteral("velum"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Velum/data/velum.svg")));
    // "Basic" is the plainest control style; every colour and shape in Velum is our own.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QCommandLineParser args;
    args.setApplicationDescription(QStringLiteral("A calm, private web browser."));
    args.addHelpOption();
    args.addVersionOption();
    args.addPositionalArgument(QStringLiteral("url"), QStringLiteral("Addresses to open."), QStringLiteral("[url...]"));
    // For development: draw the window into a picture and quit.
    QCommandLineOption shot(QStringLiteral("screenshot"), QStringLiteral("Save a picture of the window and quit."), QStringLiteral("file"));
    args.addOption(shot);
    QCommandLineOption box(QStringLiteral("command-box"), QStringLiteral("Open the command box with this text."), QStringLiteral("text"));
    args.addOption(box);
    // for measuring: "resources" opens the panel, "sleep" puts the other tabs to sleep
    QCommandLineOption demo(QStringLiteral("demo"), QStringLiteral("Run an action a while after start (for development)."), QStringLiteral("action"));
    args.addOption(demo);
    args.process(app);

    address::setEngine(QSettings().value(QStringLiteral("search/engine")).toString());
    QStringList start;
    for (const QString &typed : args.positionalArguments())
        start << address::resolve(typed).toString();

    // A second start (a link clicked in another program) opens in the window that is already there.
    // Development runs stay on their own.
    Instance instance;
    if (!args.isSet(shot) && !args.isSet(demo) && !args.isSet(box)) {
        const QString socket = Instance::socketName(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
        if (Instance::handOver(socket, start))
            return 0;
        instance.listen(socket);
    }

    QQmlApplicationEngine engine;
    engine.setInitialProperties({{QStringLiteral("startUrls"), start},
                                 {QStringLiteral("hasWidevine"), !cdm.isEmpty()}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("Velum", "Main");

    if (!engine.rootObjects().isEmpty()) {
        QObject *window = engine.rootObjects().constFirst();
        QObject::connect(&instance, &Instance::received, window,
                         [window](const QStringList &urls) { QMetaObject::invokeMethod(window, "openExternal", Q_ARG(QVariant, urls)); });
    }

    if (args.isSet(demo) && !engine.rootObjects().isEmpty()) {
        QObject *window = engine.rootObjects().constFirst();
        const QString action = args.value(demo);
        QTimer::singleShot(action == QLatin1String("sleep") ? 25000 : 3000, window,
                           [window, action] { QMetaObject::invokeMethod(window, "demo", Q_ARG(QVariant, action)); });
    }

    if (args.isSet(box) && !engine.rootObjects().isEmpty())
        QMetaObject::invokeMethod(engine.rootObjects().constFirst(), "showCommandBox", Q_ARG(QVariant, args.value(box)));

    if (args.isSet(shot) && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        const QString file = args.value(shot);
        QTimer::singleShot(6000, window, [window, file] {
            QCoreApplication::exit(window->grabWindow().save(file) ? 0 : 1);
        });
    }
    return app.exec();
}
