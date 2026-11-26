import QtQuick
import QtQuick.Layouts

// A group of related settings: a rounded card with a title. In the webcore look it is
// a plain heading with a line under its rows.
Rectangle {
    id: card
    property string heading
    property string note
    property string symbol              // an icon beside the heading
    default property alias content: body.data
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + (Theme.web ? 4 : 40)
    radius: Theme.round(16)
    color: Theme.web ? "transparent" : Theme.paneBack

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.web ? 0 : 20 }
        spacing: 8
        Row {
            visible: card.heading !== ""
            spacing: 9
            Icon { visible: card.symbol !== "" && !Theme.web; name: card.symbol; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: card.heading; color: Theme.web ? Theme.dim : Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 16 : 16; font.variableAxes: Theme.axes(700) }
        }
        Text { Layout.fillWidth: true; visible: text !== ""; text: card.note; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 13; wrapMode: Text.WordWrap; Layout.bottomMargin: 4 }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 6 }
        Rectangle { visible: Theme.web; Layout.fillWidth: true; Layout.topMargin: 12; implicitHeight: 1; color: Theme.line; opacity: 0.6 }
    }
}
