#pragma once
#include <QString>

// A download you have not agreed to yet is written under a name that ends in ".velum-hold",
// so nothing can run or open it by mistake: a small file may arrive whole before it can be
// paused. Only such files are touched here.
namespace held {

inline const QString ending = QStringLiteral(".velum-hold");

// You agreed: gives `file` in `folder` its real name, without ever replacing another file.
// Returns that name, or nothing.
QString release(const QString &folder, const QString &file);

// A path in `folder` for a new file named after `title` (which a page chose): characters
// that mean something to a file system are replaced, and an existing file is never named.
QString freePath(const QString &folder, const QString &title, const QString &suffix);

// You refused: removes the file and what the engine had started of it.
bool discard(const QString &folder, const QString &file);

}
