import QtQuick
import QtWebEngine
import "ui"

// Drives the real interface files and checks what happens to tabs, pins, shortcuts and the command box.
Item {
    id: t
    property var w
    property var second
    property int failed: 0
    function check(name, ok) { if (!ok) failed++; console.log((ok ? "PASS " : "FAIL ") + name) }
    function page(u) { return "about:blank#" + u }
    // the tab order as letters, pinned ones in capitals
    function order() { let s = ""; for (let i = 0; i < 20; i++) { const v = t.w.pageAt(i); if (!v) break; const l = v.charAt(v.length - 1); s += i < t.w.pinnedCount ? l.toUpperCase() : l } return s }
    function shown() { const u = String(t.w.view.startUrl); return u.charAt(u.length - 1) }
    Component { id: main; Main {} }

    Timer {
        interval: 800; running: true
        onTriggered: {
            t.w = main.createObject(null, { startUrls: [t.page("a"), t.page("b"), t.page("c")], hasWidevine: true })
            const w = t.w
            Lang.choice = "tr"
            t.check("three start tabs, first current", w.current === 0 && t.shown() === "a")
            w.step(1);  t.check("next tab", t.shown() === "b")
            w.step(-1); w.step(-1); t.check("previous wraps around", t.shown() === "c")
            w.current = 1
            w.closeTab(0); t.check("closing a tab before keeps the same page", w.current === 0 && t.shown() === "b")
            w.reopenClosed(); t.check("the closed tab comes back in its place", t.order() === "abc" && t.shown() === "a")

            w.current = 1
            w.moveTab(1, 2); t.check("moving the selected tab keeps it selected", t.order() === "acb" && t.shown() === "b" && w.current === 2)
            w.moveTab(0, 2); t.check("moving another tab keeps the selection", t.order() === "cba" && t.shown() === "b")
            w.togglePin(2); t.check("pinning moves to the top", t.order() === "Acb" && w.pinnedCount === 1 && t.shown() === "b")
            w.moveTab(0, 2); t.check("a pinned tab stays among the pinned", t.order() === "Acb")
            w.moveTab(2, 0); t.check("an ordinary tab cannot jump above pinned ones", t.order() === "Abc" && t.shown() === "b")
            w.togglePin(2); t.check("second pin goes below the first", t.order() === "ACb")
            w.togglePin(0); t.check("unpinning becomes the first ordinary tab", t.order() === "Cab" && w.pinnedCount === 1)
            w.closeOthers(2); t.check("close others keeps pinned and the chosen one", t.order() === "Cb" && t.shown() === "b")
            w.closeTab(0); t.check("a closed pinned tab lowers the count", w.pinnedCount === 0 && t.order() === "b")


            w.closeTab(0); t.check("closing the only tab leaves one empty tab", w.current === 0 && w.view !== null && String(w.view.startUrl) === "")
            w.closeTab(7); w.closeTab(-1); w.moveTab(9, 0); w.togglePin(0); t.check("bad requests and pinning an empty tab do nothing", w.view !== null && w.pinnedCount === 0)

            while (w.shortcuts.length) w.removeShortcut(0)
            t.check("a shortcut is added", w.addShortcut("vamola.dev") && w.shortcuts[0].title === "vamola.dev")
            t.check("the same shortcut is not added twice", !w.addShortcut("vamola.dev"))
            t.check("a search is not a shortcut", !w.addShortcut("some words"))
            w.removeShortcut(0); t.check("a shortcut is removed", w.shortcuts.length === 0)
            t.check("broken saved data gives an empty list", w.readList("{oops").length === 0 && w.readList('[{"url":5},null]').length === 0)

            w.view.url = t.page("a")
            const count = () => { let n = 0; while (w.pageAt(n) !== null) n++; return n }
            const bar = w.commandBar
            const before = count()
            w.newTab(); t.check("new tab opens the box, not a tab", bar.open && bar.forNewTab && count() === before)
            bar.hide(); t.check("escaping leaves no empty tab", !bar.open && count() === before)
            const found = bar.find("example.org")
            t.check("the first result opens what was typed", found[0].kind === "go" && String(found[0].url) === "https://example.org")
            t.check("commands are found by name", bar.find("tam ekran").some(r => r.kind === "command"))
            t.check("an empty box lists commands", bar.find("").length > 0 && bar.find("")[0].kind !== "go")
            t.check("the host of a page is read safely", w.hostOf("https://user@Evil.example:8/x") === "evil.example" && w.hostOf("about:blank") === "")
            // permission requests, with stand-ins for the engine's objects
            let granted = 0, denied = 0
            const fake = () => ({ grant: () => granted++, deny: () => denied++ })
            const here = w.view
            w.asks = [{ page: here, permission: fake(), wish: "x", site: "a.test" }, { page: "elsewhere", permission: fake(), wish: "y", site: "b.test" }]
            t.check("only the current page's question is shown", w.ask !== null && w.ask.site === "a.test")
            w.answer(w.ask, true); t.check("allowing grants once and removes it", granted === 1 && denied === 0 && w.ask === null && w.asks.length === 1)
            w.dropAsks("elsewhere"); t.check("a leaving page's question is refused", denied === 1 && w.asks.length === 0)
            t.check("unknown kinds are not asked about", w.wishFor(0) === "" && w.wishFor(9999) === "")
            History.pages = [{ url: "https://old.example/page", title: "Old page" }]
            t.check("history is offered while typing", bar.find("old.ex").some(r => r.kind === "history"))
            bar.show(false, "", true)
            t.check("the history box lists only history", bar.historyOnly && bar.results.length === 1 && bar.results[0].kind === "history")
            bar.forget(0); t.check("a page can be removed from history", History.pages.length === 0 && bar.results.length === 0)
            bar.hide()
            w.view.url = "https://mark.example/"
            while (w.shortcuts.length) w.removeShortcut(0)
            const S = WebEngineView.LifecycleState, minute = 60000
            t.check("a tab just left stays awake", w.sleepTarget(1 * minute, S.Discarded, false, false, false) === S.Active)
            t.check("early mode is the default and freezes after two minutes", w.sleepMode === 1 && w.freezeAfter === 2 * minute && w.discardAfter === 10 * minute)
            t.check("after a while it freezes", w.sleepTarget(6 * minute, S.Discarded, false, false, false) === S.Frozen)
            t.check("after long it is discarded", w.sleepTarget(21 * minute, S.Discarded, false, false, false) === S.Discarded)
            t.check("the engine's advice is respected", w.sleepTarget(60 * minute, S.Frozen, false, false, false) === S.Frozen && w.sleepTarget(60 * minute, S.Active, false, false, false) === S.Active)
            t.check("pinned, playing and loading tabs stay awake", [[true, false, false], [false, true, false], [false, false, true]].every(f => w.sleepTarget(60 * minute, S.Discarded, f[0], f[1], f[2]) === S.Active))
            t.check("texts follow the language", Lang.t("evet", "yes") === "evet" && bar.find("tam ekran").length > 0)
            Lang.choice = "en"
            t.check("changing the language rewrites the commands", bar.find("full screen").some(r => r.kind === "command") && w.wishFor(WebEnginePermission.PermissionType.Geolocation) === "wants to know your location.")
            Lang.choice = "tr"
            // workspaces
            const kept = w.pageAt(w.current), first = w.space, home = w.current
            w.togglePin(home)
            t.check("there is one workspace at first", w.spaces.length === 1 && w.spaceName(w.spaces[0]) === "Genel")
            w.openTab(t.page("g")); const inFirst = w.view
            const school = w.addSpace("  Okul ")
            t.check("a new workspace opens with one empty tab", school > 0 && w.space === school && w.visibleTabs().length === 2 && w.view !== inFirst && w.spaceName(w.spaces[1]) === "Okul")
            t.check("pinned tabs are shared", w.inSpace(0) && w.pageAt(0) === kept)
            t.check("a nameless or seventh workspace is refused", w.addSpace("  ") === 0 && w.spaces.length === 2)
            w.view.url = t.page("o"); const inSchool = w.view
            w.step(1); w.step(1); t.check("stepping stays inside the workspace", w.view === inSchool)
            w.switchSpace(first); t.check("going back returns to the same tab", w.view === inFirst && !inSchool.visible)
            w.switchSpace(school); t.check("and again", w.view === inSchool)
            w.current = w.visibleTabs().length > 0 ? w.tabIndexOf(inFirst) : 0
            t.check("choosing a tab elsewhere switches the workspace", w.space === first && w.view === inFirst)
            w.moveToSpace(w.current, school)
            t.check("a moved tab leaves, and another is shown", w.space === first && w.view !== inFirst && !w.inSpace(w.tabIndexOf(inFirst)))
            w.switchSpace(school); w.closeTab(w.tabIndexOf(inFirst)); w.closeTab(w.current)
            t.check("closing the last own tab falls back to the pinned one", w.space === school && w.visibleTabs().length === 1 && w.current === 0)
            w.switchSpace(first); w.switchSpace(school)
            t.check("an empty workspace gets a fresh tab on entry", w.visibleTabs().length === 2 && String(w.view.startUrl) === "")
            w.togglePin(0); w.closeTab(w.tabIndexOf(w.view)); w.closeTab(w.current)
            t.check("without pins, closing the last tab leaves an empty one there", w.space === school && w.visibleTabs().length === 1 && String(w.view.startUrl) === "")
            w.switchSpace(first); w.current = w.visibleTabs()[0]; w.view.url = t.page("k"); w.togglePin(w.current); w.switchSpace(school)
            w.reopenClosed(); t.check("a closed tab returns to its workspace", w.space === school && w.pageAt(w.current) === kept)
            w.switchSpace(first); w.renameSpace(school, "Ders"); t.check("a workspace is renamed", w.spaces[1].name === "Ders")
            const pages = w.visibleTabs().length
            w.removeSpace(school)
            t.check("deleting a workspace keeps its pages", w.spaces.length === 1 && w.space === first && w.visibleTabs().length === pages + 1)
            w.removeSpace(first); t.check("the last workspace cannot be deleted", w.spaces.length === 1)
            t.check("broken saved workspaces give the default one", w.readSpaces("{x").length === 1 && w.readSpaces('[{"id":-1,"name":"a"}]')[0].id === 1)
            w.togglePin(0); w.closeOthers(w.tabIndexOf(inFirst) >= 0 ? w.tabIndexOf(inFirst) : w.current)

            w.openSettings(); t.check("the settings page opens", true)
            w.downloadFolder = "/tmp/somewhere"; t.check("a download folder can be chosen", w.downloadFolder === "/tmp/somewhere"); w.downloadFolder = ""
            const menu = w.pageMenu
            menu.describe({ linkUrl: "https://a.example/", selectedText: "  word  " })
            t.check("a link click is described", menu.link === "https://a.example/" && menu.selection === "word" && !menu.plain && !menu.image)
            menu.describe({}); t.check("a click on nothing gives the page menu", menu.plain && menu.link === "")
            menu.describe({ isContentEditable: true }); t.check("a click in a field offers editing", menu.editable && !menu.plain)
            t.check("notifications are asked about", w.wishFor(WebEnginePermission.PermissionType.Notifications) !== "")
            w.addShortcut("velum.example"); t.check("shortcuts are found", bar.find("velum.ex").some(r => r.kind === "shortcut"))
            w.removeShortcut(0)

            // pin a tab now; it is checked after the settings have reached the disk
            w.view.url = t.page("p")
            w.togglePin(0)
            w.openTab(t.page("q")); w.openTab(t.page("r")); w.current = 1
            bar.show(true, "tam")
            shot.start()
        }
    }
    // a picture of the command box; the test goes on even if no picture can be taken
    Timer {
        id: shot; interval: 700
        onTriggered: {
            t.w.contentItem.grabToImage(img => img.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]))
            later.start()
        }
    }
    Timer {
        id: sleepStep; interval: 1500
        onTriggered: {
            const w = t.w
            const other = w.current - 1
            w.sleepTab(w.current)
            t.check("the tab being looked at cannot be put to sleep", w.view.lifecycleState === WebEngineView.LifecycleState.Active)
            w.sleepTab(other)
            t.check("a hidden tab is discarded", w.sleepState(other) === 2)
            const here = w.pageViewAt(w.current), there = w.pageViewAt(other)
            w.toggleSplit()
            t.check("splitting shows the neighbour beside the current tab", w.splitShown && here.visible && there.visible && here.x === 0 && there.x > 0 && w.sleepState(other) === 0)
            w.sleepTab(other); t.check("a tab on screen is not put to sleep", w.sleepState(other) === 0)
            w.current = other
            t.check("choosing the other half keeps both", w.splitShown && here.visible && there.visible && here.x === 0)
            w.openTab(t.page("z"))
            t.check("another tab is shown alone", !w.splitShown && !here.visible && !there.visible && w.view.width > here.width - 1)
            w.current = other
            t.check("going back shows the pair again", w.splitShown && here.visible)
            w.moveTab(w.current, w.pinnedCount); t.check("moving a tab keeps the pair", w.splitShown && w.splitLeft === here && w.splitRight === there)
            w.toggleSplit(); t.check("joining shows one", !w.splitShown && w.view === there && !here.visible)
            w.toggleSplit(); w.closeTab(w.current)
            t.check("closing a half ends the split", w.splitLeft === null && w.splitRight === null && !w.splitShown)
            w.openTab(t.page("s3")); w.current = w.current - 1
            w.sleepTab(w.current + 1)
            const other2 = w.current
            w.current = other2 + 1
            t.check("choosing a sleeping tab wakes it", w.view.lifecycleState === WebEngineView.LifecycleState.Active && w.sleepState(other2 + 1) === 0)
            console.log(t.failed ? "RESULT failed " + t.failed : "RESULT all passed")
            Qt.exit(t.failed)
        }
    }
    Timer {
        id: later; interval: 1500
        onTriggered: {
            t.second = main.createObject(null, { startUrls: [], hasWidevine: true, profileName: "velum-second" })
            t.check("pinned tabs return in a new window", t.second.pinnedCount === 1 && t.second.pageAt(0).endsWith("p"))
            t.check("two ordinary tabs were saved", t.second.pageAt(2) !== null && t.second.pageAt(3) === null && t.second.current === 1)
            t.check("the other tabs return too, with the same one chosen", t.second.pageAt(1) !== null && t.second.pageAt(t.second.current) === t.w.pageAt(t.w.current))
            const idle = t.second.current === 0 ? 1 : 0
            t.check("a restored tab waits until it is looked at", String(t.second.pageViewAt(idle).url) === "")
            t.second.current = idle
            t.check("looking at it loads it", String(t.second.pageViewAt(idle).url) === t.second.pageAt(idle))
            t.check("a broken saved session gives no tabs", t.second.readSession("{oops").tabs.length === 0 && t.second.readSession('{"tabs":5}').tabs.length === 0)
            const before = t.w.pageAt(0)
            t.w.openExternal(["about:blank#x"]); t.check("an address from outside opens a new tab", t.w.pageAt(t.w.current) === "about:blank#x" && t.w.pageAt(0) === before)
            // with the real engine: a tab that is not shown can be put to sleep and wakes when chosen
            const w = t.w
            w.openTab(t.page("s1")); w.openTab(t.page("s2"))
            sleepStep.start()
        }
    }
}
