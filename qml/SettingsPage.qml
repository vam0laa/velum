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
    readonly property bool narrow: width < 520

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

    component Line: RowLayout {
        property alias label: name.text
        Layout.fillWidth: true
        spacing: 12
        Text { id: name; Layout.fillWidth: true; color: Theme.text; font.pixelSize: 13; wrapMode: Text.WrapAtWordBoundaryOrAnywhere }
    }
    component Note: Text { Layout.fillWidth: true; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // categories; only their icons when the page is narrow
        Flickable {
            Layout.fillWidth: false
            Layout.preferredWidth: page.narrow ? 60 : 172
            Layout.fillHeight: true
            Layout.margins: 10
            contentHeight: menu.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: menu
                width: parent.width
                spacing: 4
                Text {
                    visible: !page.narrow
                    Layout.leftMargin: 10
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    text: Lang.t("Ayarlar", "Settings")
                    color: Theme.text
                    font.pixelSize: 28
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -0.5
                }
                Repeater {
                    model: page.sections
                    AbstractButton {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool chosen: page.section === modelData.key
                        readonly property color tone: Theme.rainbow[index % Theme.rainbow.length]
                        Layout.fillWidth: true
                        implicitHeight: 42
                        hoverEnabled: true
                        onClicked: page.section = modelData.key
                        Accessible.name: modelData.label
                        background: Rectangle {
                            radius: height / 2
                            color: entry.chosen ? Qt.alpha(entry.tone, 0.2) : entry.hovered ? Theme.raised : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.quick } }
                        }
                        contentItem: Item {
                            Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; name: entry.modelData.icon; size: 18; color: entry.chosen ? entry.tone : Theme.dim }
                            Text { x: 40; anchors.verticalCenter: parent.verticalCenter; visible: !page.narrow; text: entry.modelData.label; color: entry.chosen ? Theme.text : Theme.dim; font.pixelSize: 13; font.weight: entry.chosen ? Font.Bold : Font.Normal }
                        }
                        Hint { text: entry.modelData.label; shown: page.narrow && entry.hovered; x: entry.width + 8 }
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
                width: Math.min(parent.width - 40, 760)
                x: (parent.width - width) / 2
                y: 28
                spacing: 16

                Text { text: page.current.label; color: Theme.text; font.pixelSize: 36; font.weight: Font.ExtraBold; font.letterSpacing: -1; Layout.bottomMargin: 4 }

                // ---- appearance ----
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("tema", "theme")
                    ThemePicker { Layout.fillWidth: true }
                }
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("cam", "glass")
                    tone: Theme.green
                    Toggle {
                        label: Lang.t("Cam görünüm", "Glass look")
                        note: Lang.t("Pencereler saydamlaşır; arkadaki bulanıklığı masaüstün sağlar", "See-through windows; your desktop does the blurring")
                        on: Theme.glass
                        onClicked: Theme.glass = !Theme.glass
                    }
                    Segments {
                        visible: Theme.glass
                        options: [{ key: 0.55, label: Lang.t("Çok saydam", "Clear") }, { key: 0.72, label: Lang.t("Orta", "Medium") }, { key: 0.88, label: Lang.t("Az saydam", "Misty") }]
                        current: Theme.solidity
                        onChosen: key => Theme.solidity = key
                    }
                }
                Card {
                    visible: page.section === "look"
                    heading: Lang.t("düzen", "layout")
                    tone: Theme.mauve
                    LayoutPicker { horizontal: page.horizontalTabs; onChosen: h => page.layoutChosen(h) }
                    Toggle { label: Lang.t("Animasyonlar", "Animations"); note: Lang.t("Kapalıyken hiçbir şey kaymaz ya da büyümez", "When off, nothing slides or grows"); on: Theme.motion; onClicked: Theme.motion = !Theme.motion }
                    Toggle {
                        visible: !page.horizontalTabs
                        label: Lang.t("Yan paneli daralt", "Narrow side bar")
                        note: Lang.t("Yalnızca simgeler (Ctrl+B)", "Icons only (Ctrl+B)")
                        on: page.compactSidebar
                        onClicked: page.compactChosen(!page.compactSidebar)
                    }
                }

                Card {
                    visible: page.section === "look"
                    heading: Lang.t("başlangıç sayfası", "start page")
                    tone: Theme.pink
                    Segments {
                        options: [{ key: "plain", label: Lang.t("Sade", "Plain") }, { key: "glow", label: Lang.t("Işıltı", "Glow") }, { key: "dots", label: Lang.t("Noktalar", "Dots") }, { key: "image", label: Lang.t("Resim", "Picture") }]
                        current: page.startBackground
                        onChosen: key => {
                            if (key === "image" && page.startPicture === "")
                                pictures.open()
                            else
                                page.startChanged("startBackground", key)
                        }
                    }
                    Line {
                        visible: page.startBackground === "image"
                        label: page.startPicture
                        TextButton { text: Lang.t("Resim seç…", "Choose…"); onClicked: pictures.open() }
                    }
                    Toggle { label: Lang.t("Saat ve tarih", "Clock and date"); on: page.showClock; onClicked: page.startChanged("showClock", !page.showClock) }
                    Toggle { label: Lang.t("Kalkan sayacı", "Shield counter"); on: page.showShield; onClicked: page.startChanged("showShield", !page.showShield) }
                    Toggle { label: Lang.t("Sık gidilenler", "Most visited"); note: Lang.t("Geçmişinden, bu bilgisayarda", "From your history, on this computer"); on: page.showFrequent; onClicked: page.startChanged("showFrequent", !page.showFrequent) }
                    Toggle { label: Lang.t("Not kâğıdı", "Note"); on: page.showNote; onClicked: page.startChanged("showNote", !page.showNote) }
                }

                // ---- general ----
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("dil", "language")
                    Segments {
                        options: [{ key: "auto", label: Lang.t("Sistem", "System") }, { key: "tr", label: "Türkçe" }, { key: "en", label: "English" }]
                        current: Lang.choice
                        onChosen: key => Lang.choice = key
                    }
                }
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("arama motoru", "search engine")
                    tone: Theme.pink
                    Segments {
                        options: Address.engines
                        current: Address.engine
                        onChosen: key => Address.engine = key
                    }
                }
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("indirmeler", "downloads")
                    tone: Theme.peach
                    Line {
                        label: page.folderShown
                        TextButton { text: Lang.t("Klasör seç…", "Choose…"); onClicked: folders.open() }
                        TextButton { text: Lang.t("Varsayılan", "Default"); visible: page.downloadFolder !== ""; onClicked: page.downloadFolderChosen("") }
                    }
                }
                Card {
                    visible: page.section === "general"
                    heading: Lang.t("karşılama", "welcome")
                    tone: Theme.green
                    Line {
                        label: Lang.t("İlk açılıştaki seçimleri yeniden gez", "Go through the first-run choices again")
                        TextButton { text: Lang.t("Aç", "Open"); onClicked: page.welcomeRequested() }
                    }
                }

                // ---- tabs ----
                Card {
                    visible: page.section === "tabs"
                    heading: Lang.t("açılış", "start")
                    Toggle {
                        label: Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start")
                        note: Lang.t("Sekmeler ilk bakıldığında yüklenir", "A tab loads when you first look at it")
                        on: page.restoreSession
                        onClicked: page.restoreSessionChosen(!page.restoreSession)
                    }
                }
                Card {
                    visible: page.section === "tabs"
                    heading: Lang.t("boşta kalan sekmeler", "idle tabs")
                    tone: Theme.mauve
                    Segments {
                        options: [{ key: 0, label: Lang.t("Uyutma", "Never") }, { key: 1, label: Lang.t("Erken", "Early") }, { key: 2, label: Lang.t("Rahat", "Relaxed") }]
                        current: page.sleepMode
                        onChosen: key => page.sleepModeChosen(key)
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
                    heading: Lang.t("kalkan", "shield")
                    tone: Theme.green
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
                    heading: Lang.t("gezinme verileri", "browsing data")
                    tone: Theme.danger
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
                    heading: Lang.t("yer imleri", "bookmarks")
                    tone: Theme.peach
                    Line {
                        label: Lang.t(page.bookmarkCount + " yer imi kayıtlı", page.bookmarkCount + " bookmarks saved")
                        TextButton { text: Lang.t("Yöneticiyi aç", "Open the manager"); strong: true; onClicked: page.bookmarksRequested() }
                    }
                }
                Card {
                    visible: page.section === "bookmarks"
                    heading: Lang.t("başka tarayıcıdan", "from another browser")
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
                                radius: 8
                                color: Theme.raised
                                Text { id: key; anchors.centerIn: parent; text: shortcut.modelData[0]; color: Theme.accent; font.family: Theme.pixel; font.pixelSize: 17 }
                            }
                        }
                    }
                }

                // ---- about ----
                Card {
                    visible: page.section === "about"
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(160, 160); Layout.preferredWidth: 80; Layout.preferredHeight: 80 }
                    Text { text: "Velum " + Qt.application.version; color: Theme.text; font.pixelSize: 24; font.weight: Font.ExtraBold }
                    Note { font.pixelSize: 13; text: Lang.t("Sakin ve gizlilik odaklı bir tarayıcı. Motor: Qt WebEngine (Chromium). Engelleyici: Brave adblock-rust.", "A calm, private browser. Engine: Qt WebEngine (Chromium). Blocker: Brave adblock-rust.") }
                    Note { text: Lang.t("Varsayılan tarayıcı yapmak için: xdg-settings set default-web-browser velum.desktop", "To make it the default browser: xdg-settings set default-web-browser velum.desktop") }
                }
            }
        }
    }
}
