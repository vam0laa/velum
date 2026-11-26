import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A setting that is on or off: its name, a short explanation and a switch.
AbstractButton {
    id: choice
    property bool on
    property string label
    property string note
    Layout.fillWidth: true
    implicitHeight: 44
    focusPolicy: Qt.NoFocus
    contentItem: RowLayout {
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { Layout.fillWidth: true; text: choice.label; color: choice.enabled ? Theme.text : Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(17); elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: choice.note; visible: text !== ""; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(14); elide: Text.ElideRight }
        }
        Rectangle {
            implicitWidth: 36
            implicitHeight: 20
            radius: Theme.radius
            color: choice.on ? Theme.accent : Theme.raised
            border.width: 2
            border.color: Theme.line
            Rectangle {
                width: 14; height: 14; radius: Theme.radius; y: 3
                x: choice.on ? 19 : 3
                color: choice.on ? Theme.accentInk : Theme.dim
                Behavior on x { NumberAnimation { duration: Theme.quick } }
            }
        }
    }
    Accessible.name: label
}
