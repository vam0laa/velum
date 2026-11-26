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
            w.newTab(); t.check("a new tab opens at once, on the home page", !bar.open && count() === before + 1 && w.onStartPage)
            w.closeTab(w.current); t.check("and closes again", count() === before)
            w.showCommandBox(""); bar.hide(); t.check("escaping the command box leaves no empty tab", !bar.open && count() === before)
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
            t.check("every category opens", w.prefs.section === "about" && w.prefs.sections.length === 13)
            t.check("the command box finds the settings tab", bar.find("ayarlar").some(r => r.kind === "tab"))
            w.view.url = t.page("left"); t.check("going somewhere makes it an ordinary tab", !w.onSettings)
            w.closeTab(w.current)
            // searching the settings, and the default browser button
            w.openSettings("general"); w.prefs.query = "cookie"; t.check("searching finds cards across categories", !w.prefs.nothingFound && w.prefs.shows("privacy", "cookies") && !w.prefs.shows("tabs", "sleep"))
            w.prefs.query = "zzzz"; t.check("a search with no match says so", w.prefs.nothingFound)
            w.prefs.query = ""; t.check("clearing returns to the category", w.prefs.shows("general", "x") && !w.prefs.shows("privacy", "x"))
            DefaultBrowser.make(); t.check("the default browser button works", DefaultBrowser.current)
            w.closeTab(w.current)
            // the toolbar's star and menu
            while (w.shortcuts.length) w.removeShortcut(0)
            w.openTab("https://star.example/"); w.view.url = "https://star.example/"
            t.check("the star knows an unsaved page", !w.bookmarked)
            w.toggleBookmark(); t.check("and a saved one", w.bookmarked && w.shortcuts.length === 1)
            w.toggleBookmark(); t.check("and back", !w.bookmarked)
            w.showMenu(w.contentItem); t.check("the menu opens", w.mainMenu.opened || w.mainMenu.visible); w.mainMenu.close()
            w.closeTab(w.current)
            // both layouts
            w.horizontalTabs = true; w.openTab(t.page("h1")); w.openTab(t.page("h2"))
            const top = w.current; w.moveTab(top, w.pinnedCount)
            t.check("the horizontal layout works on the same tabs", w.pageAt(w.pinnedCount).endsWith("h2") && w.view !== null)
            w.closeTab(w.current); w.closeTab(w.visibleTabs().find(i => w.pageAt(i).endsWith("h1")))
            w.horizontalTabs = false
            Theme.palette = "latte"; t.check("a light theme is known as light", !Theme.dark)
            Theme.accentChoice = "pink"; t.check("the accent can be chosen", String(Theme.accent) === String(Theme.pink))
            Theme.accentChoice = ""; Theme.palette = "lucid"; t.check("every theme has all its colours", Theme.themes.every(x => [...Array(15).keys()].every(i => String(Theme.colorOf(x.key, i)).startsWith("#"))))
            // the start page
            History.pages = [{ url: "https://a.example/1", title: "A" }, { url: "https://a.example/2", title: "A2" }, { url: "https://b.example/", title: "" }]
            w.refreshFrequent()
            t.check("most visited shows one page per site", w.frequentPages.length === 2 && w.frequentPages[1].title === "b.example")
            History.pages = []; w.refreshFrequent()
            t.check("site icon names are safe file names", w.iconName("https://www.vamola.dev/x") === "vamola.dev" && w.iconName("https://..%2f/x") === "" && w.iconName("about:blank") === "")
            w.prefs.startChanged("showNote", false); w.prefs.startChanged("startBackground", "dots")
            t.check("the start page follows the settings", !w.showNote && w.startBackground === "dots")
            w.setStart("showNote", true); w.startBackground = "glow"
            t.check("a switch adds its widget", w.showNote && w.homeWidgets.includes("note"))
            t.check("the everyday look is the default", !Theme.web && Theme.shown === "lucid" && Theme.radius > 0)
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
            t.check("typing it again goes back", Theme.secret("velum:webcore") && !Theme.web && Theme.shown === "lucid")
            Theme.palette = "lucid"
            Theme.motion = false
            Theme.change(() => Theme.palette = "nord"); t.check("with motion off colours change at once", Theme.palette === "nord")
            Theme.motion = true; Theme.palette = "lucid"
            Theme.glass = true
            t.check("glass makes the backgrounds see-through, popups stay solid", Theme.frameBack.a < 0.6 && Theme.paneBack.a < 0.6 && Theme.window.a === 1)
            Theme.glass = false; t.check("without glass they are solid", Theme.frameBack.a === 1 && Theme.sheetBack.a === 1)
            Theme.motion = false; t.check("animations can be switched off", Theme.quick === 0 && Theme.smooth === 0)
            Theme.motion = true
            // speed
            w.setPowerMode("game"); t.check("game mode stills the interface", Theme.calm && Theme.smooth === 0 && !Theme.seeThrough && w.autoSleep)
            t.check("and freezes tabs within seconds", w.freezeAfter === 5000 && w.sleepTarget(6000, 1, false, false, false) === 1)
            t.check("sound keeps playing", w.sleepTarget(6000, 1, false, true, false) === 0)
            w.setPowerMode("saver"); t.check("saver sleeps tabs quickly", w.discardAfter === 180000)
            w.setPowerMode("nonsense"); t.check("balanced again, your look untouched", w.powerMode === "balanced" && !Theme.calm && Theme.motion)
            const pile = [{ index: 1, mb: 300, since: 50 }, { index: 2, mb: 200, since: 10 }, { index: 3, mb: 500, since: 90 }]
            t.check("the longest unseen tabs go first, only as many as needed", w.pickToSleep(pile, 1400, 1000).join() === "2,1")
            t.check("nothing goes under the limit", w.pickToSleep(pile, 900, 1000).length === 0)
            w.memoryLimit = 1; w.keepUnderLimit(); t.check("the limit measures memory", w.memoryUsed >= 0); w.memoryLimit = 0
            w.openSettings("speed"); t.check("performance settings open", w.prefs.section === "speed" && !w.prefs.nothingFound)
            w.closeTab(w.current)
            // your own look
            const usualRadius = Theme.radius
            Theme.roundness = 0; t.check("corners can be square", Theme.radius === 0 && Theme.round(22) === 0)
            Theme.roundness = 1.6; t.check("or softer", Theme.radius > usualRadius)
            Theme.density = "compact"; t.check("bars can be tighter", Theme.dense(48) < 48)
            const shades = []
            for (let i = 0; i < 15; i++) shades.push(String(Theme.pick(i)))
            t.check("your own colours are kept", Theme.keepColors(shades) && Theme.themes[Theme.themes.length - 1].key === "custom")
            t.check("bad colours are refused", !Theme.keepColors(shades.map(() => "url(x)")) && !Theme.keepColors(["#fff"]))
            // the studio
            w.openStudio(); const st = w.studio, math = st.calc
            t.check("the studio opens on what is on screen", st.opened && st.colors.length === 15 && st.colors[2] === String(Theme.surface) && st.past.length === 0)
            t.check("contrast is measured", Math.round(math.contrast("#000000", "#ffffff")) === 21 && math.contrast("#777777", "#777777") === 1)
            t.check("hue and back", math.fromHsl.apply(null, math.toHsl("#3a7bd5")) === "#3a7bd5")
            const surfaceBefore = String(Theme.surface)
            st.setColor(2, "#101820"); t.check("a main colour carries the others", st.colors[2] === "#101820" && st.colors[0] !== shades[0])
            t.check("the browser does not change before applying", String(Theme.surface) === surfaceBefore)
            st.lastStep = 0; st.setColor(6, "#111111"); t.check("unreadable writing is noticed", st.hard)
            st.repair(); t.check("and repaired", !st.hard && st.readable >= 4)
            st.undo(); t.check("undo steps back", st.hard)
            st.startOver(); t.check("starting over restores the opening look", st.colors[2] === surfaceBefore)
            st.fine = true; st.setColor(6, "#abcdef"); t.check("fine tuning changes one colour", st.colors[6] === "#abcdef" && st.colors[2] === surfaceBefore)
            st.fine = false; st.setColor(2, "#123456"); st.setShape("tabShape", "pill")
            Theme.motion = false; st.apply()
            t.check("applying makes it the browser's look", Theme.shown === "custom" && String(Theme.surface) === "#123456" && Theme.tabShape === "pill")
            Theme.goBack(); t.check("and can be undone", String(Theme.surface) === surfaceBefore && Theme.previous === null)
            Theme.motion = true
            st.begin(); st.setColor(2, "#123456"); st.close(); t.check("cancelling changes nothing", String(Theme.surface) === surfaceBefore)
            Theme.keepColors(shades.map((c, i) => i === 2 ? "#123456" : c)); Theme.palette = "custom"
            Theme.keepButtons(["reload", "back", "bogus", "reload"], ["game", "back"])
            t.check("buttons are known and once", Theme.barLeft.join() === "reload,back" && Theme.barRight.join() === "game")
            Theme.moveButton("back", -1); Theme.placeButton("history", "right")
            t.check("and can be moved", Theme.barLeft.join() === "back,reload" && Theme.barRight.join() === "game,history")
            w.horizontalTabs = true
            t.check("the toolbar shows your order", w.topToolbar.shownOrder().join() === "back,reload,address,game,history,menu")
            Theme.keepButtons(["home"], ["back"]); t.check("and follows changes", w.topToolbar.shownOrder().join() === "home,address,back,menu")
            Theme.keepButtons(["back", "reload"], ["game", "history"]); w.horizontalTabs = false
            Theme.css = ".tab-active { background: #ff0000; } .toolbar { background: #00ff00 } .nope { color: red }"
            t.check("the browser style sheet is read", Theme.styled("tab-active", "background", "") === "#ff0000" && Theme.styled("toolbar", "background", "") === "#00ff00" && Theme.cssErrors.length === 1)
            w.keepWords("Paylaşılan", "tema")
            const file = "file:///tmp/x.velumtheme"
            w.exportTheme(file)
            Theme.motion = false
            Theme.resetShape(); Theme.palette = "lucid"; w.keepWords("", "")
            t.check("reset gives the usual shape back", Theme.roundness === 1 && Theme.css === "" && Theme.barLeft.length === 4)
            w.importTheme(file)
            t.check("a saved theme comes back whole", Theme.roundness === 1.6 && Theme.density === "compact" && Theme.shown === "custom" && String(Theme.surface) === "#123456"
                    && Theme.barRight.join() === "game,history" && w.homeHeadline === "Paylaşılan")
            t.check("other files are not themes", !w.applyThemeText("{}") && !w.applyThemeText("nonsense") && !Files.write("file:///tmp/x.sh", "x"))
            t.check("a hostile theme changes nothing it should not", w.applyThemeText('{"velumTheme":1,"look":{"roundness":99,"density":"x","font":"a;b<>","colors":["red"],"palette":"nope"},"home":{"widgets":["rm"],"headline":5}}')
                    && Theme.roundness === 1.6 && Theme.density === "compact" && Theme.fontFamily === "" && Theme.custom.length === 15)
            Theme.resetShape(); Theme.palette = "lucid"; w.keepWords("", ""); w.keepWidgets(["clock", "date", "calendar", "shield"]); w.homeCss = ""
            Theme.motion = true
            for (const shape of ["pill", "square", "line", "rounded"]) Theme.tabShape = shape
            w.openSettings("look"); t.check("the look settings open", w.prefs.section === "look"); w.closeTab(w.current)
            // lettering and the way back
            t.check("many letterings come along", Theme.bundled.length >= 20 && String(Theme.fontFile("Pacifico")).endsWith("pacifico.ttf") && Theme.fontFile("Arial") === "")
            const sans = Theme.ui
            Theme.fontFamily = "Lexend"; Theme.headFamily = "Monoton"; t.check("the chosen ones are used", Theme.ui !== sans && Theme.display !== Theme.ui)
            Theme.css = ".toolbar { background: #ff0000 }"; Theme.roundness = 0; Theme.palette = "nord"
            w.resetLook(); t.check("resetting the look undoes it all", Theme.ui === sans && Theme.headFamily === "" && Theme.css === "" && Theme.roundness === 1 && Theme.palette === "lucid")
            // the style sheet reaches everything
            Theme.css = ".all { color: #ff0000; font-family: Lexend }\n.card { background: #001100 }\n.primary { background: #002200 }\n.clock { color: #0000ff }\n.toggle-on, .menu, .popup, .tooltip, .notice, .nav-active { opacity: 0.9 }"
            t.check("every part is a known name", Theme.cssErrors.length === 0)
            t.check("writing everywhere follows .all", String(Theme.text) === "#ff0000" && Theme.ui === "Lexend")
            w.openTab(""); t.check("the home page listens to the browser sheet too", w.startPage.css(["clock"], "color", "") === "#0000ff")
            w.homeCss = ".clock { color: #00ff00 }"; t.check("its own sheet wins", w.startPage.css(["clock"], "color", "") === "#00ff00"); w.homeCss = ""
            w.openSettings("look"); w.closeTab(w.current)
            Theme.css = ""; t.check("clearing gives the theme back", String(Theme.text) !== "#ff0000")
            {
            // ---- fixes from the analysis ----
            const asked = []
            const fetch_ = (name, extra) => Object.assign({ downloadFileName: name, downloadDirectory: "/tmp", url: "https://files.example/" + name, view: null, state: 0, receivedBytes: 0, totalBytes: 1,
                accept: () => asked.push("accept " + name), pause: () => asked.push("pause " + name), resume: () => asked.push("resume " + name), cancel: () => asked.push("cancel " + name) }, extra ?? {})
            const had = w.downloads.length
            t.check("programs are known as risky", w.risky("a.EXE") && w.risky("x.sh ") && w.risky("y.AppImage") && !w.risky("photo.jpg") && !w.risky("exe.pdf"))
            w.startDownload(fetch_("setup.exe")); t.check("a risky download waits for an answer", w.waiting.length === 1 && asked.join() === "accept setup.exe,pause setup.exe" && w.downloads.length === had)
            w.answerDownload(false); t.check("refusing cancels it", w.waiting.length === 0 && asked[2] === "cancel setup.exe" && w.downloads.length === had)
            w.startDownload(fetch_("doc.pdf")); t.check("an ordinary file downloads straight away", w.waiting.length === 0 && w.downloads.length === had + 1)
            w.askDownloads = true; w.startDownload(fetch_("doc2.pdf")); w.answerDownload(true); t.check("or is asked about, if you wish", asked[asked.length - 1] === "resume doc2.pdf" && w.downloads.length === had + 2)
            w.askDownloads = false; w.downloads = []
            const before = count(), here = w.view
            t.check("a window nobody clicked for is not opened", w.newWindowFrom(here, false, false, () => {}) === null && count() === before)
            const question = w.asks.find(a => a.popup)
            t.check("you are asked instead", question !== undefined)
            if (question) w.answer(question, true)
            let filled = 0
            const popped = w.newWindowFrom(here, false, false, () => filled++)
            t.check("an allowed site may", popped !== null && filled === 1 && count() === before + 1 && popped.popup && !w.onStartPage)
            w.closeTab(w.current); w.popupSites = []
            const stayed = w.view, behind = w.newWindowFrom(stayed, true, true, () => {})
            t.check("a background tab stays behind", w.view === stayed && count() === before + 1)
            w.closeTab(w.tabIndexOf(behind))
            w.openTab(t.page("full")); w.enterPageFull(w.view); t.check("a page fills the screen", w.pageFullScreen)
            w.closeTab(w.current); t.check("closing that tab brings the browser back", !w.pageFullScreen && w.fullPage === null)
            Theme.applyBundle({ palette: "constructor", accent: "toString" }); t.check("odd names in a theme file are refused", Theme.palette !== "constructor" && Theme.accentChoice !== "toString" && Theme.shown !== "constructor")
            const look = w.themeText(); w.keepWords("Eski", "x"); Files.write("file:///tmp/u.velumtheme", look); w.importTheme("file:///tmp/u.velumtheme")
            t.check("a loaded theme can be undone", w.homeHeadline === "" && w.beforeImport !== ""); Theme.motion = false; w.undoImport(); t.check("which restores what you had", w.homeHeadline === "Eski" && w.beforeImport === ""); Theme.motion = true; w.keepWords("", "")
            }
            // your own shortcuts
            t.check("the usual keys", Keymap.text("newTab") === "Ctrl+T" && Keymap.sequences("reload").join() === "Ctrl+R,F5")
            t.check("a press is written as a sequence", Keymap.fromEvent(Qt.Key_Y, Qt.ControlModifier | Qt.ShiftModifier) === "Ctrl+Shift+Y" && Keymap.fromEvent(Qt.Key_F7, Qt.NoModifier) === "F7")
            t.check("plain letters and workspace keys are refused", Keymap.fromEvent(Qt.Key_Y, Qt.NoModifier) === "" && Keymap.fromEvent(Qt.Key_Y, Qt.ShiftModifier) === "" && Keymap.fromEvent(Qt.Key_2, Qt.AltModifier) === "" && Keymap.fromEvent(Qt.Key_Control, Qt.ControlModifier) === "")
            const lost = Keymap.assign("reader", "Ctrl+T")
            t.check("a taken key moves, and says from where", lost !== "" && Keymap.text("reader") === "Ctrl+T" && Keymap.sequences("newTab").length === 0)
            Keymap.reset("newTab"); t.check("resetting takes the usual key back", Keymap.text("newTab") === "Ctrl+T" && Keymap.text("reader") === "" && Keymap.changed.newTab === undefined)
            Keymap.resetAll(); t.check("everything can be reset", Keymap.text("reader") === "Alt+R")
            w.openSettings("keys"); t.check("the shortcut settings open", w.prefs.section === "keys"); w.closeTab(w.current)
            // designing the home page
            w.keepWidgets(["clock", "tasks", "timer", "tasks", "bogus"])
            t.check("widgets are kept once, known ones only", w.homeWidgets.join() === "clock,tasks,timer")
            w.openTab(""); const sheet = w.startPage
            sheet.moveWidget("timer", -1); t.check("widgets move", w.homeWidgets.join() === "clock,timer,tasks")
            sheet.setWidget("timer", false); sheet.setWidget("calendar", true); t.check("and are removed and added", w.homeWidgets.join() === "clock,tasks,calendar")
            sheet.tasksEdited([{ text: "süt al", done: false }]); t.check("tasks are kept", w.homeTasks.length === 1 && sheet.tasks[0].text === "süt al")
            sheet.wordsEdited("  Benim  ", "bir\n\n iki \n"); t.check("your own words are used", w.homeHeadline === "Benim" && w.homeWords.join() === "bir,iki")
            sheet.setTimer(10); t.check("the timer is set", sheet.timerText === "10:00" && w.homeTimer === 10)
            sheet.toggleTimer(); t.check("and runs", sheet.timerRunning); sheet.setTimer(1000); t.check("within limits", !sheet.timerRunning && w.homeTimer === 120)
            sheet.cssEdited("/* x */ .pill, .clock { color: #ff0000; font-size: 40px; border-radius: 4 }\n.widget{background:#11223344;opacity:0.5}")
            t.check("the style sheet is read", sheet.css(["pill"], "color", "") === "#ff0000" && sheet.css(["clock"], "font-size", 0) === 40 && sheet.cssErrors.length === 0)
            t.check("css colours with transparency are turned round", sheet.css(["calendar", "widget"], "background", "") === "#44112233" && sheet.css(["widget"], "opacity", 1) === 0.5)
            sheet.cssEdited(".nope { color: red } .pill { position: fixed; color: url(http://x); font-size: 9000px; background: rgb(1,2,3) }\n.clock { color: blue")
            t.check("mistakes are reported and left out", sheet.cssErrors.length >= 5 && sheet.css(["pill"], "color", "none") === "none" && sheet.css(["pill"], "background", "") === "#ff010203")
            sheet.editor.open(2); t.check("the design panel opens", sheet.editor.visible)
            sheet.editor.visible = false; sheet.cssEdited(""); w.keepWords("", ""); w.keepTasks([]); w.keepWidgets(["clock", "date", "calendar", "shield"])
            w.closeTab(w.current)
            // the welcome pages
            t.check("the welcome screen is not made until needed", w.welcome === null); w.welcomed = false; w.showWelcome()
            t.check("the welcome starts at the first page", w.welcome.step === 0)
            w.welcome.next(); w.welcome.next(); w.welcome.back(); t.check("it moves between pages", w.welcome.step === 1)
            WebStore.fetched = []
            w.welcome.step = 4; t.check("no extension is chosen for you", w.welcome.wanted.length === 0)
            w.welcome.next(); t.check("going on without a tick installs nothing", WebStore.fetched.length === 0 && w.welcome.step === 5)
            w.welcome.back(); w.welcome.wanted = ["ddkjiahejlhfcafbddmgiahcphecmpfh", "eimadpbcbfnmbkopoojfekhnkhdbieeh"]
            w.welcome.next()
            t.check("ticked extensions are fetched when you go on", WebStore.fetched.length >= 1 && WebStore.fetched[0] === "ddkjiahejlhfcafbddmgiahcphecmpfh")
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
                    WebStore.fetched = []; w.extensionQueue = []
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
        id: statusStep; interval: 2500
        onTriggered: {
            const w = t.w
            t.check("an error answer with its own page is shown, not covered", w.view.failure === null && w.view.title === "Check")
            w.view.url = "http://127.0.0.1:8766/empty"
            emptyStep.start()
        }
    }
    Timer {
        id: emptyStep; interval: 2500
        onTriggered: {
            t.check("an empty error answer is explained", t.w.view.failure !== null && t.w.view.failure.text.indexOf("404") >= 0)
            console.log(t.failed ? "RESULT failed " + t.failed : "RESULT all passed")
            Qt.exit(t.failed)
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
            // with the real engine: a window nobody clicked for, then a risky download
            t.w.asks = []; t.w.popupSites = []
            t.w.openTab("http://127.0.0.1:8766/pop")
            t.tabsBefore = t.w.tabCount
            popStep.start()
        }
    }
    property int tabsBefore: 0
    Timer {
        id: popStep; interval: 2000
        onTriggered: {
            const w = t.w
            t.check("a real page cannot open a window unasked", w.asks.some(a => a.popup) && w.tabCount === t.tabsBefore)
            w.asks = []
            w.downloadFolder = String(Qt.resolvedUrl("data")).replace("file://", "")
            w.downloads = []
            w.view.url = "http://127.0.0.1:8766/tool.sh"
            downStep.start()
        }
    }
    Timer {
        id: downStep; interval: 2500
        onTriggered: {
            const w = t.w, d = w.waiting[0]
            t.check("a real risky download is held back", w.waiting.length === 1 && d.isPaused && w.downloads.length === 0 && d.state !== WebEngineDownloadRequest.DownloadCompleted)
            w.answerDownload(true)
            gotStep.start()
        }
    }
    Timer {
        id: gotStep; interval: 2000
        onTriggered: {
            const w = t.w
            t.check("and completes once you agree", w.downloads.length === 1 && w.downloads[0].state === WebEngineDownloadRequest.DownloadCompleted && w.downloads[0].receivedBytes > 300000)
            w.downloadFolder = ""; w.downloads = []
            w.closeTab(w.current)
            w.openTab("")
            w.view.url = "http://127.0.0.1:8766/page"
            statusStep.start()
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
