import QtQuick
import QtQuick.Controls

// A tooltip in Velum's colours.
ToolTip {
    id: tip
    property bool shown
    visible: shown && text !== ""
    delay: 450
    padding: 7
    leftPadding: 10
    rightPadding: 10
    contentItem: Text { text: tip.text; textFormat: Text.PlainText; color: Theme.text; font.pixelSize: 12 }
    background: Rectangle { radius: 8; color: Theme.raised; border.color: Theme.line }
}
