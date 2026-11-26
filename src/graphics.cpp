#include "graphics.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#include <cstdio>
#include <utility>

namespace graphics {
namespace {

// what prepare() changed for Velum alone: name and the value to give back (null: unset)
QList<std::pair<QByteArray, QByteArray>> borrowed;

void borrow(const char *name, const QByteArray &value)
{
    borrowed.append({name, qEnvironmentVariableIsSet(name) ? qgetenv(name) : QByteArray()});
    qputenv(name, value);
}

#ifdef Q_OS_LINUX
// the output of a fixed command, or nothing
QByteArray ask(const char *command)
{
    QByteArray out;
    if (FILE *pipe = popen(command, "r")) {
        char block[4096];
        for (size_t n; (n = fread(block, 1, sizeof block, pipe)) > 0 && out.size() < (1 << 20);)
            out.append(block, qsizetype(n));
        pclose(pipe);
    }
    return out;
}
#endif

}

bool hybridWithNvidia(const QString &drm)
{
    bool nvidia = false;
    bool other = false;
    const QDir dir(drm);
    // renderD* are the cards that can draw; card0-eDP-1 and friends are only screen outputs
    for (const QString &node : dir.entryList({QStringLiteral("renderD*")}, QDir::AllEntries | QDir::NoDotAndDotDot)) {
        QFile vendor(dir.filePath(node) + QStringLiteral("/device/vendor"));
        if (!vendor.open(QIODevice::ReadOnly))
            continue;
        const QByteArray id = vendor.readAll().trimmed();
        if (id == "0x10de")
            nvidia = true;
        else if (id == "0x1002" || id == "0x8086")
            other = true;
    }
    return nvidia && other;
}

double xwaylandScale(const QByteArray &monitors, const QByteArray &zeroScaling)
{
    // without zero scaling the compositor would stretch the window, which looks blurred
    if (!QJsonDocument::fromJson(zeroScaling).object().value(QLatin1String("bool")).toBool())
        return 0;
    double scale = 0;
    for (const QJsonValue &value : QJsonDocument::fromJson(monitors).array()) {
        const QJsonObject monitor = value.toObject();
        if (scale == 0 || monitor.value(QLatin1String("focused")).toBool())
            scale = monitor.value(QLatin1String("scale")).toDouble();
    }
    return scale >= 0.5 && scale <= 4 ? scale : 0;
}

QByteArray engineFlags(bool accelerate, bool careful, bool linux_)
{
    if (!accelerate)
        return "--disable-gpu";
    if (careful)
        return {};
    // the graphics card draws and decodes where its driver is trusted to
    QByteArray flags = "--enable-gpu-rasterization";
    if (linux_)
        flags += " --enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL";
    return flags;
}

QByteArray cursorTheme(const QByteArray &answer, const QStringList &folders)
{
    QByteArray name = answer.trimmed();
    if (name.size() < 3 || !name.startsWith('\'') || !name.endsWith('\''))
        return {};
    name = name.mid(1, name.size() - 2);
    if (name.contains('/') || name.startsWith('.'))
        return {};
    for (const QString &folder : folders)
        if (QDir(folder + QLatin1Char('/') + QString::fromUtf8(name) + QStringLiteral("/cursors")).exists())
            return name;
    return {};
}

bool writePointerFolder(const QString &folder, const QByteArray &theme)
{
    if (theme.isEmpty() || theme.contains('\n') || !QDir().mkpath(folder + QStringLiteral("/default")))
        return false;
    QFile file(folder + QStringLiteral("/default/index.theme"));
    const QByteArray text = "[Icon Theme]\nName=Default\nInherits=" + theme + "\n";
    return file.open(QIODevice::WriteOnly | QIODevice::Truncate) && file.write(text) == text.size();
}

int cursorPixels(const QByteArray &answer, double scale)
{
    const int size = answer.trimmed().toInt();
    return size >= 8 && size <= 128 && scale > 0 ? qRound(size * scale) : 0;
}

void restoreEnvironment()
{
    for (const auto &[name, value] : std::as_const(borrowed))
        value.isNull() ? void(qunsetenv(name.constData())) : void(qputenv(name.constData(), value));
    borrowed.clear();
}

void prepare()
{
#ifdef Q_OS_LINUX
    if (qEnvironmentVariableIsSet("HYPRLAND_INSTANCE_SIGNATURE") && qEnvironmentVariableIsSet("DISPLAY")
        && qEnvironmentVariableIntValue("VELUM_WAYLAND") == 0 && qgetenv("QT_QPA_PLATFORM") != "offscreen") {
        const double scale = xwaylandScale(ask("hyprctl monitors -j 2>/dev/null"),
                                           ask("hyprctl getoption xwayland:force_zero_scaling -j 2>/dev/null"));
        if (scale > 0) {
            borrow("QT_QPA_PLATFORM", "xcb");
            borrow("QT_SCALE_FACTOR", QByteArray::number(scale, 'f', 6));
            // the same mouse pointer as the rest of the desktop
            const QString home = QDir::homePath();
            const QByteArray theme = cursorTheme(ask("gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null"),
                {home + QStringLiteral("/.local/share/icons"), home + QStringLiteral("/.icons"), QStringLiteral("/usr/share/icons")});
            const QString cache = qEnvironmentVariable("XDG_CACHE_HOME", home + QStringLiteral("/.cache")) + QStringLiteral("/velum/pointer");
            if (!theme.isEmpty() && writePointerFolder(cache, theme)) {
                // read again for every new pointer shape, so it stays set while Velum runs
                const QByteArray usual = qEnvironmentVariableIsSet("XCURSOR_PATH") ? qgetenv("XCURSOR_PATH")
                    : QByteArray("~/.local/share/icons:~/.icons:/usr/share/icons:/usr/share/pixmaps");
                if (!usual.startsWith(cache.toLocal8Bit() + ':'))
                    qputenv("XCURSOR_PATH", cache.toLocal8Bit() + ':' + usual);
                qputenv("XCURSOR_THEME", theme);
                const int pixels = cursorPixels(ask("gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null"), scale);
                if (pixels > 0 && !qEnvironmentVariableIsSet("XCURSOR_SIZE"))
                    borrow("XCURSOR_SIZE", QByteArray::number(pixels));      // read once, at start
            }
        }
    }
    if (qEnvironmentVariableIntValue("VELUM_USE_NVIDIA") != 0)
        return;
    // a choice the user already made about Vulkan drivers is left alone
    if (qEnvironmentVariableIsSet("VK_LOADER_DRIVERS_DISABLE") || qEnvironmentVariableIsSet("VK_DRIVER_FILES"))
        return;
    if (hybridWithNvidia(QStringLiteral("/sys/class/drm")))
        qputenv("VK_LOADER_DRIVERS_DISABLE", "*nvidia*");
#endif
}

}
