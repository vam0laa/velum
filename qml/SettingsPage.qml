import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// The settings, a page of its own in a tab (Ctrl+,): categories on the left,
// their settings on the right. Changes take effect as you make them.
Rectangle {
    id: page
    property int sleepMode
    property bool restoreSession
    property string downloadFolder          // "" means the system's downloads folder
    property bool horizontalTabs
    property bool compactSidebar
    property var neverSites: []
    property int bookmarkCount
    property string section: "look"
    signal sleepModeChosen(int mode)
    signal restoreSessionChosen(bool on)
    signal downloadFolderChosen(string folder)
    signal layoutChosen(bool horizontal)
    signal compactChosen(bool on)
    signal clearRequested()
    signal askAgain(string origin)
    signal bookmarksRequested()
    signal importRequested()
    signal welcomeRequested()
    property string startBackground
    property string startPicture
    property bool showClock
    property bool showShield
    property bool showNote
    property bool showFrequent
    property bool showBookmarkBar
    signal startChanged(string name, var value)      // a property of the window and its new value
    property var extensions: []
    property bool fetchingExtension
    signal addFromStore(string typed)
    signal addFromFile(string path)
    signal openStore()
    signal openExtensionPage(url address)
    signal enableExtension(var extension, bool on)
    signal removeExtension(var extension)

    readonly property string folderShown: downloadFolder !== "" ? downloadFolder
        : decodeURIComponent(String(StandardPaths.writableLocation(StandardPaths.DownloadLocation)).replace("file://", ""))

    readonly property var sections: [
        { key: "look", icon: "palette", label: Lang.t("Görünüm", "Appearance") },
        { key: "general", icon: "settings", label: Lang.t("Genel", "General") },
        { key: "tabs", icon: "panel", label: Lang.t("Sekmeler", "Tabs") },
        { key: "privacy", icon: "shield", label: Lang.t("Gizlilik", "Privacy") },
        { key: "passwords", icon: "key", label: Lang.t("Parolalar", "Passwords") },
        { key: "extensions", icon: "puzzle", label: Lang.t("Eklentiler", "Extensions") },
        { key: "bookmarks", icon: "star", label: Lang.t("Yer imleri", "Bookmarks") },
        { key: "keys", icon: "command", label: Lang.t("Kısayollar", "Shortcuts") },
        { key: "about", icon: "alert", label: Lang.t("Hakkında", "About") }
    ]
    readonly property var current: sections.find(s => s.key === section) ?? sections[0]

    color: Theme.sheetBack

    function refresh() {
        if (visible && section === "passwords")
            passwordList.refresh()
    }
    onSectionChanged: { scroll.contentY = 0; arrive.restart(); refresh() }
    onVisibleChanged: refresh()

    FolderDialog {
        id: folders
        title: Lang.t("İndirme klasörünü seç", "Choose the downloads folder")
        onAccepted: page.downloadFolderChosen(decodeURIComponent(String(selectedFolder).replace("file://", "")))
    }

    FileDialog {
        id: pictures
        title: Lang.t("Arka plan resmini seç", "Choose the background picture")
        nameFilters: [Lang.t("Resimler", "Pictures") + " (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            page.startChanged("startPicture", decodeURIComponent(String(selectedFile).replace("file://", "")))
            page.startChanged("startBackground", "image")
        }
    }

    // a setting: its name on the left, what changes it on the right
    component Line: RowLayout {
        property alias label: name.text
        Layout.fillWidth: true
        Layout.minimumHeight: 40
        spacing: 12
        Text { id: name; Layout.fillWidth: true; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17); wrapMode: Text.WrapAtWordBoundaryOrAnywhere }
    }
    component Note: Text { Layout.fillWidth: true; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16); wrapMode: Text.WordWrap }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // the categories, always with their names
        Flickable {
            Layout.fillWidth: false
            Layout.preferredWidth: page.width < 520 ? 136 : 180
            Layout.fillHeight: true
            Layout.margins: 8
            contentHeight: menu.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: menu
                width: parent.width
                spacing: 2
                Text {
                    Layout.leftMargin: 10
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    text: Lang.t("Ayarlar", "Settings")
                    color: Theme.text
                    font.family: Theme.ui; font.pixelSize: Theme.size(22)
                    font.weight: Font.Normal
                }
                Repeater {
                    model: page.sections
                    AbstractButton {
                        id: entry
                        required property var modelData
                        readonly property bool chosen: page.section === modelData.key
                        Layout.fillWidth: true
                        implicitHeight: 34
                        hoverEnabled: true
                        onClicked: page.section = modelData.key
                        Accessible.name: modelData.label
                        background: Rectangle { radius: Theme.radius; color: entry.chosen ? (Theme.web ? Theme.accent : Theme.raised) : entry.hovered ? (Theme.web ? Theme.title : Qt.alpha(Theme.raised, 0.5)) : "transparent" }
                        contentItem: Item {
                            Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: entry.modelData.icon; size: 15; color: entry.chosen ? (Theme.web ? Theme.accentInk : Theme.accent) : Theme.text }
                            Text { anchors { left: parent.left; leftMargin: 32; right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } text: entry.modelData.label; elide: Text.ElideRight; color: entry.chosen && Theme.web ? Theme.accentInk : Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17); font.weight: entry.chosen ? Font.Bold : Font.Normal }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.line; opacity: 0.6 }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: content.implicitHeight + 72
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: content
                transform: Translate { id: slide }
                ParallelAnimation {
                    id: arrive
                    NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.smooth }
                    NumberAnimation { target: slide; property: "y"; from: 18; to: 0; duration: Theme.smooth; easing.type: Easing.OutCubic }
                }
                width: Math.min(parent.width - 36, 720)
                x: (parent.width - width) / 2
                y: 18
                spacing: 8

                Text { text: page.current.label; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(29); font.weight: Font.Normal; Layout.bottomMargin: 12 }

                // ---- appearance ----
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("Renkler", "Colours")
                    Line {
                        visible: !Theme.web
                        label: Lang.t("Tema", "Theme")
                        Dropdown {
                            options: Theme.themes.map(x => ({ key: x.key, label: x.label, color: Theme.colorOf(x.key, 8) }))
                            current: Theme.palette
                            onChosen: key => Theme.palette = key
                        }
                    }
                    Line {
                        visible: !Theme.web
                        label: Lang.t("Vurgu rengi", "Accent colour")
                        AccentDots {}
                    }
                }
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("Pencere", "Window")
                    Line {
                        label: Lang.t("Sekmeler", "Tabs")
                        Segments {
                            options: [{ key: false, label: Lang.t("Yanda", "Side") }, { key: true, label: Lang.t("Üstte", "Top") }]
                            current: page.horizontalTabs
                            onChosen: key => page.layoutChosen(key)
                        }
                    }
                    Toggle {
                        visible: !page.horizontalTabs
                        label: Lang.t("Yan paneli daralt", "Narrow side bar")
                        note: Lang.t("Yalnızca simgeler (Ctrl+B)", "Icons only (Ctrl+B)")
                        on: page.compactSidebar
                        onClicked: page.compactChosen(!page.compactSidebar)
                    }
                    Toggle {
                        visible: page.horizontalTabs && !Theme.web
                        label: Lang.t("Yer imi çubuğu", "Bookmarks bar")
                        on: page.showBookmarkBar
                        onClicked: page.startChanged("showBookmarkBar", !page.showBookmarkBar)
                    }
                    Toggle { label: Lang.t("Cam görünüm", "Glass look"); note: Lang.t("Saydam pencereler", "See-through windows"); on: Theme.glass; onClicked: Theme.glass = !Theme.glass }
                    Line {
                        visible: Theme.glass
                        label: Lang.t("Saydamlık", "Transparency")
                        Dropdown {
                            options: [{ key: 0.55, label: Lang.t("Çok saydam", "Clear") }, { key: 0.72, label: Lang.t("Orta", "Medium") }, { key: 0.88, label: Lang.t("Az saydam", "Misty") }]
                            current: Theme.solidity
                            onChosen: key => Theme.solidity = key
                        }
                    }
                    Toggle { label: Lang.t("Animasyonlar", "Animations"); on: Theme.motion; onClicked: Theme.motion = !Theme.motion }
                }
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("Ana sayfa", "Start page")
                    Line {
                        visible: !Theme.web
                        label: Lang.t("Arka plan", "Background")
                        Dropdown {
                            options: [{ key: "glow", label: Lang.t("Işıltı", "Glow") }, { key: "plain", label: Lang.t("Sade", "Plain") }, { key: "dots", label: Lang.t("Noktalar", "Dots") }, { key: "image", label: Lang.t("Resim", "Picture") }]
                            current: page.startBackground
                            onChosen: key => {
                                if (key === "image" && page.startPicture === "")
                                    pictures.open()
                                else
                                    page.startChanged("startBackground", key)
                            }
                        }
                    }
                    Line {
                        visible: !Theme.web && page.startBackground === "image"
                        label: page.startPicture
                        TextButton { text: Lang.t("Resim seç…", "Choose…"); onClicked: pictures.open() }
                    }
                    Toggle { label: Lang.t("Saat ve tarih", "Clock and date"); on: page.showClock; onClicked: page.startChanged("showClock", !page.showClock) }
                    Toggle { label: Lang.t("Kalkan uyarısı", "Shield notice"); on: page.showShield; onClicked: page.startChanged("showShield", !page.showShield) }
                    Toggle { label: Lang.t("Sık gidilenler", "Most visited"); on: page.showFrequent; onClicked: page.startChanged("showFrequent", !page.showFrequent) }
                    Toggle { label: Lang.t("Not defteri", "Note"); on: page.showNote; onClicked: page.startChanged("showNote", !page.showNote) }
                }

                // ---- general ----
                Card {
                    visible: page.section === "general"
                    Line {
                        label: Lang.t("Dil", "Language")
                        Dropdown {
                            options: [{ key: "auto", label: Lang.t("Sistem", "System") }, { key: "tr", label: "Türkçe" }, { key: "en", label: "English" }]
                            current: Lang.choice
                            onChosen: key => Lang.choice = key
                        }
                    }
                    Line {
                        label: Lang.t("Arama motoru", "Search engine")
                        Dropdown {
                            options: Address.engines
                            current: Address.engine
                            onChosen: key => Address.engine = key
                        }
                    }
                }
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("İndirmeler", "Downloads")
                    Line {
                        label: page.folderShown
                        TextButton { text: Lang.t("Klasör seç…", "Choose…"); onClicked: folders.open() }
                        TextButton { text: Lang.t("Varsayılan", "Default"); visible: page.downloadFolder !== ""; onClicked: page.downloadFolderChosen("") }
                    }
                }
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("Karşılama", "Welcome")
                    Line {
                        label: Lang.t("İlk açılıştaki seçimleri yeniden gez", "Go through the first-run choices again")
                        TextButton { text: Lang.t("Aç", "Open"); onClicked: page.welcomeRequested() }
                    }
                }

                // ---- tabs ----
                Card {
                    visible: page.section === "tabs"
                    heading: Lang.t("Açılış", "Start")
                    Toggle {
                        label: Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start")
                        note: Lang.t("Sekmeler ilk bakıldığında yüklenir", "A tab loads when you first look at it")
                        on: page.restoreSession
                        onClicked: page.restoreSessionChosen(!page.restoreSession)
                    }
                }
                Card {
                    visible: page.section === "tabs"
                    Line {
                        label: Lang.t("Boşta kalan sekmeleri uyut", "Put idle tabs to sleep")
                        Dropdown {
                            options: [{ key: 0, label: Lang.t("Uyutma", "Never") }, { key: 1, label: Lang.t("Erken", "Early") }, { key: 2, label: Lang.t("Rahat", "Relaxed") }]
                            current: page.sleepMode
                            onChosen: key => page.sleepModeChosen(key)
                        }
                    }
                    Note {
                        text: page.sleepMode === 0 ? Lang.t("Sekmeler hep açık kalır.", "Tabs always stay awake.")
                            : page.sleepMode === 1 ? Lang.t("2 dakikada donar, 10 dakikada bellekten çıkar. Sabit ve ses çalan sekmeler uyumaz.", "Frozen after 2 minutes, discarded after 10. Pinned tabs and tabs playing sound stay awake.")
                            : Lang.t("5 dakikada donar, 20 dakikada bellekten çıkar. Sabit ve ses çalan sekmeler uyumaz.", "Frozen after 5 minutes, discarded after 20. Pinned tabs and tabs playing sound stay awake.")
                    }
                }

                // ---- privacy ----
                Card {
                    visible: page.section === "privacy"
                    heading: Lang.t("Kalkan", "Shield")
                    Toggle { label: Lang.t("Reklam ve izleyici engelleme", "Block ads and trackers"); note: Lang.t("Filtre listeleriyle", "With filter lists"); on: Shield.enabled; onClicked: Shield.enabled = !Shield.enabled }
                    Toggle { label: Lang.t("Üçüncü taraf çerezleri engelle", "Block third party cookies"); note: Lang.t("Siteler arası takibi zorlaştırır", "Makes following you between sites harder"); on: Shield.blockThirdPartyCookies; onClicked: Shield.blockThirdPartyCookies = !Shield.blockThirdPartyCookies }
                    Toggle { label: Lang.t("Önce HTTPS", "HTTPS first"); note: Lang.t("http adreslerini şifreli aç", "Open http addresses encrypted"); on: Shield.httpsFirst; onClicked: Shield.httpsFirst = !Shield.httpsFirst }
                    Line {
                        label: Shield.statusText(Lang.turkish, Shield.revision, Shield.statusCode)
                        TextButton { text: Lang.t("Listeleri güncelle", "Update lists"); onClicked: Shield.updateLists() }
                    }
                }
                Card {
                    visible: page.section === "privacy"
                    heading: Lang.t("Gezinme verileri", "Browsing data")
                    Toggle { label: Lang.t("Çıkışta unut", "Forget on exit"); note: Lang.t("Geçmiş, çerezler ve sekmeler; sonraki açılıştan itibaren", "History, cookies and tabs; from the next start"); on: Shield.forgetOnExit; onClicked: Shield.forgetOnExit = !Shield.forgetOnExit }
                    TextButton { text: Lang.t("Gezinme verilerini sil…", "Delete browsing data…"); onClicked: page.clearRequested() }
                }

                // ---- passwords ----
                Card {
                    visible: page.section === "passwords"
                    PasswordList {
                        id: passwordList
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(260, page.height - 240)
                        neverSites: page.neverSites
                        onAllow: origin => page.askAgain(origin)
                    }
                }

                // ---- extensions ----
                ExtensionList {
                    visible: page.section === "extensions"
                    Layout.fillWidth: true
                    extensions: page.extensions
                    busy: page.fetchingExtension
                    onAddFromStore: typed => page.addFromStore(typed)
                    onAddFromFile: path => page.addFromFile(path)
                    onOpenStore: page.openStore()
                    onOpenPage: address => page.openExtensionPage(address)
                    onEnable: (extension, on) => page.enableExtension(extension, on)
                    onRemove: extension => page.removeExtension(extension)
                }

                // ---- bookmarks ----
                Card {
                    visible: page.section === "bookmarks"
                    heading: Lang.t("Yer imleri", "Bookmarks")
                    Line {
                        label: Lang.t(page.bookmarkCount + " yer imi kayıtlı", page.bookmarkCount + " bookmarks saved")
                        TextButton { text: Lang.t("Yöneticiyi aç", "Open the manager"); strong: true; onClicked: page.bookmarksRequested() }
                    }
                }
                Card {
                    visible: page.section === "bookmarks"
                    heading: Lang.t("Başka tarayıcıdan", "From another browser")
                    note: Lang.t("Firefox ve Chromium ailesinden yer imleri ve geçmiş. Dosyalar yalnızca okunur.", "Bookmarks and history from Firefox and Chromium relatives. Their files are only read.")
                    TextButton { text: Lang.t("İçe aktar…", "Import…"); onClicked: page.importRequested() }
                }

                // ---- shortcuts ----
                Card {
                    visible: page.section === "keys"
                    Repeater {
                        model: [
                            ["Ctrl+T", Lang.t("Yeni sekme", "New tab")], ["Ctrl+K", Lang.t("Komut kutusu", "Command box")], ["Ctrl+L", Lang.t("Adres", "Address")],
                            ["Ctrl+W", Lang.t("Sekmeyi kapat", "Close the tab")], ["Ctrl+Shift+T", Lang.t("Kapatılanı geri aç", "Reopen closed tab")], ["Ctrl+Tab", Lang.t("Sonraki sekme", "Next tab")],
                            ["Ctrl+Shift+P", Lang.t("Sekmeyi sabitle", "Pin the tab")], ["Alt+1 … 6", Lang.t("Çalışma alanları", "Workspaces")], ["Ctrl+\\", Lang.t("Bölünmüş ekran", "Split view")],
                            ["Ctrl+D", Lang.t("Yer imi", "Bookmark")], ["Ctrl+Shift+O", Lang.t("Yer imi yöneticisi", "Bookmark manager")], ["Ctrl+H", Lang.t("Geçmiş", "History")],
                            ["Ctrl+J", Lang.t("İndirmeler", "Downloads")], ["Alt+R", Lang.t("Okuma modu", "Reading mode")], ["Alt+P", Lang.t("Küçük video penceresi", "Mini video window")],
                            ["Ctrl+Shift+L", Lang.t("Parolayı doldur", "Fill the password")], ["Ctrl+F", Lang.t("Sayfada ara", "Find in page")], ["Shift+Esc", Lang.t("Kaynaklar", "Resources")],
                            ["Ctrl+B", Lang.t("Yan paneli daralt", "Narrow the side bar")], ["F11", Lang.t("Tam ekran", "Full screen")], ["Ctrl+Q", Lang.t("Çıkış", "Quit")]
                        ]
                        Line {
                            id: shortcut
                            required property var modelData
                            label: modelData[1]
                            Rectangle {
                                implicitWidth: key.implicitWidth + 20
                                implicitHeight: 26
                                radius: Theme.radius
                                color: Theme.raised
                                Text { id: key; anchors.centerIn: parent; text: shortcut.modelData[0]; color: Theme.accent; font.family: Theme.ui; font.pixelSize: Theme.size(22) }
                            }
                        }
                    }
                }

                // ---- about ----
                Card {
                    visible: page.section === "about"
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(160, 160); Layout.preferredWidth: 80; Layout.preferredHeight: 80 }
                    Text { text: "Velum " + Qt.application.version; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(31); font.weight: Font.Normal }
                    Note { font.family: Theme.ui; font.pixelSize: Theme.size(17); text: Lang.t("Sakin ve gizlilik odaklı bir tarayıcı. Motor: Qt WebEngine (Chromium). Engelleyici: Brave adblock-rust.", "A calm, private browser. Engine: Qt WebEngine (Chromium). Blocker: Brave adblock-rust.") }
                    Note { text: Lang.t("Varsayılan tarayıcı yapmak için: xdg-settings set default-web-browser velum.desktop", "To make it the default browser: xdg-settings set default-web-browser velum.desktop") }
                }
            }
        }
    }
}
