#pragma once
#include <QObject>
#include <QSettings>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include "address.h"

// Makes the functions of address.h callable from the interface as "Address".
class Address : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(QString engineName READ engineName NOTIFY engineChanged)
    Q_PROPERTY(QVariantList engines READ engines CONSTANT)

public:
    explicit Address(QObject *parent = nullptr) : QObject(parent)
    {
        address::setEngine(QSettings().value(QStringLiteral("search/engine")).toString());
    }
    QString engine() const { return QString::fromLatin1(address::engine().key); }
    QString engineName() const { return QString::fromLatin1(address::engine().name); }
    QVariantList engines() const
    {
        QVariantList out;
        for (const auto &e : address::engines())
            out.append(QVariantMap{{QStringLiteral("key"), QString::fromLatin1(e.key)}, {QStringLiteral("label"), QString::fromLatin1(e.name)}});
        return out;
    }
    void setEngine(const QString &key)
    {
        address::setEngine(key);
        QSettings().setValue(QStringLiteral("search/engine"), engine());
        emit engineChanged();
    }

    Q_INVOKABLE QUrl resolve(const QString &typed) const { return address::resolve(typed); }
    Q_INVOKABLE QUrl search(const QString &text) const { return address::searchFor(text); }
    Q_INVOKABLE bool isSearch(const QString &typed) const { return address::isSearch(typed); }
    Q_INVOKABLE QString display(const QUrl &url) const { return address::display(url); }

signals:
    void engineChanged();
};
