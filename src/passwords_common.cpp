// The part of the password store that every system shares.
#include "passwords.h"

namespace passwords {

QString origin(const QUrl &url)
{
    const QString host = url.host(QUrl::FullyEncoded).toLower();
    const bool local = host == QLatin1String("localhost") || host == QLatin1String("127.0.0.1") || host == QLatin1String("::1");
    if (host.isEmpty() || !(url.scheme() == QLatin1String("https") || (url.scheme() == QLatin1String("http") && local)))
        return {};
    QString out = url.scheme() + QLatin1String("://") + (host.contains(QLatin1Char(':')) ? QLatin1Char('[') + host + QLatin1Char(']') : host);
    const int usual = url.scheme() == QLatin1String("https") ? 443 : 80;
    if (url.port(usual) != usual)
        out += QLatin1Char(':') + QString::number(url.port());
    return out;
}

}
