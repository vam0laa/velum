#include "scriptlets.h"

#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>

namespace scriptlets {
namespace {

// "import { a, b as c } from './x.js';" over one or more lines, or "import './x.js';"
const QRegularExpression &importLine()
{
    static const QRegularExpression re(QStringLiteral("^import\\s+(?:\\{([^}]*)\\}\\s*from\\s*)?['\"](\\.[^'\"]*)['\"];?"),
                                       QRegularExpression::MultilineOption);
    return re;
}

QString resolve(const QString &path, const QString &wanted)
{
    const QString folder = path.contains(QLatin1Char('/')) ? path.section(QLatin1Char('/'), 0, -2) + QLatin1Char('/') : QString();
    const QString found = QDir::cleanPath(folder + wanted);
    static const QRegularExpression safe(QStringLiteral("^(?:[a-z0-9-]+/)*[a-z0-9.-]+\\.js$"));
    return safe.match(found).hasMatch() ? found : QString();
}

// the module as a function that returns what it exported
QString wrap(const QString &path, QString source)
{
    qsizetype at = 0;
    QRegularExpressionMatch m;
    while ((m = importLine().match(source, at)).hasMatch()) {
        QString line;
        if (!m.captured(1).trimmed().isEmpty()) {
            static const QRegularExpression renamed(QStringLiteral("\\s+as\\s+"));
            line = QStringLiteral("const {%1} = __m['%2'];").arg(m.captured(1).replace(renamed, QStringLiteral(": ")), resolve(path, m.captured(2)));
        }
        source.replace(m.capturedStart(), m.capturedLength(), line);
        at = m.capturedStart() + line.size();
    }
    static const QRegularExpression exported(
        QStringLiteral("^export\\s+(?=(?:async\\s+function|function\\*?|class|const|let)\\s+([A-Za-z_$][\\w$]*))"),
        QRegularExpression::MultilineOption);
    QStringList names;
    auto all = exported.globalMatch(source);
    while (all.hasNext())
        names.append(all.next().captured(1));
    source.remove(exported);
    return QStringLiteral("__m['") + path + QStringLiteral("'] = (() => {\n'use strict';\n") + source
        + QStringLiteral("\nreturn {") + names.join(QLatin1Char(',')) + QStringLiteral("};\n})();\n");
}

bool add(const QString &path, const QHash<QString, QString> &modules, QSet<QString> &seen, QString &out)
{
    if (seen.contains(path))
        return true;
    seen.insert(path);
    if (!modules.contains(path))
        return false;
    for (const QString &needed : imports(path, modules.value(path)))
        if (!add(needed, modules, seen, out))
            return false;
    out += wrap(path, modules.value(path));
    return true;
}

}

QStringList imports(const QString &path, const QString &source)
{
    QStringList out;
    auto all = importLine().globalMatch(source);
    while (all.hasNext()) {
        const QString found = resolve(path, all.next().captured(2));
        if (!found.isEmpty() && !out.contains(found))
            out.append(found);
    }
    return out;
}

QString converter(const QHash<QString, QString> &modules)
{
    QSet<QString> seen;
    QString body;
    if (!add(QString::fromLatin1(entry), modules, seen, body))
        return {};
    return QStringLiteral("(() => {\nconst __m = {};\n") + body + QStringLiteral(R"JS(
const base64 = text => { let s = ''; for (const b of new TextEncoder().encode(text)) s += String.fromCharCode(b); return btoa(s); };
return JSON.stringify(__m['resources/scriptlets.js'].builtinScriptlets.map(s => ({
    name: s.name,
    aliases: s.aliases || [],
    kind: { mime: s.name.endsWith('.fn') ? 'fn/javascript' : 'application/javascript' },
    content: base64(s.fn.toString()),
    dependencies: (s.dependencies || []).map(d => typeof d === 'string' ? d : d.details.name),
    permission: s.requiresTrust ? 1 : 0
})));
})())JS");
}

bool plausible(const QByteArray &json)
{
    const QJsonArray all = QJsonDocument::fromJson(json).array();
    if (all.size() < 20)
        return false;
    for (const auto &one : all)
        if (one.toObject().value(QLatin1String("name")).toString().isEmpty() || one.toObject().value(QLatin1String("content")).toString().isEmpty())
            return false;
    return true;
}

}
