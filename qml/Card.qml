import QtQuick
import QtQuick.Layouts

// A group of related settings: a small heading, its rows, and a line under them.
ColumnLayout {
    id: card
    property string heading
    property string note
    property color tone: Theme.dim
    default property alias content: body.data
    Layout.fillWidth: true
    spacing: 6

    Text { visible: card.heading !== ""; text: card.heading; color: card.tone; font.pixelSize: 12; font.weight: Font.Bold; Layout.bottomMargin: 2 }
    Text { Layout.fillWidth: true; visible: text !== ""; text: card.note; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.bottomMargin: 4 }
    ColumnLayout { id: body; Layout.fillWidth: true; spacing: 4 }
    Rectangle { Layout.fillWidth: true; Layout.topMargin: 12; Layout.bottomMargin: 6; implicitHeight: 1; color: Theme.line; opacity: 0.6 }
}
