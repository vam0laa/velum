#pragma once
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

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
        QHash<qint64, qint64> now;
        double allMb = 0, allCpu = 0;
        QHash<qint64, QPair<double, double>> measured;
        for (qint64 pid : procinfo::tree(QCoreApplication::applicationPid())) {
            const qint64 kb = procinfo::memoryKb(pid);
            const qint64 used = procinfo::cpuMs(pid);
            const double mb = kb > 0 ? kb / 1024.0 : 0;
            double cpu = 0;
            if (used >= 0) {
                now.insert(pid, used);
                if (seconds > 0.2 && m_ticks.contains(pid))
                    cpu = (used - m_ticks.value(pid)) / 10.0 / seconds;     // percent of one core
            }
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
    QElapsedTimer m_clock;
    QHash<qint64, qint64> m_ticks;
};
