import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// The horizontal layout: a row of tabs, and under it navigation and the address.
Rectangle {
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

    signal picked(int index)
    signal closed(int index)
    signal newTab()
    signal moved(int from, int to)
    signal menuRequested(int index)
    signal reloadPage()
    signal clearData()
    signal settings()
    signal showFolder(string folder)
    signal clearDownloads()
    signal spaceChosen(int id)
    signal spaceEdit(int id)
    signal spaceAdd()
    function openDownloads() { downloadButton.show() }

    implicitHeight: column.implicitHeight + 2 * Theme.gap
    radius: Theme.corner
    color: Theme.paneBack
    border.color: Theme.line

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gap }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SpaceBar {
                Layout.preferredWidth: Math.min(360, naturalWidth)
                Layout.alignment: Qt.AlignVCenter
                spaces: bar.spaces
                space: bar.space
                onChosen: id => bar.spaceChosen(id)
                onEdit: id => bar.spaceEdit(id)
                onAdd: bar.spaceAdd()
            }
            Rectangle { implicitWidth: 1; implicitHeight: 22; color: Theme.line }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: 36
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
                    wide: Math.max(120, Math.min(220, (list.width - bar.pinnedCount * 48) / Math.max(1, list.shownCount)))
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

            IconButton { symbol: "plus"; hint: Lang.t("Yeni sekme (Ctrl+T)", "New tab (Ctrl+T)"); tone: Theme.accent; onClicked: bar.newTab() }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            IconButton { symbol: "back"; hint: Lang.t("Geri (Alt+Sol)", "Back (Alt+Left)"); enabled: bar.view?.canGoBack ?? false; onClicked: bar.view.goBack() }
            IconButton { symbol: "forward"; hint: Lang.t("İleri (Alt+Sağ)", "Forward (Alt+Right)"); enabled: bar.view?.canGoForward ?? false; onClicked: bar.view.goForward() }
            IconButton {
                symbol: bar.view?.loading ? "stop" : "reload"
                hint: bar.view?.loading ? Lang.t("Durdur", "Stop") : Lang.t("Yenile (Ctrl+R)", "Reload (Ctrl+R)")
                onClicked: bar.view.loading ? bar.view.stop() : bar.view.reload()
            }
            AddressField {
                id: field
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                implicitHeight: 34
                pageUrl: bar.view?.url ?? ""
                onGo: target => { bar.view.url = target; bar.view.forceActiveFocus() }
                Rectangle {
                    anchors { left: parent.left; bottom: parent.bottom; leftMargin: 16 }
                    height: 2
                    radius: 1
                    color: Theme.accent
                    width: (parent.width - 32) * (bar.view?.loadProgress ?? 0) / 100
                    visible: bar.view?.loading ?? false
                }
            }
            ShieldButton { host: bar.host; onReload: bar.reloadPage(); onClearRequested: bar.clearData() }
            DownloadButton { id: downloadButton; downloads: bar.downloads; onShowFolder: folder => bar.showFolder(folder); onClearFinished: bar.clearDownloads() }
            IconButton { symbol: "settings"; hint: Lang.t("Ayarlar (Ctrl+,)", "Settings (Ctrl+,)"); onClicked: bar.settings() }
        }
    }
}
