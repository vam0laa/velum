import QtQuick
import QtQuick.Controls

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
    readonly property string label: title === "" ? Lang.t("Yeni sekme", "New tab") : title
    readonly property color tone: Theme.rainbow[Math.max(0, index) % Theme.rainbow.length]
    signal picked(int index)
    signal closed(int index)
    signal menuRequested(int index)
    signal dragged(int index, real sceneY)
    // set by the list: the last pinned tab draws a divider under itself
    property bool lastPinned: false

    height: shown ? 42 : 0
    visible: shown
    padding: 0
    bottomPadding: 4
    bottomInset: 4
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    onClicked: picked(index)
    Accessible.name: label

    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: row.current ? Qt.tint(Theme.surface, Qt.alpha(row.tone, 0.2)) : row.hovered ? Theme.raised : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        // a small coloured mark, one colour per tab
        Rectangle {
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            radius: 2
            height: row.current ? 18 : 8
            color: row.tone
            opacity: row.current ? 1 : 0.55
            Behavior on height { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
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
                visible: !row.loading && status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                name: "globe"
                size: 17
                color: row.tone
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
            color: row.current ? Theme.text : Theme.dim
            opacity: row.asleep > 0 ? 0.55 : 1
            font.pixelSize: 13
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
            implicitWidth: 22
            implicitHeight: 22
            iconSize: 13
            symbol: "close"
            hint: Lang.t("Sekmeyi kapat (Ctrl+W)", "Close the tab (Ctrl+W)")
            visible: !row.compact && !row.pinned && (row.hovered || row.current)
            onClicked: row.closed(row.index)
        }
    }

    Hint {
        text: row.label
        shown: row.compact && row.hovered
        x: row.width + 8
        y: (row.height - height) / 2
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
        xAxis.enabled: false
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onCentroidChanged: if (active) row.dragged(row.index, centroid.scenePosition.y)
    }
    opacity: drag.active ? 0.7 : 1

    Rectangle {
        visible: row.lastPinned
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 1; leftMargin: 6; rightMargin: 6 }
        height: 2
        color: Theme.peach
        opacity: 0.6
    }
}
