#pragma once
#include <QList>
#include <QString>

#include "historystore.h"

// Reads bookmarks and history of other browsers. Their files are copied to a temporary
// folder and the copies are read: nothing of theirs is ever changed.
namespace importer {

struct Source {
    QString path;      // the profile folder
    QString name;      // e.g. "Firefox (default-release)"
    bool firefox;      // otherwise Chromium and its relatives
};

struct Bookmark {
    QString url;
    QString title;
    QString folder;    // "" when it is not in a folder of its own
};

struct Data {
    QList<Bookmark> bookmarks;
    QList<HistoryStore::Visit> visits;
    bool ok = true;    // false: something could not be read
};

QList<Source> find(const QString &home);
// History older than `since` (seconds) is left out; a negative `since` skips history.
Data read(const Source &source, qint64 since);

}
