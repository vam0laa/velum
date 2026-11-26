import QtQuick
import QtQuick.Controls

// A square button with one icon and a tooltip.
AbstractButton {
    id: button
    property string symbol        // a name from Icon.qml
    property string hint
    property real iconSize: 18
    property bool hintBeside: false
    implicitWidth: 34
    implicitHeight: 34
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    scale: down ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: button.symbol
            size: button.iconSize
            color: button.enabled ? Theme.text : Theme.line
        }
    }
    background: Rectangle {
        radius: Theme.radius - 2
        color: button.down ? Theme.raised : button.hovered && button.enabled ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
    Accessible.name: hint

    // the little label that explains the button
    Hint {
        text: button.hint
        shown: button.hovered
        x: button.hintBeside ? button.width + 8 : 0
        y: button.hintBeside ? (button.height - height) / 2 : button.height + 4
    }
}
