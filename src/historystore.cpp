#include "historystore.h"

#include <QFile>
#include <QSqlQuery>
#include <QUrl>
#include <QUuid>
#include <QVariantMap>

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
                             "title = CASE WHEN excluded.title = '' THEN title ELSE excluded.title END"));
    q.addBindValue(parsed.toString());
    q.addBindValue(title.isNull() ? QStringLiteral("") : title);
    q.addBindValue(when);
    q.exec();
}

void HistoryStore::setTitle(const QString &url, const QString &title)
{
    if (title.isEmpty())
        return;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE pages SET title = ? WHERE url = ?"));
    q.addBindValue(title);
    q.addBindValue(url);
    q.exec();
}

int HistoryStore::merge(const QList<Visit> &visits)
{
    int taken = 0;
    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO pages(url, title, visits, last) VALUES(?, ?, ?, ?) ON CONFLICT(url) DO UPDATE SET "
                             "visits = MAX(visits, excluded.visits), last = MAX(last, excluded.last), "
                             "title = CASE WHEN title = '' THEN excluded.title ELSE title END"));
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
    return m_db.commit() ? taken : 0;
}

QVariantList HistoryStore::search(const QString &text, int limit) const
{
    QSqlQuery q(m_db);
    const QString wanted = text.trimmed();
    if (wanted.isEmpty()) {
        q.prepare(QStringLiteral("SELECT url, title FROM pages ORDER BY last DESC, rowid DESC LIMIT ?"));
    } else {
        // % and _ typed by the user mean themselves
        QString like = wanted;
        like.replace(QLatin1Char('\\'), QStringLiteral("\\\\")).replace(QLatin1Char('%'), QStringLiteral("\\%")).replace(QLatin1Char('_'), QStringLiteral("\\_"));
        like = QLatin1Char('%') + like + QLatin1Char('%');
        q.prepare(QStringLiteral("SELECT url, title FROM pages WHERE url LIKE ? ESCAPE '\\' OR title LIKE ? ESCAPE '\\' "
                                 "ORDER BY visits DESC, last DESC LIMIT ?"));
        q.addBindValue(like);
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
