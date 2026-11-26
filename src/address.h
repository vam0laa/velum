#pragma once
#include <QString>
#include <QUrl>

// Turns what a person types into the address bar into a URL.
namespace address {

// An address is opened, anything else is searched for. Empty text gives an empty URL.
QUrl resolve(const QString &typed);

// The search engines on offer; the first is the default.
struct Engine {
    const char *key;
    const char *name;
    const char *query;      // the address a search is appended to
};
const QList<Engine> &engines();
// Unknown keys leave the default in place.
void setEngine(const QString &key);
Engine engine();

// True when resolve() would search for the text instead of opening it.
bool isSearch(const QString &typed);

// The short form shown while the field is not being edited.
QString display(const QUrl &url);

}
