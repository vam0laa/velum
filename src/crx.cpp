#include "crx.h"

#include <QCryptographicHash>
#include <QList>
#include <QRegularExpression>
#include <QUrl>
#include <QtEndian>

#include <openssl/evp.h>
#include <openssl/x509.h>

#include <memory>

namespace crx {
namespace {

// One length-delimited field of a protocol buffer message.
struct Field {
    quint64 number;
    QByteArray value;
};

bool varint(const QByteArray &data, qsizetype &at, quint64 &out)
{
    out = 0;
    for (int shift = 0; shift < 64 && at < data.size(); shift += 7) {
        const quint8 byte = quint8(data[at++]);
        out |= quint64(byte & 0x7f) << shift;
        if (!(byte & 0x80))
            return true;
    }
    return false;
}

// A CRX header holds nothing but length-delimited fields; anything else is refused.
bool parse(const QByteArray &data, QList<Field> &out)
{
    qsizetype at = 0;
    while (at < data.size()) {
        quint64 key = 0, length = 0;
        if (!varint(data, at, key) || (key & 7) != 2 || !varint(data, at, length) || length > quint64(data.size() - at))
            return false;
        out.append({key >> 3, data.mid(at, qsizetype(length))});
        at += qsizetype(length);
    }
    return true;
}

QByteArray first(const QList<Field> &fields, quint64 number)
{
    for (const Field &f : fields)
        if (f.number == number)
            return f.value;
    return {};
}

// ids spell the first 16 bytes of the key's SHA-256 with the letters a to p
QString spell(const QByteArray &sixteen)
{
    QString out;
    for (const char c : sixteen) {
        out += QLatin1Char(char('a' + (quint8(c) >> 4)));
        out += QLatin1Char(char('a' + (quint8(c) & 15)));
    }
    return out;
}

bool signatureHolds(const QByteArray &publicKey, const QByteArray &signature, const QByteArray &message)
{
    const auto *der = reinterpret_cast<const unsigned char *>(publicKey.constData());
    std::unique_ptr<EVP_PKEY, decltype(&EVP_PKEY_free)> key(d2i_PUBKEY(nullptr, &der, publicKey.size()), EVP_PKEY_free);
    std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)> context(EVP_MD_CTX_new(), EVP_MD_CTX_free);
    return key && context && EVP_PKEY_base_id(key.get()) == EVP_PKEY_RSA
        && EVP_DigestVerifyInit(context.get(), nullptr, EVP_sha256(), nullptr, key.get()) == 1
        && EVP_DigestVerify(context.get(), reinterpret_cast<const unsigned char *>(signature.constData()), size_t(signature.size()),
                            reinterpret_cast<const unsigned char *>(message.constData()), size_t(message.size())) == 1;
}

}

QString idFrom(const QString &typed)
{
    const QString text = typed.trimmed();
    static const QRegularExpression bare(QStringLiteral("^[a-p]{32}$"));
    if (bare.match(text).hasMatch())
        return text;
    const QUrl url(text);
    const bool store = url.scheme() == QLatin1String("https")
        && (url.host() == QLatin1String("chromewebstore.google.com")
            || (url.host() == QLatin1String("chrome.google.com") && url.path().startsWith(QLatin1String("/webstore/"))));
    if (!store)
        return {};
    static const QRegularExpression inPath(QStringLiteral("/detail/(?:[^/]+/)?([a-p]{32})(?:/|$)"));
    return inPath.match(url.path()).captured(1);
}

QString downloadAddress(const QString &id)
{
    return QStringLiteral("https://clients2.google.com/service/update2/crx?response=redirect&prodversion=140.0.0.0"
                          "&acceptformat=crx3&x=id%3D%1%26uc").arg(id);
}

QByteArray verifiedZip(const QByteArray &package, const QString &id)
{
    if (package.size() < 12 || !package.startsWith("Cr24") || qFromLittleEndian<quint32>(package.constData() + 4) != 3)
        return {};
    const quint32 length = qFromLittleEndian<quint32>(package.constData() + 8);
    if (length > quint32(package.size() - 12) || length > (1u << 20))
        return {};
    QList<Field> header, signedData;
    if (!parse(package.mid(12, length), header))
        return {};
    const QByteArray stated = first(header, 10000);      // signed_header_data
    if (!parse(stated, signedData))
        return {};
    const QByteArray crxId = first(signedData, 1);
    if (crxId.size() != 16 || spell(crxId) != id)
        return {};

    const QByteArray zip = package.mid(12 + length);
    QByteArray message("CRX3 SignedData\0", 16);
    char size[4];
    qToLittleEndian<quint32>(quint32(stated.size()), size);
    message.append(size, 4).append(stated).append(zip);

    for (const Field &proof : header) {
        QList<Field> parts;
        if (proof.number != 2 || !parse(proof.value, parts))      // sha256_with_rsa
            continue;
        const QByteArray key = first(parts, 1);
        // the key the id is made from must be the one that signed
        if (QCryptographicHash::hash(key, QCryptographicHash::Sha256).left(16) == crxId && signatureHolds(key, first(parts, 2), message))
            return zip;
    }
    return {};
}

}
