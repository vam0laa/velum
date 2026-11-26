import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// Every setting in one place (Ctrl+,). Changes take effect as you make them.
Popup {
    id: page
    property int sleepMode
    property bool restoreSession
    property string downloadFolder          // "" means the system's downloads folder
    property int section: 0
    signal sleepModeChosen(int mode)
    signal restoreSessionChosen(bool on)
    signal downloadFolderChosen(string folder)
    signal clearRequested()

    readonly property string folderShown: downloadFolder !== "" ? downloadFolder
        : decodeURIComponent(String(StandardPaths.writableLocation(StandardPaths.DownloadLocation)).replace("file://", ""))

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(720, Overlay.overlay.width - 32)
    height: Math.min(520, Overlay.overlay.height - 32)
    padding: 4
    topPadding: 36
    background: WindowBackground { title: "settings.exe"; stripe: Theme.peach }

    FolderDialog {
        id: folders
        title: Lang.t("İndirme klasörünü seç", "Choose the downloads folder")
        onAccepted: page.downloadFolderChosen(decodeURIComponent(String(selectedFolder).replace("file://", "")))
    }

    // not set in capitals: that would turn the Turkish "i" into the wrong letter
    component Heading: Text { color: Theme.accent; font.family: Theme.pixel; font.pixelSize: 20; Layout.topMargin: 4 }
    component Row_: RowLayout {
        property alias label: name.text
        Layout.fillWidth: true
        spacing: 12
        Text { id: name; Layout.fillWidth: true; color: Theme.text; font.pixelSize: 13; wrapMode: Text.WrapAtWordBoundaryOrAnywhere }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // sections on the left
        ColumnLayout {
            Layout.fillWidth: false          // a column of names, not half the page
            Layout.preferredWidth: 160
            Layout.maximumWidth: 160
            Layout.fillHeight: true
            Layout.margins: 12
            spacing: 4
            Text { text: Lang.t("Ayarlar", "Settings"); color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold; Layout.bottomMargin: 10; Layout.leftMargin: 8 }
            Repeater {
                model: [Lang.t("Genel", "General"), Lang.t("Sekmeler", "Tabs"), Lang.t("Gizlilik", "Privacy"), Lang.t("Hakkında", "About")]
                AbstractButton {
                    id: entry
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    hoverEnabled: true
                    onClicked: page.section = index
                    contentItem: Text { text: entry.modelData; color: page.section === entry.index ? Theme.text : Theme.dim; font.pixelSize: 13; leftPadding: 10; verticalAlignment: Text.AlignVCenter }
                    background: Bevel { sunken: page.section === entry.index; visible: page.section === entry.index || entry.hovered; color: page.section === entry.index ? Theme.surface : Theme.raised }
                }
            }
            Item { Layout.fillHeight: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            color: Theme.surface
            border.color: Theme.bevelLo
            border.width: 2

            StackLayout {
                anchors { fill: parent; margins: 18 }
                currentIndex: page.section

                // General
                ColumnLayout {
                    spacing: 10
                    Heading { text: Lang.t("Dil", "Language") }
                    Segments {
                        options: [{ key: "auto", label: Lang.t("Sistem", "System") }, { key: "tr", label: "Türkçe" }, { key: "en", label: "English" }]
                        current: Lang.choice
                        onChosen: key => Lang.choice = key
                    }
                    Heading { text: Lang.t("Görünüm", "Look") }
                    Segments {
                        options: [{ key: "mocha", label: "Mocha" }, { key: "gruvbox", label: "Gruvbox" }, { key: "nord", label: "Nord" }, { key: "tokyo", label: "Tokyo" }, { key: "desktop", label: Lang.t("Masaüstü", "Desktop") }]
                        current: Theme.palette
                        onChosen: key => Theme.palette = key
                    }
                    Heading { text: Lang.t("Arama motoru", "Search engine") }
                    Segments {
                        options: Address.engines
                        current: Address.engine
                        onChosen: key => Address.engine = key
                    }
                    Heading { text: Lang.t("İndirmeler", "Downloads") }
                    Row_ {
                        label: page.folderShown
                        TextButton { text: Lang.t("Klasör seç…", "Choose…"); onClicked: folders.open() }
                        TextButton { text: Lang.t("Varsayılan", "Default"); visible: page.downloadFolder !== ""; onClicked: page.downloadFolderChosen("") }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Tabs
                ColumnLayout {
                    spacing: 10
                    Toggle {
                        label: Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start")
                        note: Lang.t("Sekmeler ilk bakıldığında yüklenir", "A tab loads when you first look at it")
                        on: page.restoreSession
                        onClicked: page.restoreSessionChosen(!page.restoreSession)
                    }
                    Heading { text: Lang.t("Boşta kalan sekmeler", "Idle tabs") }
                    Segments {
                        options: [{ key: 0, label: Lang.t("Uyutma", "Never") }, { key: 1, label: Lang.t("Erken", "Early") }, { key: 2, label: Lang.t("Rahat", "Relaxed") }]
                        current: page.sleepMode
                        onChosen: key => page.sleepModeChosen(key)
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: Theme.dim
                        font.pixelSize: 12
                        text: page.sleepMode === 0 ? Lang.t("Sekmeler hep açık kalır.", "Tabs always stay awake.")
                            : page.sleepMode === 1 ? Lang.t("2 dakikada donar, 10 dakikada bellekten çıkar. Sabit ve ses çalan sekmeler uyumaz.", "Frozen after 2 minutes, discarded after 10. Pinned tabs and tabs playing sound stay awake.")
                            : Lang.t("5 dakikada donar, 20 dakikada bellekten çıkar. Sabit ve ses çalan sekmeler uyumaz.", "Frozen after 5 minutes, discarded after 20. Pinned tabs and tabs playing sound stay awake.")
                    }
                    Item { Layout.fillHeight: true }
                }

                // Privacy
                ColumnLayout {
                    spacing: 6
                    Toggle { label: Lang.t("Reklam ve izleyici engelleme", "Block ads and trackers"); note: Lang.t("Filtre listeleriyle", "With filter lists"); on: Shield.enabled; onClicked: Shield.enabled = !Shield.enabled }
                    Toggle { label: Lang.t("Üçüncü taraf çerezleri engelle", "Block third party cookies"); note: Lang.t("Siteler arası takibi zorlaştırır", "Makes following you between sites harder"); on: Shield.blockThirdPartyCookies; onClicked: Shield.blockThirdPartyCookies = !Shield.blockThirdPartyCookies }
                    Toggle { label: Lang.t("Önce HTTPS", "HTTPS first"); note: Lang.t("http adreslerini şifreli aç", "Open http addresses encrypted"); on: Shield.httpsFirst; onClicked: Shield.httpsFirst = !Shield.httpsFirst }
                    Toggle { label: Lang.t("Çıkışta unut", "Forget on exit"); note: Lang.t("Geçmiş, çerezler ve sekmeler; sonraki açılıştan itibaren", "History, cookies and tabs; from the next start"); on: Shield.forgetOnExit; onClicked: Shield.forgetOnExit = !Shield.forgetOnExit }
                    Row_ {
                        label: Shield.statusText(Lang.turkish, Shield.revision, Shield.statusCode)
                        TextButton { text: Lang.t("Listeleri güncelle", "Update lists"); onClicked: Shield.updateLists() }
                    }
                    Item { Layout.fillHeight: true }
                    TextButton { Layout.fillWidth: true; text: Lang.t("Gezinme verilerini sil…", "Delete browsing data…"); onClicked: { page.close(); page.clearRequested() } }
                }

                // About
                ColumnLayout {
                    spacing: 8
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(128, 128); Layout.preferredWidth: 64; Layout.preferredHeight: 64 }
                    Text { text: "Velum " + Qt.application.version; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13; text: Lang.t("Sakin ve gizlilik odaklı bir tarayıcı. Motor: Qt WebEngine (Chromium). Engelleyici: Brave adblock-rust.", "A calm, private browser. Engine: Qt WebEngine (Chromium). Blocker: Brave adblock-rust.") }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12; text: Lang.t("Varsayılan tarayıcı yapmak için: xdg-settings set default-web-browser velum.desktop", "To make it the default browser: xdg-settings set default-web-browser velum.desktop") }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
