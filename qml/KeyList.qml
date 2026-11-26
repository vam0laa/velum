import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The shortcuts in the settings: press "change", then the new keys.
ColumnLayout {
    id: list
    property string waiting: ""      // the action waiting for its keys
    property string said: ""
    spacing: 6

    function press(key, modifiers) {
        if (waiting === "")
            return
        if (key === Qt.Key_Escape && modifiers === Qt.NoModifier) {
            waiting = ""
            return
        }
        const sequence = Keymap.fromEvent(key, modifiers)
        if (sequence === "")
            return
        const lost = Keymap.assign(waiting, sequence)
        said = lost === "" ? "" : Lang.t(sequence + " artık burada; \"" + lost + "\" kısayolsuz kaldı.", sequence + " is here now; \"" + lost + "\" has no shortcut.")
        waiting = ""
    }

    // listens while an action waits; the window's shortcuts stay quiet meanwhile
    Item {
        id: ear
        Keys.onShortcutOverride: event => event.accepted = list.waiting !== ""
        Keys.onPressed: event => { list.press(event.key, event.modifiers); event.accepted = true }
        onActiveFocusChanged: if (!activeFocus) list.waiting = ""
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: list.said !== "" ? Theme.danger : Theme.dim
        font.family: Theme.ui
        font.pixelSize: Theme.web ? 15 : 13
        text: list.said !== "" ? list.said : Lang.t("Yeni tuşlar Ctrl, Alt ya da Meta içermeli (F tuşları tek başına olur). Alt+1…6 çalışma alanlarınındır.", "New keys need Ctrl, Alt or Meta (F keys work alone). Alt+1…6 belong to the workspaces.")
    }
    Repeater {
        model: Keymap.actions
        RowLayout {
            id: row
            required property var modelData
            readonly property bool open: list.waiting === modelData.id
            Layout.fillWidth: true
            Layout.minimumHeight: 36
            spacing: 6
            Text { Layout.fillWidth: true; text: row.modelData.name; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 17 : 14; elide: Text.ElideRight }
            TextButton {
                implicitHeight: 30
                strong: row.open
                text: row.open ? Lang.t("Tuşlara bas… (Esc)", "Press keys… (Esc)") : Keymap.text(row.modelData.id) || Lang.t("yok", "none")
                onClicked: { list.said = ""; list.waiting = row.open ? "" : row.modelData.id; ear.forceActiveFocus() }
                Accessible.name: row.modelData.name
            }
            IconButton {
                implicitWidth: 30; implicitHeight: 30; iconSize: 13
                opacity: Keymap.changed[row.modelData.id] !== undefined ? 1 : 0
                enabled: opacity > 0
                symbol: "reload"
                hint: Lang.t("Varsayılana dön", "Back to the usual")
                onClicked: Keymap.reset(row.modelData.id)
            }
        }
    }
    TextButton { Layout.fillWidth: true; implicitHeight: 38; text: Lang.t("Hepsini varsayılana döndür", "Reset all"); onClicked: { list.said = ""; Keymap.resetAll() } }
}
