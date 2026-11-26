import QtQuick
import QtWebEngine

// The menu of one tab.
AppMenu {
    id: tabMenu
    required property var app
    property int index: 0
    readonly property bool pinned: index < app.pinnedCount
    readonly property bool movable: !pinned
    readonly property var many: visible ? app.targets(index) : [index]
    readonly property bool inGroup: visible && index < app.tabs.count && (app.tabs.get(index)?.group ?? 0) > 0
    // with several tabs selected, these act on all of them
    AppMenuItem { shown: tabMenu.movable; text: tabMenu.many.length > 1 ? Lang.t(tabMenu.many.length + " sekmeyi yeni gruba al", "Group " + tabMenu.many.length + " tabs") : Lang.t("Yeni gruba al", "Add to a new group"); onTriggered: app.newGroup(tabMenu.many, "") }
    AppMenuItem { readonly property var to: app.groups[0]; shown: tabMenu.movable && to !== undefined; text: to ? Lang.t("Gruba ekle: ", "Add to: ") + to.name : ""; onTriggered: app.addToGroup(tabMenu.many, to.id) }
    AppMenuItem { readonly property var to: app.groups[1]; shown: tabMenu.movable && to !== undefined; text: to ? Lang.t("Gruba ekle: ", "Add to: ") + to.name : ""; onTriggered: app.addToGroup(tabMenu.many, to.id) }
    AppMenuItem { readonly property var to: app.groups[2]; shown: tabMenu.movable && to !== undefined; text: to ? Lang.t("Gruba ekle: ", "Add to: ") + to.name : ""; onTriggered: app.addToGroup(tabMenu.many, to.id) }
    AppMenuItem { readonly property var to: app.groups[3]; shown: tabMenu.movable && to !== undefined; text: to ? Lang.t("Gruba ekle: ", "Add to: ") + to.name : ""; onTriggered: app.addToGroup(tabMenu.many, to.id) }
    AppMenuItem { shown: tabMenu.inGroup; text: Lang.t("Gruptan çıkar", "Remove from the group"); onTriggered: app.ungroup(tabMenu.many) }
    AppMenuItem { shown: tabMenu.many.length > 1; text: Lang.t(tabMenu.many.length + " sekmeyi kapat", "Close " + tabMenu.many.length + " tabs"); onTriggered: app.closeMany(tabMenu.many) }
    AppMenuLine {}
    AppMenuItem { text: tabMenu.pinned ? Lang.t("Sabitlemeyi kaldır", "Unpin") : Lang.t("Sabitle", "Pin"); onTriggered: app.togglePin(tabMenu.index) }
    AppMenuItem { text: Lang.t("Çoğalt", "Duplicate"); onTriggered: app.openTab(app.tabs.get(tabMenu.index).pageUrl) }
    AppMenuItem { text: Lang.t("Yenile", "Reload"); onTriggered: (app.views.itemAt(tabMenu.index) as WebEngineView).reload() }
    AppMenuItem { text: Lang.t("Sesi kapat ya da aç", "Mute or unmute"); onTriggered: app.toggleMute(tabMenu.index) }
    AppMenuItem { text: Lang.t("Uyut", "Sleep"); enabled: tabMenu.index !== app.current; onTriggered: app.sleepTab(tabMenu.index) }
    AppMenuItem { text: Lang.t("Yer imlerine ekle", "Bookmark"); onTriggered: app.addShortcut(app.tabs.get(tabMenu.index).pageUrl, app.tabs.get(tabMenu.index).title) }
    AppMenuItem { text: Lang.t("Videoyu küçük pencereye al", "Video in a small window"); onTriggered: app.openMini(tabMenu.index) }
    AppMenuItem { text: Lang.t("Yan yana aç", "Open side by side"); shown: tabMenu.index !== app.current; onTriggered: app.splitWith(tabMenu.index) }
    AppMenuItem { text: Lang.t("Bölünmeyi kapat", "End split view"); shown: app.splitShown; onTriggered: app.unsplit() }
    AppMenuItem { text: Lang.t("Tarafları değiştir", "Swap the halves"); shown: app.splitShown; onTriggered: app.swapSplit() }
    AppMenuItem { text: app.splitStacked ? Lang.t("Yan yana göster", "Show side by side") : Lang.t("Alt alta göster", "Show one above the other"); shown: app.splitShown; onTriggered: app.splitStacked = !app.splitStacked }
    // moving a tab to another workspace; there are at most six
    AppMenuItem { readonly property var to: app.spaces[0]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuItem { readonly property var to: app.spaces[1]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuItem { readonly property var to: app.spaces[2]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuItem { readonly property var to: app.spaces[3]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuItem { readonly property var to: app.spaces[4]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuItem { readonly property var to: app.spaces[5]; shown: tabMenu.movable && to !== undefined && to.id !== app.space; text: to ? "→ " + app.spaceName(to) : ""; onTriggered: app.moveToSpace(tabMenu.index, to.id) }
    AppMenuLine {}
    AppMenuItem { text: Lang.t("Kapat", "Close"); onTriggered: app.closeTab(tabMenu.index) }
    AppMenuItem { text: Lang.t("Diğerlerini kapat", "Close others"); onTriggered: app.closeOthers(tabMenu.index) }
    AppMenuItem { text: Lang.t("Kapatılanı geri aç", "Reopen closed tab"); enabled: app.closedTabs.length > 0; onTriggered: app.reopenClosed() }
}
