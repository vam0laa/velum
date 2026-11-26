#pragma once
#include <QObject>
#include <QWebEngineNotification>
#include <QtQml/qqmlregistration.h>

// Site notifications are not shown on Windows yet: the beta tells the page they were
// closed, so nothing waits for an answer.
class Notifier : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE void show(QWebEngineNotification *notification)
    {
        if (notification)
            notification->close();
    }

signals:
    void activated();
};
