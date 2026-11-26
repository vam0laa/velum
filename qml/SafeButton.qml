import QtQuick
import QtQuick.Controls

// A button for questions about your safety. Its colours are its own: no theme file and
// no style sheet can hide it or make one answer look like another.
AbstractButton {
    id: button
    property bool strong: false
    implicitHeight: 34
    implicitWidth: caption.implicitWidth + 30
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.4
    contentItem: Text {
        id: caption
        text: button.text
        textFormat: Text.PlainText
        color: button.strong ? "#0b1220" : "#eef0f4"
        font.family: Theme.sansFont.name
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle { radius: 10; color: button.strong ? (button.hovered ? "#a8c6ff" : "#8ab4ff") : button.hovered ? "#3a4150" : "#2a303c" }
}
