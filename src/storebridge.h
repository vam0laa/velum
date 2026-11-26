#pragma once
#include <QDir>
#include <QFile>
#include <QJSValue>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QObject>
#include <QStandardPaths>
#include <QtQml/qqmlregistration.h>

#include "crx.h"

// Fetches extensions from the Chrome Web Store ("WebStore"). Google is contacted only
// when you ask for an extension, and only for that package.
class WebStore : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE QString idFrom(const QString &typed) const { return crx::idFrom(typed); }

    // done(the path of a checked zip file, "") or done("", "network" | "signature" | "disk")
    Q_INVOKABLE void fetch(const QString &typed, const QJSValue &done)
    {
        const QString id = crx::idFrom(typed);
        if (id.isEmpty()) {
            call(done, {}, QStringLiteral("network"));
            return;
        }
        QNetworkRequest request{QUrl(crx::downloadAddress(id))};
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
        request.setTransferTimeout(30000);
        QNetworkReply *reply = m_network.get(request);
        connect(reply, &QNetworkReply::downloadProgress, reply, [reply](qint64 received, qint64) {
            if (received > limit)
                reply->abort();
        });
        connect(reply, &QNetworkReply::finished, this, [this, reply, id, done] {
            reply->deleteLater();
            const QByteArray body = reply->readAll();
            if (reply->error() != QNetworkReply::NoError || body.isEmpty()) {
                call(done, {}, QStringLiteral("network"));
                return;
            }
            const QByteArray zip = crx::verifiedZip(body, id);
            if (zip.isEmpty()) {
                call(done, {}, QStringLiteral("signature"));
                return;
            }
            const QString folder = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/extensions");
            QDir().mkpath(folder);
            QFile file(folder + QLatin1Char('/') + id + QStringLiteral(".zip"));
            if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate) || file.write(zip) != zip.size()) {
                call(done, {}, QStringLiteral("disk"));
                return;
            }
            file.close();
            call(done, file.fileName(), {});
        });
    }

    // removes a package once it has been installed
    Q_INVOKABLE void discard(const QString &path) const
    {
        const QString folder = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/extensions/");
        if (path.startsWith(folder) && !path.contains(QStringLiteral("..")))
            QFile::remove(path);
    }

private:
    static void call(QJSValue done, const QString &path, const QString &problem)
    {
        if (done.isCallable())
            done.call({QJSValue(path), QJSValue(problem)});
    }
    static constexpr qint64 limit = 100 * 1024 * 1024;
    QNetworkAccessManager m_network;
};
