#pragma once
#include <QObject>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

// Between file paths and file addresses ("Files"), right on Linux and on Windows.
class Files : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;
    Q_INVOKABLE QUrl toUrl(const QString &path) const { return path.isEmpty() ? QUrl() : QUrl::fromLocalFile(path); }
    // a file address, or already a path
    Q_INVOKABLE QString toPath(const QUrl &url) const { return url.isLocalFile() ? url.toLocalFile() : url.toString(); }
};
