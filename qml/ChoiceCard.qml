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
    implicitHeight: 78
    hoverEnabled: true
    scale: down ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: Theme.quick } }
    Accessible.name: label
    background: Rectangle {
        radius: Theme.web ? 0 : 22
        color: card.chosen ? Qt.tint(Theme.surface, Qt.alpha(card.tone, 0.22)) : card.hovered ? Theme.title : Theme.surface
        border.width: card.chosen ? 2 : 0
        border.color: card.tone
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
    contentItem: RowLayout {
        spacing: 14
        Rectangle {
            Layout.leftMargin: 16
            implicitWidth: card.flag ? 52 : 46; implicitHeight: card.flag ? 39 : 46
            radius: Theme.web || card.flag ? 0 : card.chosen ? 23 : 15
            color: card.flag ? "transparent" : card.picture.toString() !== "" ? card.tile : card.tone
            Behavior on radius { NumberAnimation { duration: Theme.smooth } }
            Image {
                anchors { fill: parent; margins: card.flag ? 0 : 8 }
                visible: card.picture.toString() !== ""
                source: card.picture
                sourceSize: Qt.size(104, 104)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Text { visible: card.picture.toString() === ""; anchors.centerIn: parent; text: card.mark; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: Theme.web ? 22 : 17; font.variableAxes: Theme.axes(850) }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { Layout.fillWidth: true; text: card.label; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 20 : 16; font.variableAxes: Theme.axes(750); elide: Text.ElideRight }
            Text { Layout.fillWidth: true; visible: text !== ""; text: card.note; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 12; elide: Text.ElideRight }
        }
        Rectangle {
            Layout.rightMargin: 18
            implicitWidth: 26; implicitHeight: 26
            radius: Theme.web ? 0 : 13
            color: card.chosen ? card.tone : "transparent"
            border.width: card.chosen ? 0 : 2
            border.color: Theme.line
            Text { anchors.centerIn: parent; visible: card.chosen; text: "✓"; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 16; font.variableAxes: Theme.axes(850) }
        }
    }
}
