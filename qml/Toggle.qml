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
            Text { Layout.fillWidth: true; text: choice.label; color: choice.enabled ? Theme.text : Theme.dim; font.pixelSize: 13; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: choice.note; visible: text !== ""; color: Theme.dim; font.pixelSize: 11; elide: Text.ElideRight }
        }
        Rectangle {
            implicitWidth: 34
            implicitHeight: 20
            radius: 10
            color: choice.on ? Theme.accent : Theme.raised
            Rectangle {
                width: 14; height: 14; radius: 7; y: 3
                x: choice.on ? 17 : 3
                color: choice.on ? Theme.onAccent : Theme.dim
                Behavior on x { NumberAnimation { duration: Theme.quick } }
            }
        }
    }
    Accessible.name: label
}
