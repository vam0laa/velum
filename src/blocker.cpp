#include "blocker.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <cstring>

extern "C" {
void *velumblock_builder();
void velumblock_add_list(void *, const char *, size_t, bool);
bool velumblock_add_resources(void *, const char *, size_t);
void *velumblock_build(void *);
bool velumblock_check(const void *, const char *, size_t, const char *, size_t, const char *, size_t);
char *velumblock_cosmetic(const void *, const char *, size_t);
void velumblock_string_free(char *);
void velumblock_free(void *);
}

std::shared_ptr<Blocker> Blocker::build(const QList<List> &lists, const QByteArray &resources)
{
    void *builder = velumblock_builder();
    for (const List &list : lists)
        velumblock_add_list(builder, list.text.constData(), list.text.size(), list.trusted);
    if (!resources.isEmpty())
        velumblock_add_resources(builder, resources.constData(), resources.size());
    void *engine = velumblock_build(builder);
    if (!engine)
        return {};
    return std::shared_ptr<Blocker>(new Blocker(engine));
}

Blocker::~Blocker()
{
    velumblock_free(m_engine);
}

bool Blocker::blocks(const QUrl &url, const QUrl &source, const char *kind) const
{
    const QByteArray u = url.toEncoded();
    const QByteArray s = source.toEncoded();
    return velumblock_check(m_engine, u.constData(), u.size(), s.constData(), s.size(), kind, std::strlen(kind));
}

QString Blocker::pageScript(const QUrl &url) const
{
    const QByteArray u = url.toEncoded();
    char *raw = velumblock_cosmetic(m_engine, u.constData(), u.size());
    if (!raw)
        return {};
    const QJsonObject found = QJsonDocument::fromJson(QByteArray(raw)).object();
    velumblock_string_free(raw);

    QString out;
    const QJsonArray hide = found.value(QStringLiteral("hide")).toArray();
    if (!hide.isEmpty()) {
        // one rule per selector, so that a selector the engine does not know cannot disable the rest
        QJsonArray rules;
        for (const auto &selector : hide)
            rules.append(selector.toString() + QStringLiteral("{display:none!important}"));
        out += QStringLiteral(
                   "(()=>{const rules=%1;const add=()=>{const root=document.head||document.documentElement;"
                   "if(!root)return false;const style=document.createElement('style');root.appendChild(style);"
                   "for(const r of rules){try{style.sheet.insertRule(r,style.sheet.cssRules.length)}catch(e){}}return true};"
                   "if(!add())new MutationObserver((_,o)=>{if(add())o.disconnect()}).observe(document,{childList:true,subtree:true})})();\n")
                   .arg(QString::fromUtf8(QJsonDocument(rules).toJson(QJsonDocument::Compact)));
    }
    const QString script = found.value(QStringLiteral("script")).toString();
    if (!script.isEmpty())
        out += QStringLiteral("(()=>{\nconst scriptletGlobals = {};\n") + script + QStringLiteral("\n})();");
    return out;
}
