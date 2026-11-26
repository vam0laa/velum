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
