import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// The saved logins, in the settings. Passwords are never shown; they can be copied or deleted.
ColumnLayout {
    id: panel
    property var accounts: []
    property var neverSites: []
    property bool broken: false
    property string said: ""
    property string removing: ""        // the row waiting for a second click
    signal allow(string origin)
    spacing: 8

    function refresh() {
        said = ""
        removing = ""
        Passwords.accounts("", found => {
            panel.broken = found === null
            panel.accounts = found ?? []
        })
    }

    Text {
        Layout.fillWidth: true
        text: Lang.t("Parolalar sistem anahtarlığında şifreli durur. Doldurma yalnızca sen isteyince (Ctrl+Shift+L) ve adres birebir eşleşince yapılır.", "Passwords are kept encrypted in the system keyring. A form is filled only when you ask (Ctrl+Shift+L) and the address matches exactly.")
        color: Theme.dim
        font.family: Theme.ui; font.pixelSize: Theme.size(16)
        wrapMode: Text.WordWrap
    }
    Text {
        Layout.fillWidth: true
        visible: panel.broken || (panel.accounts.length === 0)
        text: panel.broken ? Lang.t("Anahtarlığa ulaşılamadı. Kilidi açık mı?", "The keyring cannot be reached. Is it unlocked?") : Lang.t("Henüz kayıtlı parola yok.", "No saved passwords yet.")
        color: panel.broken ? Theme.danger : Theme.text
        font.family: Theme.ui; font.pixelSize: Theme.size(17)
        wrapMode: Text.WordWrap
    }
    // adding one yourself, with a strong password made for you; saving an existing name changes it
    component Field: TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: 32
        leftPadding: 10
        color: Theme.text
        placeholderTextColor: Theme.dim
        font.family: Theme.ui; font.pixelSize: Theme.size(16)
        background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: field.activeFocus ? Theme.accent : Theme.line }
    }
    property bool adding: false
    function add(site, user, secret) {
        const origin = Passwords.origin(site.indexOf("://") < 0 ? "https://" + site : site)
        if (origin === "" || secret === "") {
            said = Lang.t("Site adresi (https) ve parola gerekli.", "A site address (https) and a password are needed.")
            return false
        }
        Passwords.save(origin, user.trim(), secret, ok => { panel.refresh(); panel.said = ok ? Lang.t("Kaydedildi.", "Saved.") : Lang.t("Kaydedilemedi.", "Could not save.") })
        adding = false
        return true
    }
    FileDialog { id: csvIn; nameFilters: ["CSV (*.csv)"]; onAccepted: Passwords.importCsv(selectedFile, n => { panel.refresh(); panel.said = n < 0 ? Lang.t("Bu dosya bir parola dosyası olarak okunamadı.", "This file could not be read as a password file.") : Lang.t(n + " parola alındı. Dosyayı artık silmelisin.", n + " passwords taken in. Delete the file now.") }) }
    FileDialog { id: csvOut; fileMode: FileDialog.SaveFile; defaultSuffix: "csv"; nameFilters: ["CSV (*.csv)"]; onAccepted: Passwords.exportCsv(selectedFile, n => panel.said = n < 0 ? Lang.t("Dışa aktarılamadı.", "Could not export.") : Lang.t(n + " parola ŞİFRESİZ olarak yazıldı. İşin bitince dosyayı sil.", n + " passwords written UNENCRYPTED. Delete the file when done.")) }
    RowLayout {
        Layout.fillWidth: true
        TextButton { text: panel.adding ? Lang.t("Vazgeç", "Cancel") : Lang.t("Parola ekle", "Add a password"); onClicked: panel.adding = !panel.adding }
        Item { Layout.fillWidth: true }
        TextButton { text: Lang.t("CSV'den al", "Import CSV"); onClicked: csvIn.open() }
        property bool sure: false
        TextButton { text: parent.sure ? Lang.t("Şifresiz yazılacak, emin misin?", "Written unencrypted, sure?") : Lang.t("CSV'ye ver", "Export CSV"); enabled: panel.accounts.length > 0; onClicked: { if (parent.sure) csvOut.open(); parent.sure = !parent.sure } }
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: panel.adding
        Field { id: newSite; placeholderText: Lang.t("Site (örn. ornek.com)", "Site (e.g. example.com)") }
        Field { id: newUser; placeholderText: Lang.t("Kullanıcı adı", "User name") }
        RowLayout {
            Layout.fillWidth: true
            Field { id: newSecret; placeholderText: Lang.t("Parola", "Password"); echoMode: shown.on ? TextInput.Normal : TextInput.Password }
            TextButton { id: shown; property bool on: false; text: on ? Lang.t("Gizle", "Hide") : Lang.t("Göster", "Show"); onClicked: on = !on }
            TextButton { text: Lang.t("Güçlü parola üret", "Generate a strong one"); onClicked: { newSecret.text = Passwords.generate(20); shown.on = true } }
        }
        TextButton { Layout.alignment: Qt.AlignRight; strong: true; text: Lang.t("Kaydet", "Save"); onClicked: if (panel.add(newSite.text.trim(), newUser.text, newSecret.text)) { newSite.text = ""; newUser.text = ""; newSecret.text = ""; shown.on = false } }
    }
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: panel.accounts
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property string key: modelData.origin + " " + modelData.user
            width: ListView.view.width
            height: 48
            radius: Theme.radius
            color: Theme.window
            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                spacing: 8
                Column {
                    Layout.fillWidth: true
                    Text { width: parent.width; text: row.modelData.user || Lang.t("(adsız)", "(no name)"); textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17) }
                    Text { width: parent.width; text: row.modelData.origin; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(14) }
                }
                TextButton {
                    implicitHeight: 28
                    text: Lang.t("Kopyala", "Copy")
                    onClicked: Passwords.copy(row.modelData.origin, row.modelData.user, ok => panel.said = ok
                        ? Lang.t("Kopyalandı; 30 saniye sonra panodan silinir.", "Copied; it leaves the clipboard in 30 seconds.")
                        : Lang.t("Kopyalanamadı.", "Could not copy."))
                }
                TextButton {
                    implicitHeight: 28
                    strong: panel.removing === row.key
                    text: panel.removing === row.key ? Lang.t("Emin misin?", "Sure?") : Lang.t("Sil", "Delete")
                    onClicked: {
                        if (panel.removing !== row.key) {
                            panel.removing = row.key
                            return
                        }
                        Passwords.remove(row.modelData.origin, row.modelData.user, () => panel.refresh())
                    }
                }
            }
        }
    }
    Text { Layout.fillWidth: true; visible: text !== ""; text: panel.said; color: Theme.green; font.family: Theme.ui; font.pixelSize: Theme.size(16); wrapMode: Text.WordWrap }
    Text { visible: panel.neverSites.length > 0; text: Lang.t("Hiç sorulmayan siteler (tıkla: yine sor)", "Never asked on (click to ask again)"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
    Flow {
        Layout.fillWidth: true
        visible: panel.neverSites.length > 0
        spacing: 6
        Repeater {
            model: panel.neverSites
            TextButton { required property string modelData; implicitHeight: 26; text: modelData; onClicked: panel.allow(modelData) }
        }
    }
}
