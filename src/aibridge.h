#pragma once
#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>

#include "ai.h"

// The assistant, as the interface sees it ("Assistant"). Off until you switch it on.
class Assistant : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY changed)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY changed)
    Q_PROPERTY(QStringList models READ models NOTIFY changed)
    // "unknown", "ok" or "unreachable"
    Q_PROPERTY(QString server READ server NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString answer READ answer NOTIFY answerChanged)
    // "", "address", "server", "model" or "broken"
    Q_PROPERTY(QString problem READ problem NOTIFY answerChanged)

public:
    explicit Assistant(QObject *parent = nullptr) : QObject(parent)
    {
        const QSettings s;
        m_enabled = s.value(QStringLiteral("assistant/enabled"), false).toBool();
        m_address = s.value(QStringLiteral("assistant/address"), QStringLiteral("http://127.0.0.1:11434")).toString();
        m_model = s.value(QStringLiteral("assistant/model")).toString();
        connect(&m_client, &AiClient::busyChanged, this, &Assistant::busyChanged);
        connect(&m_client, &AiClient::piece, this, [this](const QString &text) { m_answer += text; emit answerChanged(); });
        connect(&m_client, &AiClient::finished, this, [this](const QString &problem) { m_problem = problem; emit answerChanged(); });
        connect(&m_client, &AiClient::listed, this, [this](const QStringList &models, bool reached) {
            m_models = models;
            m_server = reached ? QStringLiteral("ok") : QStringLiteral("unreachable");
            if (reached && !models.isEmpty() && !models.contains(m_model))
                setModel(models.first());
            emit changed();
        });
    }
    bool enabled() const { return m_enabled; }
    void setEnabled(bool on)
    {
        if (m_enabled == on)
            return;
        m_enabled = on;
        QSettings().setValue(QStringLiteral("assistant/enabled"), on);
        if (!on)
            m_client.cancel();
        emit changed();
    }
    QString address() const { return m_address; }
    void setAddress(const QString &address)
    {
        // only an address on this computer is ever kept
        if (AiClient::local(address).isEmpty() || address == m_address)
            return;
        m_address = address;
        QSettings().setValue(QStringLiteral("assistant/address"), address);
        m_server = QStringLiteral("unknown");
        emit changed();
    }
    QString model() const { return m_model; }
    void setModel(const QString &model)
    {
        if (model == m_model)
            return;
        m_model = model;
        QSettings().setValue(QStringLiteral("assistant/model"), model);
        emit changed();
    }
    QStringList models() const { return m_models; }
    QString server() const { return m_server; }
    bool busy() const { return m_client.busy(); }
    QString answer() const { return m_answer; }
    QString problem() const { return m_problem; }

    Q_INVOKABLE void look() { if (m_enabled) m_client.models(m_address); }
    Q_INVOKABLE void ask(const QString &question, const QString &material, bool turkish)
    {
        if (!m_enabled || question.trimmed().isEmpty())
            return;
        m_answer.clear();
        m_problem.clear();
        emit answerChanged();
        if (m_model.isEmpty()) {
            m_problem = QStringLiteral("model");
            emit answerChanged();
            return;
        }
        m_client.ask(m_address, AiClient::request(m_model, question.left(2000), material, turkish));
    }
    Q_INVOKABLE void cancel() { m_client.cancel(); }
    Q_INVOKABLE void forget() { m_client.cancel(); m_answer.clear(); m_problem.clear(); emit answerChanged(); }

signals:
    void changed();
    void busyChanged();
    void answerChanged();

private:
    AiClient m_client;
    QStringList m_models;
    QString m_address, m_model, m_answer, m_problem;
    QString m_server = QStringLiteral("unknown");
    bool m_enabled = false;
};
