import QtQuick
import QtWebEngine

// Actions run from the command line while developing.
// "app" is the window these belong to.
QtObject {
    property var app

    function demo(action) {
        if (action === "resources")
            app.resources.open()
        else if (action.startsWith("settings:"))
            app.openSettings(action.slice(9))
        else if (action.startsWith("welcome:")) {
            app.showWelcome()
            app.welcome.step = Number(action.slice(8))
        }
        else if (action === "horizontal")
            app.horizontalTabs = true
        else if (action.startsWith("menu:")) {
            const kind = action.slice(5)
            app.pageMenu.view = app.view
            app.pageMenu.describe(kind === "link" ? { linkUrl: "https://vamola.dev/", selectedText: "vamola" } : kind === "edit" ? { isContentEditable: true, selectedText: "x" } : {})
            app.pageMenu.popup(520, 220)
        }
        else if (action === "allow" && app.ask)
            app.answer(app.ask, true)
        else if (action.startsWith("wash:")) {
            app.themeWash.duration = 12000          // slow enough to be photographed
            Theme.change(() => Theme.palette = action.slice(5))
        }
        else if (action.startsWith("studio")) {
            app.openStudio()
            app.studio.tab = Number(action.split(":")[1] ?? 0)
            if (action.endsWith(":pick"))
                app.studio.picking = 8
        }
        else if (action.startsWith("design"))
            app.start.editor?.open(Number(action.split(":")[1] ?? 0))
        else if (action === "downloads")
            app.openDownloads()
        else if (action === "menu")
            app.mainMenu.popup(app.width - app.mainMenu.width - 12, 90)
        else if (action === "passwords")
            app.openPasswords()
        else if (action === "offer")
            app.passwordOffer = { origin: "https://ornek.example", user: "vamola", password: "deneme", changed: false }
        else if (action.startsWith("fetch:"))
            WebStore.fetch(action.slice(6), (path, problem) => {
                console.warn("fetch result: " + (path !== "" ? "checked package" : problem))
                WebStore.discard(path)
            })
        else if (action === "reader")
            app.toggleReader()
        else if (action === "import")
            app.openImport()
        else if (action === "bookmarks")
            app.openBookmarks()
        else if (action === "mini")
            app.toggleMini()
        else if (action.startsWith("space:"))
            app.addSpace(action.slice(6))
        else if (action === "split")
            app.toggleSplit()
        else if (action === "sleep")
            app.sleepOthers()
        else if (action.startsWith("find:")) {
            app.findBar.text = action.slice(5)
            app.findInPage()
        }
    }
}
