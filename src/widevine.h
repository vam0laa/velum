#pragma once
#include <QString>

// Widevine is Google's closed module that Netflix, Prime Video and Spotify need.
// It may not be shipped with Velum, so we look for a copy already on this computer.
namespace widevine {

// The newest libwidevinecdm.so under the known places in `home`, or an empty string.
QString find(const QString &home, const QStringList &systemDirs);
QString find();

// The path as it can be put on the engine's command line, which splits at spaces:
// on Windows the short form of the name. Empty when that is not possible.
QString forCommandLine(const QString &path);

}
