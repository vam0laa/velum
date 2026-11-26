import QtQuick
import QtQuick.Controls

// A square button with one icon and a tooltip.
AbstractButton {
    id: button
    property string symbol        // a name from Icon.qml
    property string hint
    property real iconSize: 18
    property bool hintBeside: false
    property color tone: Theme.text
    implicitWidth: 36
    implicitHeight: 32
    hoverEnabled: true
    focusPolicy: Qt.NoFocus

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: button.symbol
            size: button.iconSize
            color: button.enabled ? (button.hovered ? Theme.accent : button.tone) : Theme.line
        }
    }
    background: Rectangle {
        radius: Theme.radius
        color: button.down ? Theme.title : button.hovered && button.enabled ? Theme.raised : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
    Accessible.name: hint

    // the little label that explains the button
    Hint {
        text: button.hint
        shown: button.hovered
        x: button.hintBeside ? button.width + 8 : 0
        y: button.hintBeside ? (button.height - height) / 2 : button.height + 6
    }
}
