import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Names a new workspace, or renames and deletes an existing one.
Popup {
    id: dialog
    property int spaceId: 0             // 0: a new one
    property bool removable: false
    signal accepted(int id, string name)
    signal removed(int id)

    function show(id, name, canRemove) {
        spaceId = id
        removable = canRemove
        input.text = name
        open()
        input.forceActiveFocus()
        input.selectAll()
    }

    function save() {
        if (input.text.trim() === "")
            return
        close()
        accepted(spaceId, input.text)
    }

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 360
    padding: 18
    topPadding: 42
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("çalışma alanı", "workspace"); stripe: Theme.mauve }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 12
        TextField {
            id: input
            Layout.fillWidth: true
            implicitHeight: 38
            leftPadding: 14
            maximumLength: 20
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            placeholderText: Lang.t("Alanın adı, örn. Okul", "Name, e.g. School")
            placeholderTextColor: Theme.dim
            font.pixelSize: 13
            background: Bevel { sunken: true; radius: height / 2; color: Theme.frame; shade: input.activeFocus ? Theme.accent : Theme.line }
            onAccepted: dialog.save()
        }
        Text {
            Layout.fillWidth: true
            visible: dialog.removable
            text: Lang.t("Silersen sekmeleri kaybolmaz, başka bir alana taşınır.", "Deleting keeps its tabs: they move to another workspace.")
            color: Theme.dim
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextButton { visible: dialog.removable; text: Lang.t("Alanı sil", "Delete"); onClicked: { dialog.close(); dialog.removed(dialog.spaceId) } }
            Item { Layout.fillWidth: true }
            TextButton { text: Lang.t("Vazgeç", "Cancel"); onClicked: dialog.close() }
            TextButton { text: dialog.spaceId === 0 ? Lang.t("Oluştur", "Create") : Lang.t("Kaydet", "Save"); strong: true; enabled: input.text.trim() !== ""; onClicked: dialog.save() }
        }
    }
}
