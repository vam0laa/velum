import QtQuick

// Tab groups and selecting several tabs at once.
// A group's tabs stay next to each other; "lead" marks the first, which carries its name.
// "app" is the window these belong to.
QtObject {
    property var app
    readonly property var colours: ["accent", "mauve", "pink", "green", "peach", "danger"]

    function group(id) { return app.groups.find(g => g.id === id) ?? null }

    function keepGroups(list) {
        app.groups = list
        app.saved.groups = Shield.forgetOnExit || app.isPrivate ? "[]" : JSON.stringify(list)
    }
    function readGroups() {
        try {
            const list = JSON.parse(app.saved.groups)
            if (Array.isArray(list))
                app.groups = list.filter(g => g && Number.isInteger(g.id) && g.id > 0 && typeof g.name === "string")
                                 .map(g => ({ id: g.id, name: g.name.slice(0, 24), colour: colours.includes(g.colour) ? g.colour : "accent", collapsed: g.collapsed === true })).slice(0, 40)
        } catch (e) {
        }
    }

    // after anything moved: who leads, and groups nobody is in are dropped
    function refreshGroups() {
        const used = new Set()
        let before = 0
        for (let i = 0; i < app.tabs.count; i++) {
            const tab = app.tabs.get(i)
            const id = tab.pinned || !group(tab.group) ? 0 : tab.group
            set(i, "group", id)
            set(i, "lead", id !== 0 && id !== before)
            set(i, "folded", id !== 0 && group(id).collapsed && i !== app.current)
            before = id
            used.add(id)
        }
        if (app.restored && app.groups.some(g => !used.has(g.id)))
            keepGroups(app.groups.filter(g => used.has(g.id)))
        app.touchSession()
    }
    // only real changes are written: the tab strip lays itself out again for each
    function set(index, role, value) {
        if (app.tabs.get(index)[role] !== value)
            app.tabs.setProperty(index, role, value)
    }

    // The pages at these places (so that moving does not confuse the numbers).
    function pagesAt(indices) { return indices.filter(i => i >= 0 && i < app.tabs.count && !app.tabs.get(i).pinned).map(i => app.pageViewAt(i)) }

    // Puts the tabs into the group, next to its other tabs. All move to that group's workspace.
    function addToGroup(indices, id) {
        if (!group(id))
            return
        for (const page of pagesAt(indices)) {
            let from = app.tabIndexOf(page)
            let last = -1
            for (let i = 0; i < app.tabs.count; i++)
                if (i !== from && app.tabs.get(i).group === id)
                    last = i
            app.tabs.setProperty(from, "group", id)
            if (last >= 0) {
                app.tabs.setProperty(from, "space", app.tabs.get(last).space)
                app.moveTab(from, from > last ? last + 1 : last)
            }
        }
        clearSelection()
        refreshGroups()
    }
    function newGroup(indices, name) {
        if (pagesAt(indices).length === 0)
            return 0
        const id = app.groups.reduce((most, g) => Math.max(most, g.id), 0) + 1
        app.groups = app.groups.concat([{ id: id, name: String(name ?? "").slice(0, 24) || Lang.t("Grup ", "Group ") + id, colour: colours[(id - 1) % colours.length], collapsed: false }])
        addToGroup(indices, id)
        keepGroups(app.groups)
        return id
    }
    function ungroup(indices) {
        for (const page of pagesAt(indices)) {
            const from = app.tabIndexOf(page)
            const id = app.tabs.get(from).group
            if (id === 0)
                continue
            let last = from
            for (let i = from + 1; i < app.tabs.count && app.tabs.get(i).group === id; i++)
                last = i
            app.tabs.setProperty(from, "group", 0)
            if (last !== from)
                app.moveTab(from, last)       // it steps out behind the group
        }
        clearSelection()
        refreshGroups()
    }
    function changeGroup(id, changes) {
        keepGroups(app.groups.map(g => g.id === id ? Object.assign({}, g, changes) : g))
        refreshGroups()
    }
    function toggleGroup(id) {
        const g = group(id)
        if (g)
            changeGroup(id, { collapsed: !g.collapsed })
    }
    function membersOf(id) {
        const out = []
        for (let i = 0; i < app.tabs.count; i++)
            if (app.tabs.get(i).group === id)
                out.push(i)
        return out
    }
    function closeGroup(id) {
        for (const page of pagesAt(membersOf(id)))
            app.closeTab(app.tabIndexOf(page))
        refreshGroups()
    }
    function dissolveGroup(id) { ungroup(membersOf(id)) }

    // ---- several tabs at once ----
    function selection() {
        const out = []
        for (let i = 0; i < app.tabs.count; i++)
            if (app.tabs.get(i).chosen)
                out.push(i)
        return out
    }
    function clearSelection() {
        for (let i = 0; i < app.tabs.count; i++)
            if (app.tabs.get(i).chosen)
                app.tabs.setProperty(i, "chosen", false)
    }
    // Ctrl+click adds or takes one; Shift+click takes the stretch from the current tab
    function select(index, stretch) {
        if (index < 0 || index >= app.tabs.count)
            return
        if (selection().length === 0)
            app.tabs.setProperty(app.current, "chosen", true)
        if (stretch) {
            for (let i = Math.min(index, app.current); i <= Math.max(index, app.current); i++)
                if (app.inSpace(i))
                    app.tabs.setProperty(i, "chosen", true)
        } else {
            app.tabs.setProperty(index, "chosen", !app.tabs.get(index).chosen)
        }
    }
    // what a menu opened on `index` acts on: the selection if it is part of it, else that tab
    function targets(index) {
        const chosen = selection()
        return chosen.length > 1 && chosen.includes(index) ? chosen : [index]
    }
    function closeMany(indices) {
        const pages = indices.map(i => app.pageViewAt(i))
        for (const page of pages) {
            const at = app.tabIndexOf(page)
            if (at >= 0)
                app.closeTab(at)
        }
        clearSelection()
    }
}
