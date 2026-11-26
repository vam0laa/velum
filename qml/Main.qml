import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

ApplicationWindow {
    id: window

    property list<string> startUrls
    property alias commandBar: commandBar
    property bool hasWidevine
    property string profileName: "velum"   // the folder logins are kept in; tests use their own
    property int current: 0
    property bool compactSidebar: false
    property bool pageFullScreen: false
    property int moves: 0             // counts reorderings, so that "view" is looked up again
    property int pinnedCount: 0
    property var closedTabs: []       // for "reopen closed tab", newest last
    property var shortcuts: []        // shown on the start page: [{ title, url }]
    property int sleepMode: 1                    // 0 never, 1 early, 2 relaxed
    readonly property bool autoSleep: sleepMode > 0
    readonly property int freezeAfter: (sleepMode === 2 ? 5 : 2) * 60 * 1000      // milliseconds unseen
    readonly property int discardAfter: (sleepMode === 2 ? 20 : 10) * 60 * 1000
    property var downloads: []        // download requests of this run, newest first
    property var asks: []             // unanswered permission requests: [{ page, permission, site, wish }]
    // the question for the page being looked at, if it has one
    readonly property var ask: asks.find(a => a.page === view) ?? null
    // the page of the current tab; "views.count" and "moves" make this update when tabs change
    readonly property WebEngineView view: (moves, views.count > 0) ? views.itemAt(current) as WebEngineView : null
    readonly property bool onStartPage: view !== null && (view.url.toString() === "" || view.url.toString() === "about:blank") && !view.loading

    width: 1280
    height: 800
    visible: true
    color: Theme.frame
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
        // Present Velum as the Chrome engine it is. Some sites refuse names they do not know.
        profile.httpUserAgent = profile.httpUserAgent.replace(/QtWebEngine\/\S+\s/, "")
        shortcuts = readList(saved.shortcuts)
        // pinned tabs come back first, then what was asked for on the command line
        const pins = readList(saved.pinned)
        for (const p of pins) {
            openTab(p.url)
            tabs.setProperty(current, "pinned", true)
            pinnedCount++
        }
        for (const u of startUrls)
            openTab(u)
        if (startUrls.length === 0)
            openTab("")
        current = pinnedCount < tabs.count ? pinnedCount : 0
        restored = true
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
            list.push({ url: tabs.get(i).pageUrl })
        saved.pinned = JSON.stringify(list)
    }

    // remembered between starts
    Settings {
        id: saved
        property string pinned: "[]"
        property string shortcuts: "[]"
        property alias sleepMode: window.sleepMode
        property alias compactSidebar: window.compactSidebar
        property alias width: window.width
        property alias height: window.height
    }

    ListModel { id: tabs }

    readonly property string currentHost: view ? hostOf(view.url) : ""
    function hostOf(url) {
        const match = String(url).match(/^https?:\/\/(?:[^\/@]*@)?([^\/:?#]+)/i)
        return match ? match[1].toLowerCase() : ""
    }

    // Adds a tab after the others, switches to it and returns its page.
    function openTab(url) {
        tabs.append({ startUrl: String(url), pageUrl: String(url), title: "", siteIcon: "", loading: false, pinned: false, asleep: 0 })
        current = tabs.count - 1
        if (String(url) === "")
            Qt.callLater(() => start.field.forceActiveFocus())
        return views.itemAt(current) as WebEngineView
    }

    function closeTab(index) {
        if (index < 0 || index >= tabs.count)
            return
        const tab = tabs.get(index)
        const wasPinned = tab.pinned
        if (tab.pageUrl !== "" && tab.pageUrl !== "about:blank")
            closedTabs = closedTabs.concat([{ url: tab.pageUrl, index: index }]).slice(-25)
        if (tabs.count === 1)          // there is always one tab; closing the last one empties it
            openTab("")
        const next = index < current ? current - 1 : Math.min(current, tabs.count - 2)
        if (wasPinned)
            pinnedCount--
        tabs.remove(index)
        current = next
        moves++
        if (wasPinned)
            savePinned()
    }

    function reopenClosed() {
        if (closedTabs.length === 0)
            return
        const last = closedTabs[closedTabs.length - 1]
        closedTabs = closedTabs.slice(0, -1)
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
            if (i !== index && !tabs.get(i).pinned) {
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
        if (url === "" || url === "about:blank" || Address.isSearch(typed) || shortcuts.some(s => s.url === url) || shortcuts.length >= 500)
            return false
        const name = title || Address.display(url).replace(/^(https?:\/\/)?(www\.)?/, "").split("/")[0]
        shortcuts = shortcuts.concat([{ title: name, url: url }])
        saved.shortcuts = JSON.stringify(shortcuts)
        return true
    }

    // Ctrl+D: bookmark the page, or remove the bookmark it already has
    function toggleBookmark() {
        if (onStartPage)
            return
        const url = String(view.url)
        const at = shortcuts.findIndex(s => s.url === url)
        if (at >= 0)
            removeShortcut(at)
        else
            addShortcut(url, view.title)
    }

    function startDownload(request) {
        request.accept()            // saved into your downloads folder, never opened
        downloads = [request].concat(downloads)
        side.openDownloads()
        // a tab that was opened only to fetch the file is closed again
        for (let i = tabs.count - 1; i >= 0 && tabs.count > 1; i--) {
            const page = views.itemAt(i) as WebEngineView
            if (page && page === view && tabs.get(i).pageUrl === "")
                closeTab(i)
        }
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

    function sleepState(index) { return index >= 0 && index < tabs.count ? tabs.get(index).asleep : -1 }

    // asked for by hand: as deep as the engine allows
    function sleepTab(index) {
        const page = views.itemAt(index) as WebEngineView
        if (page && page !== view && page.url.toString() !== "" && !page.loading)
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

    Timer { interval: 30000; repeat: true; running: window.autoSleep; onTriggered: window.sleepIdleTabs(Date.now()) }

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
            return { index: i, title: tabs.get(i).title || "Yeni sekme", memory: use?.memory ?? 0, cpu: use?.cpu ?? 0,
                     state: tabs.get(i).asleep, shared: p ? users[p.renderProcessPid] > 1 : false, current: p === view }
        }).sort((a, b) => b.memory - a.memory)
        resources.total = found.total
    }

    function showCommandHistory() {
        commandBar.show(false, "", true)
    }

    function removeShortcut(index) {
        shortcuts = shortcuts.filter((s, i) => i !== index)
        saved.shortcuts = JSON.stringify(shortcuts)
    }

    function navigate(target, inNewTab) {
        if (inNewTab && !onStartPage)
            openTab(String(target))
        else
            view.url = target
        view.forceActiveFocus()
    }

    function step(by) {
        current = (current + by + tabs.count) % tabs.count
    }

    // what a permission means, in words; empty for the ones Velum always refuses
    function wishFor(type) {
        switch (type) {
        case WebEnginePermission.PermissionType.MediaAudioCapture: return "Mikrofonunu kullanmak"
        case WebEnginePermission.PermissionType.MediaVideoCapture: return "Kameranı kullanmak"
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture: return "Kameranı ve mikrofonunu kullanmak"
        case WebEnginePermission.PermissionType.Geolocation: return "Konumunu öğrenmek"
        case WebEnginePermission.PermissionType.ClipboardReadWrite: return "Panonu okumak ve değiştirmek"
        case WebEnginePermission.PermissionType.MouseLock: return "Fare imlecini kilitlemek"
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
        else if (action === "sleep")
            sleepOthers()
    }

    function showCommandBox(text) {
        commandBar.show(true, text)
    }

    function editAddress() {
        commandBar.show(false, onStartPage ? "" : String(view.url))
    }

    function newTab() {
        commandBar.show(true, "")
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: side
            Layout.fillHeight: true
            visible: !window.pageFullScreen
            compact: window.compactSidebar
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
            downloads: window.downloads
            onShowFolder: folder => Qt.openUrlExternally("file://" + folder.split("/").map(encodeURIComponent).join("/"))
            onClearDownloads: window.downloads = window.downloads.filter(d => !d.isFinished)
            onMoved: (from, to) => window.moveTab(from, to)
            onMenuRequested: i => { tabMenu.index = i; tabMenu.popup() }
        }

        // the page, as a rounded card inside the frame
        Rectangle {
            id: card
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: window.pageFullScreen ? 0 : Theme.gap
            Layout.leftMargin: 0
            radius: window.pageFullScreen ? 0 : Theme.radius
            color: Theme.surface

            Item {
                anchors.fill: parent

                Repeater {
                    id: views
                    model: tabs

                    WebEngineView {
                        id: web
                        required property int index
                        required property string startUrl
                        property double hiddenSince: 0     // when it was last looked at; 0 while shown
                        // a tab being looked at is always awake
                        onVisibleChanged: {
                            if (visible) {
                                lifecycleState = WebEngineView.LifecycleState.Active
                                hiddenSince = 0
                            } else {
                                hiddenSince = Date.now()
                            }
                        }
                        onLifecycleStateChanged: tabs.setProperty(index, "asleep", lifecycleState)
                        anchors.fill: parent
                        visible: web === window.view

                        profile: window.profile
                        backgroundColor: Theme.surface
                        settings.fullScreenSupportEnabled: true      // video full screen
                        settings.dnsPrefetchEnabled: false           // no lookups for links you did not click
                        settings.hyperlinkAuditingEnabled: false     // no "ping" tracking on links
                        settings.pluginsEnabled: true
                        settings.pdfViewerEnabled: true

                        Component.onCompleted: {
                            if (startUrl !== "")
                                url = startUrl
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
                            tabs.setProperty(index, "title", url.toString() === "about:blank" ? "" : title)
                            History.setTitle(String(url), title)
                        }
                        onIconChanged: tabs.setProperty(index, "siteIcon", String(icon))
                        onLoadingChanged: info => {
                            tabs.setProperty(index, "loading", loading)
                            if (info.status === WebEngineView.LoadSucceededStatus)
                                History.add(String(url), title)
                        }
                        onUrlChanged: {
                            tabs.setProperty(index, "pageUrl", String(url))
                            if (tabs.get(index).pinned)
                                window.savePinned()
                        }

                        // links that ask for a new window become tabs
                        onNewWindowRequested: request => request.openIn(window.openTab(""))
                        onWindowCloseRequested: window.closeTab(index)

                        onFullScreenRequested: request => {
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

            PermissionBar {
                anchors { top: parent.top; left: parent.left; margins: 12 }
                z: 2
                visible: window.ask !== null
                site: window.ask?.site ?? ""
                wish: window.ask?.wish ?? ""
                onAnswered: allow => window.answer(window.ask, allow)
            }

            StartPage {
                id: start
                anchors.fill: parent
                radius: card.radius
                visible: window.onStartPage
                hasWidevine: window.hasWidevine
                field.pageUrl: ""
                shortcuts: window.shortcuts.slice(0, 10)
                onAddShortcut: typed => window.addShortcut(typed)
                onRemoveShortcut: i => window.removeShortcut(i)
                onGo: target => {
                    window.view.url = target
                    field.text = ""
                    window.view.forceActiveFocus()
                }
            }
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
        heading: "Gezinme verileri silinsin mi?"
        detail: "Geçmiş, çerezler ve önbellek silinir; bütün sitelerden çıkış yapılır. Yer imlerin kalır. Bu geri alınamaz."
        action: "Sil"
        onConfirmed: { History.clear(); Shield.clearData(window.profile) }
    }

    CommandBar {
        id: commandBar
        anchors.fill: parent
        tabModel: tabs
        shortcuts: window.shortcuts
        history: History
        commands: [
            { name: "Sekmeyi sabitle ya da çöz", keys: "Ctrl+Shift+P", run: () => window.togglePin(window.current) },
            { name: "Kapatılan sekmeyi geri aç", keys: "Ctrl+Shift+T", run: () => window.reopenClosed() },
            { name: "Yer imi ekle ya da kaldır", keys: "Ctrl+D", run: () => window.toggleBookmark() },
            { name: "Geçmiş", keys: "Ctrl+H", run: () => Qt.callLater(window.showCommandHistory) },
            { name: "İndirmeler", keys: "Ctrl+J", run: () => side.openDownloads() },
            { name: "Kaynaklar: hangi sekme ne kadar yiyor", keys: "Shift+Esc", run: () => resources.open() },
            { name: "Diğer sekmeleri uyut", keys: "", run: () => window.sleepOthers() },
            { name: "Yan paneli daralt ya da genişlet", keys: "Ctrl+B", run: () => window.compactSidebar = !window.compactSidebar },
            { name: "Sekmeyi kapat", keys: "Ctrl+W", run: () => window.closeTab(window.current) },
            { name: "Diğer sekmeleri kapat", keys: "", run: () => window.closeOthers(window.current) },
            { name: "Gezinme verilerini sil", keys: "Ctrl+Shift+Delete", run: () => clearDialog.open() },
            { name: "Tam ekran", keys: "F11", run: () => window.toggleWindowFullScreen() },
            { name: "Velum'dan çık", keys: "Ctrl+Q", run: () => Qt.quit() }
        ]
        onOpened: (target, inNewTab) => window.navigate(target, inNewTab)
        onTabChosen: i => window.current = i
        onDismissed: if (window.view && !window.onStartPage) window.view.forceActiveFocus()
    }

    function toggleWindowFullScreen() {
        visibility === Window.FullScreen ? showNormal() : showFullScreen()
    }

    AppMenu {
        id: tabMenu
        property int index: 0
        readonly property bool pinned: index < window.pinnedCount
        MenuItem { text: tabMenu.pinned ? "Sabitlemeyi kaldır" : "Sabitle"; onTriggered: window.togglePin(tabMenu.index) }
        MenuItem { text: "Çoğalt"; onTriggered: window.openTab(tabs.get(tabMenu.index).pageUrl) }
        MenuItem { text: "Yenile"; onTriggered: (views.itemAt(tabMenu.index) as WebEngineView).reload() }
        MenuItem { text: "Uyut"; enabled: tabMenu.index !== window.current; onTriggered: window.sleepTab(tabMenu.index) }
        MenuItem { text: "Yer imlerine ekle"; onTriggered: window.addShortcut(tabs.get(tabMenu.index).pageUrl, tabs.get(tabMenu.index).title) }
        MenuSeparator {}
        MenuItem { text: "Kapat"; onTriggered: window.closeTab(tabMenu.index) }
        MenuItem { text: "Diğerlerini kapat"; onTriggered: window.closeOthers(tabMenu.index) }
        MenuItem { text: "Kapatılanı geri aç"; enabled: window.closedTabs.length > 0; onTriggered: window.reopenClosed() }
    }

    // keyboard
    Shortcut { sequences: [StandardKey.AddTab]; onActivated: window.newTab() }
    Shortcut { sequence: "Ctrl+Shift+T"; onActivated: window.reopenClosed() }
    Shortcut { sequence: "Ctrl+Shift+P"; onActivated: window.togglePin(window.current) }
    Shortcut { sequence: "Ctrl+D"; onActivated: window.toggleBookmark() }
    Shortcut { sequence: "Shift+Escape"; onActivated: resources.open() }
    Shortcut { sequence: "Ctrl+H"; onActivated: window.showCommandHistory() }
    Shortcut { sequence: "Ctrl+J"; onActivated: side.openDownloads() }
    Shortcut { sequence: "Ctrl+Shift+Del"; onActivated: clearDialog.open() }
    Shortcut { sequence: "Ctrl+K"; onActivated: commandBar.show(false, "") }
    Shortcut { sequence: "Ctrl+W"; onActivated: window.closeTab(window.current) }
    Shortcut { sequences: ["Ctrl+L", "Alt+D"]; onActivated: window.editAddress() }
    Shortcut { sequence: "Ctrl+Tab"; onActivated: window.step(1) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+Shift+Backtab"]; onActivated: window.step(-1) }
    Shortcut { sequences: ["Ctrl+R", "F5"]; onActivated: window.view.reload() }
    Shortcut { sequence: "Alt+Left"; onActivated: window.view.goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: window.view.goForward() }
    Shortcut { sequence: "Ctrl+B"; onActivated: window.compactSidebar = !window.compactSidebar }
    Shortcut { sequences: ["Ctrl++", "Ctrl+="]; onActivated: window.view.zoomFactor = Math.min(3, window.view.zoomFactor + 0.1) }
    Shortcut { sequence: "Ctrl+-"; onActivated: window.view.zoomFactor = Math.max(0.5, window.view.zoomFactor - 0.1) }
    Shortcut { sequence: "Ctrl+0"; onActivated: window.view.zoomFactor = 1 }
    Shortcut { sequence: "Escape"; enabled: window.pageFullScreen; onActivated: window.view.triggerWebAction(WebEngineView.ExitFullScreen) }
    Shortcut { sequence: "F11"; onActivated: window.toggleWindowFullScreen() }
    Shortcut { sequences: [StandardKey.Quit]; onActivated: Qt.quit() }
}
