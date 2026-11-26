import QtQuick
import QtWebEngine

// More windows. The first one is the keeper of what is shared: bookmarks, settings and the
// saved session. Other windows borrow from it; a private one also has a profile of its own
// that lives only in memory.
// "app" is the window these belong to.
QtObject {
    property var app

    // what a new window copies from the first
    readonly property var copied: ["horizontalTabs", "compactSidebar", "downloadFolder", "askDownloads", "sleepMode", "powerMode", "startBackground", "startPicture",
        "showBookmarkBar", "homeWidgets", "homeHeadline", "homeWords", "homeTasks", "homeCss", "homeTimer", "note", "readerSize", "width", "height", "profileName"]

    // Opens a window, private or not, with these addresses. Always made by the first window.
    function openWindow(hidden, urls) {
        const keeper = app.primary ?? app
        if (keeper !== app)
            return keeper.openWindow(hidden, urls)
        const component = Qt.createComponent(Qt.resolvedUrl("Main.qml"))
        if (component.status !== Component.Ready) {
            app.say(component.errorString())
            return null
        }
        const values = { secondary: true, isPrivate: hidden === true, primary: app, welcomed: true, greet: false, hasWidevine: app.hasWidevine,
                         iconFolder: app.iconFolder, startUrls: urls ?? [], settingsFile: Files.scratchFile() }
        for (const name of copied)
            values[name] = app[name]
        if (hidden !== true)
            values.sharedProfile = app.profile
        const made = component.createObject(null, values)
        if (made) {
            app.others = app.others.concat([made])
            made.raise()
            made.requestActivate()
        }
        return made
    }

    // the window is closing: its tabs go, and what it noted down
    function windowClosed(window) {
        if (!app.others.includes(window))
            return
        app.others = app.others.filter(w => w !== window)
        const notes = window.settingsFile
        Qt.callLater(() => {
            window.destroy()
            Files.discardScratch(notes)
        })
    }
    function closeOtherWindows() {
        for (const window of app.others.slice())
            window.close()
    }

    // Moves a tab into a new window. The page loads again there.
    function tabToWindow(index, hidden) {
        const tab = index >= 0 && index < app.tabs.count ? app.tabs.get(index) : null
        if (!tab || tab.pageUrl === "" || tab.kind !== "")
            return null
        const made = openWindow(hidden, [tab.pageUrl])
        if (made && hidden !== true)
            app.closeTab(index)
        return made
    }

    // a download belongs to the window of the page that started it
    function ownerOf(request) {
        const page = request.view
        if (!page)
            return null
        return app.others.find(w => w.tabIndexOf(page) >= 0) ?? null
    }
}
