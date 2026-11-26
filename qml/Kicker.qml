import QtQuick

// A pixel heading with a blinking cursor, like on vamola.dev.
Row {
    id: kicker
    property string text
    property color color: Theme.accent
    property int size: 20
    property bool caret: true
    spacing: 3
    Text { text: "> " + kicker.text; textFormat: Text.PlainText; color: kicker.color; font.family: Theme.pixel; font.pixelSize: kicker.size }
    Rectangle {
        visible: kicker.caret
        width: kicker.size * 0.42
        height: kicker.size * 0.8
        anchors.verticalCenter: parent.verticalCenter
        color: kicker.color
        SequentialAnimation on opacity {
            running: kicker.visible && kicker.caret
            loops: Animation.Infinite
            PauseAnimation { duration: 520 }
            PropertyAction { value: 0 }
            PauseAnimation { duration: 480 }
            PropertyAction { value: 1 }
        }
    }
}
