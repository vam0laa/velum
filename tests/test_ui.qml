import QtQuick
import QtWebEngine
import "ui"

// Drives the real interface files and checks what happens to tabs, pins, shortcuts and the command box.
Item {
    id: t
    property var w
    property var second
    property int failed: 0
    property var video
    property var videoHome
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
            // the bookmark manager
            const marks = w.bookmarks
            while (w.shortcuts.length) w.removeShortcut(0)
            t.check("a bookmark is saved with a name and a folder", w.saveBookmark(-1, " Site ", "vamola.dev", " Linux ") && w.shortcuts[0].title === "Site" && w.shortcuts[0].folder === "Linux")
            t.check("a missing name comes from the address", w.saveBookmark(-1, "", "example.org", "") && w.shortcuts[1].title === "example.org" && w.shortcuts[1].folder === undefined)
            t.check("bad and repeated addresses are refused", !w.saveBookmark(-1, "x", "two words", "") && !w.saveBookmark(-1, "x", "vamola.dev", "") && !w.saveBookmark(9, "x", "new.example", ""))
            t.check("editing keeps its own address", w.saveBookmark(0, "Yeni ad", "vamola.dev", "Linux") && w.shortcuts[0].title === "Yeni ad" && w.shortcuts.length === 2)
            marks.open()
            t.check("folders are listed", marks.folders.length === 1 && marks.folders[0] === "Linux" && marks.rows.length === 2)
            marks.folder = "Linux"; t.check("a folder shows its own", marks.rows.length === 1 && marks.rows[0].index === 0)
            marks.folder = "*"; marks.query = "EXAMPLE"; t.check("searching narrows the list", marks.rows.length === 1 && marks.rows[0].index === 1)
            marks.query = ""
            w.moveBookmark(0, 1); t.check("bookmarks change places", w.shortcuts[0].title === "example.org")
            marks.remove(0); t.check("deleting can be undone", w.shortcuts.length === 1 && marks.undo !== null)
            marks.restored(marks.undo.item, marks.undo.index); t.check("undo puts it back in place", w.shortcuts.length === 2 && w.shortcuts[0].title === "example.org")
            marks.folder = "Linux"; w.renameFolder("Linux", "Araçlar")
            t.check("renaming a folder moves its bookmarks", w.shortcuts[1].folder === "Araçlar" && marks.folder === "*")
            w.renameFolder("Araçlar", ""); t.check("dissolving a folder keeps them", w.shortcuts.length === 2 && marks.folders.length === 0)
            marks.edit(-1); marks.commit(); t.check("an empty form reports the problem", marks.editing === -1 && marks.error !== "")
            marks.close()
            while (w.shortcuts.length) w.removeShortcut(0)
            History.merged = 0
            const said = w.importFrom("/fake", true)
            t.check("importing brings bookmarks with folders and history", w.shortcuts.length === 2 && w.shortcuts[0].folder === "İş" && w.shortcuts[1].title === "two.example" && History.merged === 1 && said.startsWith("2 yer imi"))
            t.check("importing again adds nothing", w.importFrom("/fake", false).startsWith("0 yer imi") && w.shortcuts.length === 2 && History.merged === 1)
            t.check("an unreadable source is reported", w.importFrom("/other", false).indexOf("okunamadı") > 0)
            while (w.shortcuts.length) w.removeShortcut(0)

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

            // the settings are a tab of their own
            w.openTab(t.page("before"))
            const was = w.current
            w.openSettings("privacy")
            const settingsAt = w.current
            t.check("settings open in a tab", w.onSettings && !w.onStartPage && w.prefs.visible && w.prefs.section === "privacy")
            w.current = was; t.check("another tab hides them", !w.onSettings && !w.prefs.visible)
            const made = count()
            w.openSettings(); t.check("the same tab is used again", w.current === settingsAt && count() === made && w.prefs.section === "privacy")
            for (const s of w.prefs.sections) w.openSettings(s.key)
            t.check("every category opens", w.prefs.section === "about" && w.prefs.sections.length === 9)
            t.check("the command box finds the settings tab", bar.find("ayarlar").some(r => r.kind === "tab"))
            w.view.url = t.page("left"); t.check("going somewhere makes it an ordinary tab", !w.onSettings)
            w.closeTab(w.current)
            // both layouts
            w.horizontalTabs = true; w.openTab(t.page("h1")); w.openTab(t.page("h2"))
            const top = w.current; w.moveTab(top, w.pinnedCount)
            t.check("the horizontal layout works on the same tabs", w.pageAt(w.pinnedCount).endsWith("h2") && w.view !== null)
            w.closeTab(w.current); w.closeTab(w.visibleTabs().find(i => w.pageAt(i).endsWith("h1")))
            w.horizontalTabs = false
            Theme.palette = "latte"; t.check("a light theme is known as light", !Theme.dark)
            Theme.accentChoice = "pink"; t.check("the accent can be chosen", String(Theme.accent) === String(Theme.pink))
            Theme.accentChoice = ""; Theme.palette = "mocha"; t.check("every theme has all its colours", Theme.themes.every(x => [...Array(15).keys()].every(i => String(Theme.colorOf(x.key, i)).startsWith("#"))))
            // the start page
            History.pages = [{ url: "https://a.example/1", title: "A" }, { url: "https://a.example/2", title: "A2" }, { url: "https://b.example/", title: "" }]
            w.refreshFrequent()
            t.check("most visited shows one page per site", w.frequentPages.length === 2 && w.frequentPages[1].title === "b.example")
            History.pages = []; w.refreshFrequent()
            t.check("site icon names are safe file names", w.iconName("https://www.vamola.dev/x") === "vamola.dev" && w.iconName("https://..%2f/x") === "" && w.iconName("about:blank") === "")
            w.prefs.startChanged("showNote", false); w.prefs.startChanged("startBackground", "dots")
            t.check("the start page follows the settings", !w.showNote && w.startBackground === "dots")
            w.showNote = true; w.startBackground = "glow"
            t.check("the everyday look is the default", !Theme.web && Theme.shown === "mocha" && Theme.radius > 0)
            t.check("the theme list does not give the secret away", Theme.themes.every(x => x.key !== "cybercore" && x.key !== "night"))
            t.check("ordinary words are not secret", !Theme.secret("webcore") && !Theme.secret("velum.dev") && !Theme.web)
            w.view.url = t.page("egg"); const addressBefore = String(w.view.url)
            bar.show(false, "  Velum:WebCore "); bar.choose(0)
            t.check("typing velum:webcore opens the hidden look without leaving the page", Theme.web && !bar.open && String(w.view.url) === addressBefore && Theme.radius === 0)
            const hourNow = Theme.hour
            Theme.hour = 12; const day = Theme.shown; Theme.hour = 22; const late = Theme.shown
            t.check("webcore is bright by day and blue by night", day === "cybercore" && late === "night")
            Theme.hour = 12; t.check("text on blue is white", String(Theme.accentInk) === "#ffffff" && String(Theme.barInk) === "#ffffff")
            Theme.hour = hourNow
            t.check("typing it again goes back", Theme.secret("velum:webcore") && !Theme.web && Theme.shown === "mocha")
            Theme.palette = "mocha"
            Theme.glass = true
            t.check("glass makes the backgrounds see-through, popups stay solid", Theme.frameBack.a < 0.6 && Theme.paneBack.a < 0.6 && Theme.window.a === 1)
            Theme.glass = false; t.check("without glass they are solid", Theme.frameBack.a === 1 && Theme.sheetBack.a === 1)
            Theme.motion = false; t.check("animations can be switched off", Theme.quick === 0 && Theme.smooth === 0)
            Theme.motion = true
            // the welcome pages
            w.welcomed = false; w.welcome.open()
            t.check("the welcome starts at the first page", w.welcome.step === 0)
            w.welcome.next(); w.welcome.next(); w.welcome.back(); t.check("it moves between pages", w.welcome.step === 1)
            for (let i = 0; i < 10; i++) w.welcome.next()
            t.check("finishing is remembered", w.welcomed && !w.welcome.opened)
            w.current = was
            w.closeTab(w.current)
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
            // a page with a live video made from a canvas, so no file or network is needed
            w.openTab("")
            w.view.loadHtml('<body style="margin:0"><div id="box" style="transform:translateX(40px)"><p>text</p><canvas width="320" height="180"></canvas><video muted autoplay playsinline style="width:200px"></video></div>'
                + '<script>const c=document.querySelector("canvas"),x=c.getContext("2d");let n=0;setInterval(()=>{x.fillStyle=n++%2?"#89b4fa":"#cba6f7";x.fillRect(0,0,320,180)},50);'
                + 'const v=document.querySelector("video");v.srcObject=c.captureStream(20);v.play()</script></body>', "https://video.example/")
            videoStep.start()
        }
    }
    Timer {
        id: videoStep; interval: 2500
        onTriggered: {
            const w = t.w
            t.video = w.view
            t.videoHome = w.view.parent
            w.toggleMini()
            miniStep.start()
        }
    }
    Timer {
        id: miniStep; interval: 1200
        onTriggered: {
            const w = t.w
            t.check("the video's page moves to the small window", w.miniPage === t.video && t.video.parent === w.mini.stage && w.mini.visible)
            t.check("the window has the video's shape and the title compositors know", w.mini.height === 270 && w.mini.title === "Picture-in-Picture")
            t.video.runJavaScript("const r = document.querySelector('video').getBoundingClientRect(); [r.x, r.y, r.width, r.height, innerWidth, innerHeight, getComputedStyle(document.querySelector('p')).visibility]", r => {
                t.check("the video fills the small window and the rest is hidden", r[0] === 0 && r[1] === 0 && r[2] === r[4] && r[3] === r[5] && r[4] <= 481 && r[6] === "hidden")
                w.step(1)
                t.check("another tab can be used meanwhile", w.view !== t.video && t.video.visible && t.video.parent === w.mini.stage)
                w.sleepTab(w.tabIndexOf(t.video)); t.check("the playing tab is not put to sleep", t.video.lifecycleState === WebEngineView.LifecycleState.Active)
                w.toggleMini()
                t.check("bringing it back restores the tab", w.miniPage === null && t.video.parent === t.videoHome && !w.mini.visible && !t.video.visible)
                t.video.runJavaScript("[document.querySelectorAll('[data-velum-path],[data-velum-mini],#velum-mini').length, getComputedStyle(document.querySelector('p')).visibility]", left => {
                    t.check("the page is as it was", left[0] === 0 && left[1] === "visible")
                    w.openMini(w.tabIndexOf(t.video))
                    closeStep.start()
                })
            })
        }
    }
    Timer {
        id: closeStep; interval: 1200
        onTriggered: {
            const w = t.w
            t.check("it can be taken out again", w.miniPage === t.video)
            w.closeTab(w.tabIndexOf(t.video))
            t.check("closing the tab closes the small window", w.miniPage === null && !w.mini.visible)
            w.openTab(t.page("novideo"))
            plainStep.start()
        }
    }
    Timer {
        id: plainStep; interval: 1200
        onTriggered: { t.w.toggleMini(); doneStep.start() }
    }
    Timer {
        id: doneStep; interval: 800
        onTriggered: {
            t.check("a page without a video says so", t.w.miniPage === null && t.w.notice !== "")
            const w = t.w
            w.notice = ""
            w.toggleReader()
            noArticleStep.start()
        }
    }
    Timer {
        id: noArticleStep; interval: 800
        onTriggered: {
            const w = t.w
            t.check("a page without an article says so", !w.view.reading && w.notice !== "")
            const p = "Bu uzun bir paragraf, okuma modunun makaleyi bulabilmesi için yeterince metin taşıyor ve birkaç kez yineleniyor. ".repeat(3)
            w.view.loadHtml('<title>Deneme</title><nav class="menu"><a href="/x">Menü bağlantısı</a></nav>'
                + '<div id="content"><article><h1>Başlık</h1><p onclick="evil()" style="color:red">' + p + '</p><p>' + p + ' <a href="/iyi">iyi bağlantı</a> <a href="javascript:alert(1)">kötü</a></p><p>' + p + '</p><p>' + p + '</p>'
                + '<script>window.ran = 1</scr' + 'ipt><div class="share-buttons">Paylaş düğmeleri</div><form><input value="form"></form></article></div>'
                + '<aside class="sidebar"><p>' + 'Yan sütun yazısı. '.repeat(20) + '</p></aside>', "https://article.example/yazi")
            readStep.start()
        }
    }
    Timer {
        id: readStep; interval: 2000
        onTriggered: {
            const w = t.w
            t.check("an article is noticed", w.view.readable)
            w.toggleReader()
            shownStep.start()
        }
    }
    Timer {
        id: formStep; interval: 2500
        onTriggered: {
            const w = t.w
            t.check("a login form is noticed", w.view.loginOrigin === "https://login.example" && w.view.accounts.length === 0)
            w.view.runJavaScript("typeof QWebChannel === 'undefined' && !(window.qt && window.qt.webChannelTransport)", hidden => t.check("the page's own code cannot reach the channel", hidden === true))
            w.view.runJavaScript("document.getElementById('u').value = 'ali@x.test'; document.getElementById('p').value = 'cok gizli'; document.getElementById('p').focus()", () => {
                // the page presses its own button: not a person, so nothing must happen
                w.view.runJavaScript("document.querySelector('button').click()", () => offerStep.start())
            })
        }
    }
    Timer {
        id: offerStep; interval: 300
        onTriggered: {
            const w = t.w
            t.check("a click made by the page does not make Velum offer to save", w.passwordOffer === null)
            w.offerPassword("https://login.example", "ali@x.test", "cok gizli")
            t.check("a new login is offered", w.passwordOffer !== null && !w.passwordOffer.changed)
            w.savePassword("ali@x.test")
            t.check("saving stores it and the form knows", Passwords.store.length === 1 && w.passwordOffer === null && w.view.accounts.length === 1)
            w.offerPassword("https://login.example", "ali@x.test", "cok gizli")
            t.check("a saved login is not asked about again", w.passwordOffer === null)
            w.offerPassword("https://login.example", "ali@x.test", "yeni")
            t.check("a changed password is offered as an update", w.passwordOffer.changed); w.passwordOffer = null
            w.offerPassword("http://login.example", "a", "b"); w.offerPassword("https://login.example/path", "a", "b")
            t.check("only proper secure origins are accepted", w.passwordOffer === null)
            w.neverFor("https://never.example"); w.offerPassword("https://never.example", "a", "b")
            t.check("a site can be left alone", w.passwordOffer === null && w.neverSave.length === 1)
            w.askAgainFor("https://never.example"); t.check("and asked on again", w.neverSave.length === 0)
            w.view.runJavaScript("document.getElementById('u').value = ''; document.getElementById('p').value = ''; seen = 0", () => { w.fillPassword(); filledStep.start() })
        }
    }
    Timer {
        id: filledStep; interval: 700
        onTriggered: {
            const w = t.w
            w.view.runJavaScript("[document.getElementById('u').value, document.getElementById('p').value, document.getElementById('trap').value, seen > 0]", r => {
                t.check("filling puts name and password in, and the page hears it", r[0] === "ali@x.test" && r[1] === "cok gizli" && r[3] === true)
                t.check("hidden fields are not filled", r[2] === "")
                Passwords.store = [{ origin: "https://other.example", user: "o", password: "p" }]
                w.view.runJavaScript(w.loginScript.fill("https://other.example", "o", "p"), WebEngineScript.ApplicationWorld, done => {
                    t.check("another site's password is refused by the page script too", done === false)
                    // extensions: nothing happens before a yes
                    w.askExtension("not an extension", false)
                    t.check("a wrong store address is refused", w.wantedExtension === null && !w.extensionQuestion.opened)
                    w.askExtension("https://chromewebstore.google.com/detail/x/" + "a".repeat(32), false)
                    t.check("installing asks first", w.wantedExtension !== null && WebStore.fetched.length === 0)
                    w.addExtension()
                    t.check("then it is fetched, and a failure is told", WebStore.fetched.length === 1 && !w.fetchingExtension && w.notice !== "")
                    w.extensionQuestion.close()
                    t.check("the engine's built-in extensions are not listed", w.extensions.length === 0)
                    w.askExtension(String(Qt.resolvedUrl("extension")).replace("file://", ""), true)
                    w.addExtension(); w.extensionQuestion.close()
                    installedStep.start()
                })
            })
        }
    }
    Timer {
        id: installedStep; interval: 2500
        onTriggered: {
            const w = t.w
            t.check("an extension of our own is installed and on", w.extensions.length === 1 && w.extensions[0].name === "Velum test extension" && w.extensions[0].isEnabled)
            w.view.loadHtml("<p>sayfa</p>", "https://ext.example/")
            ranStep.start()
        }
    }
    Timer {
        id: ranStep; interval: 2000
        onTriggered: {
            const w = t.w
            w.view.runJavaScript("document.documentElement.getAttribute('data-velum-extension')", mark => {
                t.check("its content script runs on a matching page", mark === "ran")
                w.enableExtension(w.extensions[0], false)
                offStep.start()
            })
        }
    }
    Timer {
        id: offStep; interval: 1000
        onTriggered: {
            const w = t.w
            t.check("it can be switched off", w.extensions.length === 1 && !w.extensions[0].isEnabled)
            w.removeExtension(w.extensions[0])
            removedStep.start()
        }
    }
    Timer {
        id: removedStep; interval: 2000
        onTriggered: {
            t.check("and removed", t.w.extensions.length === 0)
            console.log(t.failed ? "RESULT failed " + t.failed : "RESULT all passed")
            Qt.exit(t.failed)
        }
    }
    Timer {
        id: shownStep; interval: 800
        onTriggered: {
            const w = t.w
            t.check("reading mode turns on", w.view.reading)
            w.view.runJavaScript("const s = document.getElementById('velum-reader').shadowRoot; ({ text: s.textContent, heads: s.querySelectorAll('h1').length,"
                + " dirty: s.querySelectorAll('script,form,input,[onclick],[style]').length, links: [...s.querySelectorAll('a')].map(a => a.getAttribute('href')), size: getComputedStyle(s.querySelector('.page')).fontSize })", r => {
                t.check("the article is there once, with its headline", r.heads === 1 && r.text.indexOf("Başlık") >= 0 && r.text.indexOf("yeterince metin") > 0 && r.text.indexOf("article.example") > 0)
                t.check("menus, side columns and buttons are left out", ["Menü bağlantısı", "Yan sütun", "Paylaş", "window.ran"].every(x => r.text.indexOf(x) < 0))
                t.check("nothing that runs is carried over", r.dirty === 0 && r.links.filter(l => !!l).join() === "https://article.example/iyi")
                const before = w.readerSize
                w.sizeReader(2)
                w.view.runJavaScript("getComputedStyle(document.getElementById('velum-reader').shadowRoot.querySelector('.page')).fontSize", size => {
                    t.check("the letters grow", r.size === before + "px" && size === (before + 2) + "px")
                    w.sizeReader(-2)
                    w.toggleReader()
                    w.view.runJavaScript("document.getElementById('velum-reader') === null && document.documentElement.style.overflow === ''", gone => {
                        t.check("leaving restores the page", gone === true && !w.view.reading)
                        Passwords.store = []
                        w.view.loadHtml('<form onsubmit="return false"><input type="email" id="u" autocomplete="username"><input type="password" id="p"><input type="password" id="trap" style="opacity:0;width:0"><button>Gir</button></form>'
                            + '<script>window.seen = 0; document.getElementById("p").addEventListener("input", () => seen++)</scr' + 'ipt>', "https://login.example/giris")
                        formStep.start()
                    })
                })
            })
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
