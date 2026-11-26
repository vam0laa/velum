import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// Everything that is not the page: navigation, the address and the tabs.
// "compact" turns it into a narrow strip of icons.
Panel {
    id: side
    property WebEngineView view
    property alias tabModel: list.model
    property int current
    property bool compact: false
    property alias address: field

    signal picked(int index)
    signal closed(int index)
    signal newTab()
    signal toggle()
    signal search()
    signal moved(int from, int to)
    signal menuRequested(int index)
    property var spaces: []
    property int space
    signal spaceChosen(int id)
    signal spaceEdit(int id)
    signal spaceAdd()
    property int pinnedCount: 0
    property string host: ""            // of the current page, for the shield
    signal reloadPage()
    signal clearData()
    signal settings()
    property var downloads: []
    signal showFolder(string folder)
    signal clearDownloads()
    function openDownloads() { downloadButton.show() }

    title: compact ? "" : "velum"
    implicitWidth: compact ? Theme.strip : Theme.sidebar
    Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gap
        spacing: Theme.gap

        GridLayout {
            Layout.fillWidth: true
            columns: side.compact ? 1 : 6
            columnSpacing: 2
            rowSpacing: 2
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                symbol: "panel"
                hint: side.compact ? Lang.t("Paneli genişlet (Ctrl+B)", "Widen the side bar (Ctrl+B)") : Lang.t("Paneli daralt (Ctrl+B)", "Narrow the side bar (Ctrl+B)")
                hintBeside: side.compact
                onClicked: side.toggle()
            }
            Item { Layout.fillWidth: true; visible: !side.compact }
            IconButton { Layout.alignment: Qt.AlignHCenter; symbol: "back"; hint: Lang.t("Geri (Alt+Sol)", "Back (Alt+Left)"); hintBeside: side.compact; enabled: side.view?.canGoBack ?? false; onClicked: side.view.goBack() }
            IconButton { Layout.alignment: Qt.AlignHCenter; symbol: "forward"; hint: Lang.t("İleri (Alt+Sağ)", "Forward (Alt+Right)"); hintBeside: side.compact; enabled: side.view?.canGoForward ?? false; onClicked: side.view.goForward() }
            ShieldButton {
                Layout.alignment: Qt.AlignHCenter
                host: side.host
                beside: side.compact
                onReload: side.reloadPage()
                onClearRequested: side.clearData()
            }
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                symbol: side.view?.loading ? "stop" : "reload"
                hint: side.view?.loading ? Lang.t("Durdur", "Stop") : Lang.t("Yenile (Ctrl+R)", "Reload (Ctrl+R)")
                hintBeside: side.compact
                onClicked: side.view.loading ? side.view.stop() : side.view.reload()
            }
        }

        AddressField {
            id: field
            Layout.fillWidth: true
            visible: !side.compact
            pageUrl: side.view?.url ?? ""
            onGo: target => { side.view.url = target; side.view.forceActiveFocus() }
        }
        IconButton {
            Layout.alignment: Qt.AlignHCenter
            visible: side.compact
            symbol: "search"
            hint: Lang.t("Adres (Ctrl+L)", "Address (Ctrl+L)")
            hintBeside: true
            onClicked: side.search()
        }

        // loading progress, a thin line under the address
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 2
            radius: 0
            color: "transparent"
            Rectangle {
                height: parent.height
                radius: 0
                color: Theme.accent
                width: parent.width * (side.view?.loadProgress ?? 0) / 100
                visible: side.view?.loading ?? false
                Behavior on width { NumberAnimation { duration: Theme.quick } }
            }
        }

        // where you look for it: on top of the tabs
        AbstractButton {
            id: add
            Layout.fillWidth: true
            implicitHeight: 38
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onClicked: side.newTab()
            Accessible.name: Lang.t("Yeni sekme", "New tab")
            background: Rectangle { color: add.hovered ? Theme.title : Theme.raised; border.width: 2; border.color: Theme.line; opacity: add.down ? 0.8 : 1 }
            contentItem: Item {
                Icon { x: side.compact ? (parent.width - width) / 2 : 14; anchors.verticalCenter: parent.verticalCenter; name: "plus"; color: Theme.accent; size: 17 }
                Text { x: 42; visible: !side.compact; anchors.verticalCenter: parent.verticalCenter; text: Lang.t("Yeni sekme", "New tab"); color: Theme.text; font.pixelSize: 17; font.weight: Font.Normal }
                Text { visible: !side.compact; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } text: "Ctrl+T"; color: Theme.dim; font.pixelSize: 14 }
            }
            Hint { text: Lang.t("Yeni sekme (Ctrl+T)", "New tab (Ctrl+T)"); shown: side.compact && add.hovered; x: add.width + 8; y: (add.height - height) / 2 }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0            // tabs bring their own, so hidden ones take no room
            cacheBuffer: 4000
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height   // otherwise dragging belongs to the tabs
            currentIndex: side.current
            delegate: TabItem {
                compact: side.compact
                current: index === side.current
                shown: pinned || space === side.space
                onPicked: i => side.picked(i)
                onClosed: i => side.closed(i)
                onMenuRequested: i => side.menuRequested(i)
                lastPinned: index === side.pinnedCount - 1 && index < ListView.view.count - 1
                onDragged: (i, at) => {
                    const point = list.contentItem.mapFromItem(null, at.x, at.y)
                    const over = list.indexAt(width / 2, point.y)
                    if (over >= 0 && over !== i)
                        side.moved(i, over)
                }
            }
            move: Transition { NumberAnimation { properties: "x,y"; duration: Theme.quick; easing.type: Easing.OutCubic } }
            // tabs slide in, fade out, and the rest move up smoothly
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.smooth }
                NumberAnimation { property: "x"; from: -24; to: 0; duration: Theme.smooth; easing.type: Easing.OutCubic }
            }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.quick } }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Theme.smooth; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; to: 1; duration: Theme.quick }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: side.compact ? 1 : 3
            columnSpacing: 2
            rowSpacing: 4
            SpaceBar {
                Layout.fillWidth: true
                spaces: side.spaces
                space: side.space
                compact: side.compact
                onChosen: id => side.spaceChosen(id)
                onEdit: id => side.spaceEdit(id)
                onAdd: side.spaceAdd()
            }
            IconButton {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                symbol: "settings"
                hint: Lang.t("Ayarlar (Ctrl+,)", "Settings (Ctrl+,)")
                hintBeside: side.compact
                onClicked: side.settings()
            }
            DownloadButton {
                id: downloadButton
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                downloads: side.downloads
                beside: side.compact
                above: true
                onShowFolder: folder => side.showFolder(folder)
                onClearFinished: side.clearDownloads()
            }
        }
    }
}
