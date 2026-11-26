import QtQuick

// Backups and synchronisation: what goes into the locked file, and how two copies are
// put together without losing or reviving anything.
// "app" is the window these belong to.
QtObject {
    property var app

    // everything worth keeping; never passwords, cookies or history
    function collect() {
        return { velumBackup: 1, made: Date.now(), bookmarks: app.shortcuts, removed: app.removedBookmarks,
                 look: JSON.parse(app.themeText()) }
    }

    // Bookmarks of both, by address and folder. One removed after it was added stays removed.
    function mergeBookmarks(mine, theirs, removed) {
        const gone = {}
        for (const r of removed)
            gone[r.url] = Math.max(gone[r.url] ?? 0, r.when)
        const out = [], seen = new Set()
        for (const b of mine.concat(theirs)) {
            if (!b || typeof b.url !== "string" || b.url === "" || seen.has(b.url))
                continue
            if (gone[b.url] !== undefined && gone[b.url] >= (b.added ?? 0))
                continue
            seen.add(b.url)
            const item = { title: String(b.title ?? ""), url: b.url }
            if (b.folder)
                item.folder = String(b.folder)
            if (b.added)
                item.added = b.added
            out.push(item)
        }
        return out.slice(0, app.maxBookmarks)
    }
    function mergeRemoved(mine, theirs) {
        const latest = {}
        for (const r of mine.concat(theirs))
            if (r && typeof r.url === "string" && typeof r.when === "number")
                latest[r.url] = Math.max(latest[r.url] ?? 0, r.when)
        return Object.keys(latest).map(url => ({ url: url, when: latest[url] })).sort((a, b) => b.when - a.when).slice(0, 2000)
    }

    // Takes a backup's text. `look`: also its theme and home page. False when it is not one.
    function apply(text, look) {
        let d = null
        try {
            d = JSON.parse(text)
        } catch (e) {
        }
        if (!d || d.velumBackup !== 1 || !Array.isArray(d.bookmarks))
            return false
        app.keepRemoved(mergeRemoved(app.removedBookmarks, Array.isArray(d.removed) ? d.removed : []))
        app.keepBookmarks(mergeBookmarks(app.shortcuts, d.bookmarks, app.removedBookmarks))
        if (look && d.look)
            app.applyThemeText(JSON.stringify(d.look))
        return true
    }

    function save(file, password) {
        if (password.length < 8)
            return Lang.t("Parola en az 8 karakter olsun.", "Use a password of at least 8 characters.")
        return Library.writeLocked(file, JSON.stringify(collect()), password) ? Lang.t("Yedek kaydedildi. Parolayı unutma: onsuz açılamaz.", "The backup was saved. Keep the password: nothing opens it otherwise.")
                                                                           : Lang.t("Yedek kaydedilemedi.", "The backup could not be saved.")
    }
    function restore(file, password) {
        const read = Library.readLocked(file, password)
        if (!read.opened)
            return read.found ? Lang.t("Parola yanlış ya da dosya bozuk.", "Wrong password, or a damaged file.") : Lang.t("Dosya okunamadı.", "The file could not be read.")
        return apply(read.text, true) ? Lang.t("Yedek geri yüklendi.", "The backup was restored.") : Lang.t("Bu dosya bir Velum yedeği değil.", "This is not a Velum backup.")
    }
}
