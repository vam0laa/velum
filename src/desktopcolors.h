#pragma once
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QObject>
#include <QtQml/qqmlregistration.h>

#include "palette.h"

// Offers the desktop colours to the interface and reloads them when the file changes,
// so Velum changes colour together with the wallpaper.
class DesktopColors : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QVariantMap colors READ colors NOTIFY changed)

public:
    explicit DesktopColors(QObject *parent = nullptr) : QObject(parent), m_file(palette::defaultFile())
    {
        connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &DesktopColors::load);
        connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &DesktopColors::load);
        load();
    }
    QVariantMap colors() const { return m_colors; }

signals:
    void changed();

private:
    void load()
    {
        // Theme tools often replace the file instead of writing into it, which ends a watch
        // on the file. The folder is watched too, and the file is added again each time.
        const QString folder = QFileInfo(m_file).path();
        if (QFileInfo::exists(folder) && !m_watcher.directories().contains(folder))
            m_watcher.addPath(folder);
        QFile file(m_file);
        if (!file.open(QIODevice::ReadOnly))
            return;
        if (!m_watcher.files().contains(m_file))
            m_watcher.addPath(m_file);
        const QVariantMap next = palette::parse(file.read(1 << 20));
        if (next.isEmpty() || next == m_colors)   // a half written file keeps the old colours
            return;
        m_colors = next;
        emit changed();
    }

    QString m_file;
    QVariantMap m_colors;
    QFileSystemWatcher m_watcher;
};
