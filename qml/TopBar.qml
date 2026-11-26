import QtQuick
import QtQuick.Controls
import QtQml
import QtQuick.Layouts
import QtWebEngine

// Tabs along the top: a blue strip with the tabs, under it the toolbar and the address.
Item {
    id: bar
    property WebEngineView view
    property alias tabModel: list.model
    property int current
    property int pinnedCount: 0
    property string host: ""
    property var downloads: []
    property var spaces: []
    property int space
    property alias address: field
    property alias pageButtons: buttons

    signal picked(int index)
    signal closed(int index)
    signal newTab()
    signal moved(int from, int to)
    signal menuRequested(int index)
    signal reloadPage()
    signal clearData()
    signal settings()
    signal home()
    signal showFolder(string folder)
    signal clearDownloads()
    signal spaceChosen(int id)
    signal spaceEdit(int id)
    signal spaceAdd()
    signal maximize()
    signal quitRequested()
    property var bookmarks: []
    property bool showBookmarks: true
    property var iconFor: url => ""
    signal openBookmark(url address)
    signal importRequested()
    property bool bookmarked: false
    readonly property bool onWeb: /^https?:/.test(String(view?.url ?? ""))
    signal toggleBookmark()
    signal extensions()
    signal menu(Item at)
    readonly property bool bookmarkRow: showBookmarks && !Theme.web
    function openDownloads() { downloadButton.show() }
    property var downloadTools: null        // what the list can do: { past, canOpen, open, again, forget }
    signal backMenu(bool forward, Item at)
    signal muteToggled(int index)
    property var groups: []
    property bool privateMode: false
    signal selected(int index, bool stretch)
    signal groupToggled(int id)
    signal groupMenu(int id, Item at)

    implicitHeight: strip.height + tools.height + (bookmarkRow ? Theme.dense(32) : 0)

    // the toolbar in your order: buttons left of the address, buttons right of it, the menu
    function arrange() {
        const buttons = { back: backButton, forward: forwardButton, reload: reloadButton, home: homeButton, downloads: downloadButton,
                          extensions: extensionsButton, bookmarks: bookmarksButton, history: historyButton, game: gameButton, settings: settingsButton }
        const left = Theme.web ? ["back", "forward", "reload", "home"] : Theme.barLeft
        const right = Theme.web ? ["downloads", "extensions"] : Theme.barRight
        for (const id in buttons)
            buttons[id].visible = left.includes(id) || right.includes(id)
        const order = left.map(id => buttons[id]).concat([field], right.map(id => buttons[id]), [menuButton])
        // a layout shows its items in the order they joined it
        for (const item of order) {
            item.parent = null
            item.parent = toolRow
        }
    }
    Component.onCompleted: arrange()
    Connections {
        target: Theme
        function onBarLeftChanged() { bar.arrange() }
        function onBarRightChanged() { bar.arrange() }
        function onStyleChanged() { bar.arrange() }
    }
    signal openBookmarksRequested()
    signal historyRequested()
    signal gameRequested()
    property bool gaming: false
    // the names of what the toolbar shows, from left to right (for the tests)
    function shownOrder() {
        const names = new Map([[backButton, "back"], [forwardButton, "forward"], [reloadButton, "reload"], [homeButton, "home"], [field, "address"], [downloadButton, "downloads"],
                               [extensionsButton, "extensions"], [bookmarksButton, "bookmarks"], [historyButton, "history"], [gameButton, "game"], [settingsButton, "settings"], [menuButton, "menu"]])
        toolRow.ensurePolished()
        return Array.from(toolRow.children).filter(i => i.visible).sort((a, b) => a.x - b.x).map(i => names.get(i))
    }

    AppMenu {
        id: folderMenu
        property var inside: []
        function showFor(list, button) { inside = list; popup(button, 0, button.height + 2) }
        Instantiator {
            model: folderMenu.inside.slice(0, 40)
            delegate: AppMenuItem {
                required property var modelData
                readonly property string sub: modelData.folder.split("/").slice(1).join(" / ")
                text: (sub !== "" ? sub + " › " : "") + modelData.title
                onTriggered: bar.openBookmark(modelData.url)
            }
            onObjectAdded: (index, item) => folderMenu.insertItem(index, item)
            onObjectRemoved: (index, item) => folderMenu.removeItem(item)
        }
    }

    // the strip with the tabs
    Rectangle {
        id: strip
        width: parent.width
        height: Theme.dense(42)
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.web ? Theme.stripTop : Theme.styled("tabbar", "background", Theme.frameBack) }
            GradientStop { position: 1; color: Theme.web ? Theme.stripBottom : Theme.styled("tabbar", "background", Theme.frameBack) }
        }
        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 8; topMargin: 6 }
            spacing: 8

            Item {
                visible: Theme.web
                implicitWidth: logo.implicitWidth + 6
                implicitHeight: 34
                component Word: Text { text: "VELUM"; font.family: Theme.pixel; font.pixelSize: 30; y: 2 }
                Word { x: -2; color: Theme.night ? "#3a9fb8" : "#3ff5ff" }
                Word { x: 2; color: Theme.night ? "#b0479c" : "#ff3fd0" }
                Word { id: logo; color: Theme.night ? "#dfe8ff" : "#ffffff" }
            }
            // said plainly: this window keeps nothing
            Rectangle {
                visible: bar.privateMode
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: hidden.implicitWidth + 20
                implicitHeight: 26
                radius: Theme.round(13)
                color: "#5b3fa0"
                Text { id: hidden; anchors.centerIn: parent; text: Lang.t("Gizli pencere", "Private"); color: "#ffffff"; font.family: Theme.ui; font.pixelSize: 12 }
            }
            SpaceBar {
                visible: bar.spaces.length > 1
                Layout.preferredWidth: Math.min(300, naturalWidth)
                Layout.alignment: Qt.AlignVCenter
                spaces: bar.spaces
                space: bar.space
                onChosen: id => bar.spaceChosen(id)
                onEdit: id => bar.spaceEdit(id)
                onAdd: bar.spaceAdd()
            }

            ListView {
                id: list
                Layout.fillWidth: true
                // the tabs get all the room they need before the empty strip beside them does
                Layout.preferredWidth: Math.max(48, contentWidth)
                Layout.maximumWidth: Math.max(48, contentWidth)
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                clip: true
                spacing: 0
                cacheBuffer: 4000
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width
                currentIndex: bar.current
                // a tab that grows (a group's name appears) pushes to the left; when all of
                // them fit, they start at the left edge again
                function settle() {
                    forceLayout()
                    if (contentWidth <= width + 1)
                        positionViewAtBeginning()
                    else
                        returnToBounds()
                }
                onContentWidthChanged: Qt.callLater(settle)
                onWidthChanged: Qt.callLater(settle)
                // tabs share the room, within limits
                readonly property int shownCount: {
                    let n = 0
                    for (let i = 0; i < count; i++) {
                        const tab = model.get(i)
                        if (!tab.pinned && tab.space === bar.space)
                            n++
                    }
                    return n
                }
                delegate: TabItem {
                    horizontal: true
                    wide: Math.max(120, Math.min(230, (strip.width - 420 - bar.pinnedCount * 48) / Math.max(1, list.shownCount)))
                    compact: pinned
                    current: index === bar.current
                    shown: pinned || space === bar.space
                    onPicked: i => bar.picked(i)
                    onClosed: i => bar.closed(i)
                    onMuteToggled: i => bar.muteToggled(i)
                    groups: bar.groups
                    onSelected: (i, stretch) => bar.selected(i, stretch)
                    onGroupToggled: id => bar.groupToggled(id)
                    onGroupMenu: (id, at) => bar.groupMenu(id, at)
                    onMenuRequested: i => bar.menuRequested(i)
                    lastPinned: index === bar.pinnedCount - 1 && index < list.count - 1
                    onDragged: (i, at) => {
                        const point = list.contentItem.mapFromItem(null, at.x, at.y)
                        const over = list.indexAt(point.x, height / 2)
                        if (over >= 0 && over !== i)
                            bar.moved(i, over)
                    }
                }
                move: Transition { NumberAnimation { properties: "x,y"; duration: Theme.quick; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.smooth } }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: Theme.smooth; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: Theme.quick }
                }
            }

            AbstractButton {
                id: add
                implicitWidth: 30
                implicitHeight: 30
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                onClicked: bar.newTab()
                Accessible.name: Lang.t("Yeni sekme", "New tab")
                background: Rectangle { radius: Theme.styled("newtab", "border-radius", Theme.round(8)); color: add.hovered ? Qt.alpha("#ffffff", Theme.web ? 0.25 : 0.12) : Theme.styled("newtab", "background", "transparent"); border.width: Theme.styled("newtab", "border-width", Theme.styled("newtab", "border-color", "") !== "" ? 1 : 0); border.color: Theme.styled("newtab", "border-color", Theme.line) }
                contentItem: Icon { name: "plus"; size: 20; color: Theme.web ? Theme.barInk : Theme.styled("newtab", "color", Theme.text) }
                Hint { text: Lang.t("Yeni sekme", "New tab") + Keymap.hint("newTab"); shown: add.hovered; y: add.height + 6 }
            }
            Item { Layout.fillWidth: true }
            WindowButton { visible: Qt.platform.os !== "windows"; kind: "max"; hint: Lang.t("Tam ekran", "Full screen") + Keymap.hint("fullScreen"); onClicked: bar.maximize() }
            WindowButton { visible: Qt.platform.os !== "windows"; kind: "close"; hint: Lang.t("Velum'u kapat", "Quit Velum") + Keymap.hint("quit"); onClicked: bar.quitRequested() }
        }
    }

    // the toolbar
    Rectangle {
        id: tools
        anchors { top: strip.bottom; left: parent.left; right: parent.right }
        height: Theme.dense(48)
        color: Theme.styled("toolbar", "background", Theme.paneBack)
        Rectangle { visible: Theme.web; width: parent.width; height: 2; color: Theme.edge }
        Rectangle { visible: Theme.web || !bar.bookmarkRow; anchors.bottom: parent.bottom; width: parent.width; height: Theme.web ? 2 : 1; color: Theme.line }

        RowLayout {
            id: toolRow
            anchors { fill: parent; leftMargin: 10; rightMargin: 12; topMargin: 2; bottomMargin: 2 }
            spacing: Theme.web ? 9 : 4
            IconButton { id: backButton; symbol: "back"; hint: Lang.t("Geri", "Back") + Keymap.hint("back"); enabled: bar.view?.canGoBack ?? false; onClicked: bar.view.goBack(); TapHandler { acceptedButtons: Qt.RightButton; onTapped: bar.backMenu(false, backButton) } onPressAndHold: bar.backMenu(false, backButton) }
            IconButton { id: forwardButton; symbol: "forward"; hint: Lang.t("İleri", "Forward") + Keymap.hint("forward"); enabled: bar.view?.canGoForward ?? false; onClicked: bar.view.goForward(); TapHandler { acceptedButtons: Qt.RightButton; onTapped: bar.backMenu(true, forwardButton) } onPressAndHold: bar.backMenu(true, forwardButton) }
            IconButton {
                id: reloadButton
                symbol: bar.view?.loading ? "stop" : "reload"
                hint: bar.view?.loading ? Lang.t("Durdur", "Stop") : Lang.t("Yenile", "Reload") + Keymap.hint("reload")
                onClicked: bar.view.loading ? bar.view.stop() : bar.view.reload()
            }
            IconButton { id: homeButton; symbol: "home"; hint: Lang.t("Ana sayfa", "Home page"); onClicked: bar.home() }
            AddressField {
                id: field
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                implicitHeight: Theme.dense(34)
                bare: bar.onWeb
                leftPadding: bar.onWeb ? 42 : Theme.web ? 28 : 34
                rightPadding: buttons.width + (bar.onWeb ? 40 : 10)
                pageUrl: bar.view?.url ?? ""
                onGo: target => { bar.view.url = target; bar.view.forceActiveFocus() }
                // what concerns this page sits inside its address
                ShieldButton {
                    x: 3
                    anchors.verticalCenter: parent.verticalCenter
                    visible: bar.onWeb
                    flat: true
                    implicitWidth: 32; implicitHeight: 28
                    host: bar.host
                    address: bar.view?.url ?? ""
                    onReload: bar.reloadPage()
                    onClearRequested: bar.clearData()
                }
                PageButtons { id: buttons; anchors { right: parent.right; rightMargin: bar.onWeb ? 38 : 8; verticalCenter: parent.verticalCenter } }
                IconButton {
                    anchors { right: parent.right; rightMargin: 3; verticalCenter: parent.verticalCenter }
                    visible: bar.onWeb
                    flat: true
                    implicitWidth: 32; implicitHeight: 28
                    iconSize: 17
                    symbol: "star"
                    filled: bar.bookmarked
                    tone: bar.bookmarked ? Theme.accent : Theme.dim
                    hint: (bar.bookmarked ? Lang.t("Yer imini kaldır", "Remove the bookmark") : Lang.t("Yer imlerine ekle", "Bookmark this page")) + Keymap.hint("bookmark")
                    onClicked: bar.toggleBookmark()
                }
            }
            DownloadButton { id: downloadButton; downloads: bar.downloads; onShowFolder: folder => bar.showFolder(folder); onClearFinished: bar.clearDownloads(); past: bar.downloadTools?.past ?? []; canOpen: bar.downloadTools?.canOpen ?? (n => false); onOpenFile: (f, n) => bar.downloadTools.open(f, n); onAgain: u => bar.downloadTools.again(u); onForget: i => bar.downloadTools.forget(i) }
            IconButton { id: extensionsButton; symbol: "puzzle"; hint: Lang.t("Eklentiler", "Extensions"); onClicked: bar.extensions() }
            IconButton { id: bookmarksButton; visible: false; symbol: "star"; hint: Lang.t("Yer imleri", "Bookmarks") + Keymap.hint("bookmarks"); onClicked: bar.openBookmarksRequested() }
            IconButton { id: historyButton; visible: false; symbol: "history"; hint: Lang.t("Geçmiş", "History") + Keymap.hint("history"); onClicked: bar.historyRequested() }
            IconButton { id: gameButton; visible: false; symbol: "gauge"; tone: bar.gaming ? Theme.accent : Theme.text; hint: Lang.t("Oyun modu", "Game mode") + Keymap.hint("gameMode"); onClicked: bar.gameRequested() }
            IconButton { id: settingsButton; visible: false; symbol: "settings"; hint: Lang.t("Ayarlar", "Settings") + Keymap.hint("settings"); onClicked: bar.settings() }
            IconButton { id: menuButton; symbol: "menu"; hint: Lang.t("Menü", "Menu"); onClicked: bar.menu(menuButton) }
        }
    }

    // your bookmarks, one click away
    Rectangle {
        visible: bar.bookmarkRow
        anchors { top: tools.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: Theme.styled("bookmarks", "background", Theme.paneBack)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
        ListView {
            id: marks
            anchors { fill: parent; leftMargin: 10; rightMargin: 10; bottomMargin: 4 }
            orientation: ListView.Horizontal
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            // loose bookmarks first as they are, then one entry for each outer folder
            model: {
                const loose = [], folders = new Map()
                for (const b of bar.bookmarks) {
                    if (!b.folder) {
                        loose.push(b)
                        continue
                    }
                    const name = b.folder.split("/")[0]
                    if (!folders.has(name))
                        folders.set(name, [])
                    folders.get(name).push(b)
                }
                return Array.from(folders, ([name, inside]) => ({ title: name, url: "", inside: inside })).concat(loose.slice(0, 40))
            }
            delegate: AbstractButton {
                id: mark
                required property var modelData
                required property int index
                height: marks.height
                width: Math.min(180, caption.implicitWidth + 38)
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                onClicked: modelData.inside ? folderMenu.showFor(modelData.inside, mark) : bar.openBookmark(modelData.url)
                background: Rectangle { radius: Theme.styled("bookmark", "border-radius", Theme.round(7)); color: mark.hovered ? Theme.raised : Theme.styled("bookmark", "background", "transparent"); border.width: Theme.styled("bookmark", "border-width", Theme.styled("bookmark", "border-color", "") !== "" ? 1 : 0); border.color: Theme.styled("bookmark", "border-color", Theme.line) }
                contentItem: Item {
                    Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; visible: mark.modelData.inside !== undefined; name: "folder"; size: 15; color: Theme.dim }
                    Image { id: icon; x: 8; anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; source: mark.modelData.inside ? "" : bar.iconFor(mark.modelData.url); cache: false; sourceSize: Qt.size(32, 32) }
                    Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; visible: icon.status !== Image.Ready && mark.modelData.inside === undefined; width: 15; height: 15; radius: 4; color: Theme.rainbow[mark.index % Theme.rainbow.length]
                        Text { anchors.centerIn: parent; text: String(mark.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 10 } }
                    Text { id: caption; x: 29; width: Math.min(implicitWidth, 144); anchors.verticalCenter: parent.verticalCenter; text: mark.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.styled("bookmark", "color", Theme.styled("bookmarks", "color", Theme.text)); font.family: Theme.styled("bookmark", "font-family", Theme.ui); font.pixelSize: Theme.styled("bookmark", "font-size", 12) }
                }
            }
        }
        TextButton {
            visible: bar.bookmarks.length === 0
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            implicitHeight: 24
            text: Lang.t("Yer imlerini içe aktar…", "Import bookmarks…")
            onClicked: bar.importRequested()
        }
    }
}
