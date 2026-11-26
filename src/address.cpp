#include "address.h"

#include <QFileInfo>
#include <QHostAddress>
#include <QRegularExpression>

namespace address {

namespace {

// DuckDuckGo is the default search because it does not build a profile of the user.
QUrl search(const QString &text)
{
    return QUrl(QStringLiteral("https://duckduckgo.com/?q=")
                    + QString::fromLatin1(QUrl::toPercentEncoding(text)),
                QUrl::StrictMode);
}

// Machines on this computer or the local network usually have no certificate.
bool isLocal(const QString &host)
{
    if (host == QLatin1String("localhost") || host.endsWith(QLatin1String(".local")))
        return true;
    const QHostAddress ip(host);
    if (ip.isNull())
        return false;
    return ip.isLoopback() || ip.isPrivateUse() || ip.isLinkLocal();
}

}

QUrl resolve(const QString &typed)
{
    const QString text = typed.trimmed();
    if (text.isEmpty())
        return {};

    // Only these schemes may be typed. "javascript:" and "data:" are searched for instead,
    // so that nobody can be talked into pasting code that runs on the open page.
    static const QRegularExpression known(
        QStringLiteral("^(https?://|file://|about:|chrome://)"),
        QRegularExpression::CaseInsensitiveOption);
    if (known.match(text).hasMatch()) {
        const QUrl url(text, QUrl::TolerantMode);
        return url.isValid() ? url : search(text);
    }

    if (text.startsWith(QLatin1Char('/')) && QFileInfo::exists(text))
        return QUrl::fromLocalFile(text);

    static const QRegularExpression space(QStringLiteral("\\s"));
    if (text.contains(space))
        return search(text);

    const QUrl guess(QStringLiteral("https://") + text, QUrl::StrictMode);
    const QString host = guess.host();
    // "user@host" would send a name to a different site than it seems to; search for it.
    if (!guess.isValid() || host.isEmpty() || !guess.userInfo().isEmpty())
        return search(text);

    if (isLocal(host)) {
        QUrl local = guess;
        local.setScheme(QStringLiteral("http"));
        return local;
    }

    // A public host needs a dot and an ending made of letters: "example.com" yes, "3.14" no.
    static const QRegularExpression ending(QStringLiteral("\\.(\\p{L}{2,}|xn--[a-z0-9-]+)\\.?$"),
                                           QRegularExpression::CaseInsensitiveOption);
    if (ending.match(host).hasMatch() || !QHostAddress(host).isNull() && text.count(QLatin1Char('.')) == 3)
        return guess;

    return search(text);
}

bool isSearch(const QString &typed)
{
    const QUrl url = resolve(typed);
    return !url.isEmpty() && url == search(typed.trimmed());
}

QString display(const QUrl &url)
{
    if (url.isEmpty() || url.toString() == QLatin1String("about:blank"))
        return {};
    QString s = url.toDisplayString();
    if (s.startsWith(QLatin1String("https://")))
        s.remove(0, 8);
    if (s.endsWith(QLatin1Char('/')) && s.count(QLatin1Char('/')) == 1)
        s.chop(1);
    return s;
}

}
