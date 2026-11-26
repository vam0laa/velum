import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebChannel
import QtWebEngine

ApplicationWindow {
    id: window

    property list<string> startUrls
    property alias commandBar: commandBar
    property alias pageMenu: pageMenu
    property bool hasWidevine
    property string profileName: "velum"   // the folder logins are kept in; tests use their own
    property int current: 0
    property bool compactSidebar: false
    property bool horizontalTabs: true     // the tabs along the top instead of down the side
    // the start page, as you set it up
    property string startBackground: "plain"
    property string startPicture: ""
    // the widgets of the home page, in order
    property var homeWidgets: ["clock", "date", "calendar", "shield"]
    readonly property bool showClock: homeWidgets.includes("clock")
    readonly property bool showShield: homeWidgets.includes("shield")
    readonly property bool showNote: homeWidgets.includes("note")
    property string homeHeadline: ""
    property var homeWords: []
    property var homeTasks: []
    property string homeCss: ""
    property int homeTimer: 25
    readonly property var widgetNames: ["clock", "date", "calendar", "shield", "tasks", "timer", "note"]
    function keepWidgets(list) {
        homeWidgets = Array.from(list).filter((w, i, a) => widgetNames.includes(w) && a.indexOf(w) === i)
        saved.homeWidgets = JSON.stringify(homeWidgets)
    }
    function keepTasks(list) {
        homeTasks = list.slice(0, 12)
        saved.homeTasks = JSON.stringify(homeTasks)
    }
    function keepWords(headline, words) {
        homeHeadline = String(headline).trim().slice(0, 40)
        homeWords = String(words).split("\n").map(w => w.trim().slice(0, 40)).filter(w => w !== "").slice(0, 12)
        saved.homeWords = JSON.stringify(homeWords)
    }
    function readHome() {
        try {
            if (saved.homeWidgets !== "") {
                keepWidgets(JSON.parse(saved.homeWidgets))
            } else {
                // the three switches of earlier versions
                const was = (key, usual) => String(saved.value(key, usual)) === "true"
                const list = was("showClock", true) ? ["clock", "date", "calendar"] : []
                if (was("startNotice", true))
                    list.push("shield")
                if (was("startNote", false))
                    list.push("note")
                keepWidgets(list)
            }
        } catch (e) {
        }
        homeWords = readStrings(saved.homeWords)
        try {
            const list = JSON.parse(saved.homeTasks)
            homeTasks = Array.isArray(list) ? list.filter(t => t && typeof t.text === "string").slice(0, 12) : []
        } catch (e) {
        }
    }
    // the way out of a look gone wrong
    function resetLook() {
        Theme.resetAll()
        homeCss = ""
        say(Lang.t("Görünüm sıfırlandı.", "The look was reset."))
    }

    // ---- sharing your look ----
    function themeText() {
        return JSON.stringify({ velumTheme: 1, look: Theme.bundle(),
                                home: { widgets: homeWidgets, headline: homeHeadline, words: homeWords, css: homeCss, background: startBackground === "image" ? "" : startBackground } }, null, 1)
    }
    // true when `text` was a theme; only what is valid in it is taken over
    function applyThemeText(text) {
        let d = null
        try {
            d = JSON.parse(text)
        } catch (e) {
        }
        if (!d || d.velumTheme !== 1)
            return false
        Theme.change(() => Theme.applyBundle(d.look))
        const home = d.home ?? {}
        if (Array.isArray(home.widgets))
            keepWidgets(home.widgets)
        if (typeof home.headline === "string" && Array.isArray(home.words))
            keepWords(home.headline, home.words.map(String).join("\n"))
        if (typeof home.css === "string")
            homeCss = home.css.slice(0, 20000)
        if (["dots", "glow", "plain"].includes(home.background))
            startBackground = home.background
        return true
    }
    function exportTheme(file) {
        say(Files.write(file, themeText()) ? Lang.t("Tema kaydedildi.", "The theme was saved.") : Lang.t("Tema kaydedilemedi.", "The theme could not be saved."))
    }
    function importTheme(file) {
        say(applyThemeText(Files.read(file)) ? Lang.t("Tema yüklendi.", "The theme was loaded.") : Lang.t("Bu dosya bir Velum teması değil.", "This file is not a Velum theme."))
    }

    // a switch in the settings
    function setStart(name, value) {
        const widget = { showClock: "clock", showShield: "shield", showNote: "note" }[name]
        if (!widget) {
            window[name] = value
            return
        }
        const list = homeWidgets.filter(w => w !== widget)
        keepWidgets(value ? list.concat([widget]) : list)
    }
    property bool showFrequent: false
    property string note: ""
    property var frequentPages: []
    property string iconFolder: ""          // "" keeps no site icons
    property int iconRevision: 0
    property var iconsSaved: ({})       // this run: site -> the icon last written
    property var iconNames: []          // sites that have an icon on disk
    property bool showBookmarkBar: true
    property alias mainMenu: mainMenu
    property alias startPage: start
    property alias topToolbar: topBar
    // tiling desktops draw no title bar; Windows does, with its own buttons
    readonly property bool ownButtons: Qt.platform.os !== "windows"
    readonly property bool bookmarked: view !== null && shortcuts.some(s => s.url === String(view.url))
    function showMenu(at) {
        const place = at.mapToItem(null, at.width - mainMenu.width, at.height + 6)
        mainMenu.popup(Math.max(8, place.x), Math.max(8, Math.min(place.y, height - mainMenu.implicitHeight - 8)))
    }
    property bool greet: false              // show the welcome pages if they were never seen
    property bool welcomed: false
    property var welcome: null          // made when first shown
    function showWelcome() {
        if (!welcome)
            welcome = welcomeScreen.createObject(scene)
        welcome.open()
    }
    readonly property Item prefs: prefsLoader.item
    property var extensions: []             // the installed ones
    property bool fetchingExtension: false
    property var wantedExtension: null      // waiting for your yes: { text, file }
    property alias extensionQuestion: extensionDialog
    readonly property bool onSettings: view !== null && view.kind === "settings"
    property bool pageFullScreen: false
    property int moves: 0             // counts reorderings, so that "view" is looked up again
    property int pinnedCount: 0
    property var closedTabs: []       // for "reopen closed tab", newest last
    // workspaces: separate sets of tabs. Pinned tabs and logins are shared by all of them.
    property var spaces: [{ id: 1, name: "" }]     // an empty name reads "General"
    property int space: 1             // the workspace being looked at
    property var lastInSpace: ({})    // the page each workspace was left on
    // the bookmarks, in order: [{ title, url, folder }]. The first ten are on the start page.
    property var shortcuts: []
    property alias bookmarks: bookmarksPage
    property int sleepMode: 1                    // 0 never, 1 early, 2 relaxed
    // "balanced", "game" (background tabs stand still, nothing moves) or "saver"
    property string powerMode: "balanced"
    readonly property bool autoSleep: sleepMode > 0 || powerMode !== "balanced"
    readonly property int freezeAfter: powerMode === "game" ? 5000 : powerMode === "saver" ? 30000
        : (sleepMode === 2 ? 5 : 2) * 60 * 1000      // milliseconds unseen
    readonly property int discardAfter: powerMode === "game" ? 5 * 60 * 1000 : powerMode === "saver" ? 3 * 60 * 1000
        : (sleepMode === 2 ? 20 : 10) * 60 * 1000
    property int memoryLimit: 0           // megabytes Velum should stay under; 0: no limit
    property int memoryUsed: 0            // megabytes, as last measured for the limit
    Binding { target: Theme; property: "calm"; value: window.powerMode !== "balanced" }
    function setPowerMode(mode) {
        powerMode = ["game", "saver"].includes(mode) ? mode : "balanced"
        say(powerMode === "game" ? Lang.t("Oyun modu: arka sekmeler birkaç saniyede donar.", "Game mode: background tabs freeze within seconds.")
          : powerMode === "saver" ? Lang.t("Tasarruf modu: arka sekmeler çabuk uyur.", "Saver mode: background tabs sleep quickly.")
          : Lang.t("Dengeli mod.", "Balanced mode."))
    }

    // Which tabs to put away so that `used` comes down to `limit`: the ones unseen the
    // longest first. `candidates`: [{ index, mb, since }].
    function pickToSleep(candidates, used, limit) {
        const chosen = []
        for (const c of candidates.slice().sort((a, b) => a.since - b.since)) {
            if (used <= limit)
                break
            chosen.push(c.index)
            used -= c.mb
        }
        return chosen
    }
    function keepUnderLimit() {
        const pages = []
        for (let i = 0; i < tabs.count; i++)
            pages.push(views.itemAt(i) as WebEngineView)
        const pids = pages.map(p => p && p.lifecycleState !== WebEngineView.LifecycleState.Discarded ? p.renderProcessPid : 0)
        const found = Resources.sample(pids)
        memoryUsed = Math.round(found.total.memory)
        if (memoryLimit <= 0 || memoryUsed <= memoryLimit)
            return
        const candidates = []
        pages.forEach((page, i) => {
            if (!page || page.visible || page === miniPage || page.hiddenSince === 0 || pids[i] <= 0 || tabs.get(i).pinned || page.recentlyAudible
                    || page.loading || page.recommendedState === WebEngineView.LifecycleState.Active)
                return
            // tabs of one site may share a process: each counts its part
            const sharing = pids.filter(p => p === pids[i]).length
            candidates.push({ index: i, mb: (found[String(pids[i])]?.memory ?? 0) / sharing, since: page.hiddenSince })
        })
        for (const i of pickToSleep(candidates, memoryUsed, memoryLimit))
            (views.itemAt(i) as WebEngineView).lifecycleState = WebEngineView.LifecycleState.Discarded
    }
    Timer { interval: 20000; repeat: true; running: window.memoryLimit > 0; triggeredOnStart: true; onTriggered: window.keepUnderLimit() }
    property bool restoreSession: true
    property string downloadFolder: ""   // "" = the system downloads folder
    // split view: two pages side by side. The pair is remembered as the pages themselves,
    // so moving tabs around does not disturb it.
    property WebEngineView splitLeft: null
    property WebEngineView splitRight: null
    property real splitRatio: 0.5
    readonly property bool splitShown: moves >= 0 && !pageFullScreen && splitLeft !== null && splitRight !== null && view !== null
                                       && (view === splitLeft || view === splitRight) && inSpace(splitLeft.index) && inSpace(splitRight.index)
    property var downloads: []        // download requests of this run, newest first
    property alias mini: miniPlayer
    readonly property WebEngineView miniPage: miniPlayer.page   // the tab in the small window
    property string notice: ""        // a short message over the page
    property int readerSize: 18       // letter size in reading mode
    property var passwordOffer: null  // a login waiting for "save?": { origin, user, password, changed }
    property var neverSave: []        // sites you do not want to be asked on
    property var asks: []             // unanswered permission requests: [{ page, permission, site, wish }]
    // the question for the page being looked at, if it has one
    readonly property var ask: asks.find(a => a.page === view) ?? null
    // the page of the current tab; "views.count" and "moves" make this update when tabs change
    readonly property WebEngineView view: (moves, views.count > 0) ? views.itemAt(current) as WebEngineView : null
    readonly property bool onStartPage: view !== null && !onSettings && (view.url.toString() === "" || view.url.toString() === "about:blank") && !view.loading

    width: 1280
    height: 800
    visible: true
    color: Theme.frameBack
    font.family: Theme.ui
    title: view && view.title !== "" && !onStartPage ? view.title + " - Velum" : "Velum"

    // Cookies and logins are kept on this computer, in Velum's own folder.
    WebEngineProfilePrototype {
        id: prototype
        storageName: window.profileName
        persistentCookiesPolicy: Shield.forgettingThisRun ? WebEngineProfile.NoPersistentCookies : WebEngineProfile.AllowPersistentCookies
        // an answer to "may this site use the camera?" lasts until Velum is closed
        persistentPermissionsPolicy: WebEngineProfile.StoreInMemory
    }
    property WebEngineProfile profile

    Component.onCompleted: {
        profile = prototype.instance()
        Shield.attach(profile)          // every request now passes through the shield
        profile.downloadRequested.connect(startDownload)
        profile.presentNotification.connect(n => Notifier.show(n))
        Notifier.activated.connect(() => { window.show(); window.raise(); window.requestActivate() })
        // Present Velum as the Chrome engine it is. Some sites refuse names they do not know.
        profile.httpUserAgent = profile.httpUserAgent.replace(/QtWebEngine\/\S+\s/, "")
        shortcuts = readList(saved.shortcuts)
        readHome()
        neverSave = readStrings(saved.neverSave)
        iconNames = readStrings(saved.iconNames)
        watchLogins()
        const manager = profile.extensionManager
        manager.installFinished.connect(extensionInstalled)
        manager.uninstallFinished.connect(() => Qt.callLater(refreshExtensions))
        manager.loadFinished.connect(() => Qt.callLater(refreshExtensions))
        refreshExtensions()
        spaces = readSpaces(saved.spaces)
        if (!spaces.some(s => s.id === space))
            space = spaces[0].id
        // pinned tabs come back first, then what was asked for on the command line
        // Restored tabs are "lazy": they load when first looked at.
        current = -1            // nothing is shown, and so nothing loads, until the tab is chosen
        const pins = readList(saved.pinned)
        for (const p of pins) {
            appendTab(p.url, p.title ?? "", true)
            tabs.setProperty(tabs.count - 1, "pinned", true)
            pinnedCount++
        }
        let chosen = -1
        if (restoreSession && !Shield.forgettingThisRun) {
            const session = readSession(saved.session)
            for (const p of session.tabs)
                appendTab(p.url, p.title ?? "", true, spaces.some(s => s.id === p.space) ? p.space : spaces[0].id)
            if (session.tabs.length > 0)
                chosen = Math.max(0, Math.min(session.current, tabs.count - 1))
        }
        if (startUrls.length > 0) {
            chosen = tabs.count
            for (const u of startUrls)
                appendTab(u, "", false)
        }
        if (chosen < 0) {
            chosen = tabs.count
            appendTab("", "", false)
        }
        current = chosen
        restored = true
        followCurrent()
        refreshFrequent()
        // the chosen tab was already visible or hidden before "current" settled
        Qt.callLater(() => view?.load_())
        if (greet && !welcomed)
            Qt.callLater(showWelcome)
    }

    function readSession(text) {
        try {
            const s = JSON.parse(text)
            const list = readList(JSON.stringify(s.tabs ?? []))
            return { tabs: list.slice(0, 200), current: Number.isInteger(s.current) ? s.current : 0 }
        } catch (e) {
            return { tabs: [], current: 0 }
        }
    }

    // Writes down the open tabs, a moment after they last changed.
    function saveSession() {
        if (!restored)
            return
        const list = []
        let at = 0
        for (let i = 0; i < tabs.count; i++) {
            const tab = tabs.get(i)
            if (i === current)
                at = pinnedCount + list.length
            if (!tab.pinned && tab.pageUrl !== "" && tab.pageUrl !== "about:blank")
                list.push({ url: tab.pageUrl, title: tab.title, space: tab.space })
            if (i === current && tab.pinned)
                at = i
        }
        saved.session = JSON.stringify({ tabs: list, current: at })
    }

    Timer { id: sessionTimer; interval: 800; onTriggered: window.saveSession() }
    function touchSession() { sessionTimer.restart() }
    onCurrentChanged: { followCurrent(); touchSession() }
    onMovesChanged: touchSession()
    onClosing: { closeMini(); saveSession() }

    // addresses handed over by a second start of Velum
    function openExternal(urls) {
        for (const u of urls)
            openTab(u)
        show()
        raise()
        requestActivate()
    }

    property bool restored: false

    // the address of the tab at `index`, or null when there is none
    function pageAt(index) { return index >= 0 && index < tabs.count ? tabs.get(index).pageUrl : null }

    function readList(text) {
        try {
            const list = JSON.parse(text)
            return Array.isArray(list) ? list.filter(x => x && typeof x.url === "string" && x.url !== "") : []
        } catch (e) {
            return []
        }
    }

    function savePinned() {
        if (!restored)
            return
        const list = []
        for (let i = 0; i < pinnedCount; i++)
            list.push({ url: tabs.get(i).pageUrl, title: tabs.get(i).title })
        saved.pinned = JSON.stringify(list)
    }

    // remembered between starts
    Settings {
        id: saved
        property string pinned: "[]"
        property string shortcuts: "[]"
        property string session: "{}"
        property alias restoreSession: window.restoreSession
        property alias downloadFolder: window.downloadFolder
        property alias sleepMode: window.sleepMode
        property alias powerMode: window.powerMode
        property alias memoryLimit: window.memoryLimit
        property alias compactSidebar: window.compactSidebar
        property alias tabsOnTop: window.horizontalTabs
        property alias startBack: window.startBackground
        property alias startPicture: window.startPicture
        property alias startVisited: window.showFrequent
        property alias note: window.note
        property string homeWidgets: ""
        property alias homeHeadline: window.homeHeadline
        property string homeWords: "[]"
        property string homeTasks: "[]"
        property alias homeCss: window.homeCss
        property alias homeTimer: window.homeTimer
        property alias bookmarkBar: window.showBookmarkBar
        property alias welcomed: window.welcomed
        property alias readerSize: window.readerSize
        property string neverSave: "[]"
        property string iconNames: "[]"
        property string spaces: "[]"
        property alias space: window.space
        property alias width: window.width
        property alias height: window.height
    }

    ListModel { id: tabs }

    readonly property string currentHost: view ? hostOf(view.url) : ""
    function hostOf(url) {
        const match = String(url).match(/^https?:\/\/(?:[^\/@]*@)?([^\/:?#]+)/i)
        return match ? match[1].toLowerCase() : ""
    }

    // Adds a tab after the others, in this workspace unless another is named.
    function appendTab(url, title, lazy, inWorkspace) {
        tabs.append({ startUrl: String(url), lazy: lazy === true, pageUrl: String(url), title: String(title ?? ""), siteIcon: "", loading: false, pinned: false, asleep: 0, space: inWorkspace ?? space, kind: "" })
        touchSession()
    }

    // Adds a tab, switches to it and returns its page.
    function openTab(url) {
        appendTab(url, "", false)
        current = tabs.count - 1
        if (String(url) === "")
            Qt.callLater(() => start.field?.forceActiveFocus())
        return views.itemAt(current) as WebEngineView
    }

    function closeTab(index) {
        if (index < 0 || index >= tabs.count)
            return
        const closing = views.itemAt(index) as WebEngineView
        if (closing && closing === miniPage)
            closeMini()
        if (closing && (closing === splitLeft || closing === splitRight))
            unsplit()
        const tab = tabs.get(index)
        const wasPinned = tab.pinned
        const wasCurrent = index === current
        if (tab.pageUrl !== "" && tab.pageUrl !== "about:blank")
            closedTabs = closedTabs.concat([{ url: tab.pageUrl, index: index, space: tab.space }]).slice(-25)
        // a workspace always shows one tab; closing its last one empties it
        if (inSpace(index) && neighbourOf(index) < 0)
            openTab("")
        const pick = wasCurrent ? neighbourOf(index) : current
        const next = pick > index ? pick - 1 : pick
        if (wasPinned)
            pinnedCount--
        tabs.remove(index)
        current = next
        moves++
        touchSession()
        if (wasPinned)
            savePinned()
    }

    function reopenClosed() {
        if (closedTabs.length === 0)
            return
        const last = closedTabs[closedTabs.length - 1]
        closedTabs = closedTabs.slice(0, -1)
        if (spaces.some(s => s.id === last.space))
            space = last.space
        openTab(last.url)
        moveTab(current, last.index)
    }

    // Moves a tab, keeping pinned tabs above the others and the same page selected.
    function moveTab(from, to) {
        if (from < 0 || from >= tabs.count)
            return
        const pinned = tabs.get(from).pinned
        to = pinned ? Math.max(0, Math.min(to, pinnedCount - 1)) : Math.max(pinnedCount, Math.min(to, tabs.count - 1))
        if (to === from)
            return
        let next = current
        if (current === from)
            next = to
        else if (from < current && current <= to)
            next = current - 1
        else if (to <= current && current < from)
            next = current + 1
        tabs.move(from, to, 1)
        current = next
        moves++
        if (pinned)
            savePinned()
    }

    function togglePin(index) {
        if (index < 0 || index >= tabs.count)
            return
        if (tabs.get(index).pinned) {
            // becomes the first of the ordinary tabs
            const target = pinnedCount - 1
            moveTab(index, target)
            tabs.setProperty(target, "space", space)     // it stays where you can see it
            tabs.setProperty(target, "pinned", false)
            pinnedCount--
        } else {
            const url = tabs.get(index).pageUrl
            if (url === "" || url === "about:blank")
                return
            const target = pinnedCount
            moveTab(index, target)
            tabs.setProperty(target, "pinned", true)
            pinnedCount++
        }
        savePinned()
    }

    function closeOthers(index) {
        for (let i = tabs.count - 1; i >= 0; i--) {
            if (i !== index && !tabs.get(i).pinned && inSpace(i)) {
                closeTab(i)
                if (i < index)
                    index--
            }
        }
        current = index
        moves++
    }

    function addShortcut(typed, title) {
        const url = String(Address.resolve(typed))
        if (url === "" || url === "about:blank" || Address.isSearch(typed) || shortcuts.some(s => s.url === url) || shortcuts.length >= maxBookmarks)
            return false
        const name = title || Address.display(url).replace(/^(https?:\/\/)?(www\.)?/, "").split("/")[0]
        keepBookmarks(shortcuts.concat([{ title: name, url: url }]))
        return true
    }

    readonly property int maxBookmarks: 2000
    function keepBookmarks(list) {
        shortcuts = list
        saved.shortcuts = JSON.stringify(list)
    }

    // From the manager: index -1 adds. False when the address cannot be used.
    function saveBookmark(index, title, address, folder) {
        const url = String(Address.resolve(address))
        if (url === "" || url === "about:blank" || Address.isSearch(address) || shortcuts.some((s, i) => s.url === url && i !== index))
            return false
        if (index < 0 ? shortcuts.length >= maxBookmarks : index >= shortcuts.length)
            return false
        const item = { title: String(title).trim() || Address.display(url).replace(/^(https?:\/\/)?(www\.)?/, "").split("/")[0], url: url }
        if (String(folder).trim() !== "")
            item.folder = String(folder).trim()
        const list = shortcuts.slice()
        if (index < 0)
            list.push(item)
        else
            list[index] = item
        keepBookmarks(list)
        return true
    }

    function restoreBookmark(item, index) {
        if (shortcuts.some(s => s.url === item.url))
            return
        const list = shortcuts.slice()
        list.splice(Math.max(0, Math.min(index, list.length)), 0, item)
        keepBookmarks(list)
    }

    // the two change places
    function moveBookmark(from, to) {
        if (from === to || !shortcuts[from] || !shortcuts[to])
            return
        const list = shortcuts.slice()
        list[from] = shortcuts[to]
        list[to] = shortcuts[from]
        keepBookmarks(list)
    }

    // an empty new name puts the bookmarks outside any folder
    function renameFolder(from, to) {
        keepBookmarks(shortcuts.map(s => {
            if ((s.folder ?? "") !== from)
                return s
            return to.trim() === "" ? { title: s.title, url: s.url } : { title: s.title, url: s.url, folder: to.trim() }
        }))
    }

    // the home button: an empty tab becomes the start page again
    function goHome() {
        if (onStartPage)
            return
        const at = visibleTabs().find(i => tabs.get(i).kind === "" && (tabs.get(i).pageUrl === "" || tabs.get(i).pageUrl === "about:blank"))
        if (at === undefined)
            openTab("")
        else
            current = at
    }

    function openBookmarks() { bookmarksPage.open() }
    function openImport() { importPanel.open() }
    function openPasswords() { openSettings("passwords") }
    function openDownloads() { (horizontalTabs ? topBar : side).openDownloads() }

    // Takes bookmarks (and history) of another browser. Returns the sentence to show.
    function importFrom(path, withHistory) {
        const data = Importer.read(path, withHistory)
        const known = new Set(shortcuts.map(s => s.url))
        const list = shortcuts.slice()
        for (const b of data.bookmarks) {
            const url = String(b.url)
            if (list.length >= maxBookmarks || known.has(url))
                continue
            known.add(url)
            const item = { title: b.title || hostOf(url) || url, url: url }
            if (b.folder)
                item.folder = b.folder
            list.push(item)
        }
        const added = list.length - shortcuts.length
        if (added > 0)
            keepBookmarks(list)
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
        if (onStartPage || onSettings)
            return
        const url = String(view.url)
        const at = shortcuts.findIndex(s => s.url === url)
        if (at >= 0)
            removeShortcut(at)
        else
            addShortcut(url, view.title)
    }

    function startDownload(request) {
        if (downloadFolder !== "")
            request.downloadDirectory = downloadFolder
        request.accept()            // saved into your downloads folder, never opened
        downloads = [request].concat(downloads)
        openDownloads()
        // a tab that was opened only to fetch the file is closed again
        for (let i = tabs.count - 1; i >= 0 && tabs.count > 1; i--) {
            const page = views.itemAt(i) as WebEngineView
            if (page && page === view && tabs.get(i).pageUrl === "" && tabs.get(i).kind === "")
                closeTab(i)
        }
    }

    // ---- workspaces ----
    function inSpace(index) {
        const tab = index >= 0 && index < tabs.count ? tabs.get(index) : null
        const here = space
        return tab !== null && (tab.pinned || tab.space === here)
    }

    // the tabs listed in the side bar, as numbers
    function visibleTabs() {
        const out = []
        for (let i = 0; i < tabs.count; i++)
            if (inSpace(i))
                out.push(i)
        return out
    }

    // the nearest other tab of this workspace: the one below, else the one above, else -1
    function neighbourOf(index) {
        const list = visibleTabs().filter(i => i !== index)
        return list.find(i => i > index) ?? list[list.length - 1] ?? -1
    }

    // choosing a tab of another workspace (from the command box, say) goes there
    function followCurrent() {
        if (restored && current >= 0 && current < tabs.count && !inSpace(current))
            space = tabs.get(current).space
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
        spaces = list
        saved.spaces = JSON.stringify(list)
    }

    function switchSpace(id) {
        if (id === space || !spaces.some(s => s.id === id))
            return
        // a pinned tab is everywhere, so it is not what a workspace "was left on"
        lastInSpace[space] = current >= pinnedCount ? view : null
        const left = lastInSpace[id]
        space = id
        let target = -1
        for (let i = 0; i < tabs.count; i++) {
            if (left && views.itemAt(i) === left && inSpace(i)) {
                target = i
                break
            }
            if (target < 0 && !tabs.get(i).pinned && tabs.get(i).space === id)
                target = i
        }
        if (target < 0)
            openTab("")
        else
            current = target
        touchSession()
    }

    function addSpace(name) {
        name = String(name).trim().slice(0, 20)
        if (name === "" || spaces.length >= 6)
            return 0
        const id = Math.max(...spaces.map(s => s.id)) + 1
        keepSpaces(spaces.concat([{ id: id, name: name }]))
        switchSpace(id)
        return id
    }

    function renameSpace(id, name) {
        name = String(name).trim().slice(0, 20)
        if (name !== "")
            keepSpaces(spaces.map(s => s.id === id ? { id: id, name: name } : s))
    }

    // Deleting a workspace keeps its pages: they move to another one.
    function removeSpace(id) {
        const home = spaces.find(s => s.id !== id)
        if (!home || !spaces.some(s => s.id === id))
            return
        if (space === id)
            switchSpace(home.id)
        for (let i = tabs.count - 1; i >= 0; i--) {
            const tab = tabs.get(i)
            if (tab.space !== id)
                continue
            if (!tab.pinned && (tab.pageUrl === "" || tab.pageUrl === "about:blank"))
                closeTab(i)
            else
                tabs.setProperty(i, "space", home.id)
        }
        keepSpaces(spaces.filter(s => s.id !== id))
        moves++
        touchSession()
    }

    function moveToSpace(index, id) {
        if (index < 0 || index >= tabs.count || tabs.get(index).pinned || tabs.get(index).space === id || !spaces.some(s => s.id === id))
            return
        const page = views.itemAt(index) as WebEngineView
        if (page === splitLeft || page === splitRight)
            unsplit()
        const wasCurrent = index === current
        if (wasCurrent && neighbourOf(index) < 0)
            openTab("")
        const pick = wasCurrent ? neighbourOf(index) : current
        tabs.setProperty(index, "space", id)
        current = pick
        moves++
        touchSession()
    }

    // ---- sleeping tabs ----
    // How far a tab that has not been seen for `idle` ms may be put to sleep:
    // `advice` is what the engine says is safe (it knows about sound, downloads, open connections).
    function sleepTarget(idle, advice, pinned, audible, loading) {
        if (pinned || audible || loading)
            return WebEngineView.LifecycleState.Active
        if (idle >= discardAfter && advice === WebEngineView.LifecycleState.Discarded)
            return WebEngineView.LifecycleState.Discarded
        if (idle >= freezeAfter && advice !== WebEngineView.LifecycleState.Active)
            return WebEngineView.LifecycleState.Frozen
        return WebEngineView.LifecycleState.Active
    }

    function sleepIdleTabs(now) {
        for (let i = 0; i < tabs.count; i++) {
            const page = views.itemAt(i) as WebEngineView
            if (!page || page === view || page.hiddenSince === 0)
                continue
            const target = sleepTarget(now - page.hiddenSince, page.recommendedState, tabs.get(i).pinned, page.recentlyAudible, page.loading)
            if (target > page.lifecycleState)        // only ever deeper; looking at it wakes it
                page.lifecycleState = target
        }
    }

    function pageViewAt(index) { return views.itemAt(index) as WebEngineView }
    function tabIndexOf(page) {
        for (let i = 0; i < tabs.count; i++)
            if (views.itemAt(i) === page)
                return i
        return -1
    }

    // ---- split view ----
    // Puts the tab at `index` beside the current one.
    function splitWith(index) {
        const other = views.itemAt(index) as WebEngineView
        if (!other || !view || other === view || other === miniPage || view === miniPage)
            return false
        const here = view
        splitLeft = here
        splitRight = other
        return true
    }

    function unsplit() {
        splitLeft = null
        splitRight = null
    }

    // Ctrl+\: splits with the neighbouring tab (or a new one), or ends the split.
    function toggleSplit() {
        if (splitShown) {
            unsplit()
            return
        }
        const here = current
        const others = visibleTabs().filter(i => i !== here)
        let other = others.filter(i => i < here).pop() ?? others[0]
        if (other === undefined) {
            openTab("")
            other = current
            current = here
        }
        splitWith(other)
    }

    // ---- the small video window ----
    // Alt+P and the title bar button: take the video out, or bring it back.
    function toggleMini() {
        if (miniPage)
            closeMini()
        else
            openMini(current)
    }

    function openMini(index) {
        const page = views.itemAt(index) as WebEngineView
        if (!page || page === miniPage)
            return
        closeMini()
        const missing = () => say(Lang.t("Bu sayfada küçük pencereye alınacak bir video yok.", "There is no video on this page to take out."))
        if (page.url.toString() === "" || page.lifecycleState !== WebEngineView.LifecycleState.Active) {
            missing()
            return
        }
        page.runJavaScript(miniPlayer.enterScript, found => {
            if (!found) {
                missing()
                return
            }
            closeReader(page)
            if (page === splitLeft || page === splitRight)
                unsplit()
            miniPlayer.paused = found.paused === true
            miniPlayer.height = Math.max(135, Math.min(720, Math.round(miniPlayer.width * found.height / found.width)))
            miniPlayer.page = page
            page.parent = miniPlayer.stage
            miniPlayer.show()
        })
    }

    function closeMini() {
        const page = miniPlayer.page
        if (!page)
            return
        page.runJavaScript(miniPlayer.leaveScript)
        page.parent = pagesArea
        miniPlayer.page = null
        miniPlayer.hide()
    }

    // ---- reading mode ----
    function toggleReader() {
        const page = view
        if (!page || onStartPage || page === miniPage)
            return
        if (page.reading) {
            closeReader(page)
            return
        }
        const color = c => String(c)
        const look = { size: readerSize, dark: Theme.dark, minutes: Lang.t("dk okuma", "min read"),
                       colors: { back: color(Theme.surface), text: color(Theme.text), dim: color(Theme.dim), accent: color(Theme.accent), card: color(Theme.frame), line: color(Theme.line) } }
        page.runJavaScript(reader.enter(look), WebEngineScript.ApplicationWorld, found => {
            if (found === true)
                page.reading = true
            else
                say(Lang.t("Bu sayfada okunacak bir yazı bulunamadı.", "There is no article to read on this page."))
        })
    }

    function closeReader(page) {
        if (!page || !page.reading)
            return
        page.reading = false
        page.runJavaScript(reader.leave, WebEngineScript.ApplicationWorld)
    }

    function sizeReader(by) {
        readerSize = Math.max(14, Math.min(28, readerSize + by))
        view?.runJavaScript(reader.resize(readerSize), WebEngineScript.ApplicationWorld)
    }

    Reader { id: reader }

    // ---- passwords ----
    LoginScript { id: login }
    property alias loginScript: login

    // every page gets the watcher, in the separate world only Velum's code runs in
    function watchLogins() {
        const channel = WebEngine.script()
        channel.name = "velum-channel"
        channel.sourceUrl = "qrc:///qtwebchannel/qwebchannel.js"
        channel.injectionPoint = WebEngineScript.DocumentCreation
        channel.worldId = WebEngineScript.ApplicationWorld
        const watch = WebEngine.script()
        watch.name = "velum-login"
        watch.sourceCode = login.watch
        watch.injectionPoint = WebEngineScript.DocumentReady
        watch.worldId = WebEngineScript.ApplicationWorld
        profile.userScripts.collection = [channel, watch]
    }

    function readStrings(text) {
        try {
            const list = JSON.parse(text)
            return Array.isArray(list) ? list.filter(x => typeof x === "string") : []
        } catch (e) {
            return []
        }
    }

    // a login was sent: ask whether to keep it
    function offerPassword(origin, user, password) {
        if (origin === "" || Passwords.origin(origin) !== origin || password === "" || neverSave.includes(origin))
            return
        Passwords.check(origin, user, password, state => {
            if (state === "new" || state === "changed")
                passwordOffer = { origin: origin, user: user, password: password, changed: state === "changed" }
        })
    }

    function savePassword(user) {
        const offer = passwordOffer
        if (!offer)
            return
        passwordOffer = null
        Passwords.save(offer.origin, user, offer.password, ok => {
            say(ok ? Lang.t("Parola anahtarlığa kaydedildi.", "The password is in the keyring.")
                   : Lang.t("Parola kaydedilemedi. Anahtarlığın kilidi açık mı?", "The password could not be saved. Is the keyring unlocked?"))
            for (let i = 0; i < tabs.count; i++)
                findAccounts(pageViewAt(i))
        })
    }

    function neverFor(origin) {
        passwordOffer = null
        if (!neverSave.includes(origin)) {
            neverSave = neverSave.concat([origin])
            saved.neverSave = JSON.stringify(neverSave)
        }
    }

    function askAgainFor(origin) {
        neverSave = neverSave.filter(o => o !== origin)
        saved.neverSave = JSON.stringify(neverSave)
    }

    // which saved logins fit the form on this page, if it has one
    function findAccounts(page) {
        if (!page || page.loginOrigin === "") {
            if (page)
                page.accounts = []
            return
        }
        const origin = page.loginOrigin
        Passwords.accounts(origin, found => {
            if (page.loginOrigin === origin)
                page.accounts = found ?? []
        })
    }

    // Ctrl+Shift+L and the title bar button; with several accounts you pick one
    function fillPassword() {
        const page = view
        if (!page || page.accounts.length === 0) {
            say(Lang.t("Bu sayfa için kayıtlı parola ya da giriş formu yok.", "No saved password or login form for this page."))
            return
        }
        if (page.accounts.length === 1)
            fillAccount(page, page.accounts[0].user)
        else
            accountMenu.popup(window.width - accountMenu.width - 20, window.horizontalTabs ? topBar.height + 40 : 40)
    }

    function fillAccount(page, user) {
        const origin = page.loginOrigin
        // the address bar's page and the form's page must be the same site
        if (origin === "" || Passwords.origin(page.url) !== origin)
            return
        Passwords.password(origin, user, secret => {
            if (secret === null) {
                say(Lang.t("Parola anahtarlıktan okunamadı.", "The password could not be read from the keyring."))
                return
            }
            page.runJavaScript(login.fill(origin, user, secret), WebEngineScript.ApplicationWorld, done => {
                if (done !== true)
                    say(Lang.t("Doldurulacak giriş formu bulunamadı.", "No login form to fill was found."))
            })
        })
    }

    // ---- extensions ----
    function refreshExtensions() {
        const all = profile.extensionManager.extensions
        const out = []
        for (let i = 0; i < all.length; i++)
            if (all[i].isInstalled)          // the engine's own built-in ones are not listed
                out.push(all[i])
        extensions = out
    }

    // nothing is fetched or installed before you agree
    function askExtension(text, file) {
        if (!file && WebStore.idFrom(text) === "") {
            say(Lang.t("Bu bir Web Store adresi ya da eklenti kimliği değil.", "That is not a Web Store address or an extension id."))
            return
        }
        wantedExtension = { text: String(text), file: file === true }
        extensionDialog.open()
    }

    function addExtension() {
        const wanted = wantedExtension
        wantedExtension = null
        if (!wanted)
            return
        if (wanted.file) {
            profile.extensionManager.installExtension(wanted.text)
            return
        }
        fetchingExtension = true
        say(Lang.t("Eklenti indiriliyor…", "Fetching the extension…"))
        WebStore.fetch(wanted.text, (path, problem) => {
            fetchingExtension = false
            if (path !== "") {
                fetched = path
                profile.extensionManager.installExtension(path)
            } else if (problem === "signature") {
                say(Lang.t("Paketin imzası doğrulanamadı; kurulmadı.", "The package's signature did not check out; it was not installed."))
            } else {
                say(Lang.t("Eklenti indirilemedi.", "The extension could not be fetched."))
            }
            if (path === "")
                Qt.callLater(installNext)
        })
    }
    property string fetched: ""       // the downloaded package being installed
    property var extensionQueue: []   // store ids you agreed to, still to be installed

    // one after another; each one was ticked by you
    function queueExtensions(ids) {
        extensionQueue = extensionQueue.concat(Array.from(ids).filter(id => WebStore.idFrom(id) !== "" && !extensionQueue.includes(id)))
        installNext()
    }
    function installNext() {
        if (fetchingExtension || fetched !== "" || extensionQueue.length === 0)
            return
        const id = extensionQueue[0]
        extensionQueue = extensionQueue.slice(1)
        wantedExtension = { text: id, file: false }
        addExtension()
    }

    function extensionInstalled(extension) {
        if (fetched !== "") {
            WebStore.discard(fetched)
            fetched = ""
        }
        if (extension.error !== "") {
            say(Lang.t("Eklenti kurulamadı: ", "The extension could not be installed: ") + extension.error)
        } else {
            profile.extensionManager.setExtensionEnabled(extension, true)
            say(Lang.t(extension.name + " eklendi.", extension.name + " was added."))
        }
        Qt.callLater(refreshExtensions)
        Qt.callLater(installNext)
    }

    function enableExtension(extension, on) {
        profile.extensionManager.setExtensionEnabled(extension, on)
        Qt.callLater(refreshExtensions)
    }
    function removeExtension(extension) { profile.extensionManager.uninstallExtension(extension) }

    // ---- the start page ----
    // one page per site, the most visited first
    function refreshFrequent() {
        const seen = new Set(), out = []
        for (const p of History.frequent(60)) {
            const host = hostOf(p.url)
            if (host === "" || seen.has(host))
                continue
            seen.add(host)
            out.push({ url: p.url, title: p.title || host })
            if (out.length === 6)
                break
        }
        frequentPages = out
    }
    onOnStartPageChanged: if (onStartPage) refreshFrequent()

    // Icons are kept only for sites you bookmarked, taken from pages you opened.
    function iconName(url) {
        const host = hostOf(url).replace(/^www\./, "")
        return /^[a-z0-9.-]+$/.test(host) && host.indexOf("..") < 0 ? host : ""
    }
    function iconFor(url) {
        const name = iconName(url)
        return iconFolder === "" || !iconNames.includes(name) ? "" : String(Files.toUrl(iconFolder + "/" + name + ".png")) + "#" + iconRevision
    }
    function keepIcon(pageUrl, icon) {
        const name = iconName(pageUrl)
        if (iconFolder === "" || name === "" || String(icon) === "" || iconsSaved[name] === String(icon)
                || !shortcuts.some(s => iconName(s.url) === name))
            return
        iconsSaved[name] = String(icon)
        iconGrabber.createObject(iconShelf, { source: icon, name: name })
    }
    // draws an icon out of sight and writes the picture down
    Item { id: iconShelf; x: -200; width: 64; height: 64 }
    Component {
        id: iconGrabber
        Image {
            id: grab
            property string name
            width: 64
            height: 64
            sourceSize: Qt.size(64, 64)
            onStatusChanged: {
                if (status === Image.Ready)
                    Qt.callLater(() => grab.grabToImage(result => {
                        if (result.saveToFile(window.iconFolder + "/" + grab.name + ".png")) {
                            if (!window.iconNames.includes(grab.name)) {
                                window.iconNames = window.iconNames.concat([grab.name])
                                saved.iconNames = JSON.stringify(window.iconNames)
                            }
                            window.iconRevision++
                        }
                        grab.destroy()
                    }))
                else if (status === Image.Error)
                    grab.destroy()
            }
        }
    }

    // A site may answer with an error and still send a page: a check that you are a
    // person, "not found" in its own words. That page is shown; only when there is
    // nothing at all does Velum explain.
    function explainIfBlank(page, url, status) {
        page.runJavaScript("document.body === null || (document.body.innerText.trim() === '' && document.body.querySelector('img,iframe,canvas,video,svg,form') === null)",
            WebEngineScript.ApplicationWorld, blank => {
                if (blank !== false && String(page.url) === url)
                    page.failure = { url: url, text: Lang.t("Sunucu boş bir hata yanıtı verdi (HTTP " + status + ").", "The server answered with an empty error (HTTP " + status + ")."), certificate: false }
            })
    }

    function say(text) {
        notice = text
        noticeTimer.restart()
    }
    Timer { id: noticeTimer; interval: 3500; onTriggered: window.notice = "" }

    function sleepState(index) { return index >= 0 && index < tabs.count ? tabs.get(index).asleep : -1 }

    // asked for by hand: as deep as the engine allows
    function sleepTab(index) {
        const page = views.itemAt(index) as WebEngineView
        if (page && page !== view && !page.visible && page.url.toString() !== "" && !page.loading)
            page.lifecycleState = WebEngineView.LifecycleState.Discarded
    }

    function wakeTab(index) {
        const page = views.itemAt(index) as WebEngineView
        if (page) {
            page.lifecycleState = WebEngineView.LifecycleState.Active
            page.hiddenSince = Date.now()
        }
    }

    function sleepOthers() {
        for (let i = 0; i < tabs.count; i++)
            if (!tabs.get(i).pinned)
                sleepTab(i)
    }

    Timer { interval: window.powerMode === "balanced" ? 30000 : 5000; repeat: true; running: window.autoSleep; onTriggered: window.sleepIdleTabs(Date.now()) }

    function measure() {
        const pages = []
        for (let i = 0; i < tabs.count; i++)
            pages.push(views.itemAt(i) as WebEngineView)
        const found = Resources.sample(pages.map(p => p ? p.renderProcessPid : 0))
        const users = {}
        for (const p of pages)
            if (p && p.renderProcessPid > 0)
                users[p.renderProcessPid] = (users[p.renderProcessPid] ?? 0) + 1
        resources.rows = pages.map((p, i) => {
            const use = p ? found[String(p.renderProcessPid)] : undefined
            return { index: i, title: tabs.get(i).title || Lang.t("Yeni sekme", "New tab"), memory: use?.memory ?? 0, cpu: use?.cpu ?? 0,
                     state: tabs.get(i).asleep, shared: p ? users[p.renderProcessPid] > 1 : false, current: p === view }
        }).sort((a, b) => b.memory - a.memory)
        resources.total = found.total
    }

    function findInPage() {
        if (!onStartPage && !onSettings)
            findBar.open()
    }
    // the box belongs to the page it was opened on
    onViewChanged: findBar.close()

    // Goes to the settings tab of this workspace, making one if there is none.
    function openSettings(section) {
        prefsLoader.wanted = true
        if (section)
            prefs.section = section
        let at = visibleTabs().find(i => tabs.get(i).kind === "settings")
        if (at === undefined) {
            // an empty tab turns into it
            if (onStartPage && !tabs.get(current).pinned) {
                at = current
            } else {
                appendTab("", "", false)
                at = tabs.count - 1
            }
            tabs.setProperty(at, "kind", "settings")
        }
        current = at
    }

    function showCommandHistory() {
        commandBar.show(false, "", true)
    }

    function removeShortcut(index) {
        keepBookmarks(shortcuts.filter((s, i) => i !== index))
    }

    function navigate(target, inNewTab) {
        if (inNewTab && !onStartPage)
            openTab(String(target))
        else
            view.url = target
        view.forceActiveFocus()
    }

    function step(by) {
        const list = visibleTabs()
        current = list[(list.indexOf(current) + by + list.length) % list.length]
    }

    // what a permission means, in words; empty for the ones Velum always refuses
    function wishFor(type) {
        switch (type) {
        case WebEnginePermission.PermissionType.MediaAudioCapture: return Lang.t("Mikrofonunu kullanmak istiyor.", "wants to use your microphone.")
        case WebEnginePermission.PermissionType.MediaVideoCapture: return Lang.t("Kameranı kullanmak istiyor.", "wants to use your camera.")
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture: return Lang.t("Kameranı ve mikrofonunu kullanmak istiyor.", "wants to use your camera and microphone.")
        case WebEnginePermission.PermissionType.Geolocation: return Lang.t("Konumunu öğrenmek istiyor.", "wants to know your location.")
        case WebEnginePermission.PermissionType.ClipboardReadWrite: return Lang.t("Panonu okumak ve değiştirmek istiyor.", "wants to read and change your clipboard.")
        case WebEnginePermission.PermissionType.Notifications: return Lang.t("Sana bildirim göndermek istiyor.", "wants to send you notifications.")
        case WebEnginePermission.PermissionType.MouseLock: return Lang.t("Fare imlecini kilitlemek istiyor.", "wants to lock the mouse pointer.")
        }
        return ""
    }

    function answer(item, allow) {
        asks = asks.filter(a => a !== item)
        if (allow)
            item.permission.grant()
        else
            item.permission.deny()
    }

    // a page that is leaving or closing takes its questions with it
    function dropAsks(page) {
        for (const item of asks.filter(a => a.page === page))
            answer(item, false)
    }

    function demo(action) {
        if (action === "resources")
            resources.open()
        else if (action.startsWith("settings:"))
            openSettings(action.slice(9))
        else if (action.startsWith("welcome:")) {
            showWelcome()
            welcome.step = Number(action.slice(8))
        }
        else if (action === "horizontal")
            horizontalTabs = true
        else if (action.startsWith("menu:")) {
            const kind = action.slice(5)
            pageMenu.view = view
            pageMenu.describe(kind === "link" ? { linkUrl: "https://vamola.dev/", selectedText: "vamola" } : kind === "edit" ? { isContentEditable: true, selectedText: "x" } : {})
            pageMenu.popup(520, 220)
        }
        else if (action === "allow" && ask)
            answer(ask, true)
        else if (action.startsWith("wash:")) {
            themeWash.duration = 12000          // slow enough to be photographed
            Theme.change(() => Theme.palette = action.slice(5))
        }
        else if (action.startsWith("find:")) {
            openSettings("look")
            if (action === "find:renk")
                Theme.copyCurrent()
            prefs.query = action.slice(5)
        }
        else if (action.startsWith("design"))
            start.editor?.open(Number(action.split(":")[1] ?? 0))
        else if (action === "menu")
            mainMenu.popup(width - mainMenu.width - 12, 90)
        else if (action === "passwords")
            openPasswords()
        else if (action === "offer")
            passwordOffer = { origin: "https://ornek.example", user: "vamola", password: "deneme", changed: false }
        else if (action.startsWith("fetch:"))
            WebStore.fetch(action.slice(6), (path, problem) => {
                console.warn("fetch result: " + (path !== "" ? "checked package" : problem))
                WebStore.discard(path)
            })
        else if (action === "reader")
            toggleReader()
        else if (action === "import")
            openImport()
        else if (action === "bookmarks")
            openBookmarks()
        else if (action === "mini")
            toggleMini()
        else if (action.startsWith("space:"))
            addSpace(action.slice(6))
        else if (action === "split")
            toggleSplit()
        else if (action === "sleep")
            sleepOthers()
        else if (action.startsWith("find:")) {
            findBar.text = action.slice(5)
            findInPage()
        }
    }

    function showCommandBox(text) {
        commandBar.show(true, text)
    }

    function editAddress() {
        commandBar.show(false, onStartPage ? "" : String(view.url))
    }

    // a fresh page at once, ready for typing; the command box is Ctrl+K
    function newTab() {
        openTab("")
    }

    // everything but the floating boxes; it is what a change of colours photographs
    Item {
        id: scene
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: Theme.frameBack }

        GridLayout {
            // with the tabs on top the page reaches the edges; beside them the windows float
            readonly property int gaps: window.pageFullScreen || window.horizontalTabs ? 0 : 10
            anchors { fill: parent; margins: gaps; rightMargin: gaps ? gaps + 4 : 0; bottomMargin: gaps ? gaps + 4 : 0 }
            columns: window.horizontalTabs ? 1 : 2
            rowSpacing: 0
            columnSpacing: gaps ? 18 : 0

            Sidebar {
                id: side
                Layout.fillHeight: true
                visible: !window.pageFullScreen && !window.horizontalTabs
                // a narrow window keeps its room for the page
                compact: window.compactSidebar || window.width < 640
                onToggle: window.compactSidebar = !window.compactSidebar
                onSearch: window.editAddress()
                view: window.view
                tabModel: tabs
                current: window.current
                onPicked: i => window.current = i
                onClosed: i => window.closeTab(i)
                onNewTab: window.newTab()
                pinnedCount: window.pinnedCount
                host: window.currentHost
                onReloadPage: window.view.reload()
                onClearData: clearDialog.open()
                onSettings: window.openSettings()
                downloads: window.downloads
                onShowFolder: folder => Qt.openUrlExternally(Files.toUrl(folder))
                onClearDownloads: window.downloads = window.downloads.filter(d => !d.isFinished)
                onMoved: (from, to) => window.moveTab(from, to)
                onMenuRequested: i => { tabMenu.index = i; tabMenu.popup() }
                spaces: window.spaces
                space: window.space
                onSpaceChosen: id => window.switchSpace(id)
                onSpaceEdit: id => spaceDialog.show(id, window.spaceName(window.spaces.find(s => s.id === id)), window.spaces.length > 1)
                onSpaceAdd: spaceDialog.show(0, "", false)
                onMenu: at => window.showMenu(at)
                closable: window.ownButtons
                onCloseRequested: window.close()
            }

            TopBar {
                id: topBar
                Layout.fillWidth: true
                visible: !window.pageFullScreen && window.horizontalTabs
                view: window.view
                tabModel: tabs
                current: window.current
                pinnedCount: window.pinnedCount
                host: window.currentHost
                downloads: window.downloads
                spaces: window.spaces
                space: window.space
                onPicked: i => window.current = i
                onClosed: i => window.closeTab(i)
                onNewTab: window.newTab()
                onMoved: (from, to) => window.moveTab(from, to)
                onMenuRequested: i => { tabMenu.index = i; tabMenu.popup() }
                onReloadPage: window.view.reload()
                onClearData: clearDialog.open()
                onSettings: window.openSettings()
                onHome: window.goHome()
                bookmarks: window.shortcuts
                showBookmarks: window.showBookmarkBar
                iconFor: window.iconNames.length >= 0 && window.iconRevision >= 0 ? url => window.iconFor(url) : url => ""
                onOpenBookmark: address => window.navigate(address, false)
                onImportRequested: window.openImport()
                bookmarked: window.bookmarked
                onToggleBookmark: window.toggleBookmark()
                onExtensions: window.openSettings("extensions")
                onMenu: at => window.showMenu(at)
                onMaximize: window.toggleWindowFullScreen()
                onQuitRequested: window.close()
            gaming: window.powerMode === "game"
            onGameRequested: window.setPowerMode(window.powerMode === "game" ? "balanced" : "game")
            onOpenBookmarksRequested: window.openBookmarks()
            onHistoryRequested: window.showCommandHistory()
                pageButtons.storeButton: card.storeButton
                pageButtons.keyButton: card.keyButton
                pageButtons.readerButton: card.readerButton
                pageButtons.readerOn: card.readerOn
                pageButtons.videoButton: card.videoButton
                pageButtons.videoOut: card.videoOut
                pageButtons.onStore: card.store()
                pageButtons.onFill: card.fill_()
                pageButtons.onReader: card.reader()
                pageButtons.onVideo: card.video()
                onShowFolder: folder => Qt.openUrlExternally(Files.toUrl(folder))
                onClearDownloads: window.downloads = window.downloads.filter(d => !d.isFinished)
                onSpaceChosen: id => window.switchSpace(id)
                onSpaceEdit: id => spaceDialog.show(id, window.spaceName(window.spaces.find(s => s.id === id)), window.spaces.length > 1)
                onSpaceAdd: spaceDialog.show(0, "", false)
            }

            // the page, in a window of its own
            Panel {
                id: card
                Layout.fillWidth: true
                Layout.fillHeight: true
                chrome: !window.pageFullScreen && !window.horizontalTabs
                title: window.onSettings ? Lang.t("ayarlar", "settings") : window.onStartPage ? Lang.t("başlangıç", "start") : window.view && window.view.title !== "" ? window.view.title : window.currentHost
                stripe: Theme.rainbow[Math.max(0, window.current) % Theme.rainbow.length]
                minimizable: !window.horizontalTabs
                maximizable: true
                closable: true
                onMinimize: window.compactSidebar = !window.compactSidebar
                onMaximize: window.toggleWindowFullScreen()
                onCloseRequested: window.closeTab(window.current)
                storeButton: window.view !== null && !window.fetchingExtension && WebStore.idFrom(window.view.url) !== ""
                onStore: window.askExtension(String(window.view.url), false)
                keyButton: !window.onStartPage && (window.view?.accounts.length ?? 0) > 0
                onFill_: window.fillPassword()
                readerButton: !window.onStartPage && window.view !== null && window.view !== window.miniPage && (window.view.readable || window.view.reading)
                readerOn: window.view?.reading ?? false
                onReader: window.toggleReader()
                videoButton: window.miniPage !== null || (!window.onStartPage && (window.view?.recentlyAudible ?? false))
                videoOut: window.miniPage !== null
                onVideo: window.toggleMini()

                Item {
                    id: pagesArea
                    anchors.fill: parent

                    Repeater {
                        id: views
                        model: tabs

                        WebEngineView {
                            id: web
                            required property int index
                            required property string startUrl
                            required property bool lazy
                            required property string kind
                            property bool started: false
                            property bool crashed: false
                            property string loginOrigin: ""     // set while a login form is shown
                            property var accounts: []           // saved logins that fit it
                            // how the watcher inside the page talks to Velum
                            property QtObject loginBridge: QtObject {
                                WebChannel.id: "velum"
                                function offer(origin, user, password) { window.offerPassword(String(origin), String(user), String(password)) }
                                function form(origin, present) {
                                    web.loginOrigin = present ? String(origin) : ""
                                    window.findAccounts(web)
                                }
                            }
                            webChannel: WebChannel { registeredObjects: [web.loginBridge] }
                            webChannelWorld: WebEngineScript.ApplicationWorld
                            property bool readable: false       // there is an article here
                            property bool reading: false        // and it is shown in reading mode
                            property var failure: null          // { url, text, certificate }
                            // loads the address a restored tab was waiting with
                            function load_() {
                                if (!started && startUrl !== "") {
                                    started = true
                                    url = startUrl
                                }
                            }
                            property double hiddenSince: 0     // when it was last looked at; 0 while shown
                            // a tab being looked at is always awake
                            onVisibleChanged: {
                                if (visible) {
                                    if (lazy)
                                        load_()
                                    lifecycleState = WebEngineView.LifecycleState.Active
                                    hiddenSince = 0
                                } else {
                                    hiddenSince = Date.now()
                                }
                            }
                            onLifecycleStateChanged: tabs.setProperty(index, "asleep", lifecycleState)
                            readonly property bool beside: window.splitShown && (web === window.splitLeft || web === window.splitRight)
                            // "parent" is the small window while the video is out there
                            readonly property real room: parent?.width ?? 0
                            readonly property real divide: Math.round(room * window.splitRatio)
                            visible: web === window.view || web === window.miniPage || beside
                            x: beside && web === window.splitRight ? divide + 4 : 0
                            width: !beside ? room : web === window.splitLeft ? divide - 4 : room - divide - 4
                            height: parent?.height ?? 0
                            // clicking into the other half makes that tab the current one
                            onActiveFocusChanged: if (activeFocus && beside && web !== window.view) window.current = index

                            profile: window.profile
                            // an empty tab lets the glass through; a web page gets a solid sheet
                            backgroundColor: Theme.seeThrough && (url.toString() === "" || url.toString() === "about:blank") ? "transparent" : Theme.surface
                            settings.fullScreenSupportEnabled: true      // video full screen
                            settings.errorPageEnabled: false             // Velum explains problems itself
                            // saving power: nothing starts playing by itself
                            settings.playbackRequiresUserGesture: window.powerMode === "saver"
                            // a bad certificate is never accepted, only explained
                            onCertificateError: error => {
                                if (error.isMainFrame)
                                    failure = { url: String(error.url), text: error.description, certificate: true }
                                error.rejectCertificate()
                            }
                            onRenderProcessTerminated: (status, code) => {
                                if (web === window.miniPage)
                                    window.closeMini()
                                // putting a tab to sleep ends its process too; that is not a crash
                                if (status !== WebEngineView.NormalTerminationStatus && lifecycleState === WebEngineView.LifecycleState.Active)
                                    crashed = true
                            }
                            onContextMenuRequested: request => {
                                request.accepted = true          // Velum draws its own menu
                                pageMenu.view = web
                                pageMenu.describe(request)
                                const at = web.mapToItem(null, request.position.x, request.position.y)
                                pageMenu.popup(at.x, at.y - (window.header?.height ?? 0))
                            }
                            onFindTextFinished: result => {
                                if (web === window.view) {
                                    findBar.matches = result.numberOfMatches
                                    findBar.current = result.activeMatch
                                }
                            }
                            settings.dnsPrefetchEnabled: false           // no lookups for links you did not click
                            settings.hyperlinkAuditingEnabled: false     // no "ping" tracking on links
                            settings.pluginsEnabled: true
                            settings.pdfViewerEnabled: true

                            Component.onCompleted: {
                                if (!lazy)
                                    load_()
                                if (web !== window.view)
                                    hiddenSince = Date.now()
                            }
                            Component.onDestruction: window.dropAsks(web)

                            // before a page loads: restart its counter and give it the shield's script
                            onNavigationRequested: request => {
                                if (!request.isMainFrame)
                                    return
                                window.dropAsks(web)
                                Shield.resetCount(window.hostOf(request.url))
                                const source = Shield.pageScript(request.url)
                                if (source === "") {
                                    userScripts.collection = []
                                    return
                                }
                                const script = WebEngine.script()
                                script.name = "velum-shield"
                                script.sourceCode = source
                                script.injectionPoint = WebEngineScript.DocumentCreation
                                script.worldId = WebEngineScript.MainWorld
                                userScripts.collection = [script]
                            }

                            // keep the tab list in step with the page
                            onTitleChanged: {
                                if (lazy && !started)
                                    return
                                tabs.setProperty(index, "title", url.toString() === "about:blank" ? "" : title)
                                window.touchSession()
                                History.setTitle(String(url), title)
                            }
                            onIconChanged: {
                                tabs.setProperty(index, "siteIcon", String(icon))
                                window.keepIcon(url, icon)
                            }
                            onLoadingChanged: info => {
                                tabs.setProperty(index, "loading", loading)
                                if (info.status === WebEngineView.LoadStartedStatus) {
                                    if (web === window.miniPage)      // another page: the video is gone
                                        window.closeMini()
                                    readable = false
                                    reading = false
                                    loginOrigin = ""
                                    accounts = []
                                    crashed = false
                                    failure = null
                                }
                                if (info.status === WebEngineView.LoadSucceededStatus) {
                                    History.add(String(url), title)
                                    web.runJavaScript(reader.probe, WebEngineScript.ApplicationWorld, found => web.readable = found === true)
                                }
                                // -3 means "stopped": by you, or because another page was asked for
                                if (info.status === WebEngineView.LoadFailedStatus && info.errorCode !== -3 && !failure) {
                                    if (info.errorDomain === WebEngineLoadingInfo.HttpStatusCodeDomain)
                                        window.explainIfBlank(web, String(info.url), info.errorCode)
                                    else
                                        failure = { url: String(info.url), text: info.errorString, certificate: false }
                                }
                            }
                            onUrlChanged: {
                                window.closeReader(web)      // sites that change page without loading
                                // going somewhere turns the settings tab into an ordinary one
                                if (kind !== "" && url.toString() !== "" && url.toString() !== "about:blank")
                                    tabs.setProperty(index, "kind", "")
                                if (lazy && !started)
                                    return
                                tabs.setProperty(index, "pageUrl", String(url))
                                window.touchSession()
                                if (tabs.get(index).pinned)
                                    window.savePinned()
                            }

                            // links that ask for a new window become tabs
                            onNewWindowRequested: request => request.openIn(window.openTab(""))
                            onWindowCloseRequested: window.closeTab(index)

                            onFullScreenRequested: request => {
                                if (web === window.miniPage) {
                                    request.reject()
                                    return
                                }
                                window.pageFullScreen = request.toggleOn
                                if (request.toggleOn)
                                    window.showFullScreen()
                                else
                                    window.showNormal()
                                request.accept()
                            }

                            // Camera, microphone, location and the like: you are asked.
                            // Kinds Velum cannot honour yet (such as notifications) are refused.
                            onPermissionRequested: permission => {
                                const wish = window.wishFor(permission.permissionType)
                                if (wish === "") {
                                    permission.deny()
                                    return
                                }
                                window.asks = window.asks.concat([{ page: web, permission: permission, wish: wish,
                                                                    site: window.hostOf(permission.origin) || String(permission.origin) }])
                            }
                            // do not tell pages your computer's addresses on the local network
                            settings.webRTCPublicInterfacesOnly: true
                        }
                    }
                }

                // how far the page has loaded, a thin line along its top
                Rectangle {
                    id: progress
                    readonly property bool busy: window.view !== null && window.view.loading && !window.onStartPage
                    x: window.view?.x ?? 0
                    z: 3
                    height: 3
                    radius: Theme.radius
                    width: (window.view?.width ?? 0) * (busy ? Math.max(0.08, window.view.loadProgress / 100) : 1)
                    opacity: busy ? 1 : 0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accent }
                        GradientStop { position: 1; color: Theme.pink }
                    }
                    Behavior on width { enabled: progress.busy; NumberAnimation { duration: Theme.smooth } }
                    Behavior on opacity { NumberAnimation { duration: Theme.smooth * 2 } }
                }

                // the line between the two halves: drag to resize, double click to even out
                Item {
                    id: splitter
                    visible: window.splitShown
                    x: Math.round(parent.width * window.splitRatio) - 4
                    width: 8
                    height: parent.height
                    z: 2
                    Rectangle { anchors.centerIn: parent; width: handle.containsMouse || handle.pressed ? 4 : 2; height: parent.height; color: handle.containsMouse || handle.pressed ? Theme.accent : Theme.line }
                    MouseArea {
                        id: handle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SplitHCursor
                        preventStealing: true
                        onPositionChanged: mouse => {
                            if (pressed)
                                window.splitRatio = Math.max(0.2, Math.min(0.8, mapToItem(splitter.parent, mouse.x, 0).x / splitter.parent.width))
                        }
                        onDoubleClicked: window.splitRatio = 0.5
                    }
                }
                // marks which half the address bar and the keys act on
                Rectangle {
                    visible: window.splitShown
                    x: window.view?.x ?? 0
                    width: window.view?.width ?? 0
                    height: 2
                    color: Theme.accent
                    z: 2
                }

                ProblemPage {
                    x: window.splitShown ? window.view.x : 0
                    width: window.splitShown ? window.view.width : parent.width
                    height: parent.height
                    visible: !window.onStartPage && window.view !== null && (window.view.crashed || window.view.failure !== null)
                    heading: window.view?.crashed ? Lang.t("Bu sekme çöktü", "This tab crashed") : window.view?.failure?.certificate ? Lang.t("Bu bağlantı güvenli değil", "This connection is not safe") : Lang.t("Sayfa açılamadı", "The page could not be opened")
                    address: window.view ? (window.view.failure?.url ?? String(window.view.url)) : ""
                    detail: window.view?.crashed ? Lang.t("Sayfayı çizen süreç beklenmedik şekilde kapandı.", "The process drawing the page ended unexpectedly.") : window.view?.failure?.text ?? ""
                    advice: window.view?.crashed ? Lang.t("Yeniden denemek çoğu zaman yeter.", "Trying again is usually enough.")
                          : window.view?.failure?.certificate ? Lang.t("Sitenin sertifikası doğrulanamadı. Biri araya girmiş olabilir; Velum bu uyarıyı atlamana izin vermez.", "The site's certificate could not be verified. Someone may be in between; Velum does not let you skip this.")
                          : Shield.httpsFirst ? Lang.t("İnternet bağlantını ve adresi kontrol et. Site yalnızca http destekliyorsa kalkan panelinden \"Önce HTTPS\"i kapatabilirsin.", "Check your connection and the address. If the site only supports http, switch \"HTTPS first\" off in the shield panel.")
                          : Lang.t("İnternet bağlantını ve adresi kontrol et.", "Check your connection and the address.")
                    onRetry: {
                        const page = window.view
                        const target = page.failure?.url ?? String(page.url)
                        page.failure = null
                        page.crashed = false
                        if (String(page.url) === target)
                            page.reload()
                        else
                            page.url = target
                    }
                }

                FindBar {
                    id: findBar
                    anchors { top: parent.top; right: parent.right; margins: 12 }
                    z: 3
                    onSearch: (text, backwards) => window.view.findText(text, backwards ? WebEngineView.FindBackward : 0)
                    onClosed: { window.view?.findText(""); window.view?.forceActiveFocus() }
                }

                PermissionBar {
                    anchors { top: parent.top; left: parent.left; margins: 12 }
                    z: 2
                    visible: window.ask !== null
                    site: window.ask?.site ?? ""
                    wish: window.ask?.wish ?? ""
                    onAnswered: allow => window.answer(window.ask, allow)
                }

                // what the window shows while the current tab's video is out
                Rectangle {
                    anchors.fill: parent
                    visible: window.miniPage !== null && window.view === window.miniPage
                    color: Theme.surface
                    Column {
                        anchors.centerIn: parent
                        spacing: 14
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "pip"; size: 48; color: Theme.mauve }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Lang.t("Video küçük pencerede oynuyor", "The video is playing in the small window"); color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(23); font.weight: Font.Normal }
                        TextButton { anchors.horizontalCenter: parent.horizontalCenter; strong: true; text: Lang.t("Buraya geri al", "Bring it back"); onClicked: window.closeMini() }
                    }
                }

                // letter size and the way out, while reading
                Rectangle {
                    anchors { right: parent.right; bottom: parent.bottom; margins: 18 }
                    visible: window.view?.reading ?? false
                    z: 3
                    width: readerControls.implicitWidth + 14
                    height: 42
                    radius: Theme.radius
                    color: Theme.window
                    border.color: Theme.line
                    Row {
                        id: readerControls
                        anchors.centerIn: parent
                        spacing: 6
                        TextButton { text: "A−"; implicitHeight: 28; enabled: window.readerSize > 14; onClicked: window.sizeReader(-2) }
                        TextButton { text: "A+"; implicitHeight: 28; enabled: window.readerSize < 28; onClicked: window.sizeReader(2) }
                        TextButton { text: Lang.t("Çık", "Close"); implicitHeight: 28; strong: true; onClicked: window.toggleReader() }
                    }
                }

                PasswordBar {
                    anchors { top: parent.top; right: parent.right; margins: 12 }
                    z: 4
                    visible: offer !== null
                    offer: window.passwordOffer
                    onAccepted: user => window.savePassword(user)
                    onLater: window.passwordOffer = null
                    onNever: window.neverFor(window.passwordOffer.origin)
                }

                // a short message at the bottom of the page
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: window.notice !== "" ? 18 : -10 }
                    width: Math.min(parent.width - 24, noticeText.implicitWidth + 32)
                    height: 38
                    radius: Theme.radius
                    z: 3
                    opacity: window.notice !== "" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.smooth } }
                    Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
                    Shadow { radius: Theme.radius }
                    color: Theme.raised
                    border.color: Theme.line
                    Text { id: noticeText; anchors { fill: parent; leftMargin: 16; rightMargin: 16 } text: window.notice; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17); elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                }

                // made the first time it is opened, then kept
                Loader {
                    id: prefsLoader
                    x: window.splitShown ? window.view.x : 0
                    width: window.splitShown ? window.view.width : parent.width
                    height: parent.height
                    property bool wanted: false
                    active: wanted
                    visible: window.onSettings
                    onVisibleChanged: if (visible) wanted = true
                    sourceComponent: Component {
                        SettingsPage {
                            sleepMode: window.sleepMode
                            powerMode: window.powerMode
                            memoryLimit: window.memoryLimit
                            memoryUsed: window.memoryUsed
                            onPowerModeChosen: mode => window.setPowerMode(mode)
                            onMemoryLimitChosen: mb => window.memoryLimit = mb
                            onResourcesRequested: resources.open()
                            onOpenPage: address => window.openTab(address)
                            restoreSession: window.restoreSession
                            downloadFolder: window.downloadFolder
                            horizontalTabs: window.horizontalTabs
                            compactSidebar: window.compactSidebar
                            neverSites: window.neverSave
                            bookmarkCount: window.shortcuts.length
                            onSleepModeChosen: mode => window.sleepMode = mode
                            onRestoreSessionChosen: on => window.restoreSession = on
                            onDownloadFolderChosen: folder => window.downloadFolder = folder
                            onLayoutChosen: h => window.horizontalTabs = h
                            onCompactChosen: on => window.compactSidebar = on
                            onClearRequested: clearDialog.open()
                            onAskAgain: origin => window.askAgainFor(origin)
                            onBookmarksRequested: window.openBookmarks()
                            onImportRequested: window.openImport()
                            onWelcomeRequested: window.showWelcome()
                            startBackground: window.startBackground
                            startPicture: window.startPicture
                            showClock: window.showClock
                            showShield: window.showShield
                            showNote: window.showNote
                            showFrequent: window.showFrequent
                            showBookmarkBar: window.showBookmarkBar
                            onStartChanged: (name, value) => window.setStart(name, value)
                            onResetLook: window.resetLook()
                    onExportTheme: file => window.exportTheme(file)
                    onImportTheme: file => window.importTheme(file)
                    onDesignRequested: { window.openTab(""); Qt.callLater(() => start.editor?.open(0)) }
                            extensions: window.extensions
                            fetchingExtension: window.fetchingExtension
                            onAddFromStore: typed => window.askExtension(typed, false)
                            onAddFromFile: path => window.askExtension(path, true)
                            onOpenStore: window.openTab("https://chromewebstore.google.com/")
                            onOpenExtensionPage: address => window.openTab(String(address))
                            onEnableExtension: (extension, on) => window.enableExtension(extension, on)
                            onRemoveExtension: extension => window.removeExtension(extension)
                        }
                    }
                }

                StartPage {
                    id: start
                    x: window.splitShown ? window.view.x : 0
                    width: window.splitShown ? window.view.width : parent.width
                    height: parent.height
                    visible: window.onStartPage
                    hasWidevine: window.hasWidevine
                    shortcuts: window.shortcuts.slice(0, 10)
                    total: window.shortcuts.length
                    onManage: window.openBookmarks()
                    frequent: window.showFrequent ? window.frequentPages : []
                    blocked: Shield.total
                    note: window.note
                    background: window.startBackground
                    picture: window.startPicture
                    showClock: window.showClock
                    showShield: window.showShield
                    showNote: window.showNote
                    showFrequent: window.showFrequent
                    widgets: window.homeWidgets
                    headline: window.homeHeadline
                    words: window.homeWords
                    tasks: window.homeTasks
                    cssText: window.homeCss
                    timerMinutes: window.homeTimer
                    onWidgetsEdited: list => window.keepWidgets(list)
                    onWordsEdited: (headline, words) => window.keepWords(headline, words)
                    onTasksEdited: list => window.keepTasks(list)
                    onCssEdited: text => window.homeCss = text.slice(0, 20000)
                    onTimerEdited: minutes => window.homeTimer = minutes
                    onTimerFinished: window.say(Lang.t("Süre doldu.", "Time is up."))
                    iconFor: window.iconNames.length >= 0 && window.iconRevision >= 0 ? url => window.iconFor(url) : url => ""
                    onNoteEdited: text => window.note = text
                    onCustomize: window.openSettings("look")
                    onAddShortcut: typed => window.addShortcut(typed)
                    onRemoveShortcut: i => window.removeShortcut(i)
                    onGo: target => {
                        window.view.url = target
                        if (start.field)
                            start.field.text = ""
                        window.view.forceActiveFocus()
                    }
                }
            }
        }
    }

    Component {
        id: welcomeScreen
        Welcome {
            id: welcome
            horizontalTabs: window.horizontalTabs
            onLayoutChosen: h => window.horizontalTabs = h
            onImportRequested: window.openImport()
            onFinished: window.welcomed = true
            installed: window.extensions.map(e => e.name)
            onExtensionsChosen: ids => window.queueExtensions(ids)
        }
    }

    ResourcePanel {
        id: resources
        mode: window.sleepMode
        onRefresh: window.measure()
        onSleep: i => { window.sleepTab(i); window.measure() }
        onWake: i => { window.wakeTab(i); window.measure() }
        onChoose: i => window.current = i
        onModeChosen: mode => window.sleepMode = mode
    }

    ConfirmDialog {
        id: clearDialog
        heading: Lang.t("Gezinme verileri silinsin mi?", "Delete browsing data?")
        detail: Lang.t("Geçmiş, çerezler ve önbellek silinir; bütün sitelerden çıkış yapılır. Yer imlerin kalır. Bu geri alınamaz.", "History, cookies and the cache are deleted and you are signed out everywhere. Bookmarks stay. This cannot be undone.")
        action: Lang.t("Sil", "Delete")
        onConfirmed: { History.clear(); Shield.clearData(window.profile) }
    }

    ConfirmDialog {
        id: extensionDialog
        heading: Lang.t("Bu eklenti kurulsun mu?", "Install this extension?")
        detail: Lang.t("Eklentiler gezdiğin sayfaları okuyup değiştirebilir, yazdığın parolaları da görebilir. Yalnızca güvendiğini kur.", "Extensions can read and change the pages you visit, including passwords you type. Install only what you trust.")
                + (window.wantedExtension && !window.wantedExtension.file ? Lang.t(" Paket için Google'a bağlanılacak.", " Google will be contacted for the package.") : "")
        action: Lang.t("Kur", "Install")
        onConfirmed: window.addExtension()
    }

    BookmarksPage {
        id: bookmarksPage
        items: window.shortcuts
        save: (index, title, address, folder) => window.saveBookmark(index, title, address, folder)
        onRemoved: index => window.removeShortcut(index)
        onRestored: (item, index) => window.restoreBookmark(item, index)
        onMoved: (from, to) => window.moveBookmark(from, to)
        onFolderRenamed: (from, to) => window.renameFolder(from, to)
        onChosen: target => window.navigate(target, true)
        onImportRequested: importPanel.open()
    }

    ImportPanel {
        id: importPanel
        run: (path, withHistory) => window.importFrom(path, withHistory)
    }

    MiniPlayer {
        id: miniPlayer
        onBackRequested: window.closeMini()
    }

    SpaceDialog {
        id: spaceDialog
        onAccepted: (id, name) => id === 0 ? window.addSpace(name) : window.renameSpace(id, name)
        onRemoved: id => window.removeSpace(id)
    }

    CommandBar {
        id: commandBar
        anchors.fill: parent
        tabModel: tabs
        shortcuts: window.shortcuts
        history: History
        commands: [
            { name: Lang.t("Sekmeyi sabitle ya da çöz", "Pin or unpin the tab"), keys: Keymap.text("pin"), run: () => window.togglePin(window.current) },
            { name: Lang.t("Kapatılan sekmeyi geri aç", "Reopen the closed tab"), keys: Keymap.text("reopen"), run: () => window.reopenClosed() },
            { name: Lang.t("Yer imi ekle ya da kaldır", "Add or remove a bookmark"), keys: Keymap.text("bookmark"), run: () => window.toggleBookmark() },
            { name: Lang.t("Yer imleri: düzenle, klasörle", "Bookmarks: edit and sort"), keys: Keymap.text("bookmarks"), run: () => Qt.callLater(window.openBookmarks) },
            { name: Lang.t("Başka tarayıcıdan aktar", "Import from another browser"), keys: "", run: () => Qt.callLater(window.openImport) },
            { name: Lang.t("Eklentiler", "Extensions"), keys: "", run: () => window.openSettings("extensions") },
            { name: Lang.t("Geçmiş", "History"), keys: Keymap.text("history"), run: () => Qt.callLater(window.showCommandHistory) },
            { name: Lang.t("İndirmeler", "Downloads"), keys: Keymap.text("downloads"), run: () => window.openDownloads() },
            { name: window.horizontalTabs ? Lang.t("Dikey sekmelere geç", "Move the tabs to the side") : Lang.t("Yatay sekmelere geç", "Move the tabs to the top"), keys: "", run: () => window.horizontalTabs = !window.horizontalTabs },
            { name: Lang.t("Kaynaklar: hangi sekme ne kadar yiyor", "Resources: what each tab uses"), keys: Keymap.text("resources"), run: () => resources.open() },
            { name: Lang.t("Diğer sekmeleri uyut", "Put other tabs to sleep"), keys: "", run: () => window.sleepOthers() },
            { name: Lang.t("Yan paneli daralt ya da genişlet", "Narrow or widen the side bar"), keys: Keymap.text("sidebar"), run: () => window.compactSidebar = !window.compactSidebar },
            { name: Lang.t("Sekmeyi kapat", "Close the tab"), keys: Keymap.text("closeTab"), run: () => window.closeTab(window.current) },
            { name: Lang.t("Diğer sekmeleri kapat", "Close other tabs"), keys: "", run: () => window.closeOthers(window.current) },
            { name: Lang.t("Ekranı böl ya da birleştir", "Split or join the view"), keys: Keymap.text("split"), run: () => window.toggleSplit() },
            { name: Lang.t("Videoyu küçük pencereye al ya da geri getir", "Video in a small window, or back"), keys: Keymap.text("mini"), run: () => window.toggleMini() },
            { name: Lang.t("Parolayı doldur", "Fill in the password"), keys: Keymap.text("fill"), run: () => window.fillPassword() },
            { name: Lang.t("Kayıtlı parolalar", "Saved passwords"), keys: "", run: () => Qt.callLater(window.openPasswords) },
            { name: Lang.t("Okuma modu", "Reading mode"), keys: Keymap.text("reader"), run: () => window.toggleReader() },
            { name: Lang.t("Yeni çalışma alanı", "New workspace"), keys: "", run: () => spaceDialog.show(0, "", false) },
            { name: Lang.t("Sayfada ara", "Find in page"), keys: Keymap.text("find"), run: () => Qt.callLater(window.findInPage) },
            { name: window.restoreSession ? Lang.t("Açılışta sekmeleri geri getirme", "Do not reopen tabs at start") : Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start"), keys: "", run: () => window.restoreSession = !window.restoreSession },
            { name: Lang.t("Gezinme verilerini sil", "Delete browsing data"), keys: Keymap.text("clear"), run: () => clearDialog.open() },
            { name: Lang.t("Ayarlar", "Settings"), keys: Keymap.text("settings"), run: () => Qt.callLater(window.openSettings) },
            { name: Lang.t("Tam ekran", "Full screen"), keys: Keymap.text("fullScreen"), run: () => window.toggleWindowFullScreen() },
            { name: Lang.t("Velum'dan çık", "Quit Velum"), keys: Keymap.text("quit"), run: () => Qt.quit() }
        ].concat(window.spaces.map((s, i) => ({ name: Lang.t("Çalışma alanı: ", "Workspace: ") + window.spaceName(s), keys: "Alt+" + (i + 1), run: () => window.switchSpace(s.id) })))
        onOpened: (target, inNewTab) => window.navigate(target, inNewTab)
        onTabChosen: i => window.current = i
        onDismissed: if (window.view && !window.onStartPage) window.view.forceActiveFocus()
    }

    function toggleWindowFullScreen() {
        visibility === Window.FullScreen ? showNormal() : showFullScreen()
    }

    PageMenu {
        id: pageMenu
        onOpenInTab: url => window.openTab(url)
        onSearchFor: text => window.openTab(String(Address.search(text)))
        onFind: window.findInPage()
    }

    // a newer version has been fetched and will be installed when Velum is closed
    readonly property bool updateReady: Updater.status === "ready"
    onUpdateReadyChanged: if (updateReady) say(Lang.t("Güncelleme hazır: Velum " + Updater.version + " kapatınca kurulacak.", "Update ready: Velum " + Updater.version + " will be installed when you quit."))

    // colours spread from the middle when you pick others
    ThemeWash {
        id: themeWash
        parent: window.Overlay.overlay
        z: 100000
        target: window.welcome?.opened ? window.welcome.contentItem : scene
        Component.onCompleted: Theme.washer = themeWash.run
        Component.onDestruction: if (Theme.washer === themeWash.run) Theme.washer = null
    }

    // the menu behind the three lines
    AppMenu {
        id: mainMenu
        AppMenuItem { text: Lang.t("Yeni sekme", "New tab"); keys: Keymap.text("newTab"); onTriggered: window.newTab() }
        AppMenuItem { text: Lang.t("Yeni çalışma alanı", "New workspace"); onTriggered: spaceDialog.show(0, "", false) }
        AppMenuLine {}
        AppMenuItem { text: Lang.t("Yer imleri", "Bookmarks"); keys: Keymap.text("bookmarks"); onTriggered: window.openBookmarks() }
        AppMenuItem { text: Lang.t("Geçmiş", "History"); keys: Keymap.text("history"); onTriggered: Qt.callLater(window.showCommandHistory) }
        AppMenuItem { text: Lang.t("İndirilenler", "Downloads"); keys: Keymap.text("downloads"); onTriggered: Qt.callLater(window.openDownloads) }
        AppMenuItem { text: Lang.t("Parolalar", "Passwords"); onTriggered: window.openPasswords() }
        AppMenuItem { text: Lang.t("Eklentiler", "Extensions"); onTriggered: window.openSettings("extensions") }
        AppMenuLine {}
        AppMenuItem { text: Lang.t("Sayfada ara", "Find in page"); keys: Keymap.text("find"); enabled: !window.onStartPage && !window.onSettings; onTriggered: window.findInPage() }
        AppMenuItem { text: Lang.t("Yakınlaştır", "Zoom in"); keys: Keymap.text("zoomIn"); onTriggered: window.view.zoomFactor = Math.min(3, window.view.zoomFactor + 0.1) }
        AppMenuItem { text: Lang.t("Uzaklaştır", "Zoom out"); keys: Keymap.text("zoomOut"); onTriggered: window.view.zoomFactor = Math.max(0.5, window.view.zoomFactor - 0.1) }
        AppMenuItem { text: Lang.t("Okuma modu", "Reading mode"); keys: Keymap.text("reader"); enabled: !window.onStartPage && !window.onSettings; onTriggered: window.toggleReader() }
        AppMenuItem { text: Lang.t("Küçük video penceresi", "Mini video window"); keys: Keymap.text("mini"); enabled: !window.onStartPage && !window.onSettings; onTriggered: window.toggleMini() }
        AppMenuItem { text: Lang.t("Ekranı böl ya da birleştir", "Split or join the view"); keys: Keymap.text("split"); onTriggered: window.toggleSplit() }
        AppMenuLine {}
        AppMenuItem { keys: Keymap.text("gameMode"); text: (window.powerMode === "game" ? "✓  " : "") + Lang.t("Oyun modu", "Game mode"); onTriggered: window.setPowerMode(window.powerMode === "game" ? "balanced" : "game") }
        AppMenuItem { text: (window.powerMode === "saver" ? "✓  " : "") + Lang.t("Tasarruf modu", "Saver mode"); onTriggered: window.setPowerMode(window.powerMode === "saver" ? "balanced" : "saver") }
        AppMenuLine {}
        AppMenuItem { text: Lang.t("Ayarlar", "Settings"); keys: Keymap.text("settings"); onTriggered: window.openSettings() }
        AppMenuItem { text: Lang.t("Velum'dan çık", "Quit Velum"); keys: Keymap.text("quit"); onTriggered: Qt.quit() }
    }

    // choosing between several saved accounts; five are offered
    AppMenu {
        id: accountMenu
        AppMenuItem { readonly property var account: window.view?.accounts[0]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[1]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[2]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[3]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[4]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
    }

    AppMenu {
        id: tabMenu
        property int index: 0
        readonly property bool pinned: index < window.pinnedCount
        readonly property bool movable: !pinned
        AppMenuItem { text: tabMenu.pinned ? Lang.t("Sabitlemeyi kaldır", "Unpin") : Lang.t("Sabitle", "Pin"); onTriggered: window.togglePin(tabMenu.index) }
        AppMenuItem { text: Lang.t("Çoğalt", "Duplicate"); onTriggered: window.openTab(tabs.get(tabMenu.index).pageUrl) }
        AppMenuItem { text: Lang.t("Yenile", "Reload"); onTriggered: (views.itemAt(tabMenu.index) as WebEngineView).reload() }
        AppMenuItem { text: Lang.t("Uyut", "Sleep"); enabled: tabMenu.index !== window.current; onTriggered: window.sleepTab(tabMenu.index) }
        AppMenuItem { text: Lang.t("Yer imlerine ekle", "Bookmark"); onTriggered: window.addShortcut(tabs.get(tabMenu.index).pageUrl, tabs.get(tabMenu.index).title) }
        AppMenuItem { text: Lang.t("Videoyu küçük pencereye al", "Video in a small window"); onTriggered: window.openMini(tabMenu.index) }
        AppMenuItem { text: Lang.t("Yan yana aç", "Open side by side"); shown: tabMenu.index !== window.current; onTriggered: window.splitWith(tabMenu.index) }
        AppMenuItem { text: Lang.t("Bölünmeyi kapat", "End split view"); shown: window.splitShown; onTriggered: window.unsplit() }
        // moving a tab to another workspace; there are at most six
        AppMenuItem { readonly property var to: window.spaces[0]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuItem { readonly property var to: window.spaces[1]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuItem { readonly property var to: window.spaces[2]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuItem { readonly property var to: window.spaces[3]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuItem { readonly property var to: window.spaces[4]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuItem { readonly property var to: window.spaces[5]; shown: tabMenu.movable && to !== undefined && to.id !== window.space; text: to ? "→ " + window.spaceName(to) : ""; onTriggered: window.moveToSpace(tabMenu.index, to.id) }
        AppMenuLine {}
        AppMenuItem { text: Lang.t("Kapat", "Close"); onTriggered: window.closeTab(tabMenu.index) }
        AppMenuItem { text: Lang.t("Diğerlerini kapat", "Close others"); onTriggered: window.closeOthers(tabMenu.index) }
        AppMenuItem { text: Lang.t("Kapatılanı geri aç", "Reopen closed tab"); enabled: window.closedTabs.length > 0; onTriggered: window.reopenClosed() }
    }

    // keyboard
    Shortcut { sequences: Keymap.sequences("newTab"); onActivated: window.newTab() }
    Shortcut { sequences: Keymap.sequences("reopen"); onActivated: window.reopenClosed() }
    Shortcut { sequences: Keymap.sequences("pin"); onActivated: window.togglePin(window.current) }
    Shortcut { sequences: Keymap.sequences("bookmark"); onActivated: window.toggleBookmark() }
    Shortcut { sequences: Keymap.sequences("find"); onActivated: window.findInPage() }
    Shortcut { sequences: Keymap.sequences("bookmarks"); onActivated: window.openBookmarks() }
    Shortcut { sequences: Keymap.sequences("fill"); onActivated: window.fillPassword() }
    Shortcut { sequences: Keymap.sequences("reader"); onActivated: window.toggleReader() }
    Shortcut { sequences: Keymap.sequences("mini"); onActivated: window.toggleMini() }
    Shortcut { sequence: "Alt+1"; onActivated: window.switchSpace(window.spaces[0]?.id) }
    Shortcut { sequence: "Alt+2"; onActivated: window.switchSpace(window.spaces[1]?.id ?? 0) }
    Shortcut { sequence: "Alt+3"; onActivated: window.switchSpace(window.spaces[2]?.id ?? 0) }
    Shortcut { sequence: "Alt+4"; onActivated: window.switchSpace(window.spaces[3]?.id ?? 0) }
    Shortcut { sequence: "Alt+5"; onActivated: window.switchSpace(window.spaces[4]?.id ?? 0) }
    Shortcut { sequence: "Alt+6"; onActivated: window.switchSpace(window.spaces[5]?.id ?? 0) }
    Shortcut { sequences: Keymap.sequences("split"); onActivated: window.toggleSplit() }
    Shortcut { sequences: Keymap.sequences("settings"); onActivated: window.openSettings() }
    Shortcut { sequences: Keymap.sequences("resources"); onActivated: resources.open() }
    Shortcut { sequences: Keymap.sequences("history"); onActivated: window.showCommandHistory() }
    Shortcut { sequences: Keymap.sequences("downloads"); onActivated: window.openDownloads() }
    Shortcut { sequences: Keymap.sequences("clear"); onActivated: clearDialog.open() }
    Shortcut { sequences: Keymap.sequences("commandBox"); onActivated: commandBar.show(false, "") }
    Shortcut { sequences: Keymap.sequences("closeTab"); onActivated: window.closeTab(window.current) }
    Shortcut { sequences: Keymap.sequences("address"); onActivated: window.editAddress() }
    Shortcut { sequences: Keymap.sequences("nextTab"); onActivated: window.step(1) }
    Shortcut { sequences: Keymap.sequences("previousTab"); onActivated: window.step(-1) }
    Shortcut { sequences: Keymap.sequences("reload"); onActivated: window.view.reload() }
    Shortcut { sequences: Keymap.sequences("back"); onActivated: window.view.goBack() }
    Shortcut { sequences: Keymap.sequences("forward"); onActivated: window.view.goForward() }
    Shortcut { sequences: Keymap.sequences("sidebar"); onActivated: window.compactSidebar = !window.compactSidebar }
    Shortcut { sequences: Keymap.sequences("zoomIn"); onActivated: window.view.zoomFactor = Math.min(3, window.view.zoomFactor + 0.1) }
    Shortcut { sequences: Keymap.sequences("zoomOut"); onActivated: window.view.zoomFactor = Math.max(0.5, window.view.zoomFactor - 0.1) }
    Shortcut { sequences: Keymap.sequences("zoomReset"); onActivated: window.view.zoomFactor = 1 }
    Shortcut { sequence: "Escape"; enabled: window.pageFullScreen; onActivated: window.view.triggerWebAction(WebEngineView.ExitFullScreen) }
    Shortcut { sequences: Keymap.sequences("fullScreen"); onActivated: window.toggleWindowFullScreen() }
    Shortcut { sequences: Keymap.sequences("quit"); onActivated: Qt.quit() }
    Shortcut { sequences: Keymap.sequences("resetLook"); onActivated: window.resetLook() }
    Shortcut { sequences: Keymap.sequences("gameMode"); onActivated: window.setPowerMode(window.powerMode === "game" ? "balanced" : "game") }
}
