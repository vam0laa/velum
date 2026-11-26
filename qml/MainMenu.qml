import QtQuick
import QtWebEngine

// The menu behind the three lines.
AppMenu {
    id: mainMenu
    required property var app
    AppMenuItem { text: Lang.t("Yeni sekme", "New tab"); keys: Keymap.text("newTab"); onTriggered: app.newTab() }
    AppMenuItem { text: Lang.t("Yeni çalışma alanı", "New workspace"); onTriggered: app.spaceDialog.show(0, "", false) }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Yer imleri", "Bookmarks"); keys: Keymap.text("bookmarks"); onTriggered: app.openBookmarks() }
    AppMenuItem { text: Lang.t("Geçmiş", "History"); keys: Keymap.text("history"); onTriggered: Qt.callLater(app.showCommandHistory) }
    AppMenuItem { text: Lang.t("İndirilenler", "Downloads"); keys: Keymap.text("downloads"); onTriggered: Qt.callLater(app.openDownloads) }
    AppMenuItem { text: Lang.t("Parolalar", "Passwords"); onTriggered: app.openPasswords() }
    AppMenuItem { text: Lang.t("Eklentiler", "Extensions"); onTriggered: app.openSettings("extensions") }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Sayfada ara", "Find in page"); keys: Keymap.text("find"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.findInPage() }
    AppMenuItem { text: Lang.t("Yakınlaştır", "Zoom in"); keys: Keymap.text("zoomIn"); onTriggered: app.view.zoomFactor = Math.min(3, app.view.zoomFactor + 0.1) }
    AppMenuItem { text: Lang.t("Uzaklaştır", "Zoom out"); keys: Keymap.text("zoomOut"); onTriggered: app.view.zoomFactor = Math.max(0.5, app.view.zoomFactor - 0.1) }
    AppMenuItem { text: Lang.t("Okuma modu", "Reading mode"); keys: Keymap.text("reader"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.toggleReader() }
    AppMenuItem { text: Lang.t("Küçük video penceresi", "Mini video app"); keys: Keymap.text("mini"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.toggleMini() }
    AppMenuItem { text: Lang.t("Ekranı böl ya da birleştir", "Split or join the view"); keys: Keymap.text("split"); onTriggered: app.toggleSplit() }
    AppMenuLine {}
    AppMenuItem { keys: Keymap.text("gameMode"); text: (app.powerMode === "game" ? "✓  " : "") + Lang.t("Oyun modu", "Game mode"); onTriggered: app.setPowerMode(app.powerMode === "game" ? "balanced" : "game") }
    AppMenuItem { text: (app.powerMode === "saver" ? "✓  " : "") + Lang.t("Tasarruf modu", "Saver mode"); onTriggered: app.setPowerMode(app.powerMode === "saver" ? "balanced" : "saver") }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Ayarlar", "Settings"); keys: Keymap.text("settings"); onTriggered: app.openSettings() }
    AppMenuItem { text: Lang.t("Velum'dan çık", "Quit Velum"); keys: Keymap.text("quit"); onTriggered: app.quit() }
}
