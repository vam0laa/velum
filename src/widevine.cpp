#include "widevine.h"

#include <QDir>
#include <QFileInfo>
#include <QStringList>
#include <QVersionNumber>

namespace widevine {

namespace {

const QString relative = QStringLiteral("_platform_specific/linux_x64/libwidevinecdm.so");

}

QString find(const QString &home, const QStringList &systemDirs)
{
    // 1. A copy the user installed for Velum itself, or one installed system wide.
    for (const QString &dir : systemDirs) {
        const QString path = dir + QLatin1Char('/') + relative;
        if (QFileInfo::exists(path))
            return path;
    }

    // 2. A copy another browser downloaded: <profile>/WidevineCdm/<version>/...
    const QStringList profiles = {
        QStringLiteral("/.config/chromium/WidevineCdm"),
        QStringLiteral("/.config/google-chrome/WidevineCdm"),
        QStringLiteral("/.config/BraveSoftware/Brave-Browser/WidevineCdm"),
        QStringLiteral("/.config/vivaldi/WidevineCdm"),
    };
    QString best;
    QVersionNumber bestVersion;
    for (const QString &profile : profiles) {
        const QDir dir(home + profile);
        for (const QString &name : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            const QVersionNumber version = QVersionNumber::fromString(name);
            const QString path = dir.filePath(name) + QLatin1Char('/') + relative;
            if (!version.isNull() && version > bestVersion && QFileInfo::exists(path)) {
                best = path;
                bestVersion = version;
            }
        }
    }
    return best;
}

QString find()
{
    return find(QDir::homePath(),
                {QDir::homePath() + QStringLiteral("/.local/share/velum/WidevineCdm"),
                 QStringLiteral("/opt/google/chrome/WidevineCdm"),
                 QStringLiteral("/usr/lib/chromium/WidevineCdm")});
}

}
