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
        app.keepBookmarks(app.shortcuts.concat([{ title: name, url: url, added: Date.now() }]))
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
        if (cleanFolder(folder) !== "")
            item.folder = cleanFolder(folder)
        item.added = index < 0 || app.shortcuts[index].url !== url ? Date.now() : app.shortcuts[index].added ?? Date.now()
        if (index >= 0 && app.shortcuts[index].url !== url)
            noteRemoved(app.shortcuts[index].url)
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
        list.splice(Math.max(0, Math.min(index, list.length)), 0, Object.assign({}, item, { added: Date.now() }))
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

    // folders inside folders are written "Work/Tools"
    function cleanFolder(text) { return String(text).split("/").map(p => p.trim()).filter(p => p !== "").slice(0, 6).join("/") }

    // an empty new name puts the bookmarks outside the folder; folders inside move along
    function renameFolder(from, to) {
        const name = cleanFolder(to)
        app.keepBookmarks(app.shortcuts.map(s => {
            const folder = s.folder ?? ""
            if (folder !== from && !folder.startsWith(from + "/"))
                return s
            const moved = cleanFolder(name + folder.slice(from.length))
            const next = Object.assign({}, s)
            if (moved === "")
                delete next.folder
            else
                next.folder = moved
            return next
        }))
    }

    // removals are remembered, so that synchronising does not bring them back
    function keepRemoved(list) {
        app.removedBookmarks = list
        app.saved.removedBookmarks = JSON.stringify(list)
    }
    function noteRemoved(url) { keepRemoved([{ url: url, when: Date.now() }].concat(app.removedBookmarks.filter(r => r.url !== url)).slice(0, 2000)) }

    function exportBookmarks(file) {
        app.say(Library.writeBookmarks(file, app.shortcuts) ? Lang.t("Yer imleri dışa aktarıldı.", "Bookmarks were exported.") : Lang.t("Dosya yazılamadı.", "The file could not be written."))
    }
    function importBookmarks(file) {
        const found = Library.readBookmarks(file)
        const known = new Set(app.shortcuts.map(s => s.url))
        const list = app.shortcuts.slice()
        for (const b of found) {
            if (list.length >= app.maxBookmarks || known.has(b.url))
                continue
            known.add(b.url)
            list.push(Object.assign({ added: Date.now() }, b, { title: b.title || app.hostOf(b.url) || b.url }))
        }
        const added = list.length - app.shortcuts.length
        if (added > 0)
            app.keepBookmarks(list)
        app.say(found.length === 0 ? Lang.t("Bu dosyada yer imi bulunamadı.", "No bookmarks were found in this file.") : Lang.t(added + " yer imi eklendi.", added + " bookmarks added."))
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
            const item = { title: b.title || app.hostOf(url) || url, url: url, added: Date.now() }
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
        if (app.shortcuts[index])
            noteRemoved(app.shortcuts[index].url)
        app.keepBookmarks(app.shortcuts.filter((s, i) => i !== index))
    }
}
