import QtQuick
import QtQuick.Controls

// A menu entry in Velum's colours. A hidden entry takes no room.
MenuItem {
    id: item
    property bool shown: true
    property string keys                 // the shortcut, shown on the right
    visible: shown
    height: shown ? implicitHeight : 0
    implicitHeight: 32
    contentItem: Text {
        rightPadding: shortcut.visible ? shortcut.implicitWidth + 12 : 0
        Text { id: shortcut; visible: item.keys !== ""; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } text: item.keys; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(15) }
        text: item.text
        textFormat: Text.PlainText
        color: item.enabled ? Theme.text : Theme.dim
        font.family: Theme.ui; font.pixelSize: Theme.size(17)
        leftPadding: 8
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle { radius: Theme.radius; color: item.highlighted ? Theme.raised : "transparent" }
}
