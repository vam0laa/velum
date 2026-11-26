#include "library.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QUrl>
#include <QVariantMap>

#include <openssl/evp.h>
#include <openssl/rand.h>

#include <memory>

namespace library {
namespace {

const QByteArray magic = QByteArrayLiteral("VELUMSEAL1\n");
constexpr int saltSize = 16, ivSize = 12, tagSize = 16;

QByteArray keyFrom(const QString &password, const QByteArray &salt)
{
    const QByteArray typed = password.toUtf8();
    QByteArray key(32, 0);
    // scrypt: slow and memory hungry on purpose, so that guessing is expensive
    if (EVP_PBE_scrypt(typed.constData(), size_t(typed.size()), reinterpret_cast<const unsigned char *>(salt.constData()), size_t(salt.size()),
                       1 << 15, 8, 1, 64 * 1024 * 1024, reinterpret_cast<unsigned char *>(key.data()), size_t(key.size())) != 1)
        return {};
    return key;
}

using Context = std::unique_ptr<EVP_CIPHER_CTX, decltype(&EVP_CIPHER_CTX_free)>;
unsigned char *bytes(QByteArray &a) { return reinterpret_cast<unsigned char *>(a.data()); }
const unsigned char *bytes(const QByteArray &a) { return reinterpret_cast<const unsigned char *>(a.constData()); }

QString entity(const QString &s)
{
    QString out = s;
    static const QRegularExpression number(QStringLiteral("&#(x?)([0-9a-fA-F]{1,6});"));
    for (auto m = number.match(out); m.hasMatch(); m = number.match(out, m.capturedStart() + 1)) {
        const char32_t code = m.captured(2).toUInt(nullptr, m.captured(1).isEmpty() ? 10 : 16);
        out.replace(m.capturedStart(), m.capturedLength(), QString::fromUcs4(&code, 1));
    }
    return out.replace(QLatin1String("&lt;"), QLatin1String("<")).replace(QLatin1String("&gt;"), QLatin1String(">"))
        .replace(QLatin1String("&quot;"), QLatin1String("\"")).replace(QLatin1String("&apos;"), QLatin1String("'")).replace(QLatin1String("&amp;"), QLatin1String("&"));
}

}

QString toHtml(const QVariantList &bookmarks)
{
    QString out = QStringLiteral("<!DOCTYPE NETSCAPE-Bookmark-file-1>\n<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">\n"
                                 "<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks</H1>\n<DL><p>\n");
    // sorted by folder, keeping the order within one, so each folder is opened once
    QList<std::pair<QStringList, QVariantMap>> items;
    for (const QVariant &v : bookmarks) {
        const QVariantMap m = v.toMap();
        items.append({m.value(QStringLiteral("folder")).toString().split(QLatin1Char('/'), Qt::SkipEmptyParts), m});
    }
    std::stable_sort(items.begin(), items.end(), [](const auto &a, const auto &b) {
        return std::lexicographical_compare(a.first.begin(), a.first.end(), b.first.begin(), b.first.end());
    });
    QStringList open;
    const auto indent = [&] { return QString((open.size() + 1) * 4, QLatin1Char(' ')); };
    for (const auto &[path, m] : std::as_const(items)) {
        qsizetype same = 0;
        while (same < open.size() && same < path.size() && open[same] == path[same])
            ++same;
        while (open.size() > same) {
            open.removeLast();
            out += indent() + QStringLiteral("</DL><p>\n");
        }
        while (open.size() < path.size()) {
            out += indent() + QStringLiteral("<DT><H3>") + path[open.size()].toHtmlEscaped() + QStringLiteral("</H3>\n");
            out += indent() + QStringLiteral("<DL><p>\n");
            open.append(path[open.size()]);
        }
        out += indent() + QStringLiteral("<DT><A HREF=\"") + m.value(QStringLiteral("url")).toString().toHtmlEscaped() + QStringLiteral("\">")
             + m.value(QStringLiteral("title")).toString().toHtmlEscaped() + QStringLiteral("</A>\n");
    }
    while (!open.isEmpty()) {
        open.removeLast();
        out += indent() + QStringLiteral("</DL><p>\n");
    }
    return out + QStringLiteral("</DL><p>\n");
}

QVariantList fromHtml(const QString &html)
{
    static const QRegularExpression piece(
        QStringLiteral("<h3[^>]*>(.*?)</h3>|<a\\s[^>]*?href\\s*=\\s*\"([^\"]*)\"[^>]*>(.*?)</a>|(</dl>)|(<dl[^>]*>)"),
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression tag(QStringLiteral("<[^>]*>"));
    QVariantList out;
    QStringList path;        // the folders open now; an unnamed list adds an empty step
    QString named;
    for (auto it = piece.globalMatch(html); it.hasNext() && out.size() < 5000;) {
        const auto m = it.next();
        if (!m.captured(1).isNull()) {
            named = entity(m.captured(1).remove(tag)).simplified().replace(QLatin1Char('/'), QLatin1Char('-')).left(60);
        } else if (!m.captured(5).isNull()) {
            path.append(named);
            named.clear();
        } else if (!m.captured(4).isNull()) {
            if (!path.isEmpty())
                path.removeLast();
        } else {
            const QUrl url(entity(m.captured(2)).trimmed());
            if (!url.isValid() || !(url.scheme() == QLatin1String("http") || url.scheme() == QLatin1String("https") || url.scheme() == QLatin1String("file")))
                continue;
            QVariantMap item{{QStringLiteral("url"), url.toString()},
                             {QStringLiteral("title"), entity(m.captured(3).remove(tag)).simplified().left(300)}};
            QStringList folders = path;
            folders.removeAll(QString());
            if (!folders.isEmpty())
                item.insert(QStringLiteral("folder"), folders.mid(0, 6).join(QLatin1Char('/')));
            out.append(item);
        }
    }
    return out;
}

QString generatePassword(int length)
{
    // no characters that look like one another (0 O, 1 l I)
    const QString groups[] = {QStringLiteral("abcdefghijkmnopqrstuvwxyz"), QStringLiteral("ABCDEFGHJKLMNPQRSTUVWXYZ"),
                              QStringLiteral("23456789"), QStringLiteral("!#$%&*+-=?@_")};
    const QString all = groups[0] + groups[1] + groups[2] + groups[3];
    auto *random = QRandomGenerator::system();
    const int n = qBound(12, length, 64);
    QString out;
    for (const QString &g : groups)
        out += g[random->bounded(int(g.size()))];
    while (out.size() < n)
        out += all[random->bounded(int(all.size()))];
    for (int i = int(out.size()) - 1; i > 0; --i) {     // the sure four must not stay in front
        const int j = random->bounded(i + 1);
        const QChar c = out[i];
        out[i] = out[j];
        out[j] = c;
    }
    return out;
}

QList<Login> fromCsv(const QString &csv)
{
    QList<QStringList> rows;
    QStringList row;
    QString cell;
    bool quoted = false;
    for (qsizetype i = 0; i < csv.size() && rows.size() <= 5000; ++i) {
        const QChar c = csv[i];
        if (quoted) {
            if (c == QLatin1Char('"') && i + 1 < csv.size() && csv[i + 1] == QLatin1Char('"'))
                cell += csv[++i];
            else if (c == QLatin1Char('"'))
                quoted = false;
            else
                cell += c;
        } else if (c == QLatin1Char('"') && cell.isEmpty()) {
            quoted = true;
        } else if (c == QLatin1Char(',')) {
            row.append(cell);
            cell.clear();
        } else if (c == QLatin1Char('\n')) {
            row.append(cell);
            cell.clear();
            rows.append(row);
            row.clear();
        } else if (c != QLatin1Char('\r')) {
            cell += c;
        }
    }
    if (!cell.isEmpty() || !row.isEmpty()) {
        row.append(cell);
        rows.append(row);
    }
    QList<Login> out;
    if (rows.isEmpty())
        return out;
    int url = -1, user = -1, password = -1;
    for (int i = 0; i < rows.first().size(); ++i) {
        const QString name = rows.first()[i].trimmed().toLower().remove(QChar(0xFEFF));
        if (name == QLatin1String("url") || name == QLatin1String("login_uri"))
            url = i;
        else if (name == QLatin1String("username") || name == QLatin1String("login_username"))
            user = i;
        else if (name == QLatin1String("password") || name == QLatin1String("login_password"))
            password = i;
    }
    if (url < 0 || user < 0 || password < 0)
        return out;
    for (qsizetype r = 1; r < rows.size(); ++r) {
        const QStringList &line = rows[r];
        if (line.size() > qMax(url, qMax(user, password)) && !line[url].isEmpty() && !line[password].isEmpty())
            out.append({line[url], line[user], line[password]});
    }
    return out;
}

QString toCsv(const QList<Login> &logins)
{
    const auto cell = [](QString s) { return QLatin1Char('"') + s.replace(QLatin1Char('"'), QStringLiteral("\"\"")) + QLatin1Char('"'); };
    QString out = QStringLiteral("name,url,username,password\n");
    for (const Login &l : logins)
        out += cell(QUrl(l.url).host()) + QLatin1Char(',') + cell(l.url) + QLatin1Char(',') + cell(l.user) + QLatin1Char(',') + cell(l.password) + QLatin1Char('\n');
    return out;
}

QStringList hostList(const QByteArray &file)
{
    static const QRegularExpression line(QStringLiteral("^(?:127\\.0\\.0\\.1|0\\.0\\.0\\.0)\\s+([a-z0-9._-]+\\.[a-z0-9-]+)\\s*$"),
                                         QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption);
    QStringList out;
    for (auto it = line.globalMatch(QString::fromUtf8(file)); it.hasNext() && out.size() < 200000;) {
        const QString host = it.next().captured(1).toLower();
        if (host != QLatin1String("localhost.localdomain"))
            out << host;
    }
    return out;
}

QVariantMap extensionAccess(const QByteArray &manifest)
{
    const QJsonObject m = QJsonDocument::fromJson(manifest).object();
    QStringList permissions, hosts;
    const auto add = [](QStringList &to, const QJsonValue &list) {
        for (const QJsonValue &v : list.toArray())
            if (v.isString() && to.size() < 100 && !to.contains(v.toString()))
                to << v.toString().left(200);
    };
    add(permissions, m.value(QLatin1String("permissions")));
    add(hosts, m.value(QLatin1String("host_permissions")));
    for (const QJsonValue &script : m.value(QLatin1String("content_scripts")).toArray())
        add(hosts, script.toObject().value(QLatin1String("matches")));
    return {{QStringLiteral("permissions"), permissions}, {QStringLiteral("hosts"), hosts}};
}

QByteArray seal(const QByteArray &plain, const QString &password)
{
    QByteArray salt(saltSize, 0), iv(ivSize, 0), tag(tagSize, 0), out(plain.size(), 0);
    if (password.isEmpty() || RAND_bytes(bytes(salt), saltSize) != 1 || RAND_bytes(bytes(iv), ivSize) != 1)
        return {};
    const QByteArray key = keyFrom(password, salt);
    Context c(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
    int n = 0, last = 0, extra = 0;
    if (key.isEmpty() || !c || EVP_EncryptInit_ex(c.get(), EVP_aes_256_gcm(), nullptr, bytes(key), bytes(iv)) != 1
        || EVP_EncryptUpdate(c.get(), nullptr, &extra, bytes(magic), int(magic.size())) != 1
        || EVP_EncryptUpdate(c.get(), bytes(out), &n, bytes(plain), int(plain.size())) != 1
        || EVP_EncryptFinal_ex(c.get(), bytes(out) + n, &last) != 1
        || EVP_CIPHER_CTX_ctrl(c.get(), EVP_CTRL_GCM_GET_TAG, tagSize, tag.data()) != 1)
        return {};
    return magic + salt + iv + tag + out;
}

std::optional<QByteArray> unseal(const QByteArray &sealed, const QString &password)
{
    const qsizetype head = magic.size() + saltSize + ivSize + tagSize;
    if (sealed.size() < head || !sealed.startsWith(magic) || password.isEmpty())
        return std::nullopt;
    const QByteArray salt = sealed.mid(magic.size(), saltSize), iv = sealed.mid(magic.size() + saltSize, ivSize);
    QByteArray tag = sealed.mid(magic.size() + saltSize + ivSize, tagSize);
    const QByteArray data = sealed.mid(head);
    const QByteArray key = keyFrom(password, salt);
    Context c(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
    QByteArray out(data.size(), 0);
    int n = 0, last = 0, extra = 0;
    if (key.isEmpty() || !c || EVP_DecryptInit_ex(c.get(), EVP_aes_256_gcm(), nullptr, bytes(key), bytes(iv)) != 1
        || EVP_DecryptUpdate(c.get(), nullptr, &extra, bytes(magic), int(magic.size())) != 1
        || EVP_DecryptUpdate(c.get(), bytes(out), &n, bytes(data), int(data.size())) != 1
        || EVP_CIPHER_CTX_ctrl(c.get(), EVP_CTRL_GCM_SET_TAG, tagSize, tag.data()) != 1
        || EVP_DecryptFinal_ex(c.get(), bytes(out) + n, &last) != 1)
        return std::nullopt;
    return out;
}

}
