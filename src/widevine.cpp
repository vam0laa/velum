#ifdef _WIN32
#include <windows.h>
#endif

#include "widevine.h"

#include <QDir>
#include <QFileInfo>
#include <QStringList>
#include <QVersionNumber>

namespace widevine {

namespace {

#ifdef Q_OS_WIN
const QString relative = QStringLiteral("_platform_specific/win_x64/widevinecdm.dll");
#else
const QString relative = QStringLiteral("_platform_specific/linux_x64/libwidevinecdm.so");
#endif

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
        QStringLiteral("/AppData/Local/Google/Chrome/User Data/WidevineCdm"),
        QStringLiteral("/AppData/Local/Microsoft/Edge/User Data/WidevineCdm"),
        QStringLiteral("/AppData/Local/BraveSoftware/Brave-Browser/User Data/WidevineCdm"),
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
#ifdef Q_OS_WIN
    // installed browsers keep their copy in <Program Files>/.../Application/<version>/WidevineCdm
    QStringList installed;
    for (const char *variable : {"ProgramFiles", "ProgramFiles(x86)"}) {
        for (const char *browser : {"/Google/Chrome/Application", "/Microsoft/Edge/Application"}) {
            const QDir application(qEnvironmentVariable(variable) + QLatin1String(browser));
            for (const QString &version : application.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name | QDir::Reversed))
                installed << application.filePath(version) + QStringLiteral("/WidevineCdm");
        }
    }
    return find(QDir::homePath(), installed);
#endif
    return find(QDir::homePath(),
                {QDir::homePath() + QStringLiteral("/.local/share/velum/WidevineCdm"),
                 QStringLiteral("/opt/google/chrome/WidevineCdm"),
                 QStringLiteral("/usr/lib/chromium/WidevineCdm")});
}

QString forCommandLine(const QString &path)
{
    if (!path.contains(QLatin1Char(' ')))
        return path;
#ifdef Q_OS_WIN
    wchar_t buffer[1024];
    const std::wstring longName = QDir::toNativeSeparators(path).toStdWString();
    const DWORD length = GetShortPathNameW(longName.c_str(), buffer, 1024);
    if (length > 0 && length < 1024) {
        const QString shortName = QString::fromWCharArray(buffer, int(length));
        if (!shortName.contains(QLatin1Char(' ')))
            return shortName;
    }
#endif
    return {};
}

}
