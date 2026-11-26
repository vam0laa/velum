#include "lists.h"

#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>

namespace lists {

QList<Source> sources()
{
    const auto list = [](const char *file, const char *url, bool trusted) {
        return Source{QString::fromLatin1(file), QUrl(QString::fromLatin1(url)), trusted};
    };
    return {
        list("easylist.txt", "https://easylist.to/easylist/easylist.txt", false),
        list("easyprivacy.txt", "https://easylist.to/easylist/easyprivacy.txt", false),
        list("ublock-filters.txt", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt", true),
        list("ublock-quick-fixes.txt", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt", true),
        list("ublock-privacy.txt", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt", true),
        list("ublock-unbreak.txt", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt", true),
        list(harmfulFile, "https://urlhaus.abuse.ch/downloads/hostfile/", false),
        list("resources.json", "https://raw.githubusercontent.com/brave/adblock-resources/master/dist/resources.json", false),
    };
}

bool plausible(const QString &file, const QByteArray &data)
{
    if (file.endsWith(QLatin1String(".json"))) {
        const QJsonDocument doc = QJsonDocument::fromJson(data);
        return doc.isArray() && !doc.array().isEmpty();
    }
    if (file == QLatin1String(harmfulFile))
        return data.size() > 100 && (data.contains("\n127.0.0.1\t") || data.contains("\n127.0.0.1 "));
    const QByteArray start = data.left(200).trimmed();
    return data.size() > 200 && (start.startsWith('!') || start.startsWith("[Adblock"));
}

bool isCaptchaService(const QString &host)
{
    const QString h = host.startsWith(QLatin1Char('.')) ? host.mid(1).toLower() : host.toLower();
    return h == QLatin1String("challenges.cloudflare.com") || h == QLatin1String("www.google.com")
        || h == QLatin1String("www.recaptcha.net") || h == QLatin1String("hcaptcha.com") || h.endsWith(QLatin1String(".hcaptcha.com"));
}

QByteArray forThisEngine(const QByteArray &list)
{
    // "a", "!a", and these joined with && and ||
    const auto holds = [](const QByteArray &condition) {
        const QByteArray text = QByteArray(condition).replace("||", "|").replace("&&", "&");
        for (const QByteArray &either : text.split('|')) {
            bool all = true;
            for (QByteArray word : either.split('&')) {
                word = word.trimmed();
                const bool negated = word.startsWith('!');
                if (negated)
                    word = word.mid(1).trimmed();
                all = all && ((word == "env_chromium" || word == "ext_ublock") != negated);
            }
            if (all)
                return true;
        }
        return false;
    };
    QByteArray out;
    out.reserve(list.size());
    QList<bool> open;          // for each "!#if" we are in: is this part of it taken?
    int skipping = 0;          // how many of them are not
    qsizetype at = 0;
    while (at < list.size()) {
        qsizetype end = list.indexOf('\n', at);
        end = end < 0 ? list.size() : end + 1;
        const QByteArrayView line = QByteArrayView(list).sliced(at, end - at);
        at = end;
        if (line.startsWith("!#if ")) {
            open.append(holds(line.sliced(5).toByteArray().trimmed()));
            skipping += !open.last();
        } else if (line.startsWith("!#else") && !open.isEmpty()) {
            skipping += open.last() ? 1 : -1;
            open.last() = !open.last();
        } else if (line.startsWith("!#endif") && !open.isEmpty()) {
            skipping -= !open.takeLast();
        } else if (skipping == 0) {
            out.append(line);
        }
    }
    return out;
}

QString signInAgent()
{
#ifdef Q_OS_WIN
    const QString system = QStringLiteral("Windows NT 10.0; Win64; x64");
#else
    const QString system = QStringLiteral("X11; Linux x86_64");
#endif
    return QStringLiteral("Mozilla/5.0 (%1; rv:161.0) Gecko/20100101 Firefox/161.0").arg(system);
}

QString signInScript()
{
    const QString agent = signInAgent();
    return QStringLiteral("(()=>{const say=(name,value)=>Object.defineProperty(Navigator.prototype,name,{get:()=>value,configurable:true});"
                          "say('userAgent','%1');say('appVersion','%2');say('vendor','');say('userAgentData',undefined)})();")
        .arg(agent, agent.mid(8));
}

bool shouldUpgrade(const QUrl &url)
{
    if (url.scheme() != QLatin1String("http"))
        return false;
    const QString host = url.host();
    // machines at home and on this computer rarely have certificates
    if (host == QLatin1String("localhost") || host.endsWith(QLatin1String(".local")) || !host.contains(QLatin1Char('.')))
        return false;
    const QHostAddress ip(host);
    return ip.isNull();
}

}
