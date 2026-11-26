#pragma once
#include <QList>
#include <QSqlDatabase>
#include <QString>
#include <QVariantList>

// The pages you visited, kept in a small SQLite file on this computer only.
class HistoryStore
{
public:
    struct Visit {
        QString url;
        QString title;
        int visits;
        qint64 last;      // seconds
    };
    // `path` is the database file; ":memory:" keeps nothing.
    explicit HistoryStore(const QString &path);
    ~HistoryStore();

    bool isOpen() const { return m_db.isOpen(); }
    // Remembers a visit at `when` (seconds). Only web pages are recorded.
    void add(const QString &url, const QString &title, qint64 when);
    void setTitle(const QString &url, const QString &title);
    // Takes in visits from elsewhere; importing twice changes nothing. Returns how many were taken.
    int merge(const QList<Visit> &visits);
    // Newest first; with text, pages whose address or title contains it, most visited first.
    QVariantList search(const QString &text, int limit) const;
    // pages visited more than once, most visited first
    QVariantList frequent(int limit) const;
    void remove(const QString &url);
    void clear();
    void forgetBefore(qint64 when);

private:
    HistoryStore(const HistoryStore &) = delete;
    QString m_name;
    QSqlDatabase m_db;
};
