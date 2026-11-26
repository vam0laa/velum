import QtQuick
import QtWebEngine

// Workspaces: separate sets of tabs.
// "app" is the window these belong to.
QtObject {
    property var app

    function inSpace(index) {
        const tab = index >= 0 && index < app.tabs.count ? app.tabs.get(index) : null
        const here = app.space
        return tab !== null && (tab.pinned || tab.space === here)
    }

    // the tabs listed in the side bar, as numbers
    function visibleTabs() {
        const out = []
        for (let i = 0; i < app.tabs.count; i++)
            if (app.inSpace(i))
                out.push(i)
        return out
    }

    // the nearest other tab of this workspace: the one below, else the one above, else -1
    function neighbourOf(index) {
        const list = app.visibleTabs().filter(i => i !== index)
        return list.find(i => i > index) ?? list[list.length - 1] ?? -1
    }

    // choosing a tab of another workspace (from the command box, say) goes there
    function followCurrent() {
        if (app.restored && app.current >= 0 && app.current < app.tabs.count && !app.inSpace(app.current))
            app.space = app.tabs.get(app.current).space
    }

    function spaceName(item) { return item.name || Lang.t("Genel", "General") }

    function readSpaces(text) {
        const out = []
        try {
            for (const s of JSON.parse(text))
                if (s && Number.isInteger(s.id) && s.id > 0 && typeof s.name === "string" && !out.some(o => o.id === s.id) && out.length < 6)
                    out.push({ id: s.id, name: s.name.slice(0, 20) })
        } catch (e) {
        }
        return out.length > 0 ? out : [{ id: 1, name: "" }]
    }

    function keepSpaces(list) {
        app.spaces = list
        app.saved.spaces = JSON.stringify(list)
    }

    function switchSpace(id) {
        if (id === app.space || !app.spaces.some(s => s.id === id))
            return
        // a pinned tab is everywhere, so it is not what a workspace "was left on"
        app.lastInSpace[app.space] = app.current >= app.pinnedCount ? app.view : null
        const left = app.lastInSpace[id]
        app.space = id
        let target = -1
        for (let i = 0; i < app.tabs.count; i++) {
            if (left && app.views.itemAt(i) === left && app.inSpace(i)) {
                target = i
                break
            }
            if (target < 0 && !app.tabs.get(i).pinned && app.tabs.get(i).space === id)
                target = i
        }
        if (target < 0)
            app.openTab("")
        else
            app.current = target
        app.touchSession()
    }

    function addSpace(name) {
        name = String(name).trim().slice(0, 20)
        if (name === "" || app.spaces.length >= 6)
            return 0
        const id = Math.max(...app.spaces.map(s => s.id)) + 1
        app.keepSpaces(app.spaces.concat([{ id: id, name: name }]))
        app.switchSpace(id)
        return id
    }

    function renameSpace(id, name) {
        name = String(name).trim().slice(0, 20)
        if (name !== "")
            app.keepSpaces(app.spaces.map(s => s.id === id ? { id: id, name: name } : s))
    }

    // Deleting a workspace keeps its pages: they move to another one.
    function removeSpace(id) {
        const home = app.spaces.find(s => s.id !== id)
        if (!home || !app.spaces.some(s => s.id === id))
            return
        if (app.space === id)
            app.switchSpace(home.id)
        for (let i = app.tabs.count - 1; i >= 0; i--) {
            const tab = app.tabs.get(i)
            if (tab.space !== id)
                continue
            if (!tab.pinned && (tab.pageUrl === "" || tab.pageUrl === "about:blank"))
                app.closeTab(i)
            else
                app.tabs.setProperty(i, "space", home.id)
        }
        app.keepSpaces(app.spaces.filter(s => s.id !== id))
        app.moves++
        app.touchSession()
    }

    function moveToSpace(index, id) {
        if (index < 0 || index >= app.tabs.count || app.tabs.get(index).pinned || app.tabs.get(index).space === id || !app.spaces.some(s => s.id === id))
            return
        const page = app.views.itemAt(index) as WebEngineView
        if (page === app.splitLeft || page === app.splitRight)
            app.unsplit()
        const wasCurrent = index === app.current
        if (wasCurrent && app.neighbourOf(index) < 0)
            app.openTab("")
        const pick = wasCurrent ? app.neighbourOf(index) : app.current
        app.tabs.setProperty(index, "space", id)
        app.current = pick
        app.moves++
        app.touchSession()
    }
}
