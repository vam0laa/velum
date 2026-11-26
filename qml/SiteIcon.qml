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
    Rectangle { x: 4; y: 4; width: parent.width; height: parent.height; color: Theme.bar; visible: Theme.web && mark.lifted }
    // a site's own icon gets a pale backing, so dark ones show at night too
    property color tone: Theme.accent      // behind the letter in the everyday look
    Rectangle {
        anchors.fill: parent
        radius: Theme.web ? 0 : mark.width * 0.24
        color: image.status === Image.Ready ? (Theme.night ? "#c3cdee" : "#ffffff") : Theme.web ? Theme.raised : mark.tone
        border.width: Theme.web ? 2 : 0
        border.color: Theme.accent
    }
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: mark.title.charAt(0).toLocaleUpperCase()
        textFormat: Text.PlainText
        color: !Theme.web ? Theme.accentInk : Theme.night ? Theme.text : Theme.accent
        font.family: Theme.ui; font.pixelSize: mark.width * (Theme.web ? 0.66 : 0.46)
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
