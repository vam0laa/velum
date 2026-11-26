#pragma once
#include <QByteArray>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <optional>

// Taking your things in and out: bookmarks as the HTML file every browser reads, and
// files locked with a password (backups and synchronisation).
namespace library {

// Bookmarks [{ title, url, folder: "A/B" }] as a "Netscape bookmark file".
QString toHtml(const QVariantList &bookmarks);

// Reads such a file. Only web and file addresses are taken; at most 5000.
QVariantList fromHtml(const QString &html);

// A random password of `length` characters (12 to 64) with at least one small letter, one
// capital, one digit and one sign, from the system's random source.
QString generatePassword(int length);

// The password file browsers exchange: a header naming url, username and password columns.
struct Login {
    QString url, user, password;
};
QList<Login> fromCsv(const QString &csv);          // at most 5000
QString toCsv(const QList<Login> &logins);

// Host names of a "hosts file" list (127.0.0.1<tab>name), as used for known harmful sites.
QStringList hostList(const QByteArray &file);

// What an extension's manifest.json asks for: { "permissions": [...], "hosts": [...] },
// hosts from both the host permissions and the pages its scripts run on.
QVariantMap extensionAccess(const QByteArray &manifest);

// AES-256-GCM with a key made from the password by scrypt. A changed byte, or another
// password, and nothing opens.
QByteArray seal(const QByteArray &plain, const QString &password);
std::optional<QByteArray> unseal(const QByteArray &sealed, const QString &password);

}
