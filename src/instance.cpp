#include "instance.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QElapsedTimer>
#include <QLocalSocket>
#include <QStandardPaths>
#include <QTimer>
#include <QVariant>

namespace {

constexpr int limit = 64 * 1024;    // a message is a few addresses, never more

}

QString Instance::socketName(const QString &dataFolder)
{
#ifdef Q_OS_WIN
    // a named pipe: a plain name, tied to this user's data folder
    return QStringLiteral("velum-") + QString::fromLatin1(QCryptographicHash::hash(dataFolder.toUtf8(), QCryptographicHash::Sha256).toHex().left(12));
#endif
    QString runtime = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    const QByteArray id = QCryptographicHash::hash(dataFolder.toUtf8(), QCryptographicHash::Sha256).toHex().left(12);
    return runtime + QStringLiteral("/velum-") + QString::fromLatin1(id);
}

QStringList Instance::accepted(const QByteArray &message)
{
    QStringList out;
    if (message.size() > limit)
        return out;
    for (const QByteArray &line : message.split('\n')) {
        const QUrl url(QString::fromUtf8(line).trimmed(), QUrl::StrictMode);
        const QString scheme = url.scheme();
        if (url.isValid() && (scheme == QLatin1String("https") || scheme == QLatin1String("http") || scheme == QLatin1String("file")))
            out << url.toString(QUrl::FullyEncoded);
    }
    return out.mid(0, 32);
}

bool Instance::handOver(const QString &socket, const QStringList &urls)
{
    QLocalSocket link;
    link.connectToServer(socket);
    if (!link.waitForConnected(500))
        return false;
    // an empty message still means "show your window"
    link.write(urls.join(QLatin1Char('\n')).toUtf8() + '\n');
    link.flush();
    // A Windows pipe has sent nothing until the other side has read it, and a short message
    // may also be gone already. So: wait until nothing is left, letting events through.
    QElapsedTimer waiting;
    waiting.start();
    while (link.bytesToWrite() > 0 && waiting.elapsed() < 2000) {
        link.waitForBytesWritten(20);
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
    }
    return link.bytesToWrite() == 0;
}

bool Instance::listen(const QString &socket)
{
    m_server.setSocketOptions(QLocalServer::UserAccessOption);   // only you may talk to it
    if (!m_server.listen(socket)) {
        // left behind by a Velum that ended badly; nobody answered on it just now
        QLocalServer::removeServer(socket);
        if (!m_server.listen(socket))
            return false;
    }
    connect(&m_server, &QLocalServer::newConnection, this, [this] {
        while (QLocalSocket *link = m_server.nextPendingConnection()) {
            auto finish = [this, link] {
                if (link->property("done").toBool())
                    return;
                link->setProperty("done", true);
                emit received(accepted(link->readAll()));
                link->deleteLater();
            };
            connect(link, &QLocalSocket::disconnected, this, finish);
            QTimer::singleShot(1500, link, [link] { link->disconnectFromServer(); });
        }
    });
    return true;
}
