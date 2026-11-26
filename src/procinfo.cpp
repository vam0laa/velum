#include "procinfo.h"

#include <QDir>
#include <QFile>
#include <QMultiHash>

namespace procinfo {

namespace {

// the fields of a stat line after the program name, which may itself contain spaces and brackets
QList<QByteArray> afterName(const QByteArray &stat)
{
    const int close = stat.lastIndexOf(')');
    return close < 0 ? QList<QByteArray>() : stat.mid(close + 2).split(' ');
}

}

qint64 pssKb(const QByteArray &smapsRollup)
{
    for (const QByteArray &line : smapsRollup.split('\n')) {
        if (line.startsWith("Pss:"))
            return line.mid(4).trimmed().split(' ').constFirst().toLongLong();
    }
    return -1;
}

qint64 cpuTicks(const QByteArray &stat)
{
    const QList<QByteArray> f = afterName(stat);
    // counted from the state field: utime is the 12th, stime the 13th
    return f.size() > 12 ? f[11].toLongLong() + f[12].toLongLong() : -1;
}

QList<qint64> tree(const QString &proc, qint64 root)
{
    QMultiHash<qint64, qint64> children;
    const QDir dir(proc);
    for (const QString &name : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        bool number = false;
        const qint64 pid = name.toLongLong(&number);
        if (!number)
            continue;
        QFile stat(dir.filePath(name) + QStringLiteral("/stat"));
        if (!stat.open(QIODevice::ReadOnly))
            continue;
        const QList<QByteArray> f = afterName(stat.readAll());
        if (f.size() > 1)
            children.insert(f[1].toLongLong(), pid);
    }
    QList<qint64> out{root};
    for (qsizetype i = 0; i < out.size(); ++i)
        out.append(children.values(out[i]));
    return out;
}

}
