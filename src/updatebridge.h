#pragma once
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QObject>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include "update.h"

// Keeps Velum current ("Updater"): looks for a newer signed release, downloads it quietly
// and checks it. When Velum is closed, Windows runs the new installer and the Linux
// AppImage puts the new file in its own place. Any other Linux install belongs to whoever
// installed it, so there it stays off.
class Updater : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    // "off", "idle", "checking", "current", "downloading", "ready" or "failed"
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(QString version READ version NOTIFY changed)        // of the release found

public:
    explicit Updater(QObject *parent = nullptr) : QObject(parent)
    {
        if (qEnvironmentVariableIsSet("VELUM_NO_UPDATES"))
            return;
#ifndef Q_OS_WIN
        m_image = update::ownAppImage(qEnvironmentVariable("APPIMAGE"), qEnvironmentVariable("APPDIR"), QCoreApplication::applicationFilePath());
        // a file that cannot be replaced is not worth downloading for
        if (m_image.isEmpty() || !QFileInfo(m_image).isWritable() || !QFileInfo(QFileInfo(m_image).absolutePath()).isWritable())
            return;
#endif
        m_status = QStringLiteral("idle");
        QDir(folder()).removeRecursively();      // installers of earlier runs
        connect(&m_timer, &QTimer::timeout, this, &Updater::check);
        m_timer.start(6 * 60 * 60 * 1000);
        QTimer::singleShot(20000, this, &Updater::check);
        connect(qApp, &QCoreApplication::aboutToQuit, this, &Updater::install);
    }
    QString status() const { return m_status; }
    QString version() const { return m_release.version; }

    Q_INVOKABLE void check()
    {
        if (m_status == QLatin1String("off") || m_status == QLatin1String("checking")
            || m_status == QLatin1String("downloading") || m_status == QLatin1String("ready"))
            return;
        set(QStringLiteral("checking"));
#ifdef Q_OS_WIN
        const QString latest = QStringLiteral("https://github.com/vam0laa/velum-releases/releases/latest/download/update.json");
#else
        const QString latest = QStringLiteral("https://github.com/vam0laa/velum-releases/releases/latest/download/update-linux.json");
#endif
        QNetworkReply *manifest = get(QUrl(latest));
        connect(manifest, &QNetworkReply::finished, this, [this, manifest, latest] {
            manifest->deleteLater();
            const QByteArray body = manifest->read(64 * 1024);
            if (manifest->error() != QNetworkReply::NoError)
                return set(QStringLiteral("failed"));
            QNetworkReply *signature = get(QUrl(latest + QStringLiteral(".sig")));
            connect(signature, &QNetworkReply::finished, this, [this, signature, body] {
                signature->deleteLater();
                const auto release = update::verify(body, signature->read(4096), VELUM_UPDATE_KEY,
                    QStringLiteral("https://github.com/vam0laa/velum-releases/releases/download/"));
                if (signature->error() != QNetworkReply::NoError || !release)
                    return set(QStringLiteral("failed"));
                // only ever forward: an old, properly signed release is not installed again
                const QString mine = QCoreApplication::applicationVersion();
                if (update::compare(mine, QStringLiteral("0.0.0")) < 0 || update::compare(release->version, mine) <= 0)
                    return set(QStringLiteral("current"));
                download(*release);
            });
        });
    }

signals:
    void changed();

private:
    static QString folder() { return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/updates"); }

    QNetworkReply *get(const QUrl &url)
    {
        QNetworkRequest request(url);
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
        request.setTransferTimeout(60000);
        return m_network.get(request);
    }

    void download(const update::Release &release)
    {
        m_release = release;
        QDir().mkpath(folder());
#ifdef Q_OS_WIN
        m_file = folder() + QStringLiteral("/Velum-") + release.version + QStringLiteral("-setup.exe");
#else
        m_file = folder() + QStringLiteral("/Velum-") + release.version + QStringLiteral("-x86_64.AppImage");
#endif
        auto *file = new QFile(m_file, this);
        if (!file->open(QIODevice::WriteOnly | QIODevice::Truncate))
            return set(QStringLiteral("failed"));
        set(QStringLiteral("downloading"));
        QNetworkReply *reply = get(release.url);
        connect(reply, &QNetworkReply::readyRead, this, [reply, file, limit = release.size] {
            file->write(reply->readAll());
            if (file->size() > limit)
                reply->abort();
        });
        connect(reply, &QNetworkReply::finished, this, [this, reply, file] {
            reply->deleteLater();
            file->write(reply->readAll());
            file->close();
            file->deleteLater();
            if (reply->error() == QNetworkReply::NoError && update::matches(m_file, m_release))
                return set(QStringLiteral("ready"));
            QFile::remove(m_file);
            set(QStringLiteral("failed"));
        });
    }

    void install()
    {
        // checked again right before it is run, in case the file changed since
        if (m_status != QLatin1String("ready") || !update::matches(m_file, m_release))
            return;
#ifdef Q_OS_WIN
        QProcess::startDetached(m_file, {QStringLiteral("/VERYSILENT"), QStringLiteral("/SUPPRESSMSGBOXES"),
                                         QStringLiteral("/NORESTART"), QStringLiteral("/CLOSEAPPLICATIONS")});
#else
        if (update::replaceProgram(m_file, m_image))
            QFile::remove(m_file);
#endif
    }

    void set(const QString &status)
    {
        m_status = status;
        emit changed();
    }

    QNetworkAccessManager m_network;
    QTimer m_timer;
    update::Release m_release;
    QString m_file;
    QString m_image;                 // Linux: the AppImage file Velum runs from
    QString m_status = QStringLiteral("off");
};
