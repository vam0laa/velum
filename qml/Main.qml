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
    function keepWidgets(list) { return homeLogic.keepWidgets(list) }
    function keepTasks(list) { return homeLogic.keepTasks(list) }
    function keepWords(headline, words) { return homeLogic.keepWords(headline, words) }
    function readHome() { return homeLogic.readHome() }
    // the theme studio, made when first opened
    property var studio: null
    Component { id: studioScreen; ThemeStudio {} }
    function openStudio() { return homeLogic.openStudio() }

    function resetLook() { return homeLogic.resetLook() }

    // ---- sharing your look ----
    function themeText() { return homeLogic.themeText() }
    function applyThemeText(text) { return homeLogic.applyThemeText(text) }
    function exportTheme(file) { return homeLogic.exportTheme(file) }
    property string beforeImport: ""        // the look as it was before a file replaced it
    function importTheme(file) { return homeLogic.importTheme(file) }
    function undoImport() { return homeLogic.undoImport() }

    function setStart(name, value) { return homeLogic.setStart(name, value) }
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
    readonly property alias tabCount: views.count
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
    function setPowerMode(mode) { return powerLogic.setPowerMode(mode) }

    function pickToSleep(candidates, used, limit) { return powerLogic.pickToSleep(candidates, used, limit) }
    function keepUnderLimit() { return powerLogic.keepUnderLimit() }
    Timer { interval: 20000; repeat: true; running: window.memoryLimit > 0; triggeredOnStart: true; onTriggered: window.keepUnderLimit() }
    property bool restoreSession: true
    property string downloadFolder: ""   // "" = the system downloads folder
    // split view: two pages side by side. The pair is remembered as the pages themselves,
    // so moving tabs around does not disturb it.
    property WebEngineView splitLeft: null
    property WebEngineView splitRight: null
    property real splitRatio: 0.5
    property bool splitStacked: false     // one above the other instead of side by side
    function swapSplit() {
        const left = splitLeft
        splitLeft = splitRight
        splitRight = left
    }
    property var groups: []               // tab groups: [{ id, name, colour, collapsed }]
    function refreshGroups() { tabLogic.refreshGroups() }
    function newGroup(indices, name) { return tabLogic.newGroup(indices, name) }
    function addToGroup(indices, id) { tabLogic.addToGroup(indices, id) }
    function ungroup(indices) { tabLogic.ungroup(indices) }
    function changeGroup(id, changes) { tabLogic.changeGroup(id, changes) }
    function toggleGroup(id) { tabLogic.toggleGroup(id) }
    function closeGroup(id) { tabLogic.closeGroup(id) }
    function dissolveGroup(id) { tabLogic.dissolveGroup(id) }
    function selectTab(index, stretch) { tabLogic.select(index, stretch) }
    function selection() { return tabLogic.selection() }
    function targets(index) { return tabLogic.targets(index) }
    function clearSelection() { tabLogic.clearSelection() }
    function closeMany(indices) { tabLogic.closeMany(indices) }
    function openTabSearch() { tabSearch.open() }
    property alias tabSearch: tabSearch
    property alias groupMenu: groupMenu
    readonly property bool splitShown: moves >= 0 && !pageFullScreen && splitLeft !== null && splitRight !== null && view !== null
                                       && (view === splitLeft || view === splitRight) && inSpace(splitLeft.index) && inSpace(splitRight.index)
    property var downloads: []        // download requests of this run, newest first
    property var pastDownloads: []    // what earlier downloads fetched, remembered
    readonly property var downloadTools: ({ past: pastDownloads, canOpen: name => !risky(name), open: openDownloaded, again: url => openTab(url), forget: forgetDownload })
    function clearDownloadList() { downloadLogic.clearDownloadList() }
    function recordDownload(entry) { downloadLogic.recordDownload(entry) }
    function openDownloaded(folder, name) { downloadLogic.openDownloaded(folder, name) }
    function forgetDownload(index) { downloadLogic.forgetDownload(index) }
    property var siteZoom: ({})
    property string hoveredLink: ""   // under the pointer, on the page being looked at
    function savePdf(page) { toolLogic.savePdf(page) }
    function pdfDone(path, ok) { toolLogic.pdfDone(path, ok) }
    function savePage() { toolLogic.savePage() }
    function viewSource() { toolLogic.viewSource() }
    function openDevTools(page) { toolLogic.openDevTools(page) }
    function inspect(page) { toolLogic.inspect(page) }
    function zoom(step) { toolLogic.zoom(step) }
    function zoomOf(url) { return toolLogic.zoomOf(url) }
    function toggleMute(index) { toolLogic.toggleMute(index) }
    function goToTab(number) { toolLogic.goToTab(number) }
    property alias tools: toolLogic
    property alias historyMenu: historyMenu
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
    readonly property bool onStartPage: view !== null && !onSettings && !view.popup && (view.url.toString() === "" || view.url.toString() === "about:blank") && !view.loading

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
        tabLogic.readGroups()
        downloadLogic.readDownloads()
        toolLogic.readZoom()
        try {
            const gone = JSON.parse(saved.removedBookmarks)
            if (Array.isArray(gone))
                removedBookmarks = gone
        } catch (e) {
        }
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
            for (const p of session.tabs) {
                appendTab(p.url, p.title ?? "", true, spaces.some(s => s.id === p.space) ? p.space : spaces[0].id)
                if (Number.isInteger(p.group))
                    tabs.setProperty(tabs.count - 1, "group", p.group)
            }
            if (session.tabs.length > 0 || session.current < pinnedCount)
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
        refreshGroups()
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
        if (Shield.forgetOnExit) {      // nothing about this visit is written down
            saved.session = "{}"
            return
        }
        const list = []
        let at = 0
        for (let i = 0; i < tabs.count; i++) {
            const tab = tabs.get(i)
            if (i === current)
                at = pinnedCount + list.length
            if (!tab.pinned && tab.pageUrl !== "" && tab.pageUrl !== "about:blank")
                list.push({ url: tab.pageUrl, title: tab.title, space: tab.space, group: tab.group })
            if (i === current && tab.pinned)
                at = i
        }
        saved.session = JSON.stringify({ tabs: list, current: at })
    }

    Timer { id: sessionTimer; interval: 800; onTriggered: window.saveSession() }
    function touchSession() { sessionTimer.restart() }
    onCurrentChanged: { followCurrent(); touchSession(); if (restored && groups.length > 0) Qt.callLater(refreshGroups) }
    onMovesChanged: touchSession()
    onClosing: { closeMini(); saveSession(); forgetNow() }
    // quitting goes the same way as closing the window
    function quit() {
        close()
        Qt.quit()
    }
    function forgetNow() {
        if (!Shield.forgetOnExit)
            return
        closedTabs = []
        saved.session = "{}"
        History.clear()
        saved.pastDownloads = "[]"
        saved.siteZoom = "{}"
        Shield.clearData(profile)
    }

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
        property alias askDownloads: window.askDownloads
        property alias powerMode: window.powerMode
        property alias memoryLimit: window.memoryLimit
        property alias compactSidebar: window.compactSidebar
        property alias tabsOnTop: window.horizontalTabs
        property alias startBack: window.startBackground
        property alias startPicture: window.startPicture
        property alias startVisited: window.showFrequent
        property alias note: window.note
        property string homeWidgets: ""
        property string pastDownloads: "[]"
        property string siteZoom: "{}"
        property string removedBookmarks: "[]"
        property string groups: "[]"
        property alias splitStacked: window.splitStacked
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

    // what the window does, by subject; the functions above and below hand over to these
    HomeLogic { id: homeLogic; app: window }
    BookmarkLogic { id: bookmarkLogic; app: window }
    DownloadLogic { id: downloadLogic; app: window }
    SpaceLogic { id: spaceLogic; app: window }
    PowerLogic { id: powerLogic; app: window }
    PageLogic { id: pageLogic; app: window }
    PasswordLogic { id: passwordLogic; app: window }
    ExtensionLogic { id: extensionLogic; app: window }
    SiteLogic { id: siteLogic; app: window }
    AskLogic { id: askLogic; app: window }
    DemoLogic { id: demoLogic; app: window }
    TabLogic { id: tabLogic; app: window }
    TabSearch { id: tabSearch; app: window }
    GroupMenu { id: groupMenu; app: window; parent: window.Overlay.overlay }
    BackupLogic { id: backupLogic; app: window }
    ToolLogic { id: toolLogic; app: window }
    HistoryMenu { id: historyMenu }
    property alias accountMenu: accountMenu
    property alias clearDialog: clearDialog
    property alias spaceDialog: spaceDialog
    property alias extensionDialog: extensionDialog
    property alias findBar: findBar
    property alias iconGrabber: iconGrabber
    property alias iconShelf: iconShelf
    property alias login: login
    property alias miniPlayer: miniPlayer
    property alias pagesArea: pagesArea
    property alias reader: reader
    property alias resources: resources
    property alias saved: saved
    property alias scene: scene
    property alias start: start
    property alias studioScreen: studioScreen
    property alias tabs: tabs
    property alias themeWash: themeWash
    property alias topBar: topBar
    property alias views: views

    readonly property string currentHost: view ? hostOf(view.url) : ""
    function hostOf(url) {
        const match = String(url).match(/^https?:\/\/(?:[^\/@]*@)?([^\/:?#]+)/i)
        return match ? match[1].toLowerCase() : ""
    }

    // Adds a tab after the others, in this workspace unless another is named.
    function appendTab(url, title, lazy, inWorkspace) {
        tabs.append({ startUrl: String(url), lazy: lazy === true, pageUrl: String(url), title: String(title ?? ""), siteIcon: "", loading: false, pinned: false, asleep: 0, space: inWorkspace ?? space, kind: "", audible: false, muted: false, group: 0, lead: false, folded: false, chosen: false })
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
        if (closing && closing === fullPage)
            leavePageFull()
        if (closing)
            tools.forgetPage(closing)
        if (closing && closing === findPage)
            findPage = null
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
        if (groups.length > 0)
            Qt.callLater(refreshGroups)
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
        if (groups.length > 0)
            Qt.callLater(refreshGroups)
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

    function addShortcut(typed, title) { return bookmarkLogic.addShortcut(typed, title) }

    readonly property int maxBookmarks: 2000
    function keepBookmarks(list) { return bookmarkLogic.keepBookmarks(list) }

    function saveBookmark(index, title, address, folder) { return bookmarkLogic.saveBookmark(index, title, address, folder) }

    function restoreBookmark(item, index) { return bookmarkLogic.restoreBookmark(item, index) }

    function moveBookmark(from, to) { return bookmarkLogic.moveBookmark(from, to) }

    function renameFolder(from, to) { return bookmarkLogic.renameFolder(from, to) }

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
    function openHistory() { historyPage.open() }
    property alias historyPage: historyPage
    property var removedBookmarks: []     // [{ url, when }], so synchronising does not revive them
    function keepRemoved(list) { bookmarkLogic.keepRemoved(list) }
    function exportBookmarks(file) { bookmarkLogic.exportBookmarks(file) }
    function importBookmarks(file) { bookmarkLogic.importBookmarks(file) }
    property alias backup: backupLogic
    property string backupResult: ""
    function openPasswords() { openSettings("passwords") }
    function openDownloads() { (horizontalTabs ? topBar : side).openDownloads() }

    function importFrom(path, withHistory) { return bookmarkLogic.importFrom(path, withHistory) }

    function toggleBookmark() { return bookmarkLogic.toggleBookmark() }

    property bool askDownloads: false       // ask before every download, not only risky ones
    property var waiting: []                // downloads waiting for your answer
    function risky(name) { return downloadLogic.risky(name) }
    function startDownload(request) { return downloadLogic.startDownload(request) }
    function keepDownload(request) { return downloadLogic.keepDownload(request) }
    function answerDownload(yes) { return downloadLogic.answerDownload(yes) }

    // ---- workspaces ----
    function inSpace(index) { return spaceLogic.inSpace(index) }

    function visibleTabs() { return spaceLogic.visibleTabs() }

    function neighbourOf(index) { return spaceLogic.neighbourOf(index) }

    function followCurrent() { return spaceLogic.followCurrent() }

    function spaceName(item) { return spaceLogic.spaceName(item) }

    function readSpaces(text) { return spaceLogic.readSpaces(text) }

    function keepSpaces(list) { return spaceLogic.keepSpaces(list) }

    function switchSpace(id) { return spaceLogic.switchSpace(id) }

    function addSpace(name) { return spaceLogic.addSpace(name) }

    function renameSpace(id, name) { return spaceLogic.renameSpace(id, name) }

    function removeSpace(id) { return spaceLogic.removeSpace(id) }

    function moveToSpace(index, id) { return spaceLogic.moveToSpace(index, id) }

    // ---- sleeping tabs ----
    function sleepTarget(idle, advice, pinned, audible, loading) { return powerLogic.sleepTarget(idle, advice, pinned, audible, loading) }

    function sleepIdleTabs(now) { return powerLogic.sleepIdleTabs(now) }

    function pageViewAt(index) { return views.itemAt(index) as WebEngineView }
    function tabIndexOf(page) {
        for (let i = 0; i < tabs.count; i++)
            if (views.itemAt(i) === page)
                return i
        return -1
    }

    // ---- split view ----
    function splitWith(index) { return pageLogic.splitWith(index) }

    function unsplit() { return pageLogic.unsplit() }

    function toggleSplit() { return pageLogic.toggleSplit() }

    // ---- the small video window ----
    function toggleMini() { return pageLogic.toggleMini() }

    function openMini(index) { return pageLogic.openMini(index) }

    function closeMini() { return pageLogic.closeMini() }

    // ---- reading mode ----
    function toggleReader() { return pageLogic.toggleReader() }

    function closeReader(page) { return pageLogic.closeReader(page) }

    function sizeReader(by) { return pageLogic.sizeReader(by) }

    Reader { id: reader }

    // ---- passwords ----
    LoginScript { id: login }
    property alias loginScript: login

    function watchLogins() { return passwordLogic.watchLogins() }

    function readStrings(text) {
        try {
            const list = JSON.parse(text)
            return Array.isArray(list) ? list.filter(x => typeof x === "string") : []
        } catch (e) {
            return []
        }
    }

    function offerPassword(origin, user, password) { return passwordLogic.offerPassword(origin, user, password) }

    function savePassword(user) { return passwordLogic.savePassword(user) }

    function neverFor(origin) { return passwordLogic.neverFor(origin) }

    function askAgainFor(origin) { return passwordLogic.askAgainFor(origin) }

    function findAccounts(page) { return passwordLogic.findAccounts(page) }

    function fillPassword() { return passwordLogic.fillPassword() }

    function fillAccount(page, user) { return passwordLogic.fillAccount(page, user) }

    // ---- extensions ----
    function refreshExtensions() { return extensionLogic.refreshExtensions() }

    function askExtension(text, file) { return extensionLogic.askExtension(text, file) }

    function addExtension() { return extensionLogic.addExtension() }
    property string fetched: ""       // the downloaded package being installed
    property var extensionQueue: []   // store ids you agreed to, still to be installed

    function queueExtensions(ids) { return extensionLogic.queueExtensions(ids) }
    function installNext() { return extensionLogic.installNext() }

    function extensionInstalled(extension) { return extensionLogic.extensionInstalled(extension) }

    function enableExtension(extension, on) { return extensionLogic.enableExtension(extension, on) }
    function removeExtension(extension) { return extensionLogic.removeExtension(extension) }

    // ---- the start page ----
    function refreshFrequent() { return siteLogic.refreshFrequent() }
    onOnStartPageChanged: if (onStartPage) refreshFrequent()

    function iconName(url) { return siteLogic.iconName(url) }
    function iconFor(url) { return siteLogic.iconFor(url) }
    function keepIcon(pageUrl, icon) { return siteLogic.keepIcon(pageUrl, icon) }
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

    function explainIfBlank(page, url, status) { return pageLogic.explainIfBlank(page, url, status) }

    function say(text) {
        notice = text
        noticeTimer.restart()
    }
    Timer { id: noticeTimer; interval: 3500; onTriggered: window.notice = "" }

    function sleepState(index) { return powerLogic.sleepState(index) }

    function sleepTab(index) { return powerLogic.sleepTab(index) }

    function wakeTab(index) { return powerLogic.wakeTab(index) }

    function sleepOthers() { return powerLogic.sleepOthers() }

    Timer { interval: window.powerMode === "balanced" ? 30000 : 5000; repeat: true; running: window.autoSleep; onTriggered: window.sleepIdleTabs(Date.now()) }

    function measure() { return powerLogic.measure() }

    function findInPage() { return pageLogic.findInPage() }
    // the box belongs to the page it was opened on, and so do its marks
    property WebEngineView findPage: null
    onViewChanged: {
        hoveredLink = ""
        if (findPage && findPage !== view) {
            findPage.findText("")
            findPage = null
        }
        findBar.close()
        if (pageFullScreen && fullPage !== view)
            leavePageFull()
    }

    // sites you let open windows by themselves, until Velum is closed
    property var popupSites: []
    property var permissions: []
    function listPermissions() { askLogic.listPermissions() }
    function resetPermission(item) { askLogic.resetPermission(item) }
    function newWindowFrom(from, clicked, background, fill) { return askLogic.newWindowFrom(from, clicked, background, fill) }

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

    function removeShortcut(index) { return bookmarkLogic.removeShortcut(index) }

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

    function wishFor(type) { return askLogic.wishFor(type) }

    function answer(item, allow) { return askLogic.answer(item, allow) }

    function dropAsks(page) { return askLogic.dropAsks(page) }

    function demo(action) { return demoLogic.demo(action) }

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
        Rectangle { anchors.fill: parent; color: Theme.styled("window", "background", Theme.frameBack) }

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
                onPicked: i => { window.clearSelection(); window.current = i }
                onClosed: i => window.closeTab(i)
                onNewTab: window.newTab()
                pinnedCount: window.pinnedCount
                host: window.currentHost
                onReloadPage: window.view.reload()
                onClearData: clearDialog.open()
                onSettings: window.openSettings()
                downloads: window.downloads
                onShowFolder: folder => Qt.openUrlExternally(Files.toUrl(folder))
                onClearDownloads: window.clearDownloadList()
                onMoved: (from, to) => window.moveTab(from, to)
                onMenuRequested: i => { tabMenu.index = i; tabMenu.popup() }
                onMuteToggled: i => window.toggleMute(i)
                groups: window.groups
                onSelected: (i, stretch) => window.selectTab(i, stretch)
                onGroupToggled: id => window.toggleGroup(id)
                onGroupMenu: (id, at) => groupMenu.showFor(id, at)
                spaces: window.spaces
                space: window.space
                onSpaceChosen: id => window.switchSpace(id)
                onSpaceEdit: id => spaceDialog.show(id, window.spaceName(window.spaces.find(s => s.id === id)), window.spaces.length > 1)
                onSpaceAdd: spaceDialog.show(0, "", false)
                onMenu: at => window.showMenu(at)
                downloadTools: window.downloadTools
                onBackMenu: (forward, at) => historyMenu.showFor(window.view, forward, at)
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
                onPicked: i => { window.clearSelection(); window.current = i }
                onClosed: i => window.closeTab(i)
                onNewTab: window.newTab()
                onMoved: (from, to) => window.moveTab(from, to)
                onMenuRequested: i => { tabMenu.index = i; tabMenu.popup() }
                onMuteToggled: i => window.toggleMute(i)
                groups: window.groups
                onSelected: (i, stretch) => window.selectTab(i, stretch)
                onGroupToggled: id => window.toggleGroup(id)
                onGroupMenu: (id, at) => groupMenu.showFor(id, at)
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
                downloadTools: window.downloadTools
                onBackMenu: (forward, at) => historyMenu.showFor(window.view, forward, at)
                onMaximize: window.toggleWindowFullScreen()
                onQuitRequested: window.close()
            gaming: window.powerMode === "game"
            onGameRequested: window.setPowerMode(window.powerMode === "game" ? "balanced" : "game")
            onOpenBookmarksRequested: window.openBookmarks()
            onHistoryRequested: window.openHistory()
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
                onClearDownloads: window.clearDownloadList()
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

                PageOverlay { app: window; anchors.fill: pagesArea; z: 2; visible: !window.pageFullScreen }

                Item {
                    id: pagesArea
                    anchors.fill: parent

                    Repeater {
                        id: views
                        model: tabs

                        PageView { app: window }
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
                    readonly property bool flat: window.splitStacked
                    x: flat ? 0 : Math.round(parent.width * window.splitRatio) - 4
                    y: flat ? Math.round(parent.height * window.splitRatio) - 4 : 0
                    width: flat ? parent.width : 8
                    height: flat ? 8 : parent.height
                    z: 2
                    Rectangle {
                        anchors.centerIn: parent
                        readonly property int thick: handle.containsMouse || handle.pressed ? 4 : 2
                        width: splitter.flat ? parent.width : thick
                        height: splitter.flat ? thick : parent.height
                        color: handle.containsMouse || handle.pressed ? Theme.accent : Theme.line
                    }
                    MouseArea {
                        id: handle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: splitter.flat ? Qt.SplitVCursor : Qt.SplitHCursor
                        preventStealing: true
                        onPositionChanged: mouse => {
                            if (!pressed)
                                return
                            const at = mapToItem(splitter.parent, mouse.x, mouse.y)
                            const share = splitter.flat ? at.y / splitter.parent.height : at.x / splitter.parent.width
                            window.splitRatio = Math.max(0.2, Math.min(0.8, share))
                        }
                        onDoubleClicked: window.splitRatio = 0.5
                    }
                }
                // marks which half the address bar and the keys act on
                Rectangle {
                    visible: window.splitShown
                    x: window.view?.x ?? 0
                    y: window.view?.y ?? 0
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
                    radius: Theme.styled("notice", "border-radius", Theme.radius)
                    z: 3
                    opacity: window.notice !== "" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.smooth } }
                    Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
                    Shadow { radius: Theme.radius }
                    color: Theme.styled("notice", "background", Theme.raised)
                    border.color: Theme.styled("notice", "border-color", Theme.line)
                    Text { id: noticeText; anchors { fill: parent; leftMargin: 16; rightMargin: 16 } text: window.notice; textFormat: Text.PlainText; color: Theme.styled("notice", "color", Theme.text); font.family: Theme.styled("notice", "font-family", Theme.ui); font.pixelSize: Theme.styled("notice", "font-size", Theme.size(17)); elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
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
                    askDownloads: window.askDownloads
                    onAskDownloadsChosen: on => window.askDownloads = on
                    backupResult: window.backupResult
                    onBackupRequested: (file, password) => window.backupResult = window.backup.save(file, password)
                    onRestoreRequested: (file, password) => window.backupResult = window.backup.restore(file, password)
                    permissions: window.permissions
                    popupSites: window.popupSites
                    onPermissionsWanted: window.listPermissions()
                    onResetPermission: item => window.resetPermission(item)
                    onForgetPopup: site => window.popupSites = window.popupSites.filter(s => s !== site)
                    canUndoImport: window.beforeImport !== ""
                    onUndoImport: window.undoImport()
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
                    onOpenStudio: window.openStudio()
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
        onConfirmed: { History.clear(); window.pastDownloads = []; saved.pastDownloads = "[]"; Shield.clearData(window.profile) }
    }

    ConfirmDialog {
        id: downloadDialog
        readonly property var item: window.waiting[0] ?? null
        heading: item && window.risky(String(item.downloadFileName).replace(/\.velum-hold$/, "")) ? Lang.t("Bu dosya program çalıştırabilir. İndirilsin mi?", "This file can run programs. Download it?") : Lang.t("Dosya indirilsin mi?", "Download this file?")
        detail: item ? String(item.downloadFileName).replace(/\.velum-hold$/, "") + "\n" + window.hostOf(item.url) + Lang.t("\nYalnızca güvendiğin yerden gelen dosyaları indir.", "\nOnly download files from places you trust.") : ""
        action: Lang.t("İndir", "Download")
        // answered by a button, or closed another way: then the file is not fetched
        property bool yes: false
        onConfirmed: yes = true
        onClosed: Qt.callLater(() => { const said = yes; yes = false; window.answerDownload(said) })
    }
    onWaitingChanged: if (waiting.length > 0 && !downloadDialog.opened) Qt.callLater(() => { if (window.waiting.length > 0) downloadDialog.open() })

    ConfirmDialog {
        id: extensionDialog
        heading: Lang.t("Bu eklenti kurulsun mu?", "Install this extension?")
        detail: Lang.t("Eklentiler gezdiğin sayfaları okuyup değiştirebilir, yazdığın parolaları da görebilir. Yalnızca güvendiğini kur.", "Extensions can read and change the pages you visit, including passwords you type. Install only what you trust.")
                + (window.wantedExtension && !window.wantedExtension.file ? Lang.t(" Paket için Google'a bağlanılacak.", " Google will be contacted for the package.") : "")
        action: Lang.t("Kur", "Install")
        onConfirmed: window.addExtension()
    }

    HistoryPage {
        id: historyPage
        onChosen: target => window.navigate(target, false)
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
        onExportRequested: file => window.exportBookmarks(file)
        onHtmlRequested: file => window.importBookmarks(file)
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

    CommandList { id: commandList; app: window }

    CommandBar {
        id: commandBar
        anchors.fill: parent
        tabModel: tabs
        shortcuts: window.shortcuts
        history: History
        commands: commandList.list
        onOpened: (target, inNewTab) => window.navigate(target, inNewTab)
        onTabChosen: i => window.current = i
        onDismissed: if (window.view && !window.onStartPage) window.view.forceActiveFocus()
    }

    // the window as it was before it filled the screen, to give it back that way
    property int beforeFull: Window.Windowed
    property int beforePageFull: Window.Windowed
    property WebEngineView fullPage: null       // the page filling the screen, if one does
    function toggleWindowFullScreen() { return pageLogic.toggleWindowFullScreen() }
    function enterPageFull(page) { return pageLogic.enterPageFull(page) }
    function leavePageFull() { return pageLogic.leavePageFull() }

    PageMenu {
        id: pageMenu
        onOpenInTab: url => window.openTab(url)
        onSearchFor: text => window.openTab(String(Address.search(text)))
        onFind: window.findInPage()
        onSavePdf: window.savePdf(view)
        onSavePage: window.savePage()
        onViewSource: window.viewSource()
        onInspect: window.inspect(view)
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
    MainMenu { id: mainMenu; app: window }

    // choosing between several saved accounts; five are offered
    AppMenu {
        id: accountMenu
        AppMenuItem { readonly property var account: window.view?.accounts[0]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[1]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[2]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[3]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
        AppMenuItem { readonly property var account: window.view?.accounts[4]; shown: account !== undefined; text: account ? account.user || Lang.t("(adsız)", "(no name)") : ""; onTriggered: window.fillAccount(window.view, account.user) }
    }

    TabMenu { id: tabMenu; app: window }

    Shortcuts { app: window }

}
