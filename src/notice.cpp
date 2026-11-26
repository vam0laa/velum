#include "notice.h"

namespace notice {

QString plain(const QString &text, int limit)
{
    QString out;
    for (const QChar c : text) {
        if (c == QLatin1Char('\n') || c == QLatin1Char('\t'))
            out += QLatin1Char(' ');
        else if (c.category() != QChar::Other_Control && c.category() != QChar::Other_Format)
            out += c;
    }
    out = out.simplified();
    if (out.size() > limit)
        out = out.left(limit - 1) + QChar(0x2026);
    return out.toHtmlEscaped();
}

QString body(const QString &message, const QString &site)
{
    const QString text = plain(message, 240);
    const QString from = plain(site, 80);
    return text.isEmpty() ? from : text + QLatin1Char('\n') + from;
}

}
