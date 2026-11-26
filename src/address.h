#pragma once
#include <QString>
#include <QUrl>

// Turns what a person types into the address bar into a URL.
namespace address {

// An address is opened, anything else is searched for. Empty text gives an empty URL.
QUrl resolve(const QString &typed);

// An argument of the command line: a file that exists (also by a relative name, or a
// Windows path) is that file; anything else is read like something typed.
QUrl fromArgument(const QString &argument);

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

// The search address for `text`, even when the text looks like an address.
QUrl searchFor(const QString &text);

// True when resolve() would search for the text instead of opening it.
bool isSearch(const QString &typed);

// The short form shown while the field is not being edited.
QString display(const QUrl &url);

}
