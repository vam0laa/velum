import QtQuick
import QtQuick.Controls

// A menu entry in Velum's colours. A hidden entry takes no room.
MenuItem {
    id: item
    property bool shown: true
    visible: shown
    height: shown ? implicitHeight : 0
    implicitHeight: 32
    contentItem: Text {
        text: item.text
        textFormat: Text.PlainText
        color: item.enabled ? Theme.text : Theme.dim
        font.pixelSize: 13
        leftPadding: 8
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle { radius: 8; color: item.highlighted ? Theme.raised : "transparent" }
}
