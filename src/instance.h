#pragma once
#include <QLocalServer>
#include <QObject>
#include <QStringList>
#include <QUrl>

// One Velum at a time: a second start hands its addresses to the window that is already open.
class Instance : public QObject
{
    Q_OBJECT

public:
    // A name that differs between users and between data folders.
    static QString socketName(const QString &dataFolder);

    // True when a running Velum took the addresses; this process can then leave.
    static bool handOver(const QString &socket, const QStringList &urls);

    // Starts listening for later starts. False when that is not possible.
    bool listen(const QString &socket);

    // Keeps only addresses another program may ask us to open: web pages and local files.
    static QStringList accepted(const QByteArray &message);

signals:
    void received(const QStringList &urls);

private:
    QLocalServer m_server;
};
