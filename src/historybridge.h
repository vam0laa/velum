#pragma once
#include <QDateTime>
#include <QDir>
#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QtQml/qqmlregistration.h>

#include "historystore.h"

// The history, as the interface sees it ("History"). Pages older than 90 days are forgotten.
class History : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit History(QObject *parent = nullptr) : QObject(parent), m_store(file())
    {
        // "forget on exit" covers the history too
        if (QSettings().value(QStringLiteral("shield/forgetOnExit"), false).toBool())
            m_store.clear();
        else
            m_store.forgetBefore(QDateTime::currentSecsSinceEpoch() - 90 * 24 * 60 * 60);
    }
    Q_INVOKABLE void add(const QString &url, const QString &title) { m_store.add(url, title, QDateTime::currentSecsSinceEpoch()); }
    Q_INVOKABLE void setTitle(const QString &url, const QString &title) { m_store.setTitle(url, title); }
    Q_INVOKABLE QVariantList search(const QString &text, int limit) const { return m_store.search(text, limit); }
    Q_INVOKABLE int merge(const QVariantList &list)
    {
        QList<HistoryStore::Visit> visits;
        for (const QVariant &item : list) {
            const QVariantMap v = item.toMap();
            visits.append({v.value(QStringLiteral("url")).toString(), v.value(QStringLiteral("title")).toString(),
                           v.value(QStringLiteral("visits")).toInt(), v.value(QStringLiteral("last")).toLongLong()});
        }
        return m_store.merge(visits);
    }
    Q_INVOKABLE QVariantList frequent(int limit) const { return m_store.frequent(limit); }
    Q_INVOKABLE void remove(const QString &url) { m_store.remove(url); }
    Q_INVOKABLE QVariantList browse(const QString &text, int limit) const { return m_store.browse(text, limit); }
    Q_INVOKABLE void removeSince(double when) { m_store.removeSince(qint64(when)); }
    Q_INVOKABLE void clear() { m_store.clear(); }

private:
    static QString file()
    {
        const QString folder = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(folder);
        return folder + QStringLiteral("/history.db");
    }
    HistoryStore m_store;
};
