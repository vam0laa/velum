import QtCore
import QtQuick
import QtWebEngine

// Everyday tools for the page: save as PDF, save the page, see its source, the developer
// tools, zoom, sound, and going to a tab by its number.
// "app" is the window these belong to.
QtObject {
    id: tools
    property var app

    // a page that is really a web page or a file, not one of Velum's own
    function onPage() { return app.view !== null && !app.onStartPage && !app.onSettings }

    // where downloads go
    function folder() { return app.downloadFolder !== "" ? app.downloadFolder : Files.toPath(StandardPaths.writableLocation(StandardPaths.DownloadLocation)) }

    // "Save as PDF", also what a page's own print button does
    function savePdf(page) {
        const view = page ?? app.view
        if (!view || String(view.url) === "" || view.url.toString() === "about:blank")
            return
        const path = Files.freePath(folder(), view.title || "sayfa", "pdf")
        if (path === "") {
            app.say(Lang.t("PDF için bir dosya adı bulunamadı.", "No file name could be found for the PDF."))
            return
        }
        app.say(Lang.t("PDF hazırlanıyor…", "Preparing the PDF…"))
        view.printToPdf(path)
    }
    function pdfDone(path, ok) {
        app.say(ok ? Lang.t("PDF kaydedildi: ", "PDF saved: ") + path : Lang.t("PDF kaydedilemedi.", "The PDF could not be saved."))
    }

    function savePage() {
        if (onPage())
            app.view.triggerWebAction(WebEngineView.SavePage)
    }

    function viewSource() {
        const address = String(app.view?.url ?? "")
        if (onPage() && /^(https?|file):/i.test(address))
            app.openTab("view-source:" + address)
    }

    // the developer tools of one page, in a window of their own
    property var devWindow: null
    property Component devScreen: Component { DevTools {} }
    function openDevTools(page) {
        const view = page ?? app.view
        if (!view || !onPage())
            return
        if (!devWindow)
            devWindow = devScreen.createObject(app.contentItem)
        devWindow.inspect(view)
    }
    function inspect(page) {
        openDevTools(page)
        page.triggerWebAction(WebEngineView.InspectElement)
    }
    // the page is going away
    function forgetPage(page) {
        if (devWindow && devWindow.page === page)
            devWindow.close()
    }

    // zoom is remembered for each site: { "host": 1.25 }
    function zoomOf(url) {
        const found = app.siteZoom[app.hostOf(url)]
        return typeof found === "number" ? Math.max(0.3, Math.min(5, found)) : 1
    }
    // `step` 1 closer, -1 further, 0 back to normal
    function zoom(step) {
        const view = app.view
        if (!view || !onPage())
            return
        const sizes = [0.5, 0.67, 0.75, 0.8, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5, 3]
        const now = view.zoomFactor
        const next = step === 0 ? 1 : step > 0 ? sizes.find(s => s > now + 0.001) ?? 3 : sizes.filter(s => s < now - 0.001).pop() ?? 0.5
        view.zoomFactor = next
        const host = app.hostOf(view.url)
        if (host === "")
            return
        const all = Object.assign({}, app.siteZoom)
        if (next === 1)
            delete all[host]
        else
            all[host] = next
        app.siteZoom = all
        if (!Shield.forgetOnExit && !app.isPrivate)
            app.saved.siteZoom = JSON.stringify(all)
        for (let i = 0; i < app.tabs.count; i++) {       // every open page of that site follows
            const other = app.pageViewAt(i)
            if (other && other !== view && app.hostOf(other.url) === host)
                other.zoomFactor = next
        }
    }
    function readZoom() {
        try {
            const read = JSON.parse(app.saved.siteZoom)
            if (read && typeof read === "object" && !Array.isArray(read))
                app.siteZoom = read
        } catch (e) {
        }
    }

    function toggleMute(index) {
        const page = app.pageViewAt(index)
        if (page)
            page.audioMuted = !page.audioMuted
    }

    // Ctrl+1 … 8: that tab of those shown; Ctrl+9: the last one
    function goToTab(number) {
        const shown = app.visibleTabs()
        const index = number === 9 ? shown[shown.length - 1] : shown[number - 1]
        if (index !== undefined)
            app.current = index
    }
}
