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
    Rectangle { x: 4; y: 4; width: parent.width; height: parent.height; color: Theme.bar; visible: mark.lifted }
    // a site's own icon gets a pale backing, so dark ones show at night too
    Rectangle { anchors.fill: parent; color: image.status === Image.Ready ? (Theme.night ? "#c3cdee" : "#ffffff") : Theme.raised; border.width: 2; border.color: Theme.accent }
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: mark.title.charAt(0).toLocaleUpperCase()
        textFormat: Text.PlainText
        color: Theme.night ? Theme.text : Theme.accent
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
