import QtQuick

// A bookmark's picture: the site's own icon once it has been visited, else its first letter.
// Icons come from pages you opened; the start page never asks the network for them.
Rectangle {
    id: mark
    property string title
    property string file: ""            // the saved icon, "" when there is none
    property color tone: Theme.accent
    width: 44
    height: 44
    radius: 14
    // a light backing, so that dark icons show on dark themes too
    color: image.status === Image.Ready ? "#e6e9ef" : tone
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: mark.title.charAt(0).toLocaleUpperCase()
        textFormat: Text.PlainText
        color: Theme.onAccent
        font.pixelSize: mark.width * 0.46
        font.weight: Font.ExtraBold
    }
    Image {
        id: image
        anchors { fill: parent; margins: mark.width * 0.2 }
        source: mark.file
        cache: false
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(64, 64)
    }
}
