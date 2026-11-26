#include "importer.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QUrl>
#include <QUuid>

namespace importer {
namespace {

constexpr int maxBookmarks = 2000;
constexpr int maxVisits = 20000;
// Chromium counts microseconds from 1601, everyone else from 1970
constexpr qint64 chromiumEpoch = 11644473600LL;

bool web(const QString &url)
{
    const QString scheme = QUrl(url).scheme();
    return scheme == QLatin1String("https") || scheme == QLatin1String("http");
}

// Copies the database (and its journal) into `work` and runs one query on the copy.
template<typename Row>
bool query(const QString &file, const QString &work, const QString &sql, const QList<QVariant> &values, Row row)
{
    const QString copy = work + QLatin1String("/copy.sqlite");
    for (const char *end : {"", "-wal", "-journal"}) {
        QFile::remove(copy + QLatin1String(end));
        if (QFile::exists(file + QLatin1String(end)))
            QFile::copy(file + QLatin1String(end), copy + QLatin1String(end));
    }
    const QString name = QUuid::createUuid().toString();
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), name);
        db.setDatabaseName(copy);
        if (QFile::exists(copy) && db.open()) {
            QSqlQuery q(db);
            if (q.prepare(sql)) {
                for (const QVariant &v : values)
                    q.addBindValue(v);
                ok = q.exec();
                while (ok && q.next())
                    row(q);
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(name);
    return ok;
}

void addBookmark(Data &data, QSet<QString> &seen, const QString &url, const QString &title, const QString &folder)
{
    if (!web(url) || seen.contains(url) || data.bookmarks.size() >= maxBookmarks)
        return;
    seen.insert(url);
    data.bookmarks.append({url, title.trimmed().left(120), folder.trimmed().left(40)});
}

void readFirefox(const QString &profile, qint64 since, const QString &work, Data &data)
{
    const QString file = profile + QLatin1String("/places.sqlite");
    QSet<QString> seen;
    // the built-in roots are not folders you made; "tags" holds copies and is left out
    data.ok = query(file, work, QStringLiteral(
        "SELECT p.url, b.title, CASE WHEN f.guid IN ('root________','menu________','toolbar_____','unfiled_____','mobile______') "
        "THEN '' ELSE f.title END FROM moz_bookmarks b JOIN moz_places p ON p.id = b.fk "
        "JOIN moz_bookmarks f ON f.id = b.parent LEFT JOIN moz_bookmarks g ON g.id = f.parent "
        "WHERE b.type = 1 AND IFNULL(g.guid, '') != 'tags________' ORDER BY b.parent, b.position"), {},
        [&](const QSqlQuery &q) { addBookmark(data, seen, q.value(0).toString(), q.value(1).toString(), q.value(2).toString()); });
    if (since < 0)
        return;
    data.ok &= query(file, work, QStringLiteral(
        "SELECT url, title, visit_count, last_visit_date FROM moz_places "
        "WHERE hidden = 0 AND last_visit_date >= ? ORDER BY last_visit_date DESC LIMIT ?"),
        {since * 1000000, maxVisits},
        [&](const QSqlQuery &q) {
            if (web(q.value(0).toString()))
                data.visits.append({q.value(0).toString(), q.value(1).toString(), qMax(1, q.value(2).toInt()), q.value(3).toLongLong() / 1000000});
        });
}

void walk(Data &data, QSet<QString> &seen, const QJsonObject &node, const QString &folder, int depth)
{
    for (const QJsonValue &value : node.value(QLatin1String("children")).toArray()) {
        const QJsonObject child = value.toObject();
        const QString name = child.value(QLatin1String("name")).toString();
        if (child.value(QLatin1String("type")).toString() == QLatin1String("url"))
            addBookmark(data, seen, child.value(QLatin1String("url")).toString(), name, folder);
        else if (depth < 32)
            walk(data, seen, child, name, depth + 1);
    }
}

void readChromium(const QString &profile, qint64 since, const QString &work, Data &data)
{
    QFile marks(profile + QLatin1String("/Bookmarks"));
    if (marks.exists()) {
        QSet<QString> seen;
        QJsonDocument doc;
        if (marks.size() < 32 * 1024 * 1024 && marks.open(QIODevice::ReadOnly))
            doc = QJsonDocument::fromJson(marks.readAll());
        data.ok = doc.isObject();
        const QJsonObject roots = doc.object().value(QLatin1String("roots")).toObject();
        for (const char *root : {"bookmark_bar", "other", "synced"})
            walk(data, seen, roots.value(QLatin1String(root)).toObject(), QString(), 0);
    }
    const QString history = profile + QLatin1String("/History");
    if (since < 0 || !QFile::exists(history))
        return;
    data.ok &= query(history, work, QStringLiteral(
        "SELECT url, title, visit_count, last_visit_time FROM urls "
        "WHERE hidden = 0 AND last_visit_time >= ? ORDER BY last_visit_time DESC LIMIT ?"),
        {(since + chromiumEpoch) * 1000000, maxVisits},
        [&](const QSqlQuery &q) {
            if (web(q.value(0).toString()))
                data.visits.append({q.value(0).toString(), q.value(1).toString(), qMax(1, q.value(2).toInt()), q.value(3).toLongLong() / 1000000 - chromiumEpoch});
        });
}

}

QList<Source> find(const QString &home)
{
    QList<Source> out;
    const auto folders = [](const QString &root) { return QDir(root).entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name); };

    const std::pair<const char *, const char *> foxes[] = {
        {"Firefox", ".mozilla/firefox"}, {"Firefox", ".config/mozilla/firefox"},
        {"Firefox (Flatpak)", ".var/app/org.mozilla.firefox/.mozilla/firefox"},
        {"Zen", ".zen"}, {"Zen", ".config/zen"}, {"LibreWolf", ".librewolf"}, {"LibreWolf", ".config/librewolf/librewolf"},
        {"Firefox", "AppData/Roaming/Mozilla/Firefox/Profiles"}, {"Zen", "AppData/Roaming/zen/Profiles"}, {"LibreWolf", "AppData/Roaming/librewolf/Profiles"},
    };
    for (const auto &[name, place] : foxes) {
        const QString root = home + QLatin1Char('/') + QLatin1String(place);
        for (const QString &profile : folders(root)) {
            const QString path = root + QLatin1Char('/') + profile;
            if (QFile::exists(path + QLatin1String("/places.sqlite")))   // "abc123.default-release" reads "default-release"
                out.append({path, QStringLiteral("%1 (%2)").arg(QLatin1String(name), profile.section(QLatin1Char('.'), 1).isEmpty() ? profile : profile.section(QLatin1Char('.'), 1)), true});
        }
    }

    const std::pair<const char *, const char *> chromes[] = {
        {"Chromium", ".config/chromium"}, {"Chrome", ".config/google-chrome"}, {"Brave", ".config/BraveSoftware/Brave-Browser"},
        {"Helium", ".config/net.imput.helium"}, {"Vivaldi", ".config/vivaldi"}, {"Edge", ".config/microsoft-edge"},
        {"Chrome", "AppData/Local/Google/Chrome/User Data"}, {"Edge", "AppData/Local/Microsoft/Edge/User Data"},
        {"Brave", "AppData/Local/BraveSoftware/Brave-Browser/User Data"}, {"Chromium", "AppData/Local/Chromium/User Data"},
        {"Vivaldi", "AppData/Local/Vivaldi/User Data"},
        {"Chrome (Flatpak)", ".var/app/com.google.Chrome/config/google-chrome"}, {"Brave (Flatpak)", ".var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"},
    };
    for (const auto &[name, place] : chromes) {
        const QString root = home + QLatin1Char('/') + QLatin1String(place);
        for (const QString &profile : folders(root)) {
            if (profile != QLatin1String("Default") && !profile.startsWith(QLatin1String("Profile ")))
                continue;
            const QString path = root + QLatin1Char('/') + profile;
            if (QFile::exists(path + QLatin1String("/Bookmarks")) || QFile::exists(path + QLatin1String("/History")))
                out.append({path, QStringLiteral("%1 (%2)").arg(QLatin1String(name), profile), false});
        }
    }
    return out;
}

Data read(const Source &source, qint64 since)
{
    Data data;
    QTemporaryDir work;       // readable by this user only; deleted when done
    if (!work.isValid()) {
        data.ok = false;
        return data;
    }
    if (source.firefox)
        readFirefox(source.path, since, work.path(), data);
    else
        readChromium(source.path, since, work.path(), data);
    return data;
}

}
