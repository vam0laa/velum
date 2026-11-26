#pragma once
#include <QByteArray>
#include <QString>
#include <QUrl>
#include <memory>

// The C++ face of the Rust blocking engine in blocker/src/lib.rs.
class Blocker
{
public:
    struct List {
        QByteArray text;
        bool trusted = false;   // uBlock Origin's own lists may use the stronger scripts
    };

    // Builds an engine from filter lists and the injectable scripts. Slow; may run on a worker thread.
    static std::shared_ptr<Blocker> build(const QList<List> &lists, const QByteArray &resources);
    ~Blocker();

    // `kind` is the request type in the words the filter lists use: "script", "image", ...
    bool blocks(const QUrl &url, const QUrl &source, const char *kind) const;
    // JavaScript that hides ad boxes and runs the page's scriptlets; empty when there is nothing to do.
    QString pageScript(const QUrl &url) const;

private:
    explicit Blocker(void *engine) : m_engine(engine) {}
    Blocker(const Blocker &) = delete;
    void *m_engine;
};
