#pragma once
#include <QByteArray>
#include <QString>

// Extension packages from the Chrome Web Store (CRX version 3).
namespace crx {

// The 32-letter id in a store address, or the id itself; "" when there is none.
QString idFrom(const QString &typed);

// Where the store hands out the package of an extension.
QString downloadAddress(const QString &id);

// The zip inside a package, but only if the package is signed with the key that the
// id is made from, so nobody can pass one extension off as another. Empty if not.
QByteArray verifiedZip(const QByteArray &package, const QString &id);

}
