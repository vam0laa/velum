import QtQuick
import QtWebEngine

// Downloads: which to ask about first, and the answer.
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
        const done = () => request.state !== WebEngineDownloadRequest.DownloadRequested && request.state !== WebEngineDownloadRequest.DownloadInProgress
        if (!yes) {
            request.cancel()
            Files.discard(folder, file)
            return
        }
        app.keepDownload(request)
        // the real name is given once the whole file is there
        const finish = () => {
            if (request.state === WebEngineDownloadRequest.DownloadCompleted && Files.release(folder, file) === "")
                app.say(Lang.t("Dosyaya adı verilemedi; indirme klasöründe \"" + file + "\" olarak duruyor.", "The file could not be renamed; it is in the downloads folder as \"" + file + "\"."))
        }
        if (done()) {
            finish()
        } else {
            request.stateChanged.connect(() => { if (done()) finish() })
            request.resume()
        }
    }
}
