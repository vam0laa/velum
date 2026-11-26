import QtQuick
import QtQuick.Controls
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

    implicitHeight: Theme.web ? 90 : bookmarkRow ? 122 : 90

    // the strip with the tabs
    Rectangle {
        id: strip
        width: parent.width
        height: 42
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.web ? Theme.stripTop : Theme.frameBack }
            GradientStop { position: 1; color: Theme.web ? Theme.stripBottom : Theme.frameBack }
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
                Layout.maximumWidth: Math.max(48, contentWidth)
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                clip: true
                spacing: 0
                cacheBuffer: 4000
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width
                currentIndex: bar.current
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
                background: Rectangle { color: add.hovered ? Qt.alpha("#ffffff", 0.25) : "transparent" }
                contentItem: Icon { name: "plus"; size: 20; color: Theme.web ? Theme.barInk : Theme.text }
                Hint { text: Lang.t("Yeni sekme (Ctrl+T)", "New tab (Ctrl+T)"); shown: add.hovered; y: add.height + 6 }
            }
            Item { Layout.fillWidth: true }
            WindowButton { visible: Qt.platform.os !== "windows"; kind: "max"; hint: Lang.t("Tam ekran (F11)", "Full screen (F11)"); onClicked: bar.maximize() }
            WindowButton { visible: Qt.platform.os !== "windows"; kind: "close"; hint: Lang.t("Velum'u kapat (Ctrl+Q)", "Quit Velum (Ctrl+Q)"); onClicked: bar.quitRequested() }
        }
    }

    // the toolbar
    Rectangle {
        id: tools
        anchors { top: strip.bottom; left: parent.left; right: parent.right }
        height: 48
        color: Theme.paneBack
        Rectangle { visible: Theme.web; width: parent.width; height: 2; color: Theme.edge }
        Rectangle { visible: Theme.web || !bar.bookmarkRow; anchors.bottom: parent.bottom; width: parent.width; height: Theme.web ? 2 : 1; color: Theme.line }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 12; topMargin: 2; bottomMargin: 2 }
            spacing: Theme.web ? 9 : 4
            IconButton { symbol: "back"; hint: Lang.t("Geri (Alt+Sol)", "Back (Alt+Left)"); enabled: bar.view?.canGoBack ?? false; onClicked: bar.view.goBack() }
            IconButton { symbol: "forward"; hint: Lang.t("İleri (Alt+Sağ)", "Forward (Alt+Right)"); enabled: bar.view?.canGoForward ?? false; onClicked: bar.view.goForward() }
            IconButton {
                symbol: bar.view?.loading ? "stop" : "reload"
                hint: bar.view?.loading ? Lang.t("Durdur", "Stop") : Lang.t("Yenile (Ctrl+R)", "Reload (Ctrl+R)")
                onClicked: bar.view.loading ? bar.view.stop() : bar.view.reload()
            }
            IconButton { symbol: "home"; hint: Lang.t("Ana sayfa", "Home page"); onClicked: bar.home() }
            AddressField {
                id: field
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                implicitHeight: 34
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
                    hint: bar.bookmarked ? Lang.t("Yer imini kaldır (Ctrl+D)", "Remove the bookmark (Ctrl+D)") : Lang.t("Yer imlerine ekle (Ctrl+D)", "Bookmark this page (Ctrl+D)")
                    onClicked: bar.toggleBookmark()
                }
            }
            DownloadButton { id: downloadButton; downloads: bar.downloads; onShowFolder: folder => bar.showFolder(folder); onClearFinished: bar.clearDownloads() }
            IconButton { symbol: "puzzle"; hint: Lang.t("Eklentiler", "Extensions"); onClicked: bar.extensions() }
            IconButton { id: menuButton; symbol: "menu"; hint: Lang.t("Menü", "Menu"); onClicked: bar.menu(menuButton) }
        }
    }

    // your bookmarks, one click away
    Rectangle {
        visible: bar.bookmarkRow
        anchors { top: tools.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: Theme.paneBack
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
        ListView {
            id: marks
            anchors { fill: parent; leftMargin: 10; rightMargin: 10; bottomMargin: 4 }
            orientation: ListView.Horizontal
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: bar.bookmarks.slice(0, 40)
            delegate: AbstractButton {
                id: mark
                required property var modelData
                required property int index
                height: marks.height
                width: Math.min(180, caption.implicitWidth + 38)
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                onClicked: bar.openBookmark(modelData.url)
                background: Rectangle { radius: 7; color: mark.hovered ? Theme.raised : "transparent" }
                contentItem: Item {
                    Image { id: icon; x: 8; anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; source: bar.iconFor(mark.modelData.url); cache: false; sourceSize: Qt.size(32, 32) }
                    Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; visible: icon.status !== Image.Ready; width: 15; height: 15; radius: 4; color: Theme.rainbow[mark.index % Theme.rainbow.length]
                        Text { anchors.centerIn: parent; text: String(mark.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 10 } }
                    Text { id: caption; x: 29; width: Math.min(implicitWidth, 144); anchors.verticalCenter: parent.verticalCenter; text: mark.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.ui; font.pixelSize: 12 }
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
