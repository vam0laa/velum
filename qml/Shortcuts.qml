import QtQuick

// Every keyboard shortcut of the window; the keys themselves are in Keymap.
Item {
    required property var app

    Shortcut { sequences: Keymap.sequences("newTab"); onActivated: app.newTab() }
    Shortcut { sequences: Keymap.sequences("reopen"); onActivated: app.reopenClosed() }
    Shortcut { sequences: Keymap.sequences("pin"); onActivated: app.togglePin(app.current) }
    Shortcut { sequences: Keymap.sequences("bookmark"); onActivated: app.toggleBookmark() }
    Shortcut { sequences: Keymap.sequences("find"); onActivated: app.findInPage() }
    Shortcut { sequences: Keymap.sequences("bookmarks"); onActivated: app.openBookmarks() }
    Shortcut { sequences: Keymap.sequences("fill"); onActivated: app.fillPassword() }
    Shortcut { sequences: Keymap.sequences("reader"); onActivated: app.toggleReader() }
    Shortcut { sequences: Keymap.sequences("mini"); onActivated: app.toggleMini() }
    Shortcut { sequence: "Alt+1"; onActivated: app.switchSpace(app.spaces[0]?.id) }
    Shortcut { sequence: "Alt+2"; onActivated: app.switchSpace(app.spaces[1]?.id ?? 0) }
    Shortcut { sequence: "Alt+3"; onActivated: app.switchSpace(app.spaces[2]?.id ?? 0) }
    Shortcut { sequence: "Alt+4"; onActivated: app.switchSpace(app.spaces[3]?.id ?? 0) }
    Shortcut { sequence: "Alt+5"; onActivated: app.switchSpace(app.spaces[4]?.id ?? 0) }
    Shortcut { sequence: "Alt+6"; onActivated: app.switchSpace(app.spaces[5]?.id ?? 0) }
    Shortcut { sequences: Keymap.sequences("split"); onActivated: app.toggleSplit() }
    Shortcut { sequences: Keymap.sequences("settings"); onActivated: app.openSettings() }
    Shortcut { sequences: Keymap.sequences("app.resources"); onActivated: app.resources.open() }
    Shortcut { sequences: Keymap.sequences("history"); onActivated: app.showCommandHistory() }
    Shortcut { sequences: Keymap.sequences("downloads"); onActivated: app.openDownloads() }
    Shortcut { sequences: Keymap.sequences("clear"); onActivated: app.clearDialog.open() }
    Shortcut { sequences: Keymap.sequences("commandBox"); onActivated: app.commandBar.show(false, "") }
    Shortcut { sequences: Keymap.sequences("closeTab"); onActivated: app.closeTab(app.current) }
    Shortcut { sequences: Keymap.sequences("address"); onActivated: app.editAddress() }
    Shortcut { sequences: Keymap.sequences("nextTab"); onActivated: app.step(1) }
    Shortcut { sequences: Keymap.sequences("previousTab"); onActivated: app.step(-1) }
    Shortcut { sequences: Keymap.sequences("reload"); onActivated: app.view.reload() }
    Shortcut { sequences: Keymap.sequences("back"); onActivated: app.view.goBack() }
    Shortcut { sequences: Keymap.sequences("forward"); onActivated: app.view.goForward() }
    Shortcut { sequences: Keymap.sequences("sidebar"); onActivated: app.compactSidebar = !app.compactSidebar }
    Shortcut { sequences: Keymap.sequences("zoomIn"); onActivated: app.view.zoomFactor = Math.min(3, app.view.zoomFactor + 0.1) }
    Shortcut { sequences: Keymap.sequences("zoomOut"); onActivated: app.view.zoomFactor = Math.max(0.5, app.view.zoomFactor - 0.1) }
    Shortcut { sequences: Keymap.sequences("zoomReset"); onActivated: app.view.zoomFactor = 1 }
    Shortcut { sequence: "Escape"; enabled: app.pageFullScreen; onActivated: app.leavePageFull() }
    Shortcut { sequences: Keymap.sequences("fullScreen"); onActivated: app.toggleWindowFullScreen() }
    Shortcut { sequences: Keymap.sequences("quit"); onActivated: app.quit() }
    Shortcut { sequences: Keymap.sequences("resetLook"); onActivated: app.resetLook() }
    Shortcut { sequences: Keymap.sequences("gameMode"); onActivated: app.setPowerMode(app.powerMode === "game" ? "balanced" : "game") }
}
