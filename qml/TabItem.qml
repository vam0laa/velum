import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// One tab: a row with icon and title, or only the icon when the side bar is narrow.
ItemDelegate {
    id: row
    required property int index
    required property string title
    required property string siteIcon
    required property bool loading
    required property bool pinned
    required property int asleep       // 0 awake, 1 frozen, 2 discarded
    required property int space        // the workspace it belongs to
    property bool shown: true          // false: it belongs to another workspace
    property bool current: false
    property bool compact: false
    required property string kind      // "" a web page, "settings" Velum's settings
    property bool horizontal: false    // in the bar along the top
    property real wide: 200            // how wide a horizontal tab may be
    readonly property string label: kind === "settings" ? Lang.t("Ayarlar", "Settings") : title === "" ? Lang.t("Ana sayfa", "Home") : title
    readonly property color tone: Theme.rainbow[Math.max(0, index) % Theme.rainbow.length]
    signal picked(int index)
    signal closed(int index)
    signal menuRequested(int index)
    signal dragged(int index, point at)
    // set by the list: the last pinned tab draws a divider under itself
    property bool lastPinned: false

    width: !horizontal ? (ListView.view?.width ?? 0) : !shown ? 0 : compact ? 48 : wide
    height: horizontal ? 36 : shown ? 40 : 0
    visible: shown
    padding: 0
    bottomPadding: horizontal ? 0 : 4
    bottomInset: horizontal ? 0 : 4
    rightPadding: horizontal ? 4 : 0
    rightInset: horizontal ? 4 : 0
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    onClicked: picked(index)
    Accessible.name: label

    // on the blue strip an idle tab is a darker folder; the current one joins the toolbar
    readonly property color ink: current ? Theme.text : horizontal && Theme.web ? "#dbe6ff" : Theme.dim

    background: Item {
        // vertical: a row, outlined when chosen
        Rectangle {
            anchors.fill: parent
            visible: !row.horizontal
            radius: Theme.radius
            color: row.current ? Theme.raised : row.hovered ? (Theme.web ? Theme.title : Qt.alpha(Theme.raised, 0.5)) : "transparent"
            border.width: Theme.web && row.current ? 2 : 0
            border.color: Theme.line
        }
        // everyday look: a rounded tab, filled when it is the current one
        Rectangle {
            anchors { fill: parent; topMargin: 1; bottomMargin: 3 }
            visible: row.horizontal && !Theme.web
            radius: 9
            color: row.current ? Theme.raised : row.hovered ? Qt.alpha(Theme.raised, 0.45) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        Shape {
            id: folder
            anchors.fill: parent
            visible: row.horizontal && Theme.web
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 2
                strokeColor: Theme.edge
                fillColor: row.current ? Theme.window : row.hovered ? Theme.bar : Theme.barDeep
                startX: 1; startY: folder.height
                PathLine { x: 1; y: 1 }
                PathLine { x: folder.width - 13; y: 1 }
                PathLine { x: folder.width - 1; y: 13 }
                PathLine { x: folder.width - 1; y: folder.height }
            }
        }
    }

    contentItem: Item {
        Item {
            id: mark
            width: 18
            height: 18
            x: row.compact ? (parent.width - width) / 2 : 14
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: favicon
                anchors.fill: parent
                source: row.siteIcon
                sourceSize: Qt.size(36, 36)
                visible: !row.loading && row.kind === "" && status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                name: row.kind === "settings" ? "settings" : "globe"
                size: 17
                color: row.horizontal ? row.ink : row.tone
                visible: !row.loading && !favicon.visible
            }
            // loading: four squares lighting up in turn
            Grid {
                id: blocks
                anchors.centerIn: parent
                columns: 2
                spacing: 2
                visible: row.loading
                property int step: 0
                Timer { interval: 140; repeat: true; running: blocks.visible; onTriggered: blocks.step = (blocks.step + 1) % 4 }
                Repeater {
                    model: [0, 1, 3, 2]
                    Rectangle { required property int modelData; width: 6; height: 6; color: row.tone; opacity: blocks.step === modelData ? 1 : 0.25 }
                }
            }
        }
        Text {
            anchors { left: mark.right; leftMargin: 10; right: close.visible ? close.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.label
            textFormat: Text.PlainText     // a page title is never treated as markup
            color: row.ink
            opacity: row.asleep > 0 ? 0.55 : 1
            font.family: Theme.ui; font.pixelSize: Theme.size(17)
            font.weight: row.current ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            visible: !row.compact
        }
        Icon {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            name: "pin"
            size: 14
            color: Theme.peach
            visible: !row.compact && row.pinned && row.asleep < 2
        }
        Icon {
            anchors { right: parent.right; rightMargin: row.compact ? 3 : 12; top: row.compact ? parent.top : undefined; verticalCenter: row.compact ? undefined : parent.verticalCenter }
            name: "moon"
            size: row.compact ? 11 : 14
            color: Theme.mauve
            visible: row.asleep === 2 && !(row.hovered && !row.compact && !row.pinned)
        }
        IconButton {
            id: close
            anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
            flat: true
            tone: row.ink
            implicitWidth: 22
            implicitHeight: 22
            iconSize: 13
            symbol: "close"
            hint: Lang.t("Sekmeyi kapat", "Close the tab") + Keymap.hint("closeTab")
            visible: !row.compact && !row.pinned && (row.hovered || row.current)
            onClicked: row.closed(row.index)
        }
    }

    Hint {
        text: row.label
        shown: row.compact && row.hovered
        x: row.horizontal ? 0 : row.width + 8
        y: row.horizontal ? row.height + 6 : (row.height - height) / 2
    }

    // the middle mouse button closes a tab, as in other browsers; pinned tabs are safe from it
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: if (!row.pinned) row.closed(row.index)
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: row.menuRequested(row.index)
    }
    // drag a tab up or down to move it
    DragHandler {
        id: drag
        target: null
        xAxis.enabled: row.horizontal
        yAxis.enabled: !row.horizontal
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onCentroidChanged: if (active) row.dragged(row.index, centroid.scenePosition)
    }
    opacity: drag.active ? 0.7 : 1

    Rectangle {
        visible: row.lastPinned
        x: row.horizontal ? row.width - 3 : 6
        y: row.horizontal ? 8 : row.height - 3
        width: row.horizontal ? 2 : row.width - 12
        height: row.horizontal ? row.height - 16 : 2
        color: Theme.peach
        opacity: 0.6
    }
}
