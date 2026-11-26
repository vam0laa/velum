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
    // your style sheet: ".action", and ".primary" for the one that does something
    readonly property string skin: strong ? "primary" : "action"
    function styled(property, fallback) { return Theme.styled(skin, property, fallback) }
    opacity: (enabled ? 1 : 0.45) * styled("opacity", 1)
    contentItem: Text {
        id: label
        text: button.text
        textFormat: Text.PlainText
        color: button.styled("color", button.strong ? Theme.accentInk : Theme.text)
        font.family: button.styled("font-family", Theme.ui); font.pixelSize: button.styled("font-size", Theme.size(18))
        font.variableAxes: button.styled("font-weight", 0) > 0 ? Theme.axes(button.styled("font-weight", 400)) : ({})
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
            radius: button.styled("border-radius", Theme.radius)
            width: parent.width
            height: parent.height
            color: button.strong ? (button.hovered ? Qt.darker(button.styled("background", Theme.web ? Theme.barDeep : Theme.accent), Theme.web ? 1 : 1.15) : button.styled("background", Theme.accent))
                                 : button.hovered ? Theme.title : button.styled("background", Theme.raised)
            border.width: Theme.web ? 2 : button.styled("border-width", button.styled("border-color", "") !== "" ? 1 : 0)
            border.color: button.styled("border-color", Theme.line)
        }
    }
}
