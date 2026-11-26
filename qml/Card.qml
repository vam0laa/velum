import QtQuick
import QtQuick.Layouts

// A group of related settings: a small heading over a rounded panel whose rows are
// parted by thin lines. In the webcore look it is a plain heading with a line under it.
Item {
    id: card
    property string heading
    property string note
    property bool bare: false           // the content brings its own panels
    default property alias content: body.data
    readonly property int pad: Theme.web || bare ? 0 : 24
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    opacity: Theme.styled("card", "opacity", 1)

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10
        Text { Layout.leftMargin: card.pad ? 4 : 0; visible: card.heading !== ""; text: card.heading; color: Theme.styled("card", "color", Theme.dim); font.family: Theme.styled("card", "font-family", Theme.ui); font.pixelSize: Theme.web ? 16 : 12; font.variableAxes: Theme.axes(550) }
        Text { Layout.fillWidth: true; Layout.leftMargin: card.pad ? 4 : 0; visible: text !== ""; text: card.note; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 13; wrapMode: Text.WordWrap }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: body.implicitHeight + (card.pad ? 32 : 0)
            radius: Theme.styled("card", "border-radius", Theme.round(16))
            color: Theme.web || card.bare ? "transparent" : Theme.styled("card", "background", Theme.paneBack)
            border.width: Theme.web || card.bare ? 0 : Theme.styled("card", "border-width", 1)
            border.color: Theme.styled("card", "border-color", Qt.alpha(Theme.line, 0.8))
            // a line between one row and the next; a note stays with the row above it
            Repeater {
                model: card.pad ? body.visibleChildren : []
                Rectangle {
                    required property var modelData
                    required property int index
                    visible: index > 0 && modelData.height > 0 && modelData.quiet !== true
                    x: 1; width: parent.width - 2; height: 1
                    y: body.y + modelData.y - Math.round(body.spacing / 2)
                    color: Theme.line; opacity: 0.6
                }
            }
            ColumnLayout { id: body; x: card.pad; y: card.pad ? 16 : 0; width: parent.width - card.pad * 2; spacing: card.pad ? 25 : 6 }
        }
        Rectangle { visible: Theme.web; Layout.fillWidth: true; Layout.topMargin: 12; implicitHeight: 1; color: Theme.line; opacity: 0.6 }
    }
}
