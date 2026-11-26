#pragma once
#include <QByteArray>
#include <QString>
#include <QVariantList>
#include <optional>

// Taking your things in and out: bookmarks as the HTML file every browser reads, and
// files locked with a password (backups and synchronisation).
namespace library {

// Bookmarks [{ title, url, folder: "A/B" }] as a "Netscape bookmark file".
QString toHtml(const QVariantList &bookmarks);

// Reads such a file. Only web and file addresses are taken; at most 5000.
QVariantList fromHtml(const QString &html);

// AES-256-GCM with a key made from the password by scrypt. A changed byte, or another
// password, and nothing opens.
QByteArray seal(const QByteArray &plain, const QString &password);
std::optional<QByteArray> unseal(const QByteArray &sealed, const QString &password);

}
