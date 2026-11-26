import QtQuick
import QtQuick.Layouts

// A group of related settings: a heading and its rows on a soft block.
Rectangle {
    id: card
    property string heading
    property string note
    property color tone: Theme.accent
    default property alias content: body.data
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 32
    radius: Theme.corner
    color: Theme.paneBack
    border.color: Theme.line

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            visible: card.heading !== ""
            spacing: 2
            Text { text: card.heading; color: card.tone; font.family: Theme.pixel; font.pixelSize: 21 }
            Text { Layout.fillWidth: true; visible: text !== ""; text: card.note; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap }
        }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 8 }
    }
}
