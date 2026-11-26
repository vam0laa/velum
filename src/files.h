#pragma once
#include <QFile>
#include <QObject>
#include <QSaveFile>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

#include "held.h"

// Between file paths and file addresses ("Files"), right on Linux and on Windows, and
// the reading and writing of theme files, the only files the interface may touch.
class Files : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;
    Q_INVOKABLE QUrl toUrl(const QString &path) const { return path.isEmpty() ? QUrl() : QUrl::fromLocalFile(path); }
    // a file address, or already a path
    Q_INVOKABLE QString toPath(const QUrl &url) const { return url.isLocalFile() ? url.toLocalFile() : url.toString(); }

    // a name in `folder` for a new file called after `title`; nothing existing is named
    Q_INVOKABLE QString freePath(const QString &folder, const QString &title, const QString &suffix) const { return held::freePath(folder, title, suffix); }

    // downloads waiting for your word (see held.h)
    Q_INVOKABLE QString heldEnding() const { return held::ending; }
    Q_INVOKABLE QString release(const QString &folder, const QString &file) const { return held::release(folder, file); }
    Q_INVOKABLE bool discard(const QString &folder, const QString &file) const { return held::discard(folder, file); }

    // a theme file's text; empty if it is not one, or larger than a theme can be
    Q_INVOKABLE QString read(const QUrl &url) const
    {
        QFile file(themePath(url));
        if (file.fileName().isEmpty() || !file.open(QIODevice::ReadOnly) || file.size() > limit)
            return {};
        return QString::fromUtf8(file.read(limit));
    }
    Q_INVOKABLE bool write(const QUrl &url, const QString &text) const
    {
        const QByteArray data = text.toUtf8();
        QSaveFile file(themePath(url));
        return !file.fileName().isEmpty() && data.size() <= limit && file.open(QIODevice::WriteOnly)
            && file.write(data) == data.size() && file.commit();
    }

private:
    static constexpr qint64 limit = 128 * 1024;
    static QString themePath(const QUrl &url)
    {
        const QString path = url.isLocalFile() ? url.toLocalFile() : QString();
        return path.endsWith(QLatin1String(".velumtheme"), Qt::CaseInsensitive) ? path : QString();
    }
};
