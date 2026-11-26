import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Adds a bookmark: its name and its address.
Popup {
    id: dialog
    property var save: (title, address) => false
    property bool refused: false

    function show() {
        name.text = ""
        address.text = ""
        refused = false
        open()
        name.forceActiveFocus()
    }

    function accept() {
        if (address.text.trim() === "")
            address.forceActiveFocus()
        else if (save(name.text, address.text.trim()))
            close()
        else
            refused = true
    }

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 420
    padding: 18
    topPadding: 42
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("yer imi ekle", "add a bookmark"); stripe: Theme.mauve }

    component Entry: TextField {
        Layout.fillWidth: true
        implicitHeight: 38
        leftPadding: 14
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentInk
        placeholderTextColor: Theme.dim
        font.family: Theme.ui; font.pixelSize: Theme.size(17)
        background: Bevel { sunken: true; radius: Theme.radius; color: Theme.frame; shade: parent.activeFocus ? Theme.accent : Theme.line }
        onAccepted: dialog.accept()
    }
    component Label_: Text { color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 8
        Label_ { text: Lang.t("Ad", "Name") }
        Entry { id: name; maximumLength: 80; placeholderText: Lang.t("örn. YouTube (boşsa sitenin adı)", "e.g. YouTube (the site's name if empty)") }
        Label_ { text: Lang.t("Adres", "Address") }
        Entry { id: address; placeholderText: Lang.t("örn. youtube.com", "e.g. youtube.com"); onTextChanged: dialog.refused = false }
        Text {
            Layout.fillWidth: true
            visible: dialog.refused
            text: Lang.t("Bu adres geçerli değil ya da zaten ekli.", "This address is not valid or is already there.")
            color: Theme.danger
            font.family: Theme.ui; font.pixelSize: Theme.size(16)
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 8
            Item { Layout.fillWidth: true }
            TextButton { text: Lang.t("Vazgeç", "Cancel"); onClicked: dialog.close() }
            TextButton { text: Lang.t("Ekle", "Add"); strong: true; enabled: address.text.trim() !== ""; onClicked: dialog.accept() }
        }
    }
}
