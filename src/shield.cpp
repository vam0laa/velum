#include "shield.h"
#include "scriptlets.h"
#include <QJsonDocument>
#include <QJsonArray>
#include "library.h"
#include <QWebEngineGlobalSettings>

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QElapsedTimer>
#include <QLoggingCategory>
#include <QNetworkReply>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QThread>
#include <QWebEngineCookieStore>
#include <QWebEngineUrlRequestInfo>
#include <QtWebEngineQuick/QQuickWebEngineProfile>

#include "lists.h"

// see it with: QT_LOGGING_RULES="velum.shield.debug=true" velum
Q_LOGGING_CATEGORY(shieldLog, "velum.shield", QtInfoMsg)

namespace {

constexpr qint64 freshFor = 4 * 24 * 60 * 60;   // seconds before the lists are downloaded again

const char *kindOf(QWebEngineUrlRequestInfo::ResourceType type)
{
    using Info = QWebEngineUrlRequestInfo;
    switch (type) {
    case Info::ResourceTypeSubFrame: return "sub_frame";
    case Info::ResourceTypeStylesheet: return "stylesheet";
    case Info::ResourceTypeScript:
    case Info::ResourceTypeWorker:
    case Info::ResourceTypeSharedWorker:
    case Info::ResourceTypeServiceWorker: return "script";
    case Info::ResourceTypeImage:
    case Info::ResourceTypeFavicon: return "image";
    case Info::ResourceTypeFontResource: return "font";
    case Info::ResourceTypeObject:
    case Info::ResourceTypePluginResource: return "object";
    case Info::ResourceTypeMedia: return "media";
    case Info::ResourceTypeXhr: return "xmlhttprequest";
    case Info::ResourceTypePing:
    case Info::ResourceTypeCspReport: return "ping";
    case Info::ResourceTypeWebSocket: return "websocket";
    default: return "other";
    }
}

bool isMainPage(QWebEngineUrlRequestInfo::ResourceType type)
{
    return type == QWebEngineUrlRequestInfo::ResourceTypeMainFrame
        || type == QWebEngineUrlRequestInfo::ResourceTypeNavigationPreloadMainFrame;
}

}

Shield::Shield(QObject *parent) : QWebEngineUrlRequestInterceptor(parent)
{
    QSettings settings;
    m_enabled = settings.value(QStringLiteral("shield/enabled"), true).toBool();
    m_httpsFirst = settings.value(QStringLiteral("shield/httpsFirst"), true).toBool();
    m_blockCookies = settings.value(QStringLiteral("shield/blockThirdPartyCookies"), true).toBool();
    m_forget = settings.value(QStringLiteral("shield/forgetOnExit"), false).toBool();
    m_forgettingThisRun = m_forget;
    m_safe = settings.value(QStringLiteral("shield/safeBrowsing"), true).toBool();
    m_dns = settings.value(QStringLiteral("shield/secureDns"), QStringLiteral("off")).toString();
    if (m_dns != QLatin1String("off"))      // the engine's own way needs no telling
        applyDns();
    m_cookieNotify.setSingleShot(true);
    m_cookieNotify.setInterval(300);
    connect(&m_cookieNotify, &QTimer::timeout, this, [this] { ++m_cookieRevision; emit cookiesChanged(); });
    // what sites keep besides cookies; removed before the engine opens it
    if (m_forget) {
        const QString engine = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/QtWebEngine/velum/");
        for (const char *kept : {"Local Storage", "IndexedDB", "Session Storage", "Service Worker", "databases", "File System", "Visited Links"}) {
            const QString path = engine + QLatin1String(kept);
            QFileInfo(path).isDir() ? void(QDir(path).removeRecursively()) : void(QFile::remove(path));
        }
    }
    m_total = settings.value(QStringLiteral("shield/total"), 0).toLongLong();
    const QStringList allowed = settings.value(QStringLiteral("shield/allowed")).toStringList();
    m_allowed = QSet<QString>(allowed.begin(), allowed.end());

    // many requests are blocked at once; the interface is told at most four times a second
    m_notify.setSingleShot(true);
    m_notify.setInterval(250);
    connect(&m_notify, &QTimer::timeout, this, [this] {
        QSettings().setValue(QStringLiteral("shield/total"), m_total);   // a number, nothing about where
        ++m_revision;
        emit countsChanged();
    });

    offerConverter();
    // the first time before any page loads, or the pages restored at start would go unprotected
    load(true);
    // tests set VELUM_NO_UPDATES so that they never touch the network
    if (!qEnvironmentVariableIsSet("VELUM_NO_UPDATES")) {
        const QFileInfo first(folder() + QLatin1Char('/') + lists::sources().constFirst().file);
        if (!first.exists() || first.lastModified().secsTo(QDateTime::currentDateTime()) > freshFor)
            updateLists();
        else if (!QFileInfo::exists(folder() + QStringLiteral("/ubo-scriptlets.json")) && m_converter.isEmpty())
            fetchScriptlets();
    }
}

QString Shield::folder() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/filters");
}

void Shield::setStatus(const QString &code, int count)
{
    m_status = code;
    m_statusCount = count;
    emit changed();
}

QString Shield::statusText(bool turkish, int, const QString &) const
{
    const auto t = [turkish](const char *tr, const char *en) { return QString::fromUtf8(turkish ? tr : en); };
    if (m_status == QLatin1String("ready"))
        return t("Koruma açık · %1 liste", "Protection on · %1 lists").arg(m_statusCount);
    if (m_status == QLatin1String("loading"))
        return t("Listeler yükleniyor…", "Loading lists…");
    if (m_status == QLatin1String("downloading"))
        return t("Listeler indiriliyor…", "Downloading lists…");
    if (m_status == QLatin1String("failed"))
        return t("Listeler alınamadı", "The lists could not be loaded");
    if (m_status == QLatin1String("cleared"))
        return t("Çerezler ve önbellek silindi", "Cookies and cache deleted");
    return t("Filtre listeleri henüz yok", "No filter lists yet");
}

// Reads the lists on disk and builds the engine, later on a worker thread so the window never stalls.
void Shield::load(bool wait)
{
    if (m_loading) {
        m_again = true;
        return;
    }
    QList<Blocker::List> found;
    QByteArray resources;
    for (const lists::Source &source : lists::sources()) {
        QFile file(folder() + QLatin1Char('/') + source.file);
        if (!file.open(QIODevice::ReadOnly))
            continue;
        if (source.file == QLatin1String(lists::harmfulFile)) {
            const QStringList hosts = library::hostList(file.readAll());
            m_bad = QSet<QString>(hosts.begin(), hosts.end());
            continue;
        }
        if (source.file.endsWith(QLatin1String(".json")))
            resources = file.readAll();
        else
            found.append({lists::forThisEngine(file.readAll()), source.trusted});
    }
    // uBlock Origin's page scripts, once converted, join Brave's
    QFile ubo(folder() + QStringLiteral("/ubo-scriptlets.json"));
    const bool withScripts = ubo.open(QIODevice::ReadOnly);
    if (withScripts) {
        QJsonArray all = QJsonDocument::fromJson(resources).array();
        for (const auto &one : QJsonDocument::fromJson(ubo.readAll()).array())
            all.append(one);
        resources = QJsonDocument(all).toJson(QJsonDocument::Compact);
    }
    if (found.isEmpty()) {
        setStatus(QStringLiteral("none"));
        return;
    }
    const int count = found.size();
    const auto build = [found, resources] {
        QElapsedTimer timer;
        timer.start();
        auto built = Blocker::build(found, resources);
        qCDebug(shieldLog) << "engine built from" << found.size() << "lists and" << resources.size() << "bytes of scripts in" << timer.elapsed() << "ms";
        return built;
    };
    const auto use = [this, count, withScripts](const std::shared_ptr<Blocker> &built) {
        m_loading = false;
        if (built) {
            m_blocker = built;
            m_pageScripts = withScripts;
        }
        setStatus(built ? QStringLiteral("ready") : QStringLiteral("failed"), count);
        if (std::exchange(m_again, false))
            load();
    };
    m_loading = true;
    if (wait) {
        use(build());
        return;
    }
    setStatus(QStringLiteral("loading"));
    QThread *worker = QThread::create([this, build, use] {
        auto built = build();
        QMetaObject::invokeMethod(this, [use, built] { use(built); });
    });
    connect(worker, &QThread::finished, worker, &QObject::deleteLater);
    worker->start();
}

void Shield::updateLists()
{
    if (m_pending > 0)
        return;
    QDir().mkpath(folder());
    m_failed = 0;
    setStatus(QStringLiteral("downloading"));
    fetchScriptlets();
    for (const lists::Source &source : lists::sources()) {
        QNetworkRequest request(source.url);
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Velum"));
        request.setTransferTimeout(30000);
        QNetworkReply *reply = m_network.get(request);
        ++m_pending;
        connect(reply, &QNetworkReply::finished, this, [this, reply, source] {
            reply->deleteLater();
            const QByteArray data = reply->readAll();
            bool saved = false;
            // a list is replaced only by a complete, sensible download
            if (reply->error() == QNetworkReply::NoError && data.size() < 40 * 1024 * 1024 && lists::plausible(source.file, data)) {
                QSaveFile file(folder() + QLatin1Char('/') + source.file);
                saved = file.open(QIODevice::WriteOnly) && file.write(data) == data.size() && file.commit();
            }
            if (!saved)
                ++m_failed;
            if (--m_pending == 0) {
                if (m_failed > 0 && !m_blocker)
                    setStatus(QStringLiteral("failed"), m_failed);
                load();
            }
        });
    }
}

void Shield::fetchScriptlets()
{
    if (m_waitingModules > 0)
        return;
    QDir().mkpath(folder());
    m_modules.clear();
    m_modulesFailed = false;
    fetchModule(QString::fromLatin1(scriptlets::entry));
}

void Shield::fetchModule(const QString &path)
{
    QNetworkRequest request(QUrl(QString::fromLatin1(scriptlets::root) + path));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Velum"));
    request.setTransferTimeout(30000);
    QNetworkReply *reply = m_network.get(request);
    ++m_waitingModules;
    m_modules.insert(path, QString());
    connect(reply, &QNetworkReply::finished, this, [this, reply, path] {
        reply->deleteLater();
        const QByteArray data = reply->readAll();
        if (reply->error() != QNetworkReply::NoError || data.isEmpty() || data.startsWith('<') || data.size() > 2 * 1024 * 1024) {
            m_modulesFailed = true;
        } else {
            const QString source = QString::fromUtf8(data);
            m_modules.insert(path, source);
            for (const QString &needed : scriptlets::imports(path, source))
                if (!m_modules.contains(needed) && m_modules.size() < 80)
                    fetchModule(needed);
        }
        if (--m_waitingModules > 0)
            return;
        // all or nothing: half a set of scripts is worse than the last whole one
        const QString script = m_modulesFailed ? QString() : scriptlets::converter(m_modules);
        m_modules.clear();
        if (script.isEmpty())
            return;
        QSaveFile file(folder() + QStringLiteral("/ubo-converter.js"));
        const QByteArray bytes = script.toUtf8();
        if (file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size() && file.commit())
            offerConverter();
    });
}

// a converter on disk has not given its answer yet
void Shield::offerConverter()
{
    QFile file(folder() + QStringLiteral("/ubo-converter.js"));
    const QString script = file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()) : QString();
    if (script != m_converter) {
        m_converter = script;
        emit converterChanged();
    }
}

void Shield::takeScriptlets(const QString &json)
{
    const QByteArray bytes = json.toUtf8();
    const bool good = scriptlets::plausible(bytes);
    qCDebug(shieldLog) << "page scripts converted:" << good << bytes.size() << "bytes";
    if (good) {
        QSaveFile file(folder() + QStringLiteral("/ubo-scriptlets.json"));
        if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() || !file.commit())
            return;
    }
    QFile::remove(folder() + QStringLiteral("/ubo-converter.js"));
    offerConverter();
    if (good)
        load();
}

void Shield::interceptRequest(QWebEngineUrlRequestInfo &info)
{
    const QUrl url = info.requestUrl();
    const auto type = info.resourceType();

    if (url.host() == QLatin1String(lists::signInHost))
        info.setHttpHeader("User-Agent", lists::signInAgent().toLatin1());

    // "Global Privacy Control": asks sites not to sell or share what they learn
    info.setHttpHeader("Sec-GPC", "1");

    if (m_httpsFirst && lists::shouldUpgrade(url)) {
        QUrl secure = url;
        secure.setScheme(QStringLiteral("https"));
        if (secure.port() == 80)
            secure.setPort(-1);
        info.redirect(secure);
        return;
    }

    // a site known to hand out harmful software is refused, even as the page itself
    if (isHarmful(url.host())) {
        info.block(true);
        return;
    }

    // the page the user asked for is never blocked; lists are about what the page pulls in
    if (!m_enabled || !m_blocker || isMainPage(type))
        return;
    const QString site = info.firstPartyUrl().host();
    if (m_allowed.contains(site))
        return;
    const QUrl source = info.initiator().isValid() && !info.initiator().host().isEmpty() ? info.initiator() : info.firstPartyUrl();
    if (m_blocker->blocks(url, source, kindOf(type))) {
        qCDebug(shieldLog).noquote() << "blocked" << url.host() << url.path().left(60);
        info.block(true);
        ++m_counts[site];
        if (m_blockedBy[site].size() < 200 || m_blockedBy[site].contains(url.host()))
            ++m_blockedBy[site][url.host()];
        ++m_total;
        if (!m_notify.isActive())
            m_notify.start();
    }
}

void Shield::attach(QObject *profile)
{
    auto *quick = qobject_cast<QQuickWebEngineProfile *>(profile);
    if (!quick)
        return;
    quick->setUrlRequestInterceptor(this);
    // Cookies a page's helpers set about you on other people's sites are the classic way of
    // following someone around. A site the user switched protection off for may set them.
    quick->cookieStore()->setCookieFilter([this](const QWebEngineCookieStore::FilterRequest &request) {
        if (!request.thirdParty || !m_blockCookies || lists::isCaptchaService(request.origin.host()))
            return true;
        QReadLocker lock(&m_lock);
        const bool excepted = m_allowed.contains(request.firstPartyUrl.host());
        if (!excepted)
            qCDebug(shieldLog) << "third party cookie refused for" << request.origin.host() << "on" << request.firstPartyUrl.host();
        return excepted;
    });
    if (m_forget)
        quick->cookieStore()->deleteAllCookies();
    // a list of the cookies, for the settings; private windows are left out of it
    if (m_cookieStore || quick->isOffTheRecord())
        return;
    m_cookieStore = quick->cookieStore();
    connect(m_cookieStore, &QWebEngineCookieStore::cookieAdded, this, [this](const QNetworkCookie &c) {
        auto &list = m_cookies[c.domain().startsWith(QLatin1Char('.')) ? c.domain().mid(1) : c.domain()];
        list.removeIf([&c](const QNetworkCookie &o) { return o.hasSameIdentifier(c); });
        list.append(c);
        m_cookieNotify.start();
    });
    connect(m_cookieStore, &QWebEngineCookieStore::cookieRemoved, this, [this](const QNetworkCookie &c) {
        const QString site = c.domain().startsWith(QLatin1Char('.')) ? c.domain().mid(1) : c.domain();
        if (m_cookies.contains(site)) {
            m_cookies[site].removeIf([&c](const QNetworkCookie &o) { return o.hasSameIdentifier(c); });
            if (m_cookies[site].isEmpty())
                m_cookies.remove(site);
            m_cookieNotify.start();
        }
    });
    // read once the window is up: opening the cookie file would hold up the start
    QTimer::singleShot(2500, m_cookieStore, &QWebEngineCookieStore::loadAllCookies);
}

QVariantList Shield::blockedHosts(const QString &site, int) const
{
    QList<std::pair<int, QString>> sorted;
    const auto found = m_blockedBy.value(site);
    for (auto it = found.begin(); it != found.end(); ++it)
        sorted.append({-it.value(), it.key()});
    std::sort(sorted.begin(), sorted.end());
    QVariantList out;
    for (const auto &[count, host] : std::as_const(sorted))
        out.append(QVariantMap{{QStringLiteral("host"), host}, {QStringLiteral("count"), -count}});
    return out;
}

QVariantList Shield::cookieSites(const QString &text, int) const
{
    QStringList sites = m_cookies.keys();
    sites.sort();
    QVariantList out;
    for (const QString &site : std::as_const(sites))
        if (site.contains(text.trimmed(), Qt::CaseInsensitive))
            out.append(QVariantMap{{QStringLiteral("site"), site}, {QStringLiteral("count"), int(m_cookies.value(site).size())}});
    return out;
}

void Shield::removeCookies(const QString &site)
{
    if (!m_cookieStore)
        return;
    const auto list = m_cookies.value(site);
    for (const QNetworkCookie &c : list)
        m_cookieStore->deleteCookie(c);
}

void Shield::setSafeBrowsing(bool on)
{
    if (m_safe == on)
        return;
    m_safe = on;
    QSettings().setValue(QStringLiteral("shield/safeBrowsing"), on);
    emit changed();
}

void Shield::setSecureDns(const QString &provider)
{
    const QString clean = provider == QLatin1String("cloudflare") || provider == QLatin1String("quad9") ? provider : QStringLiteral("off");
    if (m_dns == clean)
        return;
    m_dns = clean;
    QSettings().setValue(QStringLiteral("shield/secureDns"), clean);
    applyDns();
    emit changed();
}

bool Shield::encryptDnsForNow()
{
    if (m_dnsForNow || m_dns != QLatin1String("off"))
        return false;
    m_dnsForNow = true;
    using namespace QWebEngineGlobalSettings;
    setDnsMode({SecureDnsMode::SecureWithFallback, {QStringLiteral("https://cloudflare-dns.com/dns-query")}});
    return true;
}

void Shield::applyDns()
{
    using namespace QWebEngineGlobalSettings;
    if (m_dns == QLatin1String("cloudflare"))
        setDnsMode({SecureDnsMode::SecureOnly, {QStringLiteral("https://cloudflare-dns.com/dns-query")}});
    else if (m_dns == QLatin1String("quad9"))
        setDnsMode({SecureDnsMode::SecureOnly, {QStringLiteral("https://dns.quad9.net/dns-query")}});
    else
        setDnsMode({SecureDnsMode::SystemOnly, {}});
}

void Shield::clearData(QObject *profile)
{
    if (auto *quick = qobject_cast<QQuickWebEngineProfile *>(profile)) {
        quick->cookieStore()->deleteAllCookies();
        quick->clearHttpCache();
        setStatus(QStringLiteral("cleared"));
    }
}

void Shield::setBlockThirdPartyCookies(bool on)
{
    if (m_blockCookies == on)
        return;
    m_blockCookies = on;
    QSettings().setValue(QStringLiteral("shield/blockThirdPartyCookies"), on);
    emit changed();
}

void Shield::setForgetOnExit(bool on)
{
    if (m_forget == on)
        return;
    m_forget = on;
    QSettings().setValue(QStringLiteral("shield/forgetOnExit"), on);
    emit changed();
}

void Shield::resetCount(const QString &host)
{
    m_blockedBy.remove(host);
    if (m_counts.remove(host)) {
        ++m_revision;
        emit countsChanged();
    }
}

void Shield::setEnabled(bool on)
{
    if (m_enabled == on)
        return;
    m_enabled = on;
    QSettings().setValue(QStringLiteral("shield/enabled"), on);
    emit changed();
}

void Shield::setHttpsFirst(bool on)
{
    if (m_httpsFirst == on)
        return;
    m_httpsFirst = on;
    QSettings().setValue(QStringLiteral("shield/httpsFirst"), on);
    emit changed();
}

void Shield::setAllowed(const QString &host, bool allow)
{
    if (host.isEmpty() || allow == m_allowed.contains(host))
        return;
    {
        QWriteLocker lock(&m_lock);
        if (allow)
            m_allowed.insert(host);
        else
            m_allowed.remove(host);
    }
    QSettings().setValue(QStringLiteral("shield/allowed"), QStringList(m_allowed.begin(), m_allowed.end()));
    ++m_revision;
    emit countsChanged();
    emit changed();
}

QStringList Shield::earlySites() const
{
    return {QStringLiteral("www.youtube.com"), QStringLiteral("m.youtube.com"), QStringLiteral("music.youtube.com"),
            QStringLiteral("youtube.com"), QStringLiteral("www.youtube-nocookie.com"), QLatin1String(lists::signInHost)};
}

QString Shield::earlyScript(const QString &host) const
{
    // the sign-in page hears who Velum says it is there, with or without protection
    const QString script = host == QLatin1String(lists::signInHost) ? lists::signInScript()
        : scriptFor(QUrl(QStringLiteral("https://") + host + QLatin1Char('/')));
    if (script.isEmpty())
        return {};
    // the engine reads these lines and runs the script on that site only
    return QStringLiteral("// ==UserScript==\n// @match https://") + host + QStringLiteral("/*\n// ==/UserScript==\n") + script;
}

QString Shield::pageScript(const QUrl &url) const
{
    return earlySites().contains(url.host()) ? QString() : scriptFor(url);
}

QString Shield::scriptFor(const QUrl &url) const
{
    if (!m_enabled || !m_blocker || m_allowed.contains(url.host())
        || (url.scheme() != QLatin1String("https") && url.scheme() != QLatin1String("http")))
        return {};
    const QString script = m_blocker->pageScript(url);
    qCDebug(shieldLog) << "page script for" << url.host() << script.size() << "characters";
    return script;
}
