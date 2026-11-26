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
    property bool current: false
    property bool compact: false
    readonly property string label: title === "" ? "Yeni sekme" : title
    signal picked(int index)
    signal closed(int index)
    signal menuRequested(int index)
    signal dragged(int index, real sceneY)
    // set by the list: the last pinned tab draws a divider under itself
    property bool lastPinned: false

    height: 36
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    onClicked: picked(index)
    Accessible.name: label

    background: Rectangle {
        radius: Theme.radius
        color: row.current ? Theme.raised : row.hovered ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.quick } }
        // a small mark on the edge of the current tab
        Rectangle {
            width: 3
            height: row.current ? 16 : 0
            radius: 2
            color: Theme.accent
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            Behavior on height { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
        }
    }

    contentItem: Item {
        // the site icon; a globe when there is none; a pulsing dot while loading
        Item {
            id: mark
            width: 16
            height: 16
            x: row.compact ? (parent.width - width) / 2 : 12
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: favicon
                anchors.fill: parent
                source: row.siteIcon
                sourceSize: Qt.size(32, 32)
                visible: !row.loading && status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                name: "globe"
                size: 16
                color: row.current ? Theme.text : Theme.dim
                visible: !row.loading && !favicon.visible
            }
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Theme.accent
                visible: row.loading
                SequentialAnimation on scale {
                    running: row.loading
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.45; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
                }
            }
        }
        Text {
            anchors { left: mark.right; leftMargin: 10; right: close.visible ? close.left : parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: row.label
            textFormat: Text.PlainText     // a page title is never treated as markup
            color: row.current ? Theme.text : Theme.dim
            opacity: row.asleep > 0 ? 0.6 : 1
            font.pixelSize: 13
            elide: Text.ElideRight
            visible: !row.compact
        }
        Icon {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            name: "pin"
            size: 13
            color: Theme.dim
            visible: !row.compact && row.pinned && row.asleep < 2
        }
        Icon {
            anchors { right: parent.right; rightMargin: row.compact ? 2 : 10; top: row.compact ? parent.top : undefined; verticalCenter: row.compact ? undefined : parent.verticalCenter }
            name: "moon"
            size: row.compact ? 10 : 13
            color: Theme.dim
            visible: row.asleep === 2 && !(row.hovered && !row.compact && !row.pinned)
        }
        IconButton {
            id: close
            anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
            implicitWidth: 24
            implicitHeight: 24
            iconSize: 14
            symbol: "close"
            hint: "Sekmeyi kapat (Ctrl+W)"
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
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -2; leftMargin: 10; rightMargin: 10 }
        height: 1
        color: Theme.line
    }
}
