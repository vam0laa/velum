import QtQuick
import QtQuick.Controls

// A bevelled button with words; "strong" marks the choice that does something.
AbstractButton {
    id: button
    property bool strong: false
    implicitHeight: 32
    implicitWidth: label.implicitWidth + 28
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.45
    scale: down ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
    contentItem: Text {
        id: label
        text: button.text
        color: button.strong ? Theme.onAccent : Theme.text
        font.pixelSize: 13
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Theme.radius
        color: button.strong ? Theme.accent : button.hovered ? Theme.title : Theme.raised
        opacity: button.down ? 0.8 : 1
    }
}
