#pragma once
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QFile>
#include <QHash>
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include <unistd.h>

#include "procinfo.h"

// Memory and processor use of Velum's processes, for the resource panel ("Resources").
class Resources : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    // For each process id: { memory: MB, cpu: percent of one core since the last call }.
    // "total" holds the same for all of Velum together.
    Q_INVOKABLE QVariantMap sample(const QVariantList &pids)
    {
        const double seconds = m_clock.isValid() ? m_clock.restart() / 1000.0 : (m_clock.start(), 0.0);
        const double ticksPerSecond = sysconf(_SC_CLK_TCK);
        QHash<qint64, qint64> now;
        const auto measure = [&](qint64 pid, double &mb, double &cpu) {
            const QString dir = QStringLiteral("/proc/%1/").arg(pid);
            const qint64 kb = procinfo::pssKb(read(dir + QStringLiteral("smaps_rollup")));
            const qint64 ticks = procinfo::cpuTicks(read(dir + QStringLiteral("stat")));
            mb = kb > 0 ? kb / 1024.0 : 0;
            cpu = 0;
            if (ticks >= 0) {
                now.insert(pid, ticks);
                if (seconds > 0.2 && m_ticks.contains(pid))
                    cpu = (ticks - m_ticks.value(pid)) / ticksPerSecond / seconds * 100;
            }
        };
        double allMb = 0, allCpu = 0;
        QHash<qint64, QPair<double, double>> measured;
        for (qint64 pid : procinfo::tree(QStringLiteral("/proc"), QCoreApplication::applicationPid())) {
            double mb, cpu;
            measure(pid, mb, cpu);
            measured.insert(pid, {mb, cpu});
            allMb += mb;
            allCpu += cpu;
        }
        QVariantMap out;
        for (const QVariant &v : pids) {
            const qint64 pid = v.toLongLong();
            // only processes that belong to Velum are reported
            if (measured.contains(pid))
                out.insert(QString::number(pid), QVariantMap{{QStringLiteral("memory"), measured[pid].first}, {QStringLiteral("cpu"), measured[pid].second}});
        }
        out.insert(QStringLiteral("total"), QVariantMap{{QStringLiteral("memory"), allMb}, {QStringLiteral("cpu"), allCpu}});
        m_ticks = now;
        return out;
    }

private:
    static QByteArray read(const QString &path)
    {
        QFile f(path);
        return f.open(QIODevice::ReadOnly) ? f.readAll() : QByteArray();
    }
    QElapsedTimer m_clock;
    QHash<qint64, qint64> m_ticks;
};
