import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// Your own theme: the fifteen colours of the browser, each one yours to pick.
ColumnLayout {
    id: editor
    readonly property bool editing: Theme.palette === "custom" && Theme.custom.length === 15
    property int picking: -1
    spacing: 8

    ColorDialog {
        id: dialog
        title: editor.picking >= 0 ? Theme.roleNames[editor.picking] : ""
        onAccepted: Theme.setColor(editor.picking, String(selectedColor))
    }

    RowLayout {
        Layout.fillWidth: true
        TextButton { strong: !editor.editing; text: Lang.t("Ekrandaki temadan başla", "Start from the theme on screen"); onClicked: Theme.copyCurrent() }
        TextButton { visible: !editor.editing && Theme.custom.length === 15; text: Lang.t("Benim temama dön", "Back to my theme"); onClicked: Theme.change(() => { Theme.accentChoice = ""; Theme.palette = "custom" }) }
    }
    Text {
        Layout.fillWidth: true
        visible: !editor.editing
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.family: Theme.ui
        font.pixelSize: 13
        text: Lang.t("Bir temayı kopyala, sonra her rengini değiştir.", "Copy a theme, then change any of its colours.")
    }
    GridLayout {
        Layout.fillWidth: true
        visible: editor.editing
        columns: width > 520 ? 2 : 1
        columnSpacing: 18
        rowSpacing: 6
        Repeater {
            model: 15
            RowLayout {
                id: one
                required property int index
                readonly property string value: Theme.custom[index] ?? ""
                Layout.fillWidth: true
                spacing: 8
                AbstractButton {
                    implicitWidth: 32; implicitHeight: 32
                    Accessible.name: Theme.roleNames[one.index]
                    onClicked: { editor.picking = one.index; dialog.selectedColor = one.value; dialog.open() }
                    background: Rectangle { radius: Theme.round(10); color: one.value || "transparent"; border.width: 2; border.color: Theme.line }
                }
                Text { Layout.fillWidth: true; text: Theme.roleNames[one.index]; color: Theme.text; font.family: Theme.ui; font.pixelSize: 13; elide: Text.ElideRight }
                TextField {
                    id: hex
                    implicitWidth: 92; implicitHeight: 30
                    text: one.value
                    maximumLength: 24
                    color: Theme.text
                    selectByMouse: true
                    font.family: "monospace"
                    font.pixelSize: 12
                    background: Rectangle { radius: Theme.round(8); color: Theme.surface; border.color: hex.activeFocus ? Theme.accent : Theme.line }
                    onEditingFinished: { Theme.setColor(one.index, text); text = Qt.binding(() => one.value) }
                }
            }
        }
    }
}
