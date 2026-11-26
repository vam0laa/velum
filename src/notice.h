#pragma once
#include <QString>

// Prepares what a web page wrote for the desktop's notification service.
namespace notice {

// Notification servers may read simple markup, so a page's text is made plain and kept short.
QString plain(const QString &text, int limit);

// "Title" and the site it really comes from, which the page cannot choose.
QString body(const QString &message, const QString &site);

}
