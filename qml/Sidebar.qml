import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// Everything that is not the page: navigation, the address and the tabs.
// "compact" turns it into a narrow strip of icons.
Rectangle {
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
    property int pinnedCount: 0
    property string host: ""            // of the current page, for the shield
    signal reloadPage()
    signal clearData()
    property var downloads: []
    readonly property int running: downloads.filter(d => !d.isFinished).length
    signal showFolder(string folder)
    signal clearDownloads()
    function openDownloads() { downloadsPanel.open() }

    color: Theme.frame
    implicitWidth: compact ? Theme.strip : Theme.sidebar
    Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
    clip: true

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
                hint: side.compact ? "Paneli genişlet (Ctrl+B)" : "Paneli daralt (Ctrl+B)"
                hintBeside: side.compact
                onClicked: side.toggle()
            }
            Item { Layout.fillWidth: true; visible: !side.compact }
            IconButton { Layout.alignment: Qt.AlignHCenter; symbol: "back"; hint: "Geri (Alt+Sol)"; hintBeside: side.compact; enabled: side.view?.canGoBack ?? false; onClicked: side.view.goBack() }
            IconButton { Layout.alignment: Qt.AlignHCenter; symbol: "forward"; hint: "İleri (Alt+Sağ)"; hintBeside: side.compact; enabled: side.view?.canGoForward ?? false; onClicked: side.view.goForward() }
            IconButton {
                id: shieldButton
                Layout.alignment: Qt.AlignHCenter
                symbol: "shield"
                hint: "Koruma"
                hintBeside: side.compact
                readonly property int blocked: Shield.blockedCount(side.host, Shield.revision)
                opacity: Shield.enabled && !Shield.allowed(side.host, Shield.revision) ? 1 : 0.45
                onClicked: shieldPanel.open()
                Rectangle {
                    visible: shieldButton.blocked > 0
                    anchors { right: parent.right; top: parent.top; rightMargin: -2; topMargin: -2 }
                    height: 14
                    width: Math.max(14, badge.implicitWidth + 6)
                    radius: 7
                    color: Theme.accent
                    Text { id: badge; anchors.centerIn: parent; text: shieldButton.blocked > 99 ? "99+" : shieldButton.blocked; color: Theme.onAccent; font.pixelSize: 9; font.weight: Font.Bold }
                }
                ShieldPanel {
                    id: shieldPanel
                    host: side.host
                    x: side.compact ? parent.width + 8 : parent.width - width
                    y: side.compact ? 0 : parent.height + 6
                    onReload: side.reloadPage()
                    onClearRequested: side.clearData()
                }
            }
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                symbol: side.view?.loading ? "stop" : "reload"
                hint: side.view?.loading ? "Durdur" : "Yenile (Ctrl+R)"
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
            hint: "Adres (Ctrl+L)"
            hintBeside: true
            onClicked: side.search()
        }

        // loading progress, a thin line under the address
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 2
            radius: 1
            color: "transparent"
            Rectangle {
                height: parent.height
                radius: 1
                color: Theme.accent
                width: parent.width * (side.view?.loadProgress ?? 0) / 100
                visible: side.view?.loading ?? false
                Behavior on width { NumberAnimation { duration: Theme.quick } }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height   // otherwise dragging belongs to the tabs
            currentIndex: side.current
            delegate: TabItem {
                width: ListView.view.width
                compact: side.compact
                current: index === side.current
                onPicked: i => side.picked(i)
                onClosed: i => side.closed(i)
                onMenuRequested: i => side.menuRequested(i)
                lastPinned: index === side.pinnedCount - 1 && index < ListView.view.count - 1
                onDragged: (i, sceneY) => {
                    const point = list.contentItem.mapFromItem(null, 0, sceneY)
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
            columns: side.compact ? 1 : 2
        AbstractButton {
            id: add
            Layout.fillWidth: true
            implicitHeight: 36
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onClicked: side.newTab()
            Accessible.name: "Yeni sekme"
            contentItem: Item {
                Icon { id: plus; name: "plus"; color: Theme.dim; size: 16; anchors.verticalCenter: parent.verticalCenter; x: side.compact ? (parent.width - width) / 2 : 12 }
                Text { visible: !side.compact; text: "Yeni sekme"; color: Theme.dim; font.pixelSize: 13; anchors { left: plus.right; leftMargin: 10; verticalCenter: parent.verticalCenter } }
            }
            background: Rectangle { radius: Theme.radius; color: add.hovered ? Theme.surface : "transparent" }
            Hint { text: "Yeni sekme (Ctrl+T)"; shown: side.compact && add.hovered; x: add.width + 8; y: (add.height - height) / 2 }
        }
        IconButton {
            id: downloadButton
            Layout.alignment: Qt.AlignHCenter
            symbol: "download"
            hint: "İndirmeler (Ctrl+J)"
            hintBeside: side.compact
            onClicked: downloadsPanel.open()
            Rectangle {
                visible: side.running > 0
                anchors { right: parent.right; top: parent.top }
                width: 9; height: 9; radius: 5; color: Theme.accent
            }
            DownloadsPanel {
                id: downloadsPanel
                downloads: side.downloads
                x: side.compact ? parent.width + 8 : parent.width - width
                y: side.compact ? parent.height - height : -height - 6
                onShowFolder: folder => side.showFolder(folder)
                onClearFinished: side.clearDownloads()
            }
        }
        }
    }
}
