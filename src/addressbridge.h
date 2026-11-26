#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>

#include "address.h"

// Makes the functions of address.h callable from the interface as "Address".
class Address : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Q_INVOKABLE QUrl resolve(const QString &typed) const { return address::resolve(typed); }
    Q_INVOKABLE bool isSearch(const QString &typed) const { return address::isSearch(typed); }
    Q_INVOKABLE QString display(const QUrl &url) const { return address::display(url); }
};
