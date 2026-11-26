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
    property bool restoreSession: true
    property string downloadFolder: ""   // "" = the system downloads folder
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
                appendTab(p.url, p.title ?? "", true)
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
        // the chosen tab was already visible or hidden before "current" settled
        Qt.callLater(() => view?.load_())
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
                list.push({ url: tab.pageUrl, title: tab.title })
            if (i === current && tab.pinned)
                at = i
        }
        saved.session = JSON.stringify({ tabs: list, current: at })
    }

    Timer { id: sessionTimer; interval: 800; onTriggered: window.saveSession() }
    function touchSession() { sessionTimer.restart() }
    onCurrentChanged: touchSession()
    onMovesChanged: touchSession()
    onClosing: saveSession()

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
    function appendTab(url, title, lazy) {
        tabs.append({ startUrl: String(url), lazy: lazy === true, pageUrl: String(url), title: String(title ?? ""), siteIcon: "", loading: false, pinned: false, asleep: 0 })
        touchSession()
    }

    function openTab(url) {
        appendTab(url, "", false)
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
        touchSession()
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
        if (downloadFolder !== "")
            request.downloadDirectory = downloadFolder
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

    function pageViewAt(index) { return views.itemAt(index) as WebEngineView }

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
            return { index: i, title: tabs.get(i).title || Lang.t("Yeni sekme", "New tab"), memory: use?.memory ?? 0, cpu: use?.cpu ?? 0,
                     state: tabs.get(i).asleep, shared: p ? users[p.renderProcessPid] > 1 : false, current: p === view }
        }).sort((a, b) => b.memory - a.memory)
        resources.total = found.total
    }

    function findInPage() {
        if (!onStartPage)
            findBar.open()
    }
    // the box belongs to the page it was opened on
    onViewChanged: findBar.close()

    function openSettings() { settings.open() }

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
        case WebEnginePermission.PermissionType.MediaAudioCapture: return Lang.t("Mikrofonunu kullanmak istiyor.", "wants to use your microphone.")
        case WebEnginePermission.PermissionType.MediaVideoCapture: return Lang.t("Kameranı kullanmak istiyor.", "wants to use your camera.")
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture: return Lang.t("Kameranı ve mikrofonunu kullanmak istiyor.", "wants to use your camera and microphone.")
        case WebEnginePermission.PermissionType.Geolocation: return Lang.t("Konumunu öğrenmek istiyor.", "wants to know your location.")
        case WebEnginePermission.PermissionType.ClipboardReadWrite: return Lang.t("Panonu okumak ve değiştirmek istiyor.", "wants to read and change your clipboard.")
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
        else if (action.startsWith("settings:")) {
            settings.section = Number(action.slice(9))
            settings.open()
        }
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
            onSettings: window.openSettings()
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
                        required property bool lazy
                        property bool started: false
                        property bool crashed: false
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
                        anchors.fill: parent
                        visible: web === window.view

                        profile: window.profile
                        backgroundColor: Theme.surface
                        settings.fullScreenSupportEnabled: true      // video full screen
                        settings.errorPageEnabled: false             // Velum explains problems itself
                        // a bad certificate is never accepted, only explained
                        onCertificateError: error => {
                            if (error.isMainFrame)
                                failure = { url: String(error.url), text: error.description, certificate: true }
                            error.rejectCertificate()
                        }
                        onRenderProcessTerminated: (status, code) => {
                            // putting a tab to sleep ends its process too; that is not a crash
                            if (status !== WebEngineView.NormalTerminationStatus && lifecycleState === WebEngineView.LifecycleState.Active)
                                crashed = true
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
                        onIconChanged: tabs.setProperty(index, "siteIcon", String(icon))
                        onLoadingChanged: info => {
                            tabs.setProperty(index, "loading", loading)
                            if (info.status === WebEngineView.LoadStartedStatus) {
                                crashed = false
                                failure = null
                            }
                            if (info.status === WebEngineView.LoadSucceededStatus)
                                History.add(String(url), title)
                            // -3 means "stopped": by you, or because another page was asked for
                            if (info.status === WebEngineView.LoadFailedStatus && info.errorCode !== -3 && !failure)
                                failure = { url: String(info.url), text: info.errorString, certificate: false }
                        }
                        onUrlChanged: {
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

            ProblemPage {
                anchors.fill: parent
                radius: card.radius
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

    SettingsPage {
        id: settings
        sleepMode: window.sleepMode
        restoreSession: window.restoreSession
        downloadFolder: window.downloadFolder
        onSleepModeChosen: mode => window.sleepMode = mode
        onRestoreSessionChosen: on => window.restoreSession = on
        onDownloadFolderChosen: folder => window.downloadFolder = folder
        onClearRequested: clearDialog.open()
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

    CommandBar {
        id: commandBar
        anchors.fill: parent
        tabModel: tabs
        shortcuts: window.shortcuts
        history: History
        commands: [
            { name: Lang.t("Sekmeyi sabitle ya da çöz", "Pin or unpin the tab"), keys: "Ctrl+Shift+P", run: () => window.togglePin(window.current) },
            { name: Lang.t("Kapatılan sekmeyi geri aç", "Reopen the closed tab"), keys: "Ctrl+Shift+T", run: () => window.reopenClosed() },
            { name: Lang.t("Yer imi ekle ya da kaldır", "Add or remove a bookmark"), keys: "Ctrl+D", run: () => window.toggleBookmark() },
            { name: Lang.t("Geçmiş", "History"), keys: "Ctrl+H", run: () => Qt.callLater(window.showCommandHistory) },
            { name: Lang.t("İndirmeler", "Downloads"), keys: "Ctrl+J", run: () => side.openDownloads() },
            { name: Lang.t("Kaynaklar: hangi sekme ne kadar yiyor", "Resources: what each tab uses"), keys: "Shift+Esc", run: () => resources.open() },
            { name: Lang.t("Diğer sekmeleri uyut", "Put other tabs to sleep"), keys: "", run: () => window.sleepOthers() },
            { name: Lang.t("Yan paneli daralt ya da genişlet", "Narrow or widen the side bar"), keys: "Ctrl+B", run: () => window.compactSidebar = !window.compactSidebar },
            { name: Lang.t("Sekmeyi kapat", "Close the tab"), keys: "Ctrl+W", run: () => window.closeTab(window.current) },
            { name: Lang.t("Diğer sekmeleri kapat", "Close other tabs"), keys: "", run: () => window.closeOthers(window.current) },
            { name: Lang.t("Sayfada ara", "Find in page"), keys: "Ctrl+F", run: () => Qt.callLater(window.findInPage) },
            { name: window.restoreSession ? Lang.t("Açılışta sekmeleri geri getirme", "Do not reopen tabs at start") : Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start"), keys: "", run: () => window.restoreSession = !window.restoreSession },
            { name: Lang.t("Gezinme verilerini sil", "Delete browsing data"), keys: "Ctrl+Shift+Delete", run: () => clearDialog.open() },
            { name: Lang.t("Ayarlar", "Settings"), keys: "Ctrl+,", run: () => Qt.callLater(window.openSettings) },
            { name: Lang.t("Tam ekran", "Full screen"), keys: "F11", run: () => window.toggleWindowFullScreen() },
            { name: Lang.t("Velum'dan çık", "Quit Velum"), keys: "Ctrl+Q", run: () => Qt.quit() }
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
        MenuItem { text: tabMenu.pinned ? Lang.t("Sabitlemeyi kaldır", "Unpin") : Lang.t("Sabitle", "Pin"); onTriggered: window.togglePin(tabMenu.index) }
        MenuItem { text: Lang.t("Çoğalt", "Duplicate"); onTriggered: window.openTab(tabs.get(tabMenu.index).pageUrl) }
        MenuItem { text: Lang.t("Yenile", "Reload"); onTriggered: (views.itemAt(tabMenu.index) as WebEngineView).reload() }
        MenuItem { text: Lang.t("Uyut", "Sleep"); enabled: tabMenu.index !== window.current; onTriggered: window.sleepTab(tabMenu.index) }
        MenuItem { text: Lang.t("Yer imlerine ekle", "Bookmark"); onTriggered: window.addShortcut(tabs.get(tabMenu.index).pageUrl, tabs.get(tabMenu.index).title) }
        MenuSeparator {}
        MenuItem { text: Lang.t("Kapat", "Close"); onTriggered: window.closeTab(tabMenu.index) }
        MenuItem { text: Lang.t("Diğerlerini kapat", "Close others"); onTriggered: window.closeOthers(tabMenu.index) }
        MenuItem { text: Lang.t("Kapatılanı geri aç", "Reopen closed tab"); enabled: window.closedTabs.length > 0; onTriggered: window.reopenClosed() }
    }

    // keyboard
    Shortcut { sequences: [StandardKey.AddTab]; onActivated: window.newTab() }
    Shortcut { sequence: "Ctrl+Shift+T"; onActivated: window.reopenClosed() }
    Shortcut { sequence: "Ctrl+Shift+P"; onActivated: window.togglePin(window.current) }
    Shortcut { sequence: "Ctrl+D"; onActivated: window.toggleBookmark() }
    Shortcut { sequences: [StandardKey.Find]; onActivated: window.findInPage() }
    Shortcut { sequence: "Ctrl+,"; onActivated: window.openSettings() }
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
