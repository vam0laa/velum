#include "palette.h"

#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>

namespace palette {

QVariantMap parse(const QByteArray &json)
{
    static const QRegularExpression hex(QStringLiteral("^#[0-9a-fA-F]{6}$"));
    QVariantMap out;
    const QJsonObject object = QJsonDocument::fromJson(json).object();
    for (auto it = object.begin(); it != object.end(); ++it) {
        const QString value = it.value().toString();
        if (hex.match(value).hasMatch())
            out.insert(it.key(), value);
    }
    return out;
}

QString defaultFile()
{
    QString state = qEnvironmentVariable("XDG_STATE_HOME");
    if (state.isEmpty())
        state = QDir::homePath() + QStringLiteral("/.local/state");
    return state + QStringLiteral("/quickshell/user/generated/colors.json");
}

}
