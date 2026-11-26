import QtQuick
import QtQuick.Controls

// A square button with one icon: white with a blue outline and a hard shadow, or,
// when "flat", only the icon until the pointer is on it.
AbstractButton {
    id: button
    property string symbol        // a name from Icon.qml
    property string hint
    property real iconSize: 18
    property bool hintBeside: false
    property bool flat: false
    property color tone: Theme.text
    implicitWidth: 34
    implicitHeight: 30
    hoverEnabled: true
    focusPolicy: Qt.NoFocus

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: button.down && !button.flat ? 2 : 0
            anchors.verticalCenterOffset: button.down && !button.flat ? 2 : 0
            name: button.symbol
            size: button.iconSize
            color: button.enabled ? button.tone : Theme.dim
            opacity: button.enabled ? 1 : 0.5
        }
    }
    background: Item {
        Rectangle { x: 3; y: 3; width: parent.width; height: parent.height; color: Theme.hardShadow; visible: !button.flat && !button.down }
        Rectangle {
            x: button.down && !button.flat ? 2 : 0
            y: x
            width: parent.width
            height: parent.height
            color: button.hovered && button.enabled ? Theme.title : button.flat ? "transparent" : Theme.raised
            border.width: button.flat ? 0 : 2
            border.color: Theme.line
        }
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
