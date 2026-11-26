import QtQuick
import QtWebEngine

// Site icons and the pages you visit most.
// "app" is the window these belong to.
QtObject {
    property var app

    // one page per site, the most visited first
    function refreshFrequent() {
        const seen = new Set(), out = []
        for (const p of History.frequent(60)) {
            const host = app.hostOf(p.url)
            if (host === "" || seen.has(host))
                continue
            seen.add(host)
            out.push({ url: p.url, title: p.title || host })
            if (out.length === 6)
                break
        }
        app.frequentPages = out
    }

    // Icons are kept only for sites you bookmarked, taken from pages you opened.
    function iconName(url) {
        const host = app.hostOf(url).replace(/^www\./, "")
        return /^[a-z0-9.-]+$/.test(host) && host.indexOf("..") < 0 ? host : ""
    }

    function iconFor(url) {
        const name = app.iconName(url)
        return app.iconFolder === "" || !app.iconNames.includes(name) ? "" : String(Files.toUrl(app.iconFolder + "/" + name + ".png")) + "#" + app.iconRevision
    }

    // A bookmark added by hand gets its icon at once, from the site itself.
    function fetchIcon(url) {
        const name = app.iconName(url)
        if (!app.isPrivate && app.iconFolder !== "" && name !== "" && !app.iconNames.includes(name))
            Library.fetchIcon(url, app.iconFolder + "/" + name + ".png")
    }

    function keepIcon(pageUrl, icon) {
        const name = app.iconName(pageUrl)
        if (app.iconFolder === "" || name === "" || String(icon) === "" || app.iconsSaved[name] === String(icon)
                || !app.shortcuts.some(s => app.iconName(s.url) === name))
            return
        app.iconsSaved[name] = String(icon)
        app.iconGrabber.createObject(app.iconShelf, { source: icon, name: name })
    }
}
