import QtQuick
import QtWebEngine

// What can be done with the page being shown: split, small video, reading, search, full screen.
// "app" is the window these belong to.
QtObject {
    property var app

    // Puts the tab at `index` beside the current one.
    function splitWith(index) {
        const other = app.views.itemAt(index) as WebEngineView
        if (!other || !app.view || other === app.view || other === app.miniPage || app.view === app.miniPage)
            return false
        const here = app.view
        app.splitLeft = here
        app.splitRight = other
        return true
    }

    function unsplit() {
        app.splitLeft = null
        app.splitRight = null
    }

    // Ctrl+\: splits with the neighbouring tab (or a new one), or ends the split.
    function toggleSplit() {
        if (app.splitShown) {
            app.unsplit()
            return
        }
        const here = app.current
        const others = app.visibleTabs().filter(i => i !== here)
        let other = others.filter(i => i < here).pop() ?? others[0]
        if (other === undefined) {
            app.openTab("")
            other = app.current
            app.current = here
        }
        app.splitWith(other)
    }

    // Alt+P and the title bar button: take the video out, or bring it back.
    function toggleMini() {
        if (app.miniPage)
            app.closeMini()
        else
            app.openMini(app.current)
    }

    function openMini(index) {
        const page = app.views.itemAt(index) as WebEngineView
        if (!page || page === app.miniPage)
            return
        app.closeMini()
        const missing = () => app.say(Lang.t("Bu sayfada küçük pencereye alınacak bir video yok.", "There is no video on this page to take out."))
        if (page.url.toString() === "" || page.lifecycleState !== WebEngineView.LifecycleState.Active) {
            missing()
            return
        }
        page.runJavaScript(app.miniPlayer.enterScript, WebEngineScript.ApplicationWorld, found => {
            if (!found) {
                missing()
                return
            }
            app.closeReader(page)
            if (page === app.splitLeft || page === app.splitRight)
                app.unsplit()
            app.miniPlayer.paused = found.paused === true
            app.miniPlayer.height = Math.max(135, Math.min(720, Math.round(app.miniPlayer.width * found.height / found.width)))
            app.miniPlayer.page = page
            page.parent = app.miniPlayer.stage
            app.miniPlayer.show()
        })
    }

    function closeMini() {
        const page = app.miniPlayer.page
        if (!page)
            return
        page.runJavaScript(app.miniPlayer.leaveScript, WebEngineScript.ApplicationWorld)
        page.parent = app.pagesArea
        app.miniPlayer.page = null
        app.miniPlayer.hide()
    }

    function toggleReader() {
        const page = app.view
        if (!page || app.onStartPage || page === app.miniPage)
            return
        if (page.reading) {
            app.closeReader(page)
            return
        }
        const color = c => String(c)
        const look = { size: app.readerSize, dark: Theme.dark, minutes: Lang.t("dk okuma", "min read"),
                       colors: { back: color(Theme.surface), text: color(Theme.text), dim: color(Theme.dim), accent: color(Theme.accent), card: color(Theme.frame), line: color(Theme.line) } }
        page.runJavaScript(app.reader.enter(look), WebEngineScript.ApplicationWorld, found => {
            if (found === true)
                page.reading = true
            else
                app.say(Lang.t("Bu sayfada okunacak bir yazı bulunamadı.", "There is no article to read on this page."))
        })
    }

    function closeReader(page) {
        if (!page || !page.reading)
            return
        page.reading = false
        page.runJavaScript(app.reader.leave, WebEngineScript.ApplicationWorld)
    }

    function sizeReader(by) {
        app.readerSize = Math.max(14, Math.min(28, app.readerSize + by))
        app.view?.runJavaScript(app.reader.resize(app.readerSize), WebEngineScript.ApplicationWorld)
    }

    function findInPage() {
        if (!app.onStartPage && !app.onSettings) {
            app.findPage = app.view
            app.findBar.open()
        }
    }

    function toggleWindowFullScreen() {
        if (app.visibility === Window.FullScreen) {
            app.visibility = app.beforeFull
        } else {
            app.beforeFull = app.visibility
            app.showFullScreen()
        }
    }

    function enterPageFull(page) {
        if (!app.pageFullScreen)
            app.beforePageFull = app.visibility
        app.fullPage = page
        app.pageFullScreen = true
        app.showFullScreen()
        // said by the browser, with the real address, so a page cannot pretend to be it
        app.say(app.hostOf(page.url) + Lang.t(" tam ekranda · çıkmak için Esc", " is full screen · Esc to leave"))
    }

    function leavePageFull() {
        if (!app.pageFullScreen)
            return
        const page = app.fullPage
        app.fullPage = null
        app.pageFullScreen = false
        app.visibility = app.beforePageFull
        if (page)
            page.triggerWebAction(WebEngineView.ExitFullScreen)
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
}
