#pragma once
#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QSaveFile>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

#include "library.h"

// Bookmark files and locked files, as the interface sees them ("Library"). Only the two
// kinds of file named here can be touched.
class Library : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE bool writeBookmarks(const QUrl &file, const QVariantList &bookmarks) const
    {
        return write(path(file, {".html", ".htm"}), library::toHtml(bookmarks).toUtf8());
    }
    Q_INVOKABLE QVariantList readBookmarks(const QUrl &file) const
    {
        return library::fromHtml(QString::fromUtf8(read(path(file, {".html", ".htm"}))));
    }
    // The icon of a bookmarked site, saved as a small PNG. No cookies of yours go along.
    Q_INVOKABLE void fetchIcon(const QUrl &page, const QString &file)
    {
        if (!web(page) || !file.endsWith(QLatin1String(".png")))
            return;
        get(page, [this, file](const QByteArray &html, const QUrl &landed) {
            tryIcons(library::iconLinks(html, landed), file);
        });
    }
    // reads the manifest of an installed extension's folder
    Q_INVOKABLE QVariantMap extensionAccess(const QString &folder) const
    {
        return library::extensionAccess(read(folder.isEmpty() ? QString() : folder + QStringLiteral("/manifest.json")));
    }
    Q_INVOKABLE bool writeLocked(const QUrl &file, const QString &text, const QString &password) const
    {
        const QByteArray sealed = library::seal(text.toUtf8(), password);
        return !sealed.isEmpty() && write(path(file, {".velumbackup"}), sealed);
    }
    // { found, opened, text }: a file that is there but does not open has the wrong password or is damaged
    Q_INVOKABLE QVariantMap readLocked(const QUrl &file, const QString &password) const
    {
        const QByteArray sealed = read(path(file, {".velumbackup"}));
        const auto opened = sealed.isEmpty() ? std::nullopt : library::unseal(sealed, password);
        return {{QStringLiteral("found"), !sealed.isEmpty()},
                {QStringLiteral("opened"), opened.has_value()},
                {QStringLiteral("text"), opened ? QString::fromUtf8(*opened) : QString()}};
    }

signals:
    void iconSaved(const QString &file);

private:
    static bool web(const QUrl &url) { return url.scheme() == QLatin1String("https") || url.scheme() == QLatin1String("http"); }
    template <typename Done> void get(const QUrl &url, Done done)
    {
        QNetworkRequest request(url);
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Mozilla/5.0 Velum"));
        request.setTransferTimeout(10000);
        QNetworkReply *reply = m_network.get(request);
        // a page or picture far larger than expected is cut off
        connect(reply, &QNetworkReply::downloadProgress, reply, [reply](qint64 got) { if (got > 4 * 1024 * 1024) reply->abort(); });
        connect(reply, &QNetworkReply::finished, this, [reply, url, done] {
            reply->deleteLater();
            const bool ok = reply->error() == QNetworkReply::NoError;
            done(ok ? reply->readAll() : QByteArray(), ok ? reply->url() : url);
        });
    }
    void tryIcons(QList<QUrl> links, const QString &file)
    {
        if (links.isEmpty())
            return;
        const QUrl next = links.takeFirst();
        get(next, [this, links, file](QByteArray data, const QUrl &) {
            QBuffer buffer(&data);
            QImageReader reader(&buffer);
            QImage best;
            // an .ico file holds several sizes: the largest looks best
            for (int i = 0; i < 16; ++i) {
                if (i > 0 && !reader.jumpToImage(i))
                    break;
                const QSize size = reader.size();
                if (size.width() > 2048 || size.height() > 2048)
                    continue;
                const QImage image = reader.read();
                if (image.width() > best.width())
                    best = image;
            }
            if (best.isNull() || !QDir().mkpath(QFileInfo(file).path()))
                return tryIcons(links, file);
            if (best.width() > 64 || best.height() > 64)
                best = best.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            if (best.save(file, "PNG"))
                emit iconSaved(file);
        });
    }
    QNetworkAccessManager m_network;
    static constexpr qint64 limit = 16 * 1024 * 1024;
    static QString path(const QUrl &url, std::initializer_list<const char *> endings)
    {
        const QString p = url.isLocalFile() ? url.toLocalFile() : QString();
        for (const char *e : endings)
            if (p.endsWith(QLatin1String(e), Qt::CaseInsensitive))
                return p;
        return {};
    }
    static QByteArray read(const QString &p)
    {
        QFile f(p);
        return !p.isEmpty() && f.open(QIODevice::ReadOnly) && f.size() <= limit ? f.readAll() : QByteArray();
    }
    static bool write(const QString &p, const QByteArray &data)
    {
        QSaveFile f(p);
        return !p.isEmpty() && data.size() <= limit && f.open(QIODevice::WriteOnly) && f.write(data) == data.size() && f.commit();
    }
};
