import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What an empty tab shows: the time, a search box and your shortcuts.
// It is drawn by Velum itself and asks the network for nothing, not even site icons.
Rectangle {
    id: page
    property alias field: search
    property bool hasWidevine
    property var shortcuts: []
    property date now: new Date()
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)

    function greeting(hour) {
        if (hour < 5) return "İyi geceler"
        if (hour < 12) return "Günaydın"
        if (hour < 18) return "İyi günler"
        return "İyi akşamlar"
    }

    color: Theme.surface

    Timer { interval: 1000; repeat: true; running: page.visible; triggeredOnStart: true; onTriggered: page.now = new Date() }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 560)
        spacing: 14

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: Qt.resolvedUrl("../data/velum.svg")
            sourceSize: Qt.size(112, 112)
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(page.now, "HH:mm")
            color: Theme.text
            font.pixelSize: 64
            font.weight: Font.Bold
            font.letterSpacing: -2
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -10
            text: page.greeting(page.now.getHours()) + " · " + page.now.toLocaleDateString(Qt.locale("tr_TR"), "d MMMM dddd")
            color: Theme.dim
            font.pixelSize: 14
        }
        AddressField {
            id: search
            Layout.fillWidth: true
            Layout.topMargin: 8
            implicitHeight: 46
            font.pixelSize: 15
            background: Rectangle {
                radius: 14
                color: Theme.frame
                border.width: 1
                border.color: search.activeFocus ? Theme.accent : Theme.line
            }
            onGo: target => page.go(target)
        }

        // shortcuts, five in a row
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            columns: 5
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: page.shortcuts
                AbstractButton {
                    id: tile
                    required property int index
                    required property var modelData
                    implicitWidth: 96
                    implicitHeight: 84
                    hoverEnabled: true
                    onClicked: page.go(modelData.url)
                    background: Rectangle { radius: 14; color: tile.hovered ? Theme.raised : "transparent"; Behavior on color { ColorAnimation { duration: Theme.quick } } }
                    contentItem: Item {
                        Rectangle {
                            id: letter
                            width: 40; height: 40; radius: 12
                            anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                            color: Theme.frame
                            border.color: Theme.line
                            Text { anchors.centerIn: parent; text: String(tile.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold }
                        }
                        Text {
                            anchors { top: letter.bottom; topMargin: 6; left: parent.left; right: parent.right; margins: 6 }
                            text: tile.modelData.title
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            color: Theme.dim
                            font.pixelSize: 11
                        }
                        IconButton {
                            anchors { top: parent.top; right: parent.right }
                            implicitWidth: 22; implicitHeight: 22; iconSize: 12
                            symbol: "close"
                            hint: "Yer imini kaldır"
                            visible: tile.hovered || hovered
                            onClicked: page.removeShortcut(tile.index)
                        }
                    }
                }
            }
            AbstractButton {
                id: plus
                implicitWidth: 96
                implicitHeight: 84
                hoverEnabled: true
                visible: page.shortcuts.length < 10
                onClicked: { adding.visible = true; address.forceActiveFocus() }
                Accessible.name: "Yer imi ekle"
                background: Rectangle { radius: 14; color: plus.hovered ? Theme.raised : "transparent" }
                contentItem: Item {
                    Rectangle {
                        width: 40; height: 40; radius: 12
                        anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                        color: "transparent"; border.color: Theme.line
                        Icon { anchors.centerIn: parent; name: "plus"; color: Theme.dim }
                    }
                    Text { anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter } text: "Ekle"; color: Theme.dim; font.pixelSize: 11 }
                }
            }
        }
        AddressField {
            id: adding
            visible: false
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            placeholderText: "Yer imi adresi, örn. vamola.dev (Enter)"
            onAccepted: { page.addShortcut(text); text = ""; visible = false }
            Keys.onEscapePressed: { text = ""; visible = false }
            // the base field would navigate; here Enter only adds
            onGo: {}
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: !page.hasWidevine
            text: "Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz."
            color: Theme.dim
            font.pixelSize: 12
        }
    }
}
