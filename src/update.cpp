#include "update.h"

#include <QCryptographicHash>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>

#include <openssl/evp.h>

#include <memory>

namespace update {
namespace {

// major, minor, patch, then the beta number; a final release counts after every beta
std::optional<std::array<int, 4>> parts(const QString &version)
{
    static const QRegularExpression pattern(QStringLiteral("^(\\d{1,4})\\.(\\d{1,4})\\.(\\d{1,4})(?:-beta\\.(\\d{1,4}))?$"));
    const auto m = pattern.match(version);
    if (!m.hasMatch())
        return std::nullopt;
    return std::array<int, 4>{m.captured(1).toInt(), m.captured(2).toInt(), m.captured(3).toInt(),
                              m.captured(4).isNull() ? 1000000 : m.captured(4).toInt()};
}

}

int compare(const QString &a, const QString &b)
{
    const auto x = parts(a), y = parts(b);
    if (!x || !y)
        return !x && !y ? 0 : x ? 1 : -1;
    return *x < *y ? -1 : *y < *x ? 1 : 0;
}

std::optional<Release> verify(const QByteArray &manifest, const QByteArray &signature, const QByteArray &publicKey, const QString &from)
{
    const QByteArray key = QByteArray::fromHex(publicKey);
    const QByteArray sig = QByteArray::fromBase64(signature.trimmed());
    if (key.size() != 32 || sig.size() != 64 || manifest.size() > 64 * 1024)
        return std::nullopt;
    std::unique_ptr<EVP_PKEY, decltype(&EVP_PKEY_free)> pkey(
        EVP_PKEY_new_raw_public_key(EVP_PKEY_ED25519, nullptr, reinterpret_cast<const unsigned char *>(key.constData()), size_t(key.size())), EVP_PKEY_free);
    std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)> context(EVP_MD_CTX_new(), EVP_MD_CTX_free);
    if (!pkey || !context || EVP_DigestVerifyInit(context.get(), nullptr, nullptr, nullptr, pkey.get()) != 1
        || EVP_DigestVerify(context.get(), reinterpret_cast<const unsigned char *>(sig.constData()), size_t(sig.size()),
                            reinterpret_cast<const unsigned char *>(manifest.constData()), size_t(manifest.size())) != 1)
        return std::nullopt;

    const QJsonObject o = QJsonDocument::fromJson(manifest).object();
    Release r;
    r.version = o.value(QLatin1String("version")).toString();
    const QString address = o.value(QLatin1String("url")).toString();
    r.url = QUrl(address, QUrl::StrictMode);
    r.sha256 = o.value(QLatin1String("sha256")).toString().toLatin1().toLower();
    r.size = qint64(o.value(QLatin1String("size")).toDouble());
    r.notes = o.value(QLatin1String("notes")).toString().left(2000);
    static const QRegularExpression digest(QStringLiteral("^[0-9a-f]{64}$"));
    if (!parts(r.version) || !r.url.isValid() || !address.startsWith(from) || address.contains(QLatin1String(".."))
        || !digest.match(QString::fromLatin1(r.sha256)).hasMatch() || r.size <= 0 || r.size > qint64(700) * 1024 * 1024)
        return std::nullopt;
    return r;
}

bool matches(const QString &file, const Release &release)
{
    QFile f(file);
    if (!f.open(QIODevice::ReadOnly) || f.size() != release.size)
        return false;
    QCryptographicHash hash(QCryptographicHash::Sha256);
    return hash.addData(&f) && hash.result().toHex() == release.sha256;
}

}
