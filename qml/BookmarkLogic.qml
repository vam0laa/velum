import QtQuick
import QtWebEngine

// Bookmarks: adding, editing, sorting and importing them.
// "app" is the window these belong to.
QtObject {
    property var app

    function addShortcut(typed, title) {
        const url = String(Address.resolve(typed))
        if (url === "" || url === "about:blank" || Address.isSearch(typed) || app.shortcuts.some(s => s.url === url) || app.shortcuts.length >= app.maxBookmarks)
            return false
        const name = title || Address.display(url).replace(/^(https?:\/\/)?(www\.)?/, "").split("/")[0]
        app.keepBookmarks(app.shortcuts.concat([{ title: name, url: url }]))
        return true
    }

    function keepBookmarks(list) {
        app.shortcuts = list
        app.saved.shortcuts = JSON.stringify(list)
    }

    // From the manager: index -1 adds. False when the address cannot be used.
    function saveBookmark(index, title, address, folder) {
        const url = String(Address.resolve(address))
        if (url === "" || url === "about:blank" || Address.isSearch(address) || app.shortcuts.some((s, i) => s.url === url && i !== index))
            return false
        if (index < 0 ? app.shortcuts.length >= app.maxBookmarks : index >= app.shortcuts.length)
            return false
        const item = { title: String(title).trim() || Address.display(url).replace(/^(https?:\/\/)?(www\.)?/, "").split("/")[0], url: url }
        if (String(folder).trim() !== "")
            item.folder = String(folder).trim()
        const list = app.shortcuts.slice()
        if (index < 0)
            list.push(item)
        else
            list[index] = item
        app.keepBookmarks(list)
        return true
    }

    function restoreBookmark(item, index) {
        if (app.shortcuts.some(s => s.url === item.url))
            return
        const list = app.shortcuts.slice()
        list.splice(Math.max(0, Math.min(index, list.length)), 0, item)
        app.keepBookmarks(list)
    }

    // the two change places
    function moveBookmark(from, to) {
        if (from === to || !app.shortcuts[from] || !app.shortcuts[to])
            return
        const list = app.shortcuts.slice()
        list[from] = app.shortcuts[to]
        list[to] = app.shortcuts[from]
        app.keepBookmarks(list)
    }

    // an empty new name puts the bookmarks outside any folder
    function renameFolder(from, to) {
        app.keepBookmarks(app.shortcuts.map(s => {
            if ((s.folder ?? "") !== from)
                return s
            return to.trim() === "" ? { title: s.title, url: s.url } : { title: s.title, url: s.url, folder: to.trim() }
        }))
    }

    // Takes bookmarks (and history) of another browser. Returns the sentence to show.
    function importFrom(path, withHistory) {
        const data = Importer.read(path, withHistory)
        const known = new Set(app.shortcuts.map(s => s.url))
        const list = app.shortcuts.slice()
        for (const b of data.bookmarks) {
            const url = String(b.url)
            if (list.length >= app.maxBookmarks || known.has(url))
                continue
            known.add(url)
            const item = { title: b.title || app.hostOf(url) || url, url: url }
            if (b.folder)
                item.folder = b.folder
            list.push(item)
        }
        const added = list.length - app.shortcuts.length
        if (added > 0)
            app.keepBookmarks(list)
        const pages = data.visits.length > 0 ? History.merge(data.visits) : 0
        let text = Lang.t(added + " yer imi eklendi", added + " bookmarks added")
        if (withHistory)
            text += Lang.t(", " + pages + " sayfa geçmişe alındı", ", " + pages + " pages taken into the history")
        if (!data.ok)
            text += Lang.t(". Bazı dosyalar okunamadı; o tarayıcı açıksa kapatıp yeniden dene.", ". Some files could not be read; if that browser is open, close it and try again.")
        return text + (data.ok ? "." : "")
    }

    // Ctrl+D: bookmark the page, or remove the bookmark it already has
    function toggleBookmark() {
        if (app.onStartPage || app.onSettings)
            return
        const url = String(app.view.url)
        const at = app.shortcuts.findIndex(s => s.url === url)
        if (at >= 0)
            app.removeShortcut(at)
        else
            app.addShortcut(url, app.view.title)
    }

    function removeShortcut(index) {
        app.keepBookmarks(app.shortcuts.filter((s, i) => i !== index))
    }
}
