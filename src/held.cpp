#include "held.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

namespace held {
namespace {

bool plain(const QString &file)
{
    return file.endsWith(ending) && file.size() > ending.size() && !file.contains(QLatin1Char('/')) && !file.contains(QLatin1Char('\\'));
}

}

QString release(const QString &folder, const QString &file)
{
    if (!plain(file))
        return {};
    const QDir dir(folder);
    const QString wanted = file.chopped(ending.size());
    const QString stem = QFileInfo(wanted).completeBaseName();
    const QString suffix = QFileInfo(wanted).suffix();
    QString name = wanted;
    for (int n = 1; dir.exists(name) && n < 1000; ++n)
        name = QStringLiteral("%1 (%2)%3").arg(stem).arg(n).arg(suffix.isEmpty() ? QString() : QLatin1Char('.') + suffix);
    // rename() refuses to replace a file that is there
    return QFile::rename(dir.filePath(file), dir.filePath(name)) ? name : QString();
}

QString freePath(const QString &folder, const QString &title, const QString &suffix)
{
    QString stem;
    for (const QChar c : title)
        stem += c.category() == QChar::Other_Control || c.category() == QChar::Other_Format || QStringLiteral("/\\:*?\"<>|").contains(c) ? QLatin1Char(' ') : c;
    stem = stem.simplified().left(80);
    while (stem.startsWith(QLatin1Char('.')) || stem.startsWith(QLatin1Char(' ')))
        stem.remove(0, 1);
    if (stem.isEmpty())
        stem = QStringLiteral("page");
    const QDir dir(folder);
    if (folder.isEmpty() || !dir.exists())
        return {};
    for (int n = 0; n < 1000; ++n) {
        const QString name = (n == 0 ? stem : QStringLiteral("%1 (%2)").arg(stem).arg(n)) + QLatin1Char('.') + suffix;
        if (!dir.exists(name))
            return dir.filePath(name);
    }
    return {};
}

bool discard(const QString &folder, const QString &file)
{
    if (!plain(file))
        return false;
    const QDir dir(folder);
    QFile::remove(dir.filePath(file) + QStringLiteral(".download"));
    return !dir.exists(file) || QFile::remove(dir.filePath(file));
}

}
