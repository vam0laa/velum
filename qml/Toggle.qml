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
    implicitHeight: Math.max(Theme.web ? 44 : 40, words.implicitHeight)
    readonly property string skin: on ? "toggle-on" : "toggle"
    focusPolicy: Qt.NoFocus
    contentItem: RowLayout {
        spacing: 16
        ColumnLayout {
            id: words
            Layout.fillWidth: true
            spacing: 3
            Text { Layout.fillWidth: true; text: choice.label; textFormat: Text.PlainText; color: choice.enabled ? Theme.text : Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(18); font.variableAxes: Theme.axes(500); wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; text: choice.note; textFormat: Text.PlainText; visible: text !== ""; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16); wrapMode: Text.WordWrap }
        }
        Rectangle {
            implicitWidth: 44
            implicitHeight: 24
            radius: Theme.styled(choice.skin, "border-radius", Theme.round(12))
            color: Theme.styled(choice.skin, "background", choice.on ? Theme.accent : Theme.raised)
            border.width: Theme.styled(choice.skin, "border-width", Theme.web ? 2 : 1)
            border.color: Theme.styled(choice.skin, "border-color", choice.on ? Qt.lighter(Theme.accent, 1.15) : Theme.line)
            Behavior on color { ColorAnimation { duration: Theme.quick } }
            Rectangle {
                width: 18; height: 18; radius: Theme.styled(choice.skin, "border-radius", Theme.round(9)); y: 3
                x: choice.on ? 23 : 3
                color: Theme.styled(choice.skin, "color", choice.on ? Theme.accentInk : Theme.dim)
                Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
            }
        }
    }
    Accessible.name: label
}
