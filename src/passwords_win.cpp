// Passwords on Windows: the Credential Manager, which encrypts them for your account.
// Velum itself writes none of them to disk.
#include <windows.h>
#include <wincred.h>

#include "passwords.h"

#include <algorithm>
#include <string>

namespace passwords {
namespace {

// "Velum:<origin>|<user>"; an origin never holds "|", so the first one separates them
const QString prefix = QStringLiteral("Velum:");

std::wstring target(const QString &origin, const QString &user)
{
    return (prefix + origin + QLatin1Char('|') + user).toStdWString();
}

}

std::optional<QList<Account>> accounts(const QString &origin)
{
    DWORD count = 0;
    PCREDENTIALW *found = nullptr;
    if (!CredEnumerateW(L"Velum:*", 0, &count, &found))
        return GetLastError() == ERROR_NOT_FOUND ? std::optional<QList<Account>>(QList<Account>()) : std::nullopt;
    QList<Account> out;
    for (DWORD i = 0; i < count; ++i) {
        const QString name = QString::fromWCharArray(found[i]->TargetName);
        const qsizetype bar = name.indexOf(QLatin1Char('|'));
        if (found[i]->Type != CRED_TYPE_GENERIC || !name.startsWith(prefix) || bar < 0)
            continue;
        const QString o = name.mid(prefix.size(), bar - prefix.size());
        if (origin.isEmpty() || o == origin)
            out.append({o, name.mid(bar + 1)});
    }
    CredFree(found);
    std::sort(out.begin(), out.end(), [](const Account &a, const Account &b) { return std::tie(a.origin, a.user) < std::tie(b.origin, b.user); });
    return out;
}

std::optional<QString> password(const QString &origin, const QString &user)
{
    PCREDENTIALW found = nullptr;
    if (!CredReadW(target(origin, user).c_str(), CRED_TYPE_GENERIC, 0, &found))
        return std::nullopt;
    // target names ignore capitals on Windows; the user name must match exactly
    std::optional<QString> out;
    if (QString::fromWCharArray(found->TargetName) == prefix + origin + QLatin1Char('|') + user)
        out = QString::fromUtf8(reinterpret_cast<const char *>(found->CredentialBlob), int(found->CredentialBlobSize));
    CredFree(found);
    return out;
}

bool save(const QString &origin, const QString &user, const QString &password)
{
    const QByteArray secret = password.toUtf8();
    if (origin.isEmpty() || secret.isEmpty() || secret.size() > CRED_MAX_CREDENTIAL_BLOB_SIZE)
        return false;
    std::wstring name = target(origin, user);
    std::wstring who = user.toStdWString();
    CREDENTIALW credential{};
    credential.Type = CRED_TYPE_GENERIC;
    credential.TargetName = name.data();
    credential.UserName = who.data();
    credential.CredentialBlobSize = DWORD(secret.size());
    credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<char *>(secret.constData()));
    credential.Persist = CRED_PERSIST_LOCAL_MACHINE;     // stays on this computer
    return CredWriteW(&credential, 0);
}

bool remove(const QString &origin, const QString &user)
{
    return !origin.isEmpty() && CredDeleteW(target(origin, user).c_str(), CRED_TYPE_GENERIC, 0);
}

}
