import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A large choice: a coloured mark, a name, a line about it and a tick when chosen.
AbstractButton {
    id: card
    property string mark                // one or two letters, when there is no picture
    property url picture                // a logo or a flag
    property bool flag: false           // a flag keeps its shape; a logo sits on a white tile
    property color tile: "#ffffff"
    property string label
    property string note
    property color tone: Theme.accent
    property bool chosen: false
    Layout.fillWidth: true
    implicitHeight: 64
    hoverEnabled: true
    scale: down ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: Theme.quick } }
    Accessible.name: label
    background: Rectangle {
        radius: Theme.round(12)
        color: card.chosen || card.hovered ? Theme.raised : "transparent"
        border.width: 1
        border.color: card.chosen ? card.tone : Qt.alpha(Theme.line, 0.8)
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
    contentItem: RowLayout {
        spacing: 14
        Rectangle {
            Layout.leftMargin: 16
            implicitWidth: card.flag ? 40 : 36; implicitHeight: card.flag ? 30 : 36
            radius: Theme.web || card.flag ? 0 : 10
            color: card.flag ? "transparent" : card.picture.toString() !== "" ? card.tile : Theme.title
            Behavior on radius { NumberAnimation { duration: Theme.smooth } }
            Image {
                anchors { fill: parent; margins: card.flag ? 0 : 7 }
                visible: card.picture.toString() !== ""
                source: card.picture
                sourceSize: Qt.size(104, 104)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Text { visible: card.picture.toString() === ""; anchors.centerIn: parent; text: card.mark; color: Theme.mauve; font.family: Theme.ui; font.pixelSize: Theme.web ? 22 : 15; font.variableAxes: Theme.axes(550) }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { Layout.fillWidth: true; text: card.label; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 20 : 14; font.variableAxes: Theme.axes(550); elide: Text.ElideRight }
            Text { Layout.fillWidth: true; visible: text !== ""; text: card.note; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 12; elide: Text.ElideRight }
        }
        Rectangle {
            Layout.rightMargin: 18
            implicitWidth: 20; implicitHeight: 20
            radius: Theme.round(10)
            color: card.chosen ? card.tone : "transparent"
            border.width: card.chosen ? 0 : 2
            border.color: Theme.line
            Text { anchors.centerIn: parent; visible: card.chosen; text: "✓"; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 12; font.variableAxes: Theme.axes(700) }
        }
    }
}
