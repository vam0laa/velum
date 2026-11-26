// Process figures on Windows.
#include <windows.h>
#include <psapi.h>
#include <tlhelp32.h>

#include "procinfo.h"

#include <QMultiHash>

namespace procinfo {
namespace {

struct Handle {
    HANDLE value;
    explicit Handle(qint64 pid) : value(OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, DWORD(pid))) {}
    ~Handle() { if (value) CloseHandle(value); }
};

qint64 milliseconds(const FILETIME &t)
{
    return qint64((quint64(t.dwHighDateTime) << 32 | t.dwLowDateTime) / 10000);
}

}

qint64 memoryKb(qint64 pid)
{
    const Handle process(pid);
    PROCESS_MEMORY_COUNTERS_EX counters{};
    if (!process.value || !GetProcessMemoryInfo(process.value, reinterpret_cast<PROCESS_MEMORY_COUNTERS *>(&counters), sizeof counters))
        return -1;
    return qint64(counters.PrivateUsage / 1024);
}

qint64 cpuMs(qint64 pid)
{
    const Handle process(pid);
    FILETIME created, ended, kernel, user;
    if (!process.value || !GetProcessTimes(process.value, &created, &ended, &kernel, &user))
        return -1;
    return milliseconds(kernel) + milliseconds(user);
}

QList<qint64> tree(qint64 root)
{
    QMultiHash<qint64, qint64> children;
    const HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot != INVALID_HANDLE_VALUE) {
        PROCESSENTRY32W entry{};
        entry.dwSize = sizeof entry;
        for (BOOL more = Process32FirstW(snapshot, &entry); more; more = Process32NextW(snapshot, &entry))
            if (entry.th32ProcessID != entry.th32ParentProcessID)
                children.insert(entry.th32ParentProcessID, entry.th32ProcessID);
        CloseHandle(snapshot);
    }
    QList<qint64> out{root};
    for (qsizetype i = 0; i < out.size() && out.size() < 4096; ++i)
        for (qint64 child : children.values(out[i]))
            if (!out.contains(child))      // numbers are reused on Windows: never loop
                out.append(child);
    return out;
}

}
