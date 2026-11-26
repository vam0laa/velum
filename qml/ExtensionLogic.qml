import QtQuick
import QtWebEngine

// Extensions: installing, switching and removing them.
// "app" is the window these belong to.
QtObject {
    property var app

    function refreshExtensions() {
        const all = app.profile.extensionManager.extensions
        const out = []
        for (let i = 0; i < all.length; i++)
            if (all[i].isInstalled)          // the engine's own built-in ones are not listed
                out.push(all[i])
        app.extensions = out
    }

    // nothing is fetched or installed before you agree
    function askExtension(text, file) {
        if (!file && WebStore.idFrom(text) === "") {
            app.say(Lang.t("Bu bir Web Store adresi ya da eklenti kimliği değil.", "That is not a Web Store address or an extension id."))
            return
        }
        app.wantedExtension = { text: String(text), file: file === true }
        app.extensionDialog.open()
    }

    function addExtension() {
        const wanted = app.wantedExtension
        app.wantedExtension = null
        if (!wanted)
            return
        if (wanted.file) {
            app.profile.extensionManager.installExtension(wanted.text)
            return
        }
        app.fetchingExtension = true
        app.say(Lang.t("Eklenti indiriliyor…", "Fetching the extension…"))
        WebStore.fetch(wanted.text, (path, problem) => {
            app.fetchingExtension = false
            if (path !== "") {
                app.fetched = path
                app.profile.extensionManager.installExtension(path)
            } else if (problem === "signature") {
                app.say(Lang.t("Paketin imzası doğrulanamadı; kurulmadı.", "The package's signature did not check out; it was not installed."))
            } else {
                app.say(Lang.t("Eklenti indirilemedi.", "The extension could not be fetched."))
            }
            if (path === "")
                Qt.callLater(app.installNext)
        })
    }

    // one after another; each one was ticked by you
    function queueExtensions(ids) {
        app.extensionQueue = app.extensionQueue.concat(Array.from(ids).filter(id => WebStore.idFrom(id) !== "" && !app.extensionQueue.includes(id)))
        app.installNext()
    }

    function installNext() {
        if (app.fetchingExtension || app.fetched !== "" || app.extensionQueue.length === 0)
            return
        const id = app.extensionQueue[0]
        app.extensionQueue = app.extensionQueue.slice(1)
        app.wantedExtension = { text: id, file: false }
        app.addExtension()
    }

    function extensionInstalled(extension) {
        if (app.fetched !== "") {
            WebStore.discard(app.fetched)
            app.fetched = ""
        }
        if (extension.error !== "") {
            app.say(Lang.t("Eklenti kurulamadı: ", "The extension could not be installed: ") + extension.error)
        } else {
            app.profile.extensionManager.setExtensionEnabled(extension, true)
            app.say(Lang.t(extension.name + " eklendi.", extension.name + " was added."))
        }
        Qt.callLater(app.refreshExtensions)
        Qt.callLater(app.installNext)
    }

    function enableExtension(extension, on) {
        app.profile.extensionManager.setExtensionEnabled(extension, on)
        Qt.callLater(app.refreshExtensions)
    }

    function removeExtension(extension) { app.profile.extensionManager.uninstallExtension(extension) }
}
