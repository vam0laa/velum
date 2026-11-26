import QtQuick
import QtWebEngine

// Downloads: which to ask about first, the answer, and what is remembered of them.
// "app" is the window these belong to.
QtObject {
    property var app

    // kinds that run when opened
    function risky(name) {
        return /\.(exe|msi|msix|bat|cmd|com|scr|ps1|vbs|vbe|js|jse|wsf|hta|lnk|reg|jar|apk|appimage|deb|rpm|sh|bash|run|desktop|dmg|pkg|iso)$/i.test(String(name).trim())
    }

    function startDownload(request) {
        if (app.downloadFolder !== "")
            request.downloadDirectory = app.downloadFolder
        const ask = app.askDownloads || app.risky(request.downloadFileName)
        if (ask)    // until you answer it only exists under a name that cannot be opened
            request.downloadFileName = request.downloadFileName + Files.heldEnding()
        request.accept()            // saved into your downloads folder, never opened
        if (ask) {
            request.pause()         // a large file stops here; a small one may be whole already
            app.waiting = app.waiting.concat([request])
        } else {
            whenEnded(request, () => noteEnd(request, request.downloadFileName))
            app.keepDownload(request)
        }
        // a tab that a page opened only to fetch the file is closed again
        const from = request.view
        if (from && from.popup && from.url.toString() === "")
            app.closeTab(app.tabIndexOf(from))
    }

    function keepDownload(request) {
        app.downloads = [request].concat(app.downloads)
        app.openDownloads()
    }

    function answerDownload(yes) {
        const request = app.waiting[0]
        if (!request)
            return
        app.waiting = app.waiting.slice(1)
        const folder = request.downloadDirectory, file = request.downloadFileName
        if (!yes) {
            request.cancel()
            Files.discard(folder, file)
            return
        }
        app.keepDownload(request)
        // the real name is given once the whole file is there
        whenEnded(request, () => {
            if (request.state !== WebEngineDownloadRequest.DownloadCompleted) {
                noteEnd(request, file.replace(Files.heldEnding(), ""))
                return
            }
            const name = Files.release(folder, file)
            if (name === "")
                app.say(Lang.t("Dosyaya adı verilemedi; indirme klasöründe \"" + file + "\" olarak duruyor.", "The file could not be renamed; it is in the downloads folder as \"" + file + "\"."))
            else
                noteEnd(request, name)
        })
        if (!ended(request))
            request.resume()
    }

    function ended(request) {
        return request.state !== WebEngineDownloadRequest.DownloadRequested && request.state !== WebEngineDownloadRequest.DownloadInProgress
    }
    // runs `then` once the download is over, however it ends
    function whenEnded(request, then) {
        let done = false
        const check = () => {
            if (!done && ended(request)) {
                done = true
                then()
            }
        }
        request.stateChanged.connect(check)
        check()
    }

    // ---- what is remembered ----
    function noteEnd(request, name) {
        recordDownload({ name: name, folder: request.downloadDirectory, url: String(request.url ?? ""),
                         size: request.receivedBytes, ok: request.state === WebEngineDownloadRequest.DownloadCompleted, when: Date.now() })
    }
    function recordDownload(entry) {
        app.pastDownloads = [entry].concat(app.pastDownloads.filter(p => p.name !== entry.name || p.folder !== entry.folder)).slice(0, 100)
        writeDownloads()
    }
    function writeDownloads() {
        app.saved.pastDownloads = Shield.forgetOnExit ? "[]" : JSON.stringify(app.pastDownloads)
    }
    function readDownloads() {
        try {
            const list = JSON.parse(app.saved.pastDownloads)
            if (Array.isArray(list))
                app.pastDownloads = list.filter(p => p && typeof p.name === "string" && typeof p.folder === "string").slice(0, 100)
        } catch (e) {
        }
    }
    function forgetDownload(index) {
        app.pastDownloads = app.pastDownloads.filter((p, i) => i !== index)
        writeDownloads()
    }
    function clearDownloadList() {
        app.downloads = app.downloads.filter(d => !d.isFinished)
        app.pastDownloads = []
        writeDownloads()
    }
    // only on your click, and never a file that can run programs
    function openDownloaded(folder, name) {
        if (!app.risky(name) && !/[\/\\]/.test(name))
            Qt.openUrlExternally(Files.toUrl(folder + "/" + name))
    }
}
