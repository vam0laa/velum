import QtQuick
import QtQuick.Controls

// A tooltip: a small white note with a blue outline.
ToolTip {
    id: tip
    property bool shown
    visible: shown && text !== ""
    delay: 450
    padding: 5
    leftPadding: 9
    rightPadding: 9
    contentItem: Text { text: tip.text; textFormat: Text.PlainText; color: Theme.styled("tooltip", "color", Theme.text); font.family: Theme.styled("tooltip", "font-family", Theme.ui); font.pixelSize: Theme.styled("tooltip", "font-size", Theme.size(16)) }
    background: Rectangle { radius: Theme.styled("tooltip", "border-radius", Theme.radius); color: Theme.styled("tooltip", "background", Theme.raised); border.width: Theme.web ? 2 : Theme.styled("tooltip", "border-width", 1); border.color: Theme.styled("tooltip", "border-color", Theme.line); Shadow { reach: 3 } }
}
