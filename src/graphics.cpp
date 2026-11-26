#include "graphics.h"

#include <QDir>
#include <QFile>

namespace graphics {

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

void prepare()
{
    // Draw on the main thread. With the threaded loop a window resized by the compositor
    // could stop drawing for seconds, showing its old picture stretched and cut in half.
    if (!qEnvironmentVariableIsSet("QSG_RENDER_LOOP"))
        qputenv("QSG_RENDER_LOOP", "basic");
    if (qEnvironmentVariableIntValue("VELUM_USE_NVIDIA") != 0)
        return;
    // a choice the user already made about Vulkan drivers is left alone
    if (qEnvironmentVariableIsSet("VK_LOADER_DRIVERS_DISABLE") || qEnvironmentVariableIsSet("VK_DRIVER_FILES"))
        return;
    if (hybridWithNvidia(QStringLiteral("/sys/class/drm")))
        qputenv("VK_LOADER_DRIVERS_DISABLE", "*nvidia*");
}

}
