import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The bar along the bottom: a start button, what the browser is doing, and the clock.
Bevel {
    id: bar
    property string host
    property int tabCount
    property int sleeping
    property int blocked
    signal start()
    signal resources()
    property date now: new Date()

    implicitHeight: 40
    color: Theme.window

    Timer { interval: 1000; repeat: true; running: bar.visible; triggeredOnStart: true; onTriggered: bar.now = new Date() }

    component Cell: Bevel {
        property alias text: words.text
        property color tone: Theme.dim
        sunken: true
        color: Theme.frame
        implicitHeight: 28
        implicitWidth: words.implicitWidth + 18
        Text { id: words; anchors.centerIn: parent; textFormat: Text.PlainText; color: parent.tone; font.family: Theme.pixel; font.pixelSize: 18 }
    }

    RowLayout {
        anchors { fill: parent; margins: 6 }
        spacing: 6
        AbstractButton {
            id: startButton
            implicitHeight: 28
            implicitWidth: 96
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onClicked: bar.start()
            Accessible.name: "Velum"
            background: Bevel { sunken: startButton.down; color: startButton.hovered ? Theme.title : Theme.raised }
            contentItem: Row {
                leftPadding: 8
                spacing: 6
                Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(40, 40); width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "velum"; color: Theme.text; font.family: Theme.brand; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            Hint { text: Lang.t("Komut kutusu (Ctrl+K)", "Command box (Ctrl+K)"); shown: startButton.hovered; y: -height - 6 }
        }
        Cell { visible: bar.host !== ""; text: bar.host; tone: Theme.text; Layout.maximumWidth: 320; clip: true }
        Item { Layout.fillWidth: true }
        Cell { visible: bar.blocked > 0; text: bar.blocked + Lang.t(" engellendi", " blocked"); tone: Theme.green }
        Cell {
            tone: Theme.mauve
            text: bar.tabCount + Lang.t(" sekme", bar.tabCount === 1 ? " tab" : " tabs") + (bar.sleeping > 0 ? " · " + bar.sleeping + Lang.t(" uyuyor", " asleep") : "")
            MouseArea { anchors.fill: parent; onClicked: bar.resources() }
        }
        Cell { text: Qt.formatTime(bar.now, "HH:mm"); tone: Theme.accent }
    }
}
