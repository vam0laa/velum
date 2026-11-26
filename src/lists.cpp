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
        list("resources.json", "https://raw.githubusercontent.com/brave/adblock-resources/master/dist/resources.json", false),
    };
}

bool plausible(const QString &file, const QByteArray &data)
{
    if (file.endsWith(QLatin1String(".json"))) {
        const QJsonDocument doc = QJsonDocument::fromJson(data);
        return doc.isArray() && !doc.array().isEmpty();
    }
    const QByteArray start = data.left(200).trimmed();
    return data.size() > 200 && (start.startsWith('!') || start.startsWith("[Adblock"));
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
