import QtQuick
import QtWebEngine

// The menu behind the three lines.
AppMenu {
    id: mainMenu
    required property var app
    AppMenuItem { text: Lang.t("Yeni sekme", "New tab"); keys: Keymap.text("newTab"); onTriggered: app.newTab() }
    AppMenuItem { text: Lang.t("Yeni pencere", "New window"); keys: Keymap.text("newWindow"); onTriggered: app.openWindow(false) }
    AppMenuItem { text: Lang.t("Yeni gizli pencere", "New private window"); keys: Keymap.text("privateWindow"); onTriggered: app.openWindow(true) }
    AppMenuItem { text: Lang.t("Sekmelerde ara", "Search tabs"); keys: Keymap.text("tabSearch"); onTriggered: Qt.callLater(app.openTabSearch) }
    AppMenuItem { text: Lang.t("Yeni çalışma alanı", "New workspace"); onTriggered: app.spaceDialog.show(0, "", false) }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Yer imleri", "Bookmarks"); keys: Keymap.text("bookmarks"); onTriggered: app.openBookmarks() }
    AppMenuItem { text: Lang.t("Geçmiş", "History"); keys: Keymap.text("history"); onTriggered: Qt.callLater(app.openHistory) }
    AppMenuItem { text: Lang.t("İndirilenler", "Downloads"); keys: Keymap.text("downloads"); onTriggered: Qt.callLater(app.openDownloads) }
    AppMenuItem { text: Lang.t("Parolalar", "Passwords"); onTriggered: app.openPasswords() }
    AppMenuItem { text: Lang.t("Eklentiler", "Extensions"); onTriggered: app.openSettings("extensions") }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Yapay zekâ yardımcısı", "Assistant"); keys: Keymap.text("assistant"); onTriggered: app.toggleAssistant() }
    AppMenuItem { text: Lang.t("Sayfada ara", "Find in page"); keys: Keymap.text("find"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.findInPage() }
    AppMenuItem { text: Lang.t("Yakınlaştır", "Zoom in"); keys: Keymap.text("zoomIn"); onTriggered: app.zoom(1) }
    AppMenuItem { text: Lang.t("Uzaklaştır", "Zoom out"); keys: Keymap.text("zoomOut"); onTriggered: app.zoom(-1) }
    AppMenuItem { text: Lang.t("PDF olarak kaydet", "Save as PDF"); keys: Keymap.text("pdf"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.savePdf() }
    AppMenuItem { text: Lang.t("Sayfayı kaydet", "Save page"); keys: Keymap.text("savePage"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.savePage() }
    AppMenuItem { text: Lang.t("Geliştirici araçları", "Developer tools"); keys: Keymap.text("devTools"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.openDevTools() }
    AppMenuItem { text: Lang.t("Okuma modu", "Reading mode"); keys: Keymap.text("reader"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.toggleReader() }
    AppMenuItem { text: Lang.t("Küçük video penceresi", "Mini video window"); keys: Keymap.text("mini"); enabled: !app.onStartPage && !app.onSettings; onTriggered: app.toggleMini() }
    AppMenuItem { text: Lang.t("Ekranı böl ya da birleştir", "Split or join the view"); keys: Keymap.text("split"); onTriggered: app.toggleSplit() }
    AppMenuLine {}
    AppMenuItem { keys: Keymap.text("gameMode"); text: (app.powerMode === "game" ? "✓  " : "") + Lang.t("Oyun modu", "Game mode"); onTriggered: app.setPowerMode(app.powerMode === "game" ? "balanced" : "game") }
    AppMenuItem { text: (app.powerMode === "saver" ? "✓  " : "") + Lang.t("Tasarruf modu", "Saver mode"); onTriggered: app.setPowerMode(app.powerMode === "saver" ? "balanced" : "saver") }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Ayarlar", "Settings"); keys: Keymap.text("settings"); onTriggered: app.openSettings() }
    AppMenuItem { text: Lang.t("Velum'dan çık", "Quit Velum"); keys: Keymap.text("quit"); onTriggered: app.quit() }
}
