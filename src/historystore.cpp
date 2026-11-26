#include "historystore.h"

#include <QFile>
#include <QSqlQuery>
#include <QUrl>
#include <QUuid>
#include <QVariantMap>

QString searchFold(const QString &text)
{
    QString s = text;
    s.replace(QChar(0x0130), QLatin1Char('i')).replace(QChar(0x0131), QLatin1Char('i'));
    return s.toLower();
}

HistoryStore::HistoryStore(const QString &path) : m_name(QUuid::createUuid().toString())
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_name);
    m_db.setDatabaseName(path);
    if (!m_db.open())
        return;
    if (path != QLatin1String(":memory:"))
        QFile::setPermissions(path, QFile::ReadOwner | QFile::WriteOwner);   // nobody else's business
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("PRAGMA secure_delete=ON"));   // deleted pages really leave the file
    q.exec(QStringLiteral("CREATE TABLE IF NOT EXISTS pages(url TEXT PRIMARY KEY, title TEXT NOT NULL DEFAULT '', "
                          "visits INTEGER NOT NULL DEFAULT 1, last INTEGER NOT NULL)"));
    // the searched form of address and title; older databases get it filled in once
    q.exec(QStringLiteral("ALTER TABLE pages ADD COLUMN fold TEXT"));      // fails when it is there
    fill();
}

// writes the searched form of every row that lacks it
void HistoryStore::fill()
{
    QList<std::pair<QString, QString>> missing;
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("SELECT url, title FROM pages WHERE fold IS NULL"));
    while (q.next())
        missing.append({q.value(0).toString(), q.value(1).toString()});
    if (missing.isEmpty())
        return;
    m_db.transaction();
    q.prepare(QStringLiteral("UPDATE pages SET fold = ? WHERE url = ?"));
    for (const auto &[url, title] : std::as_const(missing)) {
        q.addBindValue(searchFold(url + QLatin1Char('\n') + title));
        q.addBindValue(url);
        q.exec();
    }
    m_db.commit();
}

HistoryStore::~HistoryStore()
{
    m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(m_name);
}

void HistoryStore::add(const QString &url, const QString &title, qint64 when)
{
    QUrl parsed(url);
    if (parsed.scheme() != QLatin1String("https") && parsed.scheme() != QLatin1String("http"))
        return;
    parsed.setUserInfo(QString());   // never write a password to disk
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO pages(url, title, last) VALUES(?, ?, ?) ON CONFLICT(url) DO UPDATE SET "
                             "visits = visits + 1, last = excluded.last, "
                             "title = CASE WHEN excluded.title = '' THEN title ELSE excluded.title END, fold = NULL"));
    q.addBindValue(parsed.toString());
    q.addBindValue(title.isNull() ? QStringLiteral("") : title);
    q.addBindValue(when);
    q.exec();
    fill();
}

void HistoryStore::setTitle(const QString &url, const QString &title)
{
    if (title.isEmpty())
        return;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE pages SET title = ?, fold = NULL WHERE url = ?"));
    q.addBindValue(title);
    q.addBindValue(url);
    q.exec();
    fill();
}

int HistoryStore::merge(const QList<Visit> &visits)
{
    int taken = 0;
    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO pages(url, title, visits, last) VALUES(?, ?, ?, ?) ON CONFLICT(url) DO UPDATE SET "
                             "visits = MAX(visits, excluded.visits), last = MAX(last, excluded.last), "
                             "title = CASE WHEN title = '' THEN excluded.title ELSE title END, fold = NULL"));
    for (const Visit &v : visits) {
        QUrl parsed(v.url);
        if (parsed.scheme() != QLatin1String("https") && parsed.scheme() != QLatin1String("http"))
            continue;
        parsed.setUserInfo(QString());
        q.addBindValue(parsed.toString());
        q.addBindValue(v.title.isNull() ? QStringLiteral("") : v.title);
        q.addBindValue(qMax(1, v.visits));
        q.addBindValue(v.last);
        if (q.exec())
            ++taken;
    }
    if (!m_db.commit())
        return 0;
    fill();
    return taken;
}

QVariantList HistoryStore::search(const QString &text, int limit) const
{
    QSqlQuery q(m_db);
    const QString wanted = text.trimmed();
    if (wanted.isEmpty()) {
        q.prepare(QStringLiteral("SELECT url, title FROM pages ORDER BY last DESC, rowid DESC LIMIT ?"));
    } else {
        // % and _ typed by the user mean themselves
        QString like = searchFold(wanted);
        like.replace(QLatin1Char('\\'), QStringLiteral("\\\\")).replace(QLatin1Char('%'), QStringLiteral("\\%")).replace(QLatin1Char('_'), QStringLiteral("\\_"));
        like = QLatin1Char('%') + like + QLatin1Char('%');
        q.prepare(QStringLiteral("SELECT url, title FROM pages WHERE fold LIKE ? ESCAPE '\\' "
                                 "ORDER BY visits DESC, last DESC LIMIT ?"));
        q.addBindValue(like);
    }
    q.addBindValue(limit);
    QVariantList out;
    if (!q.exec())
        return out;
    while (q.next())
        out.append(QVariantMap{{QStringLiteral("url"), q.value(0)}, {QStringLiteral("title"), q.value(1)}});
    return out;
}

QVariantList HistoryStore::frequent(int limit) const
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT url, title FROM pages WHERE visits > 1 ORDER BY visits DESC, last DESC LIMIT ?"));
    q.addBindValue(limit);
    QVariantList out;
    if (!q.exec())
        return out;
    while (q.next())
        out.append(QVariantMap{{QStringLiteral("url"), q.value(0)}, {QStringLiteral("title"), q.value(1)}});
    return out;
}

QVariantList HistoryStore::browse(const QString &text, int limit) const
{
    QString like = searchFold(text.trimmed());
    like.replace(QLatin1Char('\\'), QStringLiteral("\\\\")).replace(QLatin1Char('%'), QStringLiteral("\\%")).replace(QLatin1Char('_'), QStringLiteral("\\_"));
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT url, title, last FROM pages WHERE fold LIKE ? ESCAPE '\\' ORDER BY last DESC, rowid DESC LIMIT ?"));
    q.addBindValue(QString(QLatin1Char('%') + like + QLatin1Char('%')));
    q.addBindValue(limit);
    QVariantList out;
    if (!q.exec())
        return out;
    while (q.next())
        out.append(QVariantMap{{QStringLiteral("url"), q.value(0)}, {QStringLiteral("title"), q.value(1)}, {QStringLiteral("last"), q.value(2)}});
    return out;
}

void HistoryStore::removeSince(qint64 when)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM pages WHERE last >= ?"));
    q.addBindValue(when);
    q.exec();
}

void HistoryStore::remove(const QString &url)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM pages WHERE url = ?"));
    q.addBindValue(url);
    q.exec();
}

void HistoryStore::clear()
{
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("DELETE FROM pages"));
    q.exec(QStringLiteral("VACUUM"));
}

void HistoryStore::forgetBefore(qint64 when)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM pages WHERE last < ?"));
    q.addBindValue(when);
    q.exec();
}
