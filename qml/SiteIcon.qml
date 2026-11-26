import QtQuick

// A bookmark's picture: the site's own icon once it has been visited, else its first
// letter. Icons come from pages you opened; the start page never asks the network.
Item {
    id: mark
    property string title
    property string file: ""            // the saved icon, "" when there is none
    property bool lifted: true
    width: 52
    height: 52
    Rectangle { x: 4; y: 4; width: parent.width; height: parent.height; color: Theme.accent; visible: mark.lifted }
    Rectangle { anchors.fill: parent; color: "#ffffff"; border.width: 2; border.color: Theme.accent }
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: mark.title.charAt(0).toLocaleUpperCase()
        textFormat: Text.PlainText
        color: Theme.palette === "cybercore" ? Theme.accent : "#0b17a8"
        font.pixelSize: 34
    }
    Image {
        id: image
        anchors { fill: parent; margins: 10 }
        source: mark.file
        cache: false
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(64, 64)
    }
}
