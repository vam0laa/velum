#pragma once
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#include <QHash>
#include <QObject>
#include <QPointer>
#include <QWebEngineNotification>
#include <QtQml/qqmlregistration.h>
#include <memory>

#include "notice.h"

// Shows a site's notification through the desktop (org.freedesktop.Notifications)
// and tells the page when it is clicked. The interface calls it "Notifier".
class Notifier : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Notifier(QObject *parent = nullptr) : QObject(parent)
    {
        auto bus = QDBusConnection::sessionBus();
        bus.connect(service(), path(), service(), QStringLiteral("ActionInvoked"), this, SLOT(invoked(uint,QString)));
        bus.connect(service(), path(), service(), QStringLiteral("NotificationClosed"), this, SLOT(closed(uint,uint)));
    }

    Q_INVOKABLE void show(QWebEngineNotification *notification)
    {
        if (!notification)
            return;
        QDBusMessage call = QDBusMessage::createMethodCall(service(), path(), service(), QStringLiteral("Notify"));
        call << QStringLiteral("Velum") << uint(0) << QStringLiteral("velum")
             << notice::plain(notification->title(), 80)
             << notice::body(notification->message(), notification->origin().host())
             << QStringList{QStringLiteral("default"), QStringLiteral("Open")}
             << QVariantMap{{QStringLiteral("desktop-entry"), QStringLiteral("velum")}} << -1;
        const QDBusReply<uint> reply = QDBusConnection::sessionBus().call(call, QDBus::Block, 1000);
        if (!reply.isValid())
            return;
        m_shown.insert(reply.value(), notification);
        notification->show();
    }

signals:
    void activated();      // a notification was clicked: bring the window forward

private slots:
    void invoked(uint id, const QString &)
    {
        if (const auto n = m_shown.value(id)) {
            n->click();
            emit activated();
        }
    }
    void closed(uint id, uint)
    {
        if (const auto n = m_shown.take(id))
            n->close();
    }

private:
    static QString service() { return QStringLiteral("org.freedesktop.Notifications"); }
    static QString path() { return QStringLiteral("/org/freedesktop/Notifications"); }
    QHash<uint, QPointer<QWebEngineNotification>> m_shown;
};
