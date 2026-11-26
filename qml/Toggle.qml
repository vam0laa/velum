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
        // a check box that says what it is
        Bevel {
            implicitWidth: 52
            implicitHeight: 26
            sunken: true
            color: choice.on ? Theme.green : Theme.frame
            Text { anchors.centerIn: parent; text: choice.on ? Lang.t("açık", "on") : Lang.t("kapalı", "off"); color: choice.on ? Theme.onAccent : Theme.dim; font.family: Theme.pixel; font.pixelSize: 18 }
        }
    }
    Accessible.name: label
}
