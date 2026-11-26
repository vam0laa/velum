import QtQuick
import QtWebChannel
import QtWebEngine

// One tab's page: what it may do, what it asks for, and how it keeps the window informed.
WebEngineView {
    id: web
    required property var app      // the window this page is shown in
    required property int index
    required property string startUrl
    required property bool lazy
    required property string kind
    property bool started: false
    property bool popup: false          // opened by a page
    property bool crashed: false
    property string loginOrigin: ""     // set while a login form is shown
    property var accounts: []           // saved logins that fit it
    // how the watcher inside the page talks to Velum
    property QtObject loginBridge: QtObject {
        WebChannel.id: "velum"
        function offer(origin, user, password) { if (!app.isPrivate) app.offerPassword(String(origin), String(user), String(password)) }
        function form(origin, present) {
            web.loginOrigin = present ? String(origin) : ""
            app.findAccounts(web)
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
    onLifecycleStateChanged: app.tabs.setProperty(index, "asleep", lifecycleState)
    readonly property bool beside: app.splitShown && (web === app.splitLeft || web === app.splitRight)
    // "parent" is the small window while the video is out there
    readonly property real room: parent?.width ?? 0
    readonly property real tall: parent?.height ?? 0
    readonly property bool stacked: beside && app.splitStacked
    readonly property real divide: Math.round((stacked ? tall : room) * app.splitRatio)
    visible: web === app.view || web === app.miniPage || beside
    x: beside && !stacked && web === app.splitRight ? divide + 4 : 0
    y: stacked && web === app.splitRight ? divide + 4 : 0
    width: !beside || stacked ? room : web === app.splitLeft ? divide - 4 : room - divide - 4
    height: !stacked ? tall : web === app.splitLeft ? divide - 4 : tall - divide - 4
    // clicking into the other half makes that tab the current one
    onActiveFocusChanged: if (activeFocus && beside && web !== app.view) app.current = index

    profile: app.profile
    // an empty tab lets the glass through; a web page gets a solid sheet
    // a web page that sets no colour of its own expects white behind its black writing
    // (darkened pages lie on the theme's own colour instead)
    backgroundColor: url.toString() === "" || url.toString() === "about:blank" ? (Theme.seeThrough ? "transparent" : Theme.surface)
        : Theme.darkening ? Theme.surface : "white"
    settings.fullScreenSupportEnabled: true      // video full screen
    settings.errorPageEnabled: false             // Velum explains problems itself
    // saving power: nothing starts playing by itself
    settings.playbackRequiresUserGesture: app.powerMode === "saver"
    // a bad certificate is never accepted, only explained
    onCertificateError: error => {
        if (error.isMainFrame)
            failure = { url: String(error.url), text: error.description, certificate: true }
        error.rejectCertificate()
    }
    onRenderProcessTerminated: (status, code) => {
        if (web === app.miniPage)
            app.closeMini()
        // putting a tab to sleep ends its process too; that is not a crash
        if (status !== WebEngineView.NormalTerminationStatus && lifecycleState === WebEngineView.LifecycleState.Active)
            crashed = true
    }
    onContextMenuRequested: request => {
        request.accepted = true          // Velum draws its own menu
        app.pageMenu.view = web
        app.pageMenu.describe(request)
        const at = web.mapToItem(null, request.position.x, request.position.y)
        app.pageMenu.popup(at.x, at.y - (app.header?.height ?? 0))
    }
    onFindTextFinished: result => {
        if (web === app.view) {
            app.findBar.matches = result.numberOfMatches
            app.findBar.current = result.activeMatch
        }
    }
    settings.dnsPrefetchEnabled: false           // no lookups for links you did not click
    settings.hyperlinkAuditingEnabled: false     // no "ping" tracking on links
    settings.pluginsEnabled: true
    settings.pdfViewerEnabled: true
    // a turn of the wheel glides instead of jumping; the engine leaves this off
    settings.scrollAnimatorEnabled: Theme.moving
    // the engine's own dark mode: sites with a dark look of their own are left as they are
    settings.forceDarkMode: Theme.darkening

    Component.onCompleted: {
        if (!lazy)
            load_()
        if (web !== app.view)
            hiddenSince = Date.now()
    }
    Component.onDestruction: app.dropAsks(web)

    // before a page loads: restart its counter and give it the shield's script
    onNavigationRequested: request => {
        if (!request.isMainFrame)
            return
        app.dropAsks(web)
        Shield.resetCount(app.hostOf(request.url))
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
        app.tabs.setProperty(index, "title", url.toString() === "about:blank" ? "" : title)
        app.touchSession()
        if (!app.isPrivate)
            History.setTitle(String(url), title)
    }
    onIconChanged: {
        app.tabs.setProperty(index, "siteIcon", String(icon))
        if (!app.isPrivate)
            app.keepIcon(url, icon)
    }
    // the page whose secure connection is being tried again, and how often
    property string mendUrl: ""
    property int mendTries: 0
    function tryAgain() { again.restart() }
    property Timer again: Timer {
        interval: 700
        onTriggered: String(web.url) === web.mendUrl ? web.reload() : web.url = web.mendUrl
    }
    onLoadingChanged: info => {
        app.tabs.setProperty(index, "loading", loading)
        if (info.status === WebEngineView.LoadStartedStatus) {
            again.stop()          // going somewhere else gives up the other try
            if (web === app.miniPage)      // another page: the video is gone
                app.closeMini()
            readable = false
            reading = false
            loginOrigin = ""
            accounts = []
            crashed = false
            failure = null
        }
        if (info.status === WebEngineView.LoadSucceededStatus) {
            mendUrl = ""
            zoomFactor = app.zoomOf(url)
            if (!app.isPrivate)
                History.add(String(url), title)
            web.runJavaScript(app.reader.probe, WebEngineScript.ApplicationWorld, found => web.readable = found === true)
        }
        // -3 means "stopped": by you, or because another page was asked for
        if (info.status === WebEngineView.LoadFailedStatus && info.errorCode !== -3 && !failure) {
            if (info.errorDomain === WebEngineLoadingInfo.HttpStatusCodeDomain)
                app.explainIfBlank(web, String(info.url), info.errorCode)
            else if (!app.mendConnection(web, String(info.url), info.errorString))
                failure = { url: String(info.url), text: Shield.harmful(app.hostOf(info.url))
                    ? Lang.t("Velum bu siteyi açmadı: zararlı yazılım dağıttığı bildirilen siteler listesinde (URLhaus). Ayarlar → Gizlilik'ten kapatılabilir.", "Velum did not open this site: it is listed as handing out harmful software (URLhaus). This can be switched off in Settings → Privacy.")
                    : info.errorString, certificate: false }
        }
    }
    onUrlChanged: {
        app.closeReader(web)      // sites that change page without loading
        // going somewhere turns the settings tab into an ordinary one
        if (kind !== "" && url.toString() !== "" && url.toString() !== "about:blank")
            app.tabs.setProperty(index, "kind", "")
        if (lazy && !started)
            return
        app.tabs.setProperty(index, "pageUrl", String(url))
        app.touchSession()
        if (app.tabs.get(index).pinned)
            app.savePinned()
    }

    onLinkHovered: url => { if (web === app.view) app.hoveredLink = String(url) }
    // a page's own print button: Velum saves a PDF
    onPrintRequested: app.savePdf(web)
    onPdfPrintingFinished: (path, success) => app.pdfDone(path, success)
    onRecentlyAudibleChanged: app.tabs.setProperty(index, "audible", web.recentlyAudible)
    onAudioMutedChanged: app.tabs.setProperty(index, "muted", web.audioMuted)

    // links that ask for a new window become tabs
    onNewWindowRequested: request => app.newWindowFrom(web, request.userInitiated,
        request.destination === WebEngineNewWindowRequest.InNewBackgroundTab, page => request.openIn(page))
    onWindowCloseRequested: app.closeTab(index)

    onFullScreenRequested: request => {
        if (web === app.miniPage) {
            request.reject()
            return
        }
        request.accept()
        if (request.toggleOn)
            app.enterPageFull(web)
        else if (app.fullPage === web)
            app.leavePageFull()
    }

    // Camera, microphone, location and the like: you are asked.
    // Kinds Velum cannot honour yet (such as notifications) are refused.
    onPermissionRequested: permission => {
        const wish = app.wishFor(permission.permissionType)
        if (wish === "") {
            permission.deny()
            return
        }
        app.asks = app.asks.concat([{ page: web, permission: permission, wish: wish,
                                            site: app.hostOf(permission.origin) || String(permission.origin) }])
    }
    // do not tell pages your computer's addresses on the local network
    settings.webRTCPublicInterfacesOnly: true
}
