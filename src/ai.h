#pragma once
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QUrl>

class QNetworkReply;

// Talking to a language model that runs on this computer (an Ollama server). It only ever
// connects to this machine, and all it does with the answer is hand the words over.
class AiClient : public QObject
{
    Q_OBJECT

public:
    explicit AiClient(QObject *parent = nullptr);

    // The server's address, only if it is on this computer ("http://127.0.0.1:11434").
    static QUrl local(const QString &address);
    // What is sent: a fixed instruction, the text to work on (clearly marked as material,
    // cut to `limit` characters) and your question.
    static QByteArray request(const QString &model, const QString &question, const QString &material, bool turkish, int limit = 12000);

    void models(const QString &address);
    void ask(const QString &address, const QByteArray &body);
    void cancel();
    bool busy() const { return m_reply != nullptr; }

signals:
    void listed(const QStringList &models, bool reached);
    void piece(const QString &text);
    void finished(const QString &problem);      // empty: the whole answer came
    void busyChanged();

private:
    QNetworkReply *send(const QUrl &url, const QByteArray &body);
    void take(const QByteArray &data);
    QNetworkAccessManager m_network;
    QPointer<QNetworkReply> m_reply;
    QByteArray m_buffer;
    qint64 m_received = 0;
    bool m_done = false;
};
