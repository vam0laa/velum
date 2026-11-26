#pragma once
#include <QHash>
#include <QNetworkCookie>
#include <QVariantList>
#include <QWebEngineCookieStore>
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
    // a script waiting to be run on an empty page; its answer goes to takeScriptlets()
    Q_PROPERTY(QString converter READ converter NOTIFY converterChanged)
    // refuse sites on the list of known harmful ones (abuse.ch URLhaus)
    Q_PROPERTY(bool safeBrowsing READ safeBrowsing WRITE setSafeBrowsing NOTIFY changed)
    // "off": the system looks names up; "cloudflare" or "quad9": only over an encrypted line
    Q_PROPERTY(QString secureDns READ secureDns WRITE setSecureDns NOTIFY changed)
    Q_PROPERTY(int cookieRevision READ cookieRevision NOTIFY cookiesChanged)
    // "none", "loading", "ready", "downloading", "failed" or "cleared"; statusText() words it
    Q_PROPERTY(QString statusCode READ statusCode NOTIFY changed)
    Q_PROPERTY(double total READ total NOTIFY countsChanged)        // everything blocked so far
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
    QString statusCode() const { return m_status; }
    QString converter() const { return m_converter; }
    Q_INVOKABLE void takeScriptlets(const QString &json);
    // the arguments after `turkish` only make interface bindings re-read the text
    Q_INVOKABLE QString statusText(bool turkish, int revision = 0, const QString &code = {}) const;
    int revision() const { return m_revision; }
    double total() const { return double(m_total); }

    Q_INVOKABLE void attach(QObject *profile);                      // start watching a browser profile
    Q_INVOKABLE int blockedCount(const QString &host, int /*revision*/ = 0) const { return m_counts.value(host); }
    Q_INVOKABLE void resetCount(const QString &host);
    Q_INVOKABLE bool allowed(const QString &host, int /*revision*/ = 0) const { return m_allowed.contains(host); }
    Q_INVOKABLE void setAllowed(const QString &host, bool allow);   // "do not block on this site"
    Q_INVOKABLE QString pageScript(const QUrl &url) const;
    // Sites whose script must be there before their first page: it is given to the whole
    // profile in advance, and pageScript() leaves them out.
    Q_INVOKABLE QStringList earlySites() const;
    Q_INVOKABLE QString earlyScript(const QString &host) const;
    Q_INVOKABLE void updateLists();
    Q_INVOKABLE void clearData(QObject *profile);                   // cookies and cached files
    bool safeBrowsing() const { return m_safe; }
    void setSafeBrowsing(bool on);
    bool isHarmful(const QString &host) const { return m_safe && m_bad.contains(host.toLower()); }
    Q_INVOKABLE bool harmful(const QString &host) const { return isHarmful(host); }
    QString secureDns() const { return m_dns; }
    void setSecureDns(const QString &provider);
    // [{ host, count }] of what was refused on `site`, most first
    Q_INVOKABLE QVariantList blockedHosts(const QString &site, int /*revision*/ = 0) const;
    int cookieRevision() const { return m_cookieRevision; }
    // [{ site, count }] of the sites that have cookies here
    Q_INVOKABLE QVariantList cookieSites(const QString &text, int /*revision*/ = 0) const;
    Q_INVOKABLE void removeCookies(const QString &site);

signals:
    void changed();
    void countsChanged();
    void cookiesChanged();
    void converterChanged();

private:
    void load(bool wait = false);
    QString scriptFor(const QUrl &url) const;
    void fetchScriptlets();
    void fetchModule(const QString &path);
    void offerConverter();
    QHash<QString, QString> m_modules;                     // path -> source, while downloading
    QString m_converter;
    int m_waitingModules = 0;
    bool m_modulesFailed = false;
    void applyDns();
    void setStatus(const QString &code, int count = 0);
    QString folder() const;

    std::shared_ptr<Blocker> m_blocker;
    QNetworkAccessManager m_network;
    QHash<QString, int> m_counts;
    QSet<QString> m_allowed;
    QSet<QString> m_bad;                                   // known harmful hosts
    QHash<QString, QHash<QString, int>> m_blockedBy;       // site -> refused host -> times
    QHash<QString, QList<QNetworkCookie>> m_cookies;       // domain -> cookies
    QWebEngineCookieStore *m_cookieStore = nullptr;
    QTimer m_cookieNotify;
    QString m_dns = QStringLiteral("off");
    int m_cookieRevision = 0;
    bool m_safe = true;
    // the cookie filter runs on the engine's network thread, so what it reads is guarded
    mutable QReadWriteLock m_lock;
    std::atomic<bool> m_blockCookies{true};
    bool m_forget = false;
    bool m_forgettingThisRun = false;
    QTimer m_notify;
    QString m_status = QStringLiteral("none");
    int m_statusCount = 0;
    int m_revision = 0;
    qint64 m_total = 0;
    int m_pending = 0;
    int m_failed = 0;
    bool m_enabled = true;
    bool m_httpsFirst = true;
    bool m_loading = false;
    bool m_again = false;        // something changed while the engine was being built
};
