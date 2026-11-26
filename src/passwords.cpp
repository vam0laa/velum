// GLib's headers use names that Qt turns into keywords, so they come first.
#include <libsecret/secret.h>

#include "passwords.h"

#include <algorithm>

namespace passwords {
namespace {

const SecretSchema *schema()
{
    static const SecretSchema s = {
        "dev.vamola.velum.Password", SECRET_SCHEMA_NONE,
        {{"origin", SECRET_SCHEMA_ATTRIBUTE_STRING}, {"user", SECRET_SCHEMA_ATTRIBUTE_STRING}, {nullptr, SECRET_SCHEMA_ATTRIBUTE_STRING}},
        0, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr};
    return &s;
}

bool failed(GError *error)
{
    if (!error)
        return false;
    g_warning("velum: keyring: %s", error->message);     // never contains a secret
    g_error_free(error);
    return true;
}

}

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

std::optional<QList<Account>> accounts(const QString &origin)
{
    GHashTable *wanted = g_hash_table_new_full(g_str_hash, g_str_equal, nullptr, g_free);
    if (!origin.isEmpty())
        g_hash_table_insert(wanted, const_cast<char *>("origin"), g_strdup(origin.toUtf8().constData()));
    GError *error = nullptr;
    GList *found = secret_password_searchv_sync(schema(), wanted, SecretSearchFlags(SECRET_SEARCH_ALL | SECRET_SEARCH_UNLOCK), nullptr, &error);
    g_hash_table_unref(wanted);
    if (failed(error))
        return std::nullopt;
    QList<Account> out;
    for (GList *item = found; item; item = item->next) {
        GHashTable *attributes = secret_retrievable_get_attributes(SECRET_RETRIEVABLE(item->data));
        const char *o = static_cast<const char *>(g_hash_table_lookup(attributes, "origin"));
        const char *u = static_cast<const char *>(g_hash_table_lookup(attributes, "user"));
        if (o && u)
            out.append({QString::fromUtf8(o), QString::fromUtf8(u)});
        g_hash_table_unref(attributes);
    }
    g_list_free_full(found, g_object_unref);
    std::sort(out.begin(), out.end(), [](const Account &a, const Account &b) { return std::tie(a.origin, a.user) < std::tie(b.origin, b.user); });
    return out;
}

std::optional<QString> password(const QString &origin, const QString &user)
{
    GError *error = nullptr;
    gchar *secret = secret_password_lookup_sync(schema(), nullptr, &error,
        "origin", origin.toUtf8().constData(), "user", user.toUtf8().constData(), nullptr);
    if (failed(error) || !secret)
        return std::nullopt;
    const QString out = QString::fromUtf8(secret);
    secret_password_free(secret);
    return out;
}

bool save(const QString &origin, const QString &user, const QString &password)
{
    if (origin.isEmpty() || password.isEmpty())
        return false;
    const QString label = QStringLiteral("Velum: %1 (%2)").arg(origin, user);
    GError *error = nullptr;
    const gboolean ok = secret_password_store_sync(schema(), SECRET_COLLECTION_DEFAULT, label.toUtf8().constData(),
        password.toUtf8().constData(), nullptr, &error,
        "origin", origin.toUtf8().constData(), "user", user.toUtf8().constData(), nullptr);
    return !failed(error) && ok;
}

bool remove(const QString &origin, const QString &user)
{
    // both are always given: an empty search must never wipe more than one account
    if (origin.isEmpty())
        return false;
    GError *error = nullptr;
    const gboolean ok = secret_password_clear_sync(schema(), nullptr, &error,
        "origin", origin.toUtf8().constData(), "user", user.toUtf8().constData(), nullptr);
    return !failed(error) && ok;
}

}
