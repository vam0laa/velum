#include <QCommandLineParser>
#include <QDir>
#include <QElapsedTimer>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStyleHints>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QtWebEngineQuick>

#include <cstdio>

#include "address.h"
#include "graphics.h"
#include "instance.h"
#include "widevine.h"

int main(int argc, char *argv[])
{
    // VELUM_TIMING=1 prints how long the start took, up to the first picture on screen
    QElapsedTimer sinceStart;
    sinceStart.start();

    // The engine reads its switches once, while starting. So this comes before everything else.
    const QString cdm = widevine::forCommandLine(widevine::find());
    QByteArray flags = qgetenv("QTWEBENGINE_CHROMIUM_FLAGS");
    if (!cdm.isEmpty())
        flags += " --widevine-path=" + cdm.toLocal8Bit();
    // "use the graphics card"; extra switches that kept a start from finishing are left out
    bool trying = false;
    bool careful = false;
    {
        QSettings settings;
        const bool accelerate = settings.value(QStringLiteral("graphics/accelerate"), true).toBool();
        careful = settings.value(QStringLiteral("graphics/careful")).toBool()
                             || settings.value(QStringLiteral("graphics/pending")).toBool();
        trying = accelerate && !careful;
#ifdef Q_OS_LINUX
        flags += ' ' + graphics::engineFlags(accelerate, careful, true);
#else
        flags += ' ' + graphics::engineFlags(accelerate, careful, false);
#endif
    }
    if (!flags.trimmed().isEmpty())
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", flags.trimmed());

    graphics::prepare();

    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);
    graphics::restoreEnvironment();
#ifdef Q_OS_LINUX
    // One turn of the wheel moves the page 100 px, as in other browsers; the toolkit's
    // three lines give 60. The engine reads this once, so it is set before any page.
    app.styleHints()->setWheelScrollLines(5);
#endif
    app.setApplicationName(QStringLiteral("velum"));
    app.setOrganizationName(QStringLiteral("velum"));
    app.setApplicationVersion(QStringLiteral(VELUM_VERSION));      // may carry "-beta.N"
    app.setDesktopFileName(QStringLiteral("velum"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Velum/data/velum.svg")));
    // the interface's own lettering for anything that does not choose a font
    const int font = QFontDatabase::addApplicationFont(QStringLiteral(":/qt/qml/Velum/data/fonts/Inter.ttf"));
    if (font >= 0)
        app.setFont(QFont(QFontDatabase::applicationFontFamilies(font).value(0)));

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
        start << address::fromArgument(typed).toString(QUrl::FullyEncoded);

    // A second start (a link clicked in another program) opens in the window that is already there.
    // Development runs stay on their own.
    Instance instance;
    if (!args.isSet(shot) && !args.isSet(demo) && !args.isSet(box)) {
        const QString socket = Instance::socketName(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
        if (Instance::handOver(socket, start))
            return 0;
        instance.listen(socket);
    }

    // noted only now: a second start that handed its link over, or --help, leaves no mark
    QSettings().setValue(QStringLiteral("graphics/careful"), careful);
    QSettings().setValue(QStringLiteral("graphics/pending"), trying);

    QQuickWindow::setDefaultAlphaBuffer(true);     // needed for the glass look
    QQmlApplicationEngine engine;
    // the welcome pages are not shown to development runs
    const bool greet = !args.isSet(shot) && !args.isSet(demo) && !args.isSet(box);
    // where the icons of your bookmarked sites are kept, for the start page
    const QString icons = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/icons");
    QDir().mkpath(icons);
    engine.setInitialProperties({{QStringLiteral("startUrls"), start},
                                 {QStringLiteral("iconFolder"), icons},
                                 {QStringLiteral("greet"), greet},
                                 {QStringLiteral("hasWidevine"), !cdm.isEmpty()}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("Velum", "Main");

    if (!engine.rootObjects().isEmpty()) {
        QObject *window = engine.rootObjects().constFirst();
        QObject::connect(&instance, &Instance::received, window,
                         [window](const QStringList &urls) { QMetaObject::invokeMethod(window, "openExternal", Q_ARG(QVariant, urls)); });
    }

    // still running a while later, or closed properly: this start worked
    if (trying) {
        const auto worked = [] { QSettings().setValue(QStringLiteral("graphics/pending"), false); };
        QTimer::singleShot(15000, &app, worked);
        QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, worked);
    }

    if (qEnvironmentVariableIsSet("VELUM_TIMING") && !engine.rootObjects().isEmpty()) {
        std::fprintf(stderr, "velum: interface loaded after %lld ms\n", sinceStart.elapsed());
        if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst()))
            QObject::connect(window, &QQuickWindow::frameSwapped, window,
                             [sinceStart] { std::fprintf(stderr, "velum: first picture after %lld ms\n", sinceStart.elapsed()); },
                             Qt::SingleShotConnection);
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
