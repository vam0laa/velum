#pragma once
#include <QList>
#include <QString>
#include <QUrl>
#include <optional>

// Passwords, kept in the system keyring (GNOME Keyring, KWallet's secret service, KeePassXC).
// Velum itself writes none of them to disk. These calls may wait for the keyring to be
// unlocked, so the interface makes them from another thread.
namespace passwords {

struct Account {
    QString origin;     // "https://site.example"
    QString user;
};

// The origin a password may belong to: https, or this computer itself. Otherwise "".
QString origin(const QUrl &url);

// Empty `origin` lists everything. No passwords are fetched. nullopt: the keyring failed.
std::optional<QList<Account>> accounts(const QString &origin);
std::optional<QString> password(const QString &origin, const QString &user);
bool save(const QString &origin, const QString &user, const QString &password);
bool remove(const QString &origin, const QString &user);

}
