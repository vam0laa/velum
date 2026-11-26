#pragma once
#include <QByteArray>
#include <QList>
#include <QString>
#include <QUrl>

// The filter lists Velum downloads, and the checks a download must pass.
namespace lists {

// the list of hosts known to hand out harmful software; not an ad filter
inline constexpr char harmfulFile[] = "harmful-hosts.txt";

struct Source {
    QString file;
    QUrl url;
    bool trusted;    // may use uBlock Origin's stronger scripts
};

QList<Source> sources();

// True when `data` looks like what `file` should contain: not an error page, not cut short to nothing.
bool plausible(const QString &file, const QByteArray &data);

// Whether a request to `url` over plain http should be sent over https instead.
bool shouldUpgrade(const QUrl &url);

}
