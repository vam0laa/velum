#pragma once
#include <QHash>
#include <QNetworkAccessManager>
#include <QReadWriteLock>
#include <QObject>
#include <QSet>
#include <QTimer>
#include <QWebEngineUrlRequestInterceptor>
#include <QtQml/qqmlregistration.h>
#include <atomic>
#include <memory>

#include "blocker.h"

// Velum's protection: it looks at every request the engine makes, blocks ads and trackers,
// upgrades http to https, and keeps the filter lists fresh. The interface calls it "Shield".
class Shield : public QWebEngineUrlRequestInterceptor
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(bool httpsFirst READ httpsFirst WRITE setHttpsFirst NOTIFY changed)
    Q_PROPERTY(bool blockThirdPartyCookies READ blockThirdPartyCookies WRITE setBlockThirdPartyCookies NOTIFY changed)
    Q_PROPERTY(bool forgetOnExit READ forgetOnExit WRITE setForgetOnExit NOTIFY changed)
    // the value forgetOnExit had at start: the engine accepts its cookie setting only once
    Q_PROPERTY(bool forgettingThisRun READ forgettingThisRun CONSTANT)
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(int revision READ revision NOTIFY countsChanged)   // bindings watch this to re-read counts

public:
    explicit Shield(QObject *parent = nullptr);

    void interceptRequest(QWebEngineUrlRequestInfo &info) override;

    bool enabled() const { return m_enabled; }
    void setEnabled(bool on);
    bool httpsFirst() const { return m_httpsFirst; }
    void setHttpsFirst(bool on);
    bool blockThirdPartyCookies() const { return m_blockCookies; }
    void setBlockThirdPartyCookies(bool on);
    bool forgetOnExit() const { return m_forget; }
    void setForgetOnExit(bool on);
    bool forgettingThisRun() const { return m_forgettingThisRun; }
    bool ready() const { return m_blocker != nullptr; }
    QString status() const { return m_status; }
    int revision() const { return m_revision; }

    Q_INVOKABLE void attach(QObject *profile);                      // start watching a browser profile
    Q_INVOKABLE int blockedCount(const QString &host, int /*revision*/ = 0) const { return m_counts.value(host); }
    Q_INVOKABLE void resetCount(const QString &host);
    Q_INVOKABLE bool allowed(const QString &host, int /*revision*/ = 0) const { return m_allowed.contains(host); }
    Q_INVOKABLE void setAllowed(const QString &host, bool allow);   // "do not block on this site"
    Q_INVOKABLE QString pageScript(const QUrl &url) const;
    Q_INVOKABLE void updateLists();
    Q_INVOKABLE void clearData(QObject *profile);                   // cookies and cached files

signals:
    void changed();
    void countsChanged();

private:
    void load();
    void setStatus(const QString &text);
    QString folder() const;

    std::shared_ptr<Blocker> m_blocker;
    QNetworkAccessManager m_network;
    QHash<QString, int> m_counts;
    QSet<QString> m_allowed;
    // the cookie filter runs on the engine's network thread, so what it reads is guarded
    mutable QReadWriteLock m_lock;
    std::atomic<bool> m_blockCookies{true};
    bool m_forget = false;
    bool m_forgettingThisRun = false;
    QTimer m_notify;
    QString m_status;
    int m_revision = 0;
    int m_pending = 0;
    int m_failed = 0;
    bool m_enabled = true;
    bool m_httpsFirst = true;
    bool m_loading = false;
};
