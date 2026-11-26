#pragma once
#include <QDesktopServices>
#include <QObject>
#include <QSettings>
#include <QUrl>
#include <QProcess>
#include <QStandardPaths>
#include <QtQml/qqmlregistration.h>

// Is Velum the default browser, and make it so ("DefaultBrowser"). Uses xdg-settings.
class DefaultBrowser : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool current READ current NOTIFY changed)

public:
    explicit DefaultBrowser(QObject *parent = nullptr) : QObject(parent) { refresh(); }
    bool current() const { return m_current; }

    Q_INVOKABLE void refresh()
    {
#ifdef Q_OS_WIN
        const QSettings choice(QStringLiteral("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\https\\UserChoice"), QSettings::NativeFormat);
        const bool now = choice.value(QStringLiteral("ProgId")).toString() == QLatin1String("VelumHTML");
        if (now != m_current) {
            m_current = now;
            emit changed();
        }
        return;
#endif
        run({QStringLiteral("get"), QStringLiteral("default-web-browser")}, [this](const QByteArray &out, bool ok) {
            const bool now = ok && out.trimmed() == "velum.desktop";
            if (now != m_current) {
                m_current = now;
                emit changed();
            }
        });
    }
    // only ever called by the button that says so
    Q_INVOKABLE void make()
    {
#ifdef Q_OS_WIN
        // Windows lets only you choose; this opens the right page of its settings
        QDesktopServices::openUrl(QUrl(QStringLiteral("ms-settings:defaultapps?registeredAppUser=Velum")));
        return;
#endif
        run({QStringLiteral("set"), QStringLiteral("default-web-browser"), QStringLiteral("velum.desktop")},
            [this](const QByteArray &, bool) { refresh(); });
    }

signals:
    void changed();

private:
    template<typename Done>
    void run(const QStringList &arguments, Done done)
    {
        const QString tool = QStandardPaths::findExecutable(QStringLiteral("xdg-settings"));
        if (tool.isEmpty())
            return;
        auto *process = new QProcess(this);
        connect(process, &QProcess::finished, this, [process, done](int code) {
            done(process->readAllStandardOutput(), code == 0);
            process->deleteLater();
        });
        process->start(tool, arguments);
    }
    bool m_current = false;
};
