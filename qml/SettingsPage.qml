import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

// The settings, a page of its own in a tab (Ctrl+,): categories on the left, their
// cards on the right, and a search over all of them. Changes take effect at once.
Rectangle {
    id: page
    property int sleepMode
    property bool restoreSession
    property string downloadFolder          // "" means the system's downloads folder
    property bool horizontalTabs
    property bool compactSidebar
    property var neverSites: []
    property int bookmarkCount
    property string section: "general"
    property string query: ""
    signal sleepModeChosen(int mode)
    property string powerMode: "balanced"
    property int memoryLimit
    property int memoryUsed
    signal powerModeChosen(string mode)
    signal memoryLimitChosen(int mb)
    signal resourcesRequested()
    signal openPage(string address)
    signal restoreSessionChosen(bool on)
    signal downloadFolderChosen(string folder)
    signal layoutChosen(bool horizontal)
    signal compactChosen(bool on)
    signal clearRequested()
    signal askAgain(string origin)
    signal bookmarksRequested()
    signal importRequested()
    signal welcomeRequested()
    property var extensions: []
    property bool fetchingExtension
    signal addFromStore(string typed)
    signal addFromFile(string path)
    signal openStore()
    signal openExtensionPage(url address)
    signal enableExtension(var extension, bool on)
    signal removeExtension(var extension)
    property string startBackground
    property string startPicture
    property bool showClock
    property bool showShield
    property bool showNote
    property bool showFrequent
    property bool showBookmarkBar
    signal startChanged(string name, var value)      // a property of the window and its new value
    signal designRequested()
    signal resetLook()
    signal openStudio()
    signal exportTheme(url file)
    signal importTheme(url file)

    readonly property string folderShown: downloadFolder !== "" ? downloadFolder
        : Files.toPath(StandardPaths.writableLocation(StandardPaths.DownloadLocation))
    readonly property bool narrow: width < 700

    readonly property var sections: [
        { key: "general", icon: "settings", label: Lang.t("Genel", "General") },
        { key: "home", icon: "home", label: Lang.t("Ana sayfa", "Home page") },
        { key: "search", icon: "search", label: Lang.t("Arama", "Search") },
        { key: "look", icon: "palette", label: Lang.t("Görünüm", "Appearance") },
        { key: "privacy", icon: "shield", label: Lang.t("Gizlilik ve güvenlik", "Privacy and security") },
        { key: "passwords", icon: "key", label: Lang.t("Parolalar", "Passwords") },
        { key: "tabs", icon: "panel", label: Lang.t("Sekmeler", "Tabs") },
        { key: "speed", icon: "gauge", label: Lang.t("Performans", "Performance") },
        { key: "downloads", icon: "download", label: Lang.t("İndirilenler", "Downloads") },
        { key: "extensions", icon: "puzzle", label: Lang.t("Eklentiler", "Extensions"), divided: true },
        { key: "bookmarks", icon: "star", label: Lang.t("Yer imleri", "Bookmarks") },
        { key: "keys", icon: "command", label: Lang.t("Kısayollar", "Shortcuts") },
        { key: "about", icon: "alert", label: Lang.t("Velum hakkında", "About Velum") }
    ]
    readonly property var current: sections.find(s => s.key === section) ?? sections[0]

    // is a card of category `key` on screen? While searching, its words decide.
    function shows(key, words) {
        const q = query.trim().toLocaleLowerCase()
        return q === "" ? section === key : String(words).toLocaleLowerCase().indexOf(q) >= 0
    }
    readonly property bool nothingFound: query.trim() !== "" && ![general1, general2, general3, general4, home1, search1, look1, look2, privacy1, privacy2, passwords1, tabs1, speed1, speed2, look3, look4, look5, look6, look7, downloads1, extensions1, marks1, marks2, keys1, about1].some(c => c.wanted)

    color: Theme.sheetBack

    function refresh() {
        if (visible && passwords1.wanted)
            passwordList.refresh()
        if (visible)
            DefaultBrowser.refresh()
    }
    onSectionChanged: { search.text = ""; query = ""; scroll.contentY = 0; arrive.restart(); refresh() }
    onVisibleChanged: refresh()

    FolderDialog {
        id: folders
        title: Lang.t("İndirme klasörünü seç", "Choose the downloads folder")
        onAccepted: page.downloadFolderChosen(Files.toPath(selectedFolder))
    }
    FileDialog {
        id: pictures
        title: Lang.t("Arka plan resmini seç", "Choose the background picture")
        nameFilters: [Lang.t("Resimler", "Pictures") + " (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            page.startChanged("startPicture", Files.toPath(selectedFile))
            page.startChanged("startBackground", "image")
        }
    }

    FileDialog {
        id: themeOut
        title: Lang.t("Temayı kaydet", "Save the theme")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "velumtheme"
        nameFilters: [Lang.t("Velum teması", "Velum theme") + " (*.velumtheme)"]
        onAccepted: page.exportTheme(selectedFile)
    }
    FileDialog {
        id: themeIn
        title: Lang.t("Tema yükle", "Load a theme")
        nameFilters: [Lang.t("Velum teması", "Velum theme") + " (*.velumtheme)"]
        onAccepted: page.importTheme(selectedFile)
    }

    // a setting: its name on the left, what changes it on the right
    component Line: RowLayout {
        property alias label: name.text
        Layout.fillWidth: true
        Layout.minimumHeight: 40
        spacing: 12
        Text { id: name; Layout.fillWidth: true; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 17 : 14; wrapMode: Text.WrapAtWordBoundaryOrAnywhere }
    }
    component Note: Text { Layout.fillWidth: true; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 13; wrapMode: Text.WordWrap }
    component Group: Card {
        property bool wanted
        visible: wanted
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Flickable {
            Layout.fillWidth: false
            Layout.preferredWidth: page.narrow ? 170 : 290
            Layout.fillHeight: true
            Layout.leftMargin: page.narrow ? 8 : 28
            Layout.topMargin: 22
            contentHeight: menu.implicitHeight + 24
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: menu
                width: parent.width - 10
                spacing: 3
                Row {
                    Layout.leftMargin: 10
                    Layout.bottomMargin: 16
                    spacing: 10
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(64, 64); width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Lang.t("Ayarlar", "Settings"); color: Theme.text; font.family: Theme.ui; font.pixelSize: 24; font.variableAxes: Theme.axes(800); anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater {
                    model: page.sections
                    ColumnLayout {
                        id: item
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 0
                        Rectangle { visible: item.modelData.divided === true; Layout.fillWidth: true; Layout.margins: 10; implicitHeight: 1; color: Theme.line }
                        AbstractButton {
                            id: entry
                            readonly property bool chosen: page.query === "" && page.section === item.modelData.key
                            readonly property color ink: chosen ? Theme.accentInk : Theme.text
                            Layout.fillWidth: true
                            implicitHeight: 44
                            hoverEnabled: true
                            onClicked: { search.text = ""; page.query = ""; page.section = item.modelData.key }
                            Accessible.name: item.modelData.label
                            background: Rectangle { radius: Theme.round(height / 2); color: entry.chosen ? Theme.accent : entry.hovered ? (Theme.web ? Theme.title : Theme.raised) : "transparent"; Behavior on color { ColorAnimation { duration: Theme.quick } } }
                            contentItem: Item {
                                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: item.modelData.icon; size: 17; color: entry.ink }
                                Text { anchors { left: parent.left; leftMargin: 44; right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter } text: item.modelData.label; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; color: entry.ink; font.family: Theme.ui; font.pixelSize: Theme.web ? 17 : 14; font.variableAxes: Theme.axes(entry.chosen ? 700 : 450) }
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: content.implicitHeight + 80
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
                x: Math.max(18, Math.min((parent.width - width) / 2, 48))
                y: 22
                spacing: 16

                TextField {
                    id: search
                    Layout.fillWidth: true
                    implicitHeight: 42
                    leftPadding: 44
                    placeholderText: Lang.t("Ayarlarda ara", "Search settings")
                    placeholderTextColor: Theme.dim
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentInk
                    font.family: Theme.ui
                    font.pixelSize: Theme.web ? 18 : 14
                    selectByMouse: true
                    onTextEdited: page.query = text
                    Keys.onEscapePressed: { text = ""; page.query = "" }
                    background: Rectangle {
                        radius: Theme.round(height / 2)
                        color: "transparent"
                        border.width: search.activeFocus ? 2 : 1
                        border.color: search.activeFocus ? Theme.accent : Theme.line
                        Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 16; color: Theme.dim }
                    }
                }
                Row {
                    Layout.topMargin: 6
                    spacing: 10
                    Icon { name: page.query === "" ? page.current.icon : "search"; size: 22; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: page.query === "" ? page.current.label : Lang.t("Arama sonuçları", "Search results"); color: Theme.text; font.family: Theme.ui; font.pixelSize: 24; font.variableAxes: Theme.axes(800) }
                }
                Note { visible: page.nothingFound; text: Lang.t("Bununla eşleşen bir ayar yok.", "No setting matches that.") }

                // ---- general ----
                Group {
                    id: general1
                    wanted: page.shows("general", "varsayılan tarayıcı default browser")
                    heading: Lang.t("Varsayılan tarayıcı", "Default browser")
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 84
                        radius: Theme.round(12)
                        color: Theme.raised
                        RowLayout {
                            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                            spacing: 16
                            Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(112, 112); Layout.preferredWidth: 52; Layout.preferredHeight: 52 }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 17 : 14
                                text: DefaultBrowser.current ? Lang.t("Velum varsayılan tarayıcın.", "Velum is your default browser.") : Lang.t("Velum varsayılan tarayıcın değil.", "Velum is not your default browser.") }
                            TextButton { visible: !DefaultBrowser.current; strong: true; implicitHeight: 36; text: Lang.t("Varsayılan yap", "Make default"); onClicked: DefaultBrowser.make() }
                        }
                    }
                }
                Group {
                    id: general2
                    wanted: page.shows("general", "dil language türkçe english")
                    heading: Lang.t("Dil", "Language")
                    symbol: "globe"
                    Line {
                        label: Lang.t("Velum'un dili", "Velum's language")
                        Dropdown {
                            options: [{ key: "auto", label: Lang.t("Sistem", "System") }, { key: "tr", label: "Türkçe" }, { key: "en", label: "English" }]
                            current: Lang.choice
                            onChosen: key => Lang.choice = key
                        }
                    }
                }
                Group {
                    id: general3
                    wanted: page.shows("general", "içe aktar import firefox chrome yer imi geçmiş")
                    heading: Lang.t("Tarayıcı verilerini içe aktar", "Import browser data")
                    symbol: "download"
                    note: Lang.t("Firefox ve Chromium ailesinden yer imleri ve geçmiş. Dosyaları yalnızca okunur.", "Bookmarks and history from Firefox and Chromium relatives. Their files are only read.")
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Verileri içe aktar…", "Import data…"); onClicked: page.importRequested() }
                }
                Group {
                    id: general4
                    wanted: page.shows("general", "karşılama welcome ilk açılış tema")
                    heading: Lang.t("Karşılama", "Welcome")
                    symbol: "star"
                    Line {
                        label: Lang.t("İlk açılıştaki seçimleri yeniden gez", "Go through the first-run choices again")
                        TextButton { text: Lang.t("Aç", "Open"); onClicked: page.welcomeRequested() }
                    }
                }

                // ---- home page ----
                Group {
                    id: home1
                    wanted: page.shows("home", "ana sayfa home saat kalkan not sık gidilen arka plan background")
                    heading: Lang.t("Ana sayfada neler olsun", "What the home page shows")
                    symbol: "home"
                    TextButton { visible: !Theme.web; Layout.fillWidth: true; implicitHeight: 40; strong: true; text: Lang.t("Ana sayfayı tasarla: widget, yazı, CSS…", "Design the home page: widgets, words, CSS…"); onClicked: page.designRequested() }
                    Toggle { label: Lang.t("Büyük saat", "Big clock"); on: page.showClock; onClicked: page.startChanged("showClock", !page.showClock) }
                    Toggle { label: Lang.t("Kalkan sayacı", "Shield counter"); on: page.showShield; onClicked: page.startChanged("showShield", !page.showShield) }
                    Toggle { label: Lang.t("Not defteri", "Note"); on: page.showNote; onClicked: page.startChanged("showNote", !page.showNote) }
                    Toggle { label: Lang.t("Sık gidilenler", "Most visited"); note: Lang.t("Geçmişinden, bu bilgisayarda", "From your history, on this computer"); on: page.showFrequent; onClicked: page.startChanged("showFrequent", !page.showFrequent) }
                    Line {
                        visible: !Theme.web
                        label: Lang.t("Arka plan", "Background")
                        Dropdown {
                            options: [{ key: "plain", label: Lang.t("Sade", "Plain") }, { key: "glow", label: Lang.t("Işıltı", "Glow") }, { key: "dots", label: Lang.t("Noktalar", "Dots") }, { key: "image", label: Lang.t("Resim", "Picture") }]
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
                }

                // ---- search ----
                Group {
                    id: search1
                    wanted: page.shows("search", "arama motoru search engine duckduckgo google brave startpage")
                    heading: Lang.t("Varsayılan arama motoru", "Default search engine")
                    symbol: "search"
                    note: Lang.t("Adres çubuğuna yazdıkların bu motora gider.", "What you type in the address bar goes to this one.")
                    Line {
                        label: Lang.t("Arama motoru", "Search engine")
                        Dropdown {
                            options: Address.engines
                            current: Address.engine
                            onChosen: key => Address.engine = key
                        }
                    }
                }

                // ---- appearance ----
                Group {
                    id: look1
                    wanted: page.shows("look", "tema renk theme colour accent vurgu koyu açık dark light")
                    heading: Lang.t("Tema", "Theme")
                    symbol: "palette"
                    ThemePicker { visible: !Theme.web; Layout.fillWidth: true }
                    Note { visible: Theme.web; text: "velum:webcore" }
                }
                Group {
                    id: look2
                    wanted: page.shows("look", "sekme düzen yatay dikey tabs cam glass animasyon yer imi çubuğu")
                    heading: Lang.t("Pencere", "Window")
                    symbol: "panel"
                    Line {
                        label: Lang.t("Sekmeler", "Tabs")
                        Segments {
                            options: [{ key: false, label: Lang.t("Yanda", "Side") }, { key: true, label: Lang.t("Üstte", "Top") }]
                            current: page.horizontalTabs
                            onChosen: key => page.layoutChosen(key)
                        }
                    }
                    Toggle { visible: !page.horizontalTabs; label: Lang.t("Yan paneli daralt", "Narrow side bar"); note: Lang.t("Yalnızca simgeler", "Icons only") + Keymap.hint("sidebar"); on: page.compactSidebar; onClicked: page.compactChosen(!page.compactSidebar) }
                    Toggle { visible: page.horizontalTabs && !Theme.web; label: Lang.t("Yer imi çubuğu", "Bookmarks bar"); on: page.showBookmarkBar; onClicked: page.startChanged("showBookmarkBar", !page.showBookmarkBar) }
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

                Group {
                    id: look7
                    wanted: !Theme.web && page.shows("look", "sıfırla varsayılan bozuldu eski reset default")
                    heading: Lang.t("Bir şeyler ters mi gitti?", "Did something go wrong?")
                    symbol: "reload"
                    Note { text: Lang.t("Renkleri, şekli, yazı tiplerini ve tarayıcı CSS'ini ilk hâline döndürür. Kendi temanın renkleri silinmez, istersen geri seçebilirsin.", "Puts colours, shape, lettering and the browser style sheet back as they were. Your theme's colours are kept; you can pick it again.") + (Keymap.text("resetLook") !== "" ? "\n" + Lang.t("Hiçbir şey görünmüyorsa: ", "If nothing can be seen: ") + Keymap.text("resetLook") : "") }
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Görünümü sıfırla", "Reset the look"); onClicked: page.resetLook() }
                }
                Group {
                    id: look3
                    wanted: !Theme.web && page.shows("look", "kendi temam renk editör stüdyo custom theme studio colours özel")
                    heading: Lang.t("Tema Stüdyosu", "Theme Studio")
                    symbol: "palette"
                    StudioCard { Layout.fillWidth: true; onOpenStudio: page.openStudio() }
                }
                Group {
                    id: look4
                    wanted: !Theme.web && page.shows("look", "şekil köşe yoğunluk sekme biçimi yazı tipi font araç çubuğu düğme toolbar corners density")
                    heading: Lang.t("Şekil ve yerleşim", "Shape and layout")
                    symbol: "panel"
                    ShapeEditor { Layout.fillWidth: true; horizontalTabs: page.horizontalTabs }
                }
                Group {
                    id: look5
                    wanted: !Theme.web && page.shows("look", "css stil style sheet özelleştir")
                    heading: Lang.t("Tarayıcı CSS'i", "Browser style sheet")
                    symbol: "command"
                    CssEditor { Layout.fillWidth: true }
                }
                Group {
                    id: look6
                    wanted: !Theme.web && page.shows("look", "paylaş kaydet yükle dosya share export import tema")
                    heading: Lang.t("Görünümünü paylaş", "Share your look")
                    symbol: "download"
                    Note { text: Lang.t("Renkler, şekil, CSS ve ana sayfa tasarımın tek dosyada. Yer imlerin, görevlerin, notun ve geçmişin dosyaya girmez.", "Colours, shape, style sheets and the home page design in one file. Bookmarks, tasks, your note and history stay out of it.") }
                    RowLayout {
                        Layout.fillWidth: true
                        TextButton { Layout.fillWidth: true; implicitHeight: 40; strong: true; text: Lang.t("Dosyaya kaydet…", "Save to a file…"); onClicked: themeOut.open() }
                        TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Dosyadan yükle…", "Load from a file…"); onClicked: themeIn.open() }
                    }
                }

                // ---- privacy ----
                Group {
                    id: privacy1
                    wanted: page.shows("privacy", "kalkan reklam izleyici çerez https shield ads trackers cookies filtre")
                    heading: Lang.t("Kalkan", "Shield")
                    symbol: "shield"
                    Toggle { label: Lang.t("Reklam ve izleyici engelleme", "Block ads and trackers"); note: Lang.t("Filtre listeleriyle", "With filter lists"); on: Shield.enabled; onClicked: Shield.enabled = !Shield.enabled }
                    Toggle { label: Lang.t("Üçüncü taraf çerezleri engelle", "Block third party cookies"); note: Lang.t("Siteler arası takibi zorlaştırır", "Makes following you between sites harder"); on: Shield.blockThirdPartyCookies; onClicked: Shield.blockThirdPartyCookies = !Shield.blockThirdPartyCookies }
                    Toggle { label: Lang.t("Önce HTTPS", "HTTPS first"); note: Lang.t("http adreslerini şifreli aç", "Open http addresses encrypted"); on: Shield.httpsFirst; onClicked: Shield.httpsFirst = !Shield.httpsFirst }
                    Line {
                        label: Shield.statusText(Lang.turkish, Shield.revision, Shield.statusCode)
                        TextButton { text: Lang.t("Listeleri güncelle", "Update lists"); onClicked: Shield.updateLists() }
                    }
                }
                Group {
                    id: privacy2
                    wanted: page.shows("privacy", "gezinme verileri geçmiş çerez sil unut delete history data")
                    heading: Lang.t("Gezinme verileri", "Browsing data")
                    symbol: "history"
                    Toggle { label: Lang.t("Çıkışta unut", "Forget on exit"); note: Lang.t("Geçmiş, çerezler ve sekmeler; sonraki açılıştan itibaren", "History, cookies and tabs; from the next start"); on: Shield.forgetOnExit; onClicked: Shield.forgetOnExit = !Shield.forgetOnExit }
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Gezinme verilerini sil…", "Delete browsing data…"); onClicked: page.clearRequested() }
                }

                // ---- passwords ----
                Group {
                    id: passwords1
                    wanted: page.shows("passwords", "parola şifre anahtarlık password keyring")
                    heading: Lang.t("Kayıtlı parolalar", "Saved passwords")
                    symbol: "key"
                    PasswordList {
                        id: passwordList
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(260, page.height - 300)
                        neverSites: page.neverSites
                        onAllow: origin => page.askAgain(origin)
                    }
                    onVisibleChanged: if (visible) page.refresh()
                }

                // ---- performance ----
                Group {
                    id: speed1
                    wanted: page.shows("speed", "performans oyun tasarruf pil ısı ram bellek mod performance game saver battery memory")
                    heading: Lang.t("Hız ve bellek", "Speed and memory")
                    symbol: "gauge"
                    Line {
                        label: Lang.t("Mod", "Mode")
                        Segments {
                            options: [{ key: "balanced", label: Lang.t("Dengeli", "Balanced") }, { key: "game", label: Lang.t("Oyun", "Game") }, { key: "saver", label: Lang.t("Tasarruf", "Saver") }]
                            current: page.powerMode
                            onChosen: key => page.powerModeChosen(key)
                        }
                    }
                    Note {
                        text: page.powerMode === "game" ? Lang.t("Baktığın dışındaki sekmeler birkaç saniyede donar, 5 dakikada bellekten çıkar; animasyon ve cam kapalı. Ses çalan ve sabit sekmeler çalışmaya devam eder.", "Tabs you are not looking at freeze within seconds and leave memory after 5 minutes; no animations or glass. Tabs playing sound and pinned tabs carry on.")
                            : page.powerMode === "saver" ? Lang.t("Arka sekmeler 30 saniyede donar, 3 dakikada uyur; animasyon ve cam kapalı, videolar kendiliğinden başlamaz.", "Background tabs freeze after 30 seconds and sleep after 3 minutes; no animations or glass, videos do not start by themselves.")
                            : Lang.t("Uyutma süreleri Sekmeler bölümündeki gibi; görünüm senin ayarında.", "Tabs sleep as set under Tabs; the look is as you set it.")
                    }
                    Line {
                        label: Lang.t("Bellek sınırı", "Memory limit")
                        Dropdown {
                            options: [{ key: 0, label: Lang.t("Sınır yok", "No limit") }, { key: 1024, label: "1 GB" }, { key: 2048, label: "2 GB" }, { key: 3072, label: "3 GB" }, { key: 4096, label: "4 GB" }, { key: 6144, label: "6 GB" }]
                            current: page.memoryLimit
                            onChosen: key => page.memoryLimitChosen(key)
                        }
                    }
                    Note {
                        visible: page.memoryLimit > 0
                        text: Lang.t("Aşılınca en uzun süredir bakmadığın sekmeler uyutulur; baktığın, ses çalan ve sabit sekmelere dokunulmaz. Bu yüzden sınır bazen aşılabilir.", "Above it, the tabs unseen the longest are put to sleep; shown, sounding and pinned tabs are left alone, so it can be exceeded.")
                              + (page.memoryUsed > 0 ? "\n" + Lang.t("Şu an: ", "Now: ") + page.memoryUsed + " MB" : "")
                    }
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Hangi sekme ne kadar kullanıyor?", "What does each tab use?"); onClicked: page.resourcesRequested() }
                }
                Group {
                    id: speed2
                    wanted: page.shows("speed", "ekran kartı hızlandırma gpu video donanım graphics acceleration hardware")
                    heading: Lang.t("Ekran kartı", "Graphics card")
                    symbol: "gauge"
                    Toggle { label: Lang.t("Ekran kartını kullan", "Use graphics acceleration"); note: Lang.t("Kaydırma ve video daha akıcı olur", "Smoother scrolling and video"); on: Gpu.on; onClicked: Gpu.on = !Gpu.on }
                    Note { text: Lang.t("Sayfalar bozuk ya da siyah görünürse kapat.", "Switch it off if pages look broken or black.") }
                    Note { visible: Gpu.careful; color: Theme.danger; text: Lang.t("Son açılış yarıda kaldığı için bazı hızlandırmalar kapalı. Anahtarı kapatıp açarsan yeniden denenir.", "The last start did not finish, so some acceleration is off. Switch it off and on to try again.") }
                    Note { visible: Gpu.changed; text: Lang.t("Değişiklik Velum'u kapatıp açınca geçerli olur.", "The change applies after restarting Velum.") }
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("Ekran kartı durumunu göster", "Show graphics status"); onClicked: page.openPage("chrome://gpu") }
                }

                // ---- tabs ----
                Group {
                    id: tabs1
                    wanted: page.shows("tabs", "sekme açılış uyut bellek tabs sleep restore")
                    heading: Lang.t("Sekmeler", "Tabs")
                    symbol: "panel"
                    Toggle { label: Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start"); note: Lang.t("Sekmeler ilk bakıldığında yüklenir", "A tab loads when you first look at it"); on: page.restoreSession; onClicked: page.restoreSessionChosen(!page.restoreSession) }
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

                // ---- downloads ----
                Group {
                    id: downloads1
                    wanted: page.shows("downloads", "indirme klasör download folder")
                    heading: Lang.t("İndirme klasörü", "Downloads folder")
                    symbol: "folder"
                    note: Lang.t("Velum indirilen bir dosyayı hiçbir zaman kendiliğinden açmaz.", "Velum never opens a downloaded file by itself.")
                    Line {
                        label: page.folderShown
                        TextButton { text: Lang.t("Klasör seç…", "Choose…"); onClicked: folders.open() }
                        TextButton { text: Lang.t("Varsayılan", "Default"); visible: page.downloadFolder !== ""; onClicked: page.downloadFolderChosen("") }
                    }
                }

                // ---- extensions ----
                Group {
                    id: extensions1
                    wanted: page.shows("extensions", "eklenti uzantı chrome web store extension")
                    color: "transparent"
                    implicitHeight: extensionList.implicitHeight
                    ExtensionList {
                        id: extensionList
                        Layout.fillWidth: true
                        Layout.margins: Theme.web ? 0 : -20
                        extensions: page.extensions
                        busy: page.fetchingExtension
                        onAddFromStore: typed => page.addFromStore(typed)
                        onAddFromFile: path => page.addFromFile(path)
                        onOpenStore: page.openStore()
                        onOpenPage: address => page.openExtensionPage(address)
                        onEnable: (extension, on) => page.enableExtension(extension, on)
                        onRemove: extension => page.removeExtension(extension)
                    }
                }

                // ---- bookmarks ----
                Group {
                    id: marks1
                    wanted: page.shows("bookmarks", "yer imi klasör bookmarks")
                    heading: Lang.t("Yer imleri", "Bookmarks")
                    symbol: "star"
                    Line {
                        label: Lang.t(page.bookmarkCount + " yer imi kayıtlı", page.bookmarkCount + " bookmarks saved")
                        TextButton { text: Lang.t("Yöneticiyi aç", "Open the manager"); strong: true; onClicked: page.bookmarksRequested() }
                    }
                }
                Group {
                    id: marks2
                    wanted: page.shows("bookmarks", "içe aktar import yer imi")
                    heading: Lang.t("Başka tarayıcıdan", "From another browser")
                    symbol: "download"
                    TextButton { Layout.fillWidth: true; implicitHeight: 40; text: Lang.t("İçe aktar…", "Import…"); onClicked: page.importRequested() }
                }

                // ---- shortcuts ----
                Group {
                    id: keys1
                    wanted: page.shows("keys", "kısayol klavye shortcut keyboard ctrl")
                    heading: Lang.t("Klavye kısayolları", "Keyboard shortcuts")
                    symbol: "command"
                    KeyList { Layout.fillWidth: true }
                }

                // ---- about ----
                Group {
                    id: about1
                    wanted: page.shows("about", "hakkında sürüm about version velum")
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(160, 160); Layout.preferredWidth: 80; Layout.preferredHeight: 80 }
                    Text { text: "Velum " + Qt.application.version; color: Theme.text; font.family: Theme.ui; font.pixelSize: 28; font.variableAxes: Theme.axes(800) }
                    Line {
                        visible: Updater.status !== "off"
                        label: Updater.status === "checking" ? Lang.t("Güncelleme aranıyor…", "Looking for an update…")
                             : Updater.status === "downloading" ? Lang.t("Yeni sürüm iniyor: " + Updater.version, "Downloading version " + Updater.version)
                             : Updater.status === "ready" ? Lang.t("Velum " + Updater.version + " hazır; kapatınca kurulacak.", "Velum " + Updater.version + " is ready; it installs when you quit.")
                             : Updater.status === "current" ? Lang.t("Velum güncel.", "Velum is up to date.")
                             : Updater.status === "failed" ? Lang.t("Güncelleme denetlenemedi.", "Could not check for updates.")
                             : Lang.t("Güncellemeler kendiliğinden denetlenir.", "Updates are checked automatically.")
                        TextButton { text: Lang.t("Şimdi denetle", "Check now"); visible: Updater.status !== "ready"; onClicked: Updater.check() }
                    }
                    Note { text: Lang.t("Sakin ve gizlilik odaklı bir tarayıcı. Motor: Qt WebEngine (Chromium). Engelleyici: Brave adblock-rust.", "A calm, private browser. Engine: Qt WebEngine (Chromium). Blocker: Brave adblock-rust.") }
                }
            }
        }
    }
}
