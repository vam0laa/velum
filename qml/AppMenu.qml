import QtQuick
import QtQuick.Controls

// A context menu in Velum's colours.
Menu {
    id: menu
    padding: 6
    background: Rectangle { implicitWidth: 230; radius: 12; color: Theme.surface; border.color: Theme.line }
    delegate: MenuItem {
        id: item
        implicitHeight: 32
        contentItem: Text {
            text: item.text
            color: item.enabled ? Theme.text : Theme.line
            font.pixelSize: 13
            leftPadding: 8
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { radius: 8; color: item.highlighted ? Theme.raised : "transparent" }
    }
}
