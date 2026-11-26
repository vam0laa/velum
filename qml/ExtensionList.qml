import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// The extensions, in the settings: add one from the Chrome Web Store or from your own
// files, turn them on and off, remove them.
ColumnLayout {
    id: panel
    property var extensions: []
    property bool busy: false
    property string removing: ""
    signal addFromStore(string typed)
    signal addFromFile(string path)
    signal openStore()
    signal openPage(url address)
    signal enable(var extension, bool on)
    signal remove(var extension)
    spacing: 14

    function localPath(url) { return Files.toPath(url) }

    FileDialog {
        id: zip
        title: Lang.t("Eklenti paketini seç", "Choose an extension package")
        nameFilters: ["Zip (*.zip)"]
        onAccepted: panel.addFromFile(panel.localPath(selectedFile))
    }
    FolderDialog {
        id: folder
        title: Lang.t("Eklenti klasörünü seç", "Choose an extension folder")
        onAccepted: panel.addFromFile(panel.localPath(selectedFolder))
    }

    Card {
        heading: "Chrome Web Store"
        note: Lang.t("Mağazada eklentinin sayfasını aç ve başlık çubuğundaki \"Velum'a ekle\"ye bas, ya da adresini buraya yapıştır. Paket Google'dan indirilir ve imzası doğrulanır. Mağazanın kendi \"Chrome'a ekle\" düğmesi burada çalışmaz.",
                     "Open an extension's page in the store and press \"Add to Velum\" in the title bar, or paste its address here. The package comes from Google and its signature is checked. The store's own \"Add to Chrome\" button does not work here.")
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: address
                Layout.fillWidth: true
                implicitHeight: 36
                leftPadding: 14
                placeholderText: Lang.t("Mağaza adresi ya da eklenti kimliği", "Store address or extension id")
                placeholderTextColor: Theme.dim
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentInk
                font.family: Theme.ui; font.pixelSize: Theme.size(17)
                selectByMouse: true
                background: Rectangle { radius: Theme.radius; color: Theme.frame; border.color: address.activeFocus ? Theme.accent : Theme.line }
                onAccepted: add.clicked()
            }
            TextButton {
                id: add
                text: panel.busy ? Lang.t("İndiriliyor…", "Fetching…") : Lang.t("Ekle", "Add")
                strong: true
                enabled: !panel.busy && address.text.trim() !== ""
                onClicked: panel.addFromStore(address.text)
            }
        }
        TextButton { text: Lang.t("Web Store'u aç", "Open the Web Store"); onClicked: panel.openStore() }
    }

    Card {
        heading: Lang.t("Önerilenler", "Suggested")
        Recommended {
            Layout.fillWidth: true
            installed: panel.extensions.map(e => e.name)
            onInstall: id => panel.addFromStore(id)
        }
    }

    Card {
        heading: Lang.t("Kurulu", "Installed")
        Text {
            Layout.fillWidth: true
            visible: panel.extensions.length === 0
            text: Lang.t("Henüz eklenti yok.", "No extensions yet.")
            color: Theme.dim
            font.family: Theme.ui; font.pixelSize: Theme.size(17)
        }
        Repeater {
            model: panel.extensions
            Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: column.implicitHeight + 20
                radius: Theme.radius
                color: Theme.surface
                ColumnLayout {
                    id: column
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 6
                    Toggle {
                        label: row.modelData.name
                        note: row.modelData.error !== "" ? row.modelData.error : row.modelData.description
                        on: row.modelData.isEnabled
                        onClicked: panel.enable(row.modelData, !row.modelData.isEnabled)
                    }
                    RowLayout {
                        spacing: 8
                        TextButton {
                            implicitHeight: 28
                            visible: String(row.modelData.actionPopupUrl) !== "" && row.modelData.isEnabled
                            text: Lang.t("Penceresini aç", "Open its panel")
                            onClicked: panel.openPage(row.modelData.actionPopupUrl)
                        }
                        TextButton {
                            implicitHeight: 28
                            strong: panel.removing === row.modelData.id
                            text: panel.removing === row.modelData.id ? Lang.t("Emin misin?", "Sure?") : Lang.t("Kaldır", "Remove")
                            onClicked: {
                                if (panel.removing !== row.modelData.id) {
                                    panel.removing = row.modelData.id
                                    return
                                }
                                panel.removing = ""
                                panel.remove(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Card {
        heading: Lang.t("Kendi dosyandan", "From your own files")
        note: Lang.t("Yalnızca Manifest V3 eklentiler. Chrome'un her özelliği bu motorda yok; bazı eklentiler eksik çalışabilir ya da hiç çalışmayabilir.",
                     "Manifest V3 extensions only. The engine does not offer everything Chrome does; some extensions work partly or not at all.")
        RowLayout {
            spacing: 8
            TextButton { text: Lang.t("Zip seç…", "Choose a zip…"); onClicked: zip.open() }
            TextButton { text: Lang.t("Klasör seç…", "Choose a folder…"); onClicked: folder.open() }
        }
    }
}
