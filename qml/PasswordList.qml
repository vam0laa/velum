import QtQuick
import QtQuick.Controls
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
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Text {
        Layout.fillWidth: true
        visible: panel.broken || (panel.accounts.length === 0)
        text: panel.broken ? Lang.t("Anahtarlığa ulaşılamadı. Kilidi açık mı?", "The keyring cannot be reached. Is it unlocked?") : Lang.t("Henüz kayıtlı parola yok.", "No saved passwords yet.")
        color: panel.broken ? Theme.danger : Theme.text
        font.pixelSize: 13
        wrapMode: Text.WordWrap
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
                    Text { width: parent.width; text: row.modelData.user || Lang.t("(adsız)", "(no name)"); textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.pixelSize: 13 }
                    Text { width: parent.width; text: row.modelData.origin; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.pixelSize: 11 }
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
    Text { Layout.fillWidth: true; visible: text !== ""; text: panel.said; color: Theme.green; font.pixelSize: 12; wrapMode: Text.WordWrap }
    Text { visible: panel.neverSites.length > 0; text: Lang.t("Hiç sorulmayan siteler (tıkla: yine sor)", "Never asked on (click to ask again)"); color: Theme.dim; font.pixelSize: 12 }
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
