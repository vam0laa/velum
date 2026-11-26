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
    signal closeTabRequested()
    function openDownloads() { downloadButton.show() }

    implicitHeight: 90

    // the strip with the tabs
    Rectangle {
        id: strip
        width: parent.width
        height: 42
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.stripTop }
            GradientStop { position: 1; color: Theme.stripBottom }
        }
        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 8; topMargin: 6 }
            spacing: 8

            Item {
                implicitWidth: logo.implicitWidth + 6
                implicitHeight: 34
                component Word: Text { text: "VELUM"; font.pixelSize: 30; y: 2 }
                Word { x: -2; color: Theme.night ? "#3a9fb8" : "#3ff5ff" }
                Word { x: 2; color: Theme.night ? "#b0479c" : "#ff3fd0" }
                Word { id: logo; color: Theme.night ? "#dfe8ff" : "#ffffff" }
            }
            SpaceBar {
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
                contentItem: Icon { name: "plus"; size: 20; color: Theme.barInk }
                Hint { text: Lang.t("Yeni sekme (Ctrl+T)", "New tab (Ctrl+T)"); shown: add.hovered; y: add.height + 6 }
            }
            Item { Layout.fillWidth: true }
            WindowButton { kind: "max"; hint: Lang.t("Tam ekran (F11)", "Full screen (F11)"); onClicked: bar.maximize() }
            WindowButton { kind: "close"; hint: Lang.t("Sekmeyi kapat (Ctrl+W)", "Close the tab (Ctrl+W)"); onClicked: bar.closeTabRequested() }
        }
    }

    // the toolbar
    Rectangle {
        anchors { top: strip.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: Theme.paneBack
        Rectangle { width: parent.width; height: 2; color: Theme.edge }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.line }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 12; topMargin: 2; bottomMargin: 2 }
            spacing: 9
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
                implicitHeight: 32
                pageUrl: bar.view?.url ?? ""
                onGo: target => { bar.view.url = target; bar.view.forceActiveFocus() }
            }
            PageButtons { id: buttons }
            ShieldButton { host: bar.host; onReload: bar.reloadPage(); onClearRequested: bar.clearData() }
            DownloadButton { id: downloadButton; downloads: bar.downloads; onShowFolder: folder => bar.showFolder(folder); onClearFinished: bar.clearDownloads() }
            IconButton { symbol: "settings"; hint: Lang.t("Ayarlar (Ctrl+,)", "Settings (Ctrl+,)"); onClicked: bar.settings() }
        }
    }
}
