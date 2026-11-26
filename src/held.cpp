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

bool discard(const QString &folder, const QString &file)
{
    if (!plain(file))
        return false;
    const QDir dir(folder);
    QFile::remove(dir.filePath(file) + QStringLiteral(".download"));
    return !dir.exists(file) || QFile::remove(dir.filePath(file));
}

}
