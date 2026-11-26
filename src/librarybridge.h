#pragma once
#include <QFile>
#include <QObject>
#include <QSaveFile>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

#include "library.h"

// Bookmark files and locked files, as the interface sees them ("Library"). Only the two
// kinds of file named here can be touched.
class Library : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE bool writeBookmarks(const QUrl &file, const QVariantList &bookmarks) const
    {
        return write(path(file, {".html", ".htm"}), library::toHtml(bookmarks).toUtf8());
    }
    Q_INVOKABLE QVariantList readBookmarks(const QUrl &file) const
    {
        return library::fromHtml(QString::fromUtf8(read(path(file, {".html", ".htm"}))));
    }
    // reads the manifest of an installed extension's folder
    Q_INVOKABLE QVariantMap extensionAccess(const QString &folder) const
    {
        return library::extensionAccess(read(folder.isEmpty() ? QString() : folder + QStringLiteral("/manifest.json")));
    }
    Q_INVOKABLE bool writeLocked(const QUrl &file, const QString &text, const QString &password) const
    {
        const QByteArray sealed = library::seal(text.toUtf8(), password);
        return !sealed.isEmpty() && write(path(file, {".velumbackup"}), sealed);
    }
    // { found, opened, text }: a file that is there but does not open has the wrong password or is damaged
    Q_INVOKABLE QVariantMap readLocked(const QUrl &file, const QString &password) const
    {
        const QByteArray sealed = read(path(file, {".velumbackup"}));
        const auto opened = sealed.isEmpty() ? std::nullopt : library::unseal(sealed, password);
        return {{QStringLiteral("found"), !sealed.isEmpty()},
                {QStringLiteral("opened"), opened.has_value()},
                {QStringLiteral("text"), opened ? QString::fromUtf8(*opened) : QString()}};
    }

private:
    static constexpr qint64 limit = 16 * 1024 * 1024;
    static QString path(const QUrl &url, std::initializer_list<const char *> endings)
    {
        const QString p = url.isLocalFile() ? url.toLocalFile() : QString();
        for (const char *e : endings)
            if (p.endsWith(QLatin1String(e), Qt::CaseInsensitive))
                return p;
        return {};
    }
    static QByteArray read(const QString &p)
    {
        QFile f(p);
        return !p.isEmpty() && f.open(QIODevice::ReadOnly) && f.size() <= limit ? f.readAll() : QByteArray();
    }
    static bool write(const QString &p, const QByteArray &data)
    {
        QSaveFile f(p);
        return !p.isEmpty() && data.size() <= limit && f.open(QIODevice::WriteOnly) && f.write(data) == data.size() && f.commit();
    }
};
