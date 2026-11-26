#pragma once
#include <QClipboard>
#include <QFutureWatcher>
#include <QGuiApplication>
#include <QJSEngine>
#include <QJSValue>
#include <QMimeData>
#include <QObject>
#include <QThreadPool>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrentRun>
#include <QtQml/qqmlregistration.h>

#include "passwords.h"

// The keyring, as the interface sees it ("Passwords"). Every call answers later,
// through the function it was given, so a locked keyring never freezes the window.
class Passwords : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Passwords(QObject *parent = nullptr) : QObject(parent) { m_pool.setMaxThreadCount(1); }

    Q_INVOKABLE QString origin(const QUrl &url) const { return passwords::origin(url); }

    // done([{ origin, user }]) or done(null) when the keyring cannot be used
    Q_INVOKABLE void accounts(const QString &origin, const QJSValue &done)
    {
        run([origin] {
            const auto found = passwords::accounts(origin);
            if (!found)
                return QVariant::fromValue(nullptr);
            QVariantList out;
            for (const auto &a : *found)
                out.append(QVariantMap{{QStringLiteral("origin"), a.origin}, {QStringLiteral("user"), a.user}});
            return QVariant(out);
        }, done);
    }

    // done("same" | "changed" | "new" | "error"): is this login already saved?
    Q_INVOKABLE void check(const QString &origin, const QString &user, const QString &password, const QJSValue &done)
    {
        run([origin, user, password] {
            const auto found = passwords::accounts(origin);
            if (!found)
                return QVariant(QStringLiteral("error"));
            bool known = false;
            for (const auto &a : *found) {
                // a form without a name field matches any account with this password
                if (a.user != user && !user.isEmpty())
                    continue;
                const auto saved = passwords::password(origin, a.user);
                if (saved && *saved == password)
                    return QVariant(QStringLiteral("same"));
                known = known || a.user == user;
            }
            return QVariant(known ? QStringLiteral("changed") : QStringLiteral("new"));
        }, done);
    }

    Q_INVOKABLE void save(const QString &origin, const QString &user, const QString &password, const QJSValue &done)
    {
        run([origin, user, password] { return QVariant(passwords::save(origin, user, password)); }, done);
    }

    // done(the password) or done(null); used only to fill a form you asked to be filled
    Q_INVOKABLE void password(const QString &origin, const QString &user, const QJSValue &done)
    {
        run([origin, user] {
            const auto found = passwords::password(origin, user);
            return found ? QVariant(*found) : QVariant::fromValue(nullptr);
        }, done);
    }

    Q_INVOKABLE void remove(const QString &origin, const QString &user, const QJSValue &done)
    {
        run([origin, user] { return QVariant(passwords::remove(origin, user)); }, done);
    }

    // Puts a password on the clipboard, marked as secret, and takes it off after 30 seconds.
    Q_INVOKABLE void copy(const QString &origin, const QString &user, const QJSValue &done)
    {
        auto *watcher = new QFutureWatcher<std::optional<QString>>(this);
        connect(watcher, &QFutureWatcherBase::finished, this, [this, watcher, done] {
            const auto found = watcher->result();
            watcher->deleteLater();
            if (found) {
                auto *data = new QMimeData;
                data->setText(*found);
                // clipboard history tools that know this leave it out
                data->setData(QStringLiteral("x-kde-passwordManagerHint"), "secret");
                QGuiApplication::clipboard()->setMimeData(data);
                const QString copied = *found;
                QTimer::singleShot(30000, this, [copied] {
                    if (QGuiApplication::clipboard()->text() == copied)
                        QGuiApplication::clipboard()->clear();
                });
            }
            call(done, QVariant(found.has_value()));
        });
        watcher->setFuture(QtConcurrent::run(&m_pool, [origin, user] { return passwords::password(origin, user); }));
    }

private:
    void call(QJSValue done, const QVariant &value)
    {
        if (QJSEngine *engine = qjsEngine(this); engine && done.isCallable())
            done.call({value.isNull() ? QJSValue(QJSValue::NullValue) : engine->toScriptValue(value)});
    }

    template<typename Work>
    void run(Work work, const QJSValue &done)
    {
        auto *watcher = new QFutureWatcher<QVariant>(this);
        connect(watcher, &QFutureWatcherBase::finished, this, [this, watcher, done] {
            watcher->deleteLater();
            call(done, watcher->result());
        });
        watcher->setFuture(QtConcurrent::run(&m_pool, work));
    }

    QThreadPool m_pool;
};
