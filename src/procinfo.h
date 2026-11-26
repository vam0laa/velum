#pragma once
#include <QByteArray>
#include <QList>

// Reads what processes use from /proc. Velum only ever looks at its own.
namespace procinfo {

// Proportional memory (shared pages divided fairly) in kilobytes from smaps_rollup, or -1.
qint64 pssKb(const QByteArray &smapsRollup);

// User plus system CPU time in clock ticks from a /proc/<pid>/stat line, or -1.
qint64 cpuTicks(const QByteArray &stat);

// `root` and every process started by it, found under `proc` (normally "/proc").
QList<qint64> tree(const QString &proc, qint64 root);

}
