import QtQuick
import QtQuick.Controls

// A square button with words; "strong" marks the choice that does something.
AbstractButton {
    id: button
    property bool strong: false
    implicitHeight: 32
    implicitWidth: label.implicitWidth + 28
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        id: label
        text: button.text
        color: button.strong ? Theme.accentInk : Theme.text
        font.family: Theme.ui; font.pixelSize: Theme.size(18)
        leftPadding: Theme.web && button.down ? 2 : 0
        topPadding: Theme.web && button.down ? 2 : 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Item {
        Rectangle { x: 3; y: 3; width: parent.width; height: parent.height; color: Theme.hardShadow; visible: Theme.web && !button.down }
        Rectangle {
            x: Theme.web && button.down ? 2 : 0
            y: x
            radius: Theme.radius
            width: parent.width
            height: parent.height
            color: button.strong ? (button.hovered ? Theme.barDeep : Theme.accent) : button.hovered ? Theme.title : Theme.raised
            border.width: Theme.web ? 2 : 0
            border.color: Theme.line
        }
    }
}
