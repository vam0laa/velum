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
    property bool filled: false
    property color tone: Theme.text
    implicitWidth: 34
    implicitHeight: 30
    hoverEnabled: true
    focusPolicy: Qt.NoFocus

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Theme.web && button.down && !button.flat ? 2 : 0
            anchors.verticalCenterOffset: Theme.web && button.down && !button.flat ? 2 : 0
            name: button.symbol
            size: button.iconSize
            color: button.enabled ? button.tone : Theme.dim
            filled: button.filled
            opacity: button.enabled ? 1 : 0.5
        }
    }
    background: Item {
        Rectangle { x: 3; y: 3; width: parent.width; height: parent.height; color: Theme.hardShadow; visible: Theme.web && !button.flat && !button.down }
        Rectangle {
            x: Theme.web && button.down && !button.flat ? 2 : 0
            y: x
            width: parent.width
            height: parent.height
            radius: Theme.radius
            color: button.hovered && button.enabled ? (Theme.web ? Theme.title : Theme.raised) : !Theme.web || button.flat ? "transparent" : Theme.raised
            border.width: Theme.web && !button.flat ? 2 : 0
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
