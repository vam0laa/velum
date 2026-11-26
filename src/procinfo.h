#pragma once
#include <QByteArray>
#include <QList>

// What processes use: from /proc on Linux, from the system's own calls on Windows.
// Velum only ever looks at its own.
namespace procinfo {

// Memory in kilobytes (shared pages divided fairly on Linux, private ones on Windows), or -1.
qint64 memoryKb(qint64 pid);

// Processor time used so far, in milliseconds, or -1.
qint64 cpuMs(qint64 pid);

// `root` and every process started by it.
QList<qint64> tree(qint64 root);

// Proportional memory (shared pages divided fairly) in kilobytes from smaps_rollup, or -1.
qint64 pssKb(const QByteArray &smapsRollup);

// User plus system CPU time in clock ticks from a /proc/<pid>/stat line, or -1.
qint64 cpuTicks(const QByteArray &stat);

// `root` and every process started by it, found under `proc` (normally "/proc").
QList<qint64> tree(const QString &proc, qint64 root);

}
