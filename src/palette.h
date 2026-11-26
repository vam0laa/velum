#pragma once
#include <QString>
#include <QVariantMap>

// The colours of the desktop theme, as written by the Quickshell shell when the wallpaper changes.
namespace palette {

// Keeps only entries that really are "#rrggbb" colours. Bad input gives an empty map.
QVariantMap parse(const QByteArray &json);

QString defaultFile();

}
