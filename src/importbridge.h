#pragma once
#include <QDateTime>
#include <QDir>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include "importer.h"

// Importing from other browsers, as the interface sees it ("Importer").
// Nothing is looked at until these are called from the import panel.
class Importer : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE QVariantList sources() const
    {
        QVariantList out;
        for (const importer::Source &s : importer::find(QDir::homePath()))
            out.append(QVariantMap{{QStringLiteral("path"), s.path}, {QStringLiteral("name"), s.name}});
        return out;
    }

    // { ok, bookmarks: [{ url, title, folder }], visits: [{ url, title, visits, last }] }
    Q_INVOKABLE QVariantMap read(const QString &path, bool history) const
    {
        // only profiles found above are read, whatever is asked for
        for (const importer::Source &s : importer::find(QDir::homePath())) {
            if (s.path != path)
                continue;
            const qint64 since = history ? QDateTime::currentSecsSinceEpoch() - 90 * 24 * 60 * 60 : -1;
            const importer::Data data = importer::read(s, since);
            QVariantList bookmarks, visits;
            for (const auto &b : data.bookmarks)
                bookmarks.append(QVariantMap{{QStringLiteral("url"), b.url}, {QStringLiteral("title"), b.title}, {QStringLiteral("folder"), b.folder}});
            for (const auto &v : data.visits)
                visits.append(QVariantMap{{QStringLiteral("url"), v.url}, {QStringLiteral("title"), v.title}, {QStringLiteral("visits"), v.visits}, {QStringLiteral("last"), v.last}});
            return {{QStringLiteral("ok"), data.ok}, {QStringLiteral("bookmarks"), bookmarks}, {QStringLiteral("visits"), visits}};
        }
        return {{QStringLiteral("ok"), false}, {QStringLiteral("bookmarks"), QVariantList()}, {QStringLiteral("visits"), QVariantList()}};
    }
};
