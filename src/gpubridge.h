#pragma once
#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>

// The "use the graphics card" switch ("Gpu"). It is read before the engine starts, so a
// change applies from the next start.
class Gpu : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool on READ on WRITE setOn NOTIFY changedOn)
    Q_PROPERTY(bool changed READ changed NOTIFY changedOn)      // differs from this run's
    Q_PROPERTY(bool careful READ careful NOTIFY changedOn)      // extras left out after a failed start

public:
    explicit Gpu(QObject *parent = nullptr) : QObject(parent)
    {
        m_started = m_on = QSettings().value(QStringLiteral("graphics/accelerate"), true).toBool();
        m_careful = QSettings().value(QStringLiteral("graphics/careful")).toBool();
    }
    bool on() const { return m_on; }
    bool changed() const { return m_on != m_started; }
    bool careful() const { return m_on && m_careful; }
    void setOn(bool on)
    {
        if (on == m_on)
            return;
        m_on = on;
        m_careful = false;      // switching it yourself gives it a fresh try
        QSettings settings;
        settings.setValue(QStringLiteral("graphics/accelerate"), on);
        settings.setValue(QStringLiteral("graphics/careful"), false);
        emit changedOn();
    }

signals:
    void changedOn();

private:
    bool m_on = true;
    bool m_started = true;
    bool m_careful = false;
};
