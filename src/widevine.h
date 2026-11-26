#pragma once
#include <QString>

// Widevine is Google's closed module that Netflix, Prime Video and Spotify need.
// It may not be shipped with Velum, so we look for a copy already on this computer.
namespace widevine {

// The newest libwidevinecdm.so under the known places in `home`, or an empty string.
QString find(const QString &home, const QStringList &systemDirs);
QString find();

}
