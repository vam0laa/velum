#pragma once
#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>

#include "graphics.h"

// The graphics acceleration setting ("Gpu"). It is read before the engine starts, so a
// change applies from the next start.
class Gpu : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changedMode)   // "auto", "boost", "off"
    Q_PROPERTY(bool changed READ changed NOTIFY changedMode)              // differs from this run's
    Q_PROPERTY(bool fellBack READ fellBack CONSTANT)                      // "boost" was given up at start

public:
    explicit Gpu(QObject *parent = nullptr) : QObject(parent)
    {
        m_started = m_mode = graphics::cleanMode(QSettings().value(QStringLiteral("graphics/mode")).toString());
        m_fellBack = QSettings().value(QStringLiteral("graphics/fellBack")).toBool();
    }
    QString mode() const { return m_mode; }
    bool changed() const { return m_mode != m_started; }
    bool fellBack() const { return m_fellBack; }
    void setMode(const QString &mode)
    {
        const QString clean = graphics::cleanMode(mode);
        if (clean == m_mode)
            return;
        m_mode = clean;
        QSettings settings;
        settings.setValue(QStringLiteral("graphics/mode"), clean);
        settings.setValue(QStringLiteral("graphics/fellBack"), false);
        emit changedMode();
    }

signals:
    void changedMode();

private:
    QString m_mode;
    QString m_started;
    bool m_fellBack = false;
};
