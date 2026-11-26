#pragma once
#include <QByteArray>
#include <QString>
#include <QUrl>
#include <optional>

// Updates: what a release says about itself, and whether it can be trusted.
// A release is a small description (update.json) signed with Velum's release key, whose
// secret half never leaves the maintainer's computer.
namespace update {

struct Release {
    QString version;       // "0.1.0-beta.2"
    QUrl url;              // the installer
    QByteArray sha256;     // of the installer, in hex
    qint64 size = 0;
    QString notes;
};

// -1, 0 or 1. "0.1.0-beta.2" comes after "0.1.0-beta.1" and before "0.1.0".
// A version that cannot be read is older than everything.
int compare(const QString &a, const QString &b);

// The release in `manifest`, only if `signature` (base64) is the release key's signature of
// exactly these bytes, and the installer lies at `from`. `publicKey` is the key in hex.
std::optional<Release> verify(const QByteArray &manifest, const QByteArray &signature, const QByteArray &publicKey, const QString &from);

// Does the file have the size and the digest the release states?
bool matches(const QString &file, const Release &release);

}
