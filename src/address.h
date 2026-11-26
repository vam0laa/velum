#pragma once
#include <QString>
#include <QUrl>

// Turns what a person types into the address bar into a URL.
namespace address {

// An address is opened, anything else is searched for. Empty text gives an empty URL.
QUrl resolve(const QString &typed);

// True when resolve() would search for the text instead of opening it.
bool isSearch(const QString &typed);

// The short form shown while the field is not being edited.
QString display(const QUrl &url);

}
