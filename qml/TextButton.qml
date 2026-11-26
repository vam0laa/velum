import QtQuick
import QtQuick.Controls

// A button with words; "strong" marks the choice that does something.
AbstractButton {
    id: button
    property bool strong: false
    implicitHeight: 32
    implicitWidth: label.implicitWidth + 28
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.45
    contentItem: Text { id: label; text: button.text; color: button.strong ? Theme.onAccent : Theme.text; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    background: Rectangle {
        radius: 9
        color: button.strong ? Theme.accent : button.hovered ? Theme.raised : "transparent"
        border.width: button.strong ? 0 : 1          // so it reads as a button on any background
        border.color: Theme.line
    }
}
