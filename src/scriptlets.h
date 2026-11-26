#pragma once
#include <QByteArray>
#include <QHash>
#include <QString>
#include <QStringList>

// uBlock Origin's page scripts (they are what stops video ads) come as JavaScript modules.
// Velum downloads them and turns them into what the blocking library reads.
namespace scriptlets {

inline constexpr char root[] = "https://raw.githubusercontent.com/gorhill/uBlock/master/src/js/";
inline constexpr char entry[] = "resources/scriptlets.js";

// the modules `source` (the module at `path`) imports, as paths below the root
QStringList imports(const QString &path, const QString &source);

// One script that runs all modules and gives the scripts back as JSON. It is meant for an
// empty page. Empty when a module is missing or uses an import this does not understand.
QString converter(const QHash<QString, QString> &modules);

// whether `json` is a usable answer of that script
bool plausible(const QByteArray &json);

}
