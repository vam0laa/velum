import QtQuick
import QtQuick.Controls

// A tooltip like a small yellow note, in pixel letters.
ToolTip {
    id: tip
    property bool shown
    visible: shown && text !== ""
    delay: 450
    padding: 6
    leftPadding: 9
    rightPadding: 9
    contentItem: Text { text: tip.text; textFormat: Text.PlainText; color: Theme.onAccent; font.family: Theme.pixel; font.pixelSize: 17 }
    background: Bevel { color: Theme.peach }
}
