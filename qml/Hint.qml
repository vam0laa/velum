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
    contentItem: Text { text: tip.text; textFormat: Text.PlainText; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
    background: Rectangle { radius: Theme.radius; color: Theme.raised; border.width: Theme.web ? 2 : 1; border.color: Theme.line; Shadow { reach: 3 } }
}
