import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// Backup and restore, in the settings.
ColumnLayout {
    id: card
    property string result
    signal backup(url file, string password)
    signal restore(url file, string password)
    spacing: 8

    FileDialog { id: out; fileMode: FileDialog.SaveFile; defaultSuffix: "velumbackup"; nameFilters: ["Velum (*.velumbackup)"]; onAccepted: card.backup(selectedFile, secret.text) }
    FileDialog { id: into; nameFilters: ["Velum (*.velumbackup)"]; onAccepted: card.restore(selectedFile, secret.text) }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.family: Theme.ui
        font.pixelSize: 13
        text: Lang.t("Yer imleri, tema ve ana sayfa tasarımı, parolayla şifrelenmiş tek dosyada. Parolalar, çerezler ve geçmiş dosyaya girmez.", "Bookmarks, theme and home page design in one file locked with a password. Passwords, cookies and history stay out of it.")
    }
    TextField {
        id: secret
        Layout.fillWidth: true
        implicitHeight: 36
        leftPadding: 12
        echoMode: TextInput.Password
        placeholderText: Lang.t("Yedek parolası (en az 8 karakter)", "Backup password (at least 8 characters)")
        placeholderTextColor: Theme.dim
        color: Theme.text
        font.family: Theme.ui; font.pixelSize: 13
        background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: secret.activeFocus ? Theme.accent : Theme.line }
    }
    RowLayout {
        Layout.fillWidth: true
        TextButton { Layout.fillWidth: true; implicitHeight: 38; strong: true; enabled: secret.text.length >= 8; text: Lang.t("Yedekle…", "Back up…"); onClicked: out.open() }
        TextButton { Layout.fillWidth: true; implicitHeight: 38; enabled: secret.text.length > 0; text: Lang.t("Geri yükle…", "Restore…"); onClicked: into.open() }
    }
    Text { Layout.fillWidth: true; visible: text !== ""; text: card.result; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.ui; font.pixelSize: 13 }
}
