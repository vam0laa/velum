import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// Synchronisation, in the settings.
ColumnLayout {
    id: card
    property string folder           // "" when off
    property string status
    property string picked
    signal start(string folder, string password)
    signal stop()
    signal now()
    spacing: 8

    FolderDialog { id: chooser; onAccepted: card.picked = Files.toPath(selectedFolder) }
    component Words: Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 13 }

    Words { text: Lang.t("Sunucu yok. Yer imlerin, parolayla şifrelenmiş tek dosyada senin seçtiğin klasöre yazılır; klasörü Syncthing ya da bir bulut programı diğer bilgisayarına taşır. Orada aynı klasörü ve parolayı seç. Parolalar, geçmiş ve sekmeler eşitlenmez.", "No server. Your bookmarks go, locked with a password, into one file in a folder you choose; Syncthing or a cloud program carries it to your other computer. Choose the same folder and password there. Passwords, history and tabs are not synchronised.") }
    Words { visible: card.folder !== ""; color: Theme.text; text: Lang.t("Klasör: ", "Folder: ") + card.folder }
    RowLayout {
        Layout.fillWidth: true
        visible: card.folder === ""
        TextButton { text: Lang.t("Klasör seç…", "Choose a folder…"); onClicked: chooser.open() }
        Words { text: card.picked; elide: Text.ElideMiddle; wrapMode: Text.NoWrap }
    }
    TextField {
        id: secret
        Layout.fillWidth: true
        visible: card.folder === ""
        implicitHeight: 36
        leftPadding: 12
        echoMode: TextInput.Password
        placeholderText: Lang.t("Eşitleme parolası (en az 8 karakter)", "Password (at least 8 characters)")
        placeholderTextColor: Theme.dim
        color: Theme.text
        font.family: Theme.ui; font.pixelSize: 13
        background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: secret.activeFocus ? Theme.accent : Theme.line }
    }
    TextButton { Layout.fillWidth: true; implicitHeight: 38; strong: true; visible: card.folder === ""; enabled: card.picked !== "" && secret.text.length >= 8; text: Lang.t("Eşitlemeyi başlat", "Start synchronising"); onClicked: { card.start(card.picked, secret.text); secret.text = "" } }
    RowLayout {
        Layout.fillWidth: true
        visible: card.folder !== ""
        TextButton { Layout.fillWidth: true; implicitHeight: 38; strong: true; text: Lang.t("Şimdi eşitle", "Synchronise now"); onClicked: card.now() }
        TextButton { Layout.fillWidth: true; implicitHeight: 38; text: Lang.t("Kapat", "Switch off"); onClicked: card.stop() }
    }
    Words { visible: card.status !== ""; color: Theme.text; text: card.status }
}
