import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The theme studio: the controls on the left, a living preview on the right. Nothing
// changes in the browser until "apply", so nothing here can be spoilt. The studio has
// colours of its own and stays readable whatever you make.
Popup {
    id: studio
    parent: Overlay.overlay
    x: 0; y: 0
    width: parent?.width ?? 1000
    height: parent?.height ?? 700
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape

    signal applied()

    // ---- the look being made ----
    property var colors: []
    property real roundness: 1
    property string tabShape: "rounded"
    property string density: "normal"
    property string fontFamily: ""
    property string headFamily: ""
    property var past: []            // earlier states, newest last
    property var start: null         // as it was when the studio opened
    property int picking: -1         // the colour whose picker is open
    property bool fine: false        // the other colours are shown
    property int tab: 0
    property double lastStep: 0

    property alias calc: math
    ColorMath { id: math }

    function state() { return { colors: colors.slice(), roundness: roundness, tabShape: tabShape, density: density, fontFamily: fontFamily, headFamily: headFamily } }
    function restore(s) {
        colors = s.colors.slice(); roundness = s.roundness; tabShape = s.tabShape; density = s.density; fontFamily = s.fontFamily; headFamily = s.headFamily
    }
    // remembers the state before a change; a slider being dragged counts once
    function remember() {
        const now = Date.now()
        if (now - lastStep > 700)
            past = past.concat([state()]).slice(-50)
        lastStep = now
    }
    function undo() {
        if (past.length === 0)
            return
        restore(past[past.length - 1])
        past = past.slice(0, -1)
        lastStep = 0
    }
    function startOver() {
        lastStep = 0
        remember()
        restore(start)
    }
    function begin() {
        const list = []
        for (let i = 0; i < 15; i++)
            list.push(String(i === 8 ? Theme.accent : Theme.pick(i)))
        colors = list
        roundness = Theme.roundness; tabShape = Theme.tabShape; density = Theme.density; fontFamily = Theme.fontFamily; headFamily = Theme.headFamily
        past = []; picking = -1; tab = 0; lastStep = 0
        start = state()
        open()
    }
    function useBase(key) {
        lastStep = 0
        remember()
        const list = []
        for (let i = 0; i < 15; i++)
            list.push(String(Theme.colorOf(key, i)))
        colors = list
    }
    // a main colour carries the others with it; a fine one changes alone
    function setColor(i, value) {
        remember()
        let list = colors.slice()
        list[i] = value
        if ([1, 2, 6, 8].includes(i) && !fine)
            list = math.derive(list[2], list[1], list[6], list[8])
        colors = list
    }
    function setShape(name, value) {
        lastStep = 0
        remember()
        studio[name] = value
    }

    // writing that is hard to read, said plainly
    readonly property real readable: colors.length === 15 ? Math.min(math.contrast(colors[6], colors[2]), math.contrast(colors[6], colors[1]), math.contrast(colors[6], colors[3])) : 21
    readonly property real onAccent: colors.length === 15 ? math.contrast(colors[9], colors[8]) : 21
    readonly property bool hard: readable < 4 || onAccent < 3
    function repair() {
        lastStep = 0
        remember()
        const list = colors.slice()
        if (readable < 4) {
            list[6] = math.inkOn(list[2])
            list[7] = math.mix(list[6], list[2], 0.3)
            // bars and buttons that still swallow the writing move towards the page
            for (const i of [1, 3])
                if (math.contrast(list[6], list[i]) < 4)
                    list[i] = math.mix(list[2], list[6], i === 1 ? 0.04 : 0.1)
        }
        list[9] = math.inkOn(list[8])
        colors = list
    }
    function apply() {
        const look = state()
        Theme.change(() => {
            Theme.keepPrevious()
            Theme.keepColors(look.colors)
            Theme.accentChoice = ""
            Theme.palette = "custom"
            Theme.roundness = look.roundness; Theme.tabShape = look.tabShape; Theme.density = look.density
            Theme.fontFamily = look.fontFamily; Theme.headFamily = look.headFamily
        })
        close()
        applied()
    }

    // ---- its own colours ----
    readonly property color back: "#0f1115"
    readonly property color panel: "#171a20"
    readonly property color field: "#222630"
    readonly property color ink: "#eef0f4"
    readonly property color quiet: "#9aa0ad"
    readonly property color blue: "#8ab4ff"

    component Words: Text { color: studio.ink; font.family: Theme.sansFont.name; font.pixelSize: 13; textFormat: Text.PlainText }
    component Press: AbstractButton {
        id: press
        property bool strong: false
        implicitHeight: 38
        implicitWidth: caption.implicitWidth + 32
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        opacity: enabled ? 1 : 0.35
        scale: down ? 0.97 : 1
        background: Rectangle { radius: 12; color: press.strong ? (press.hovered ? Qt.lighter(studio.blue, 1.1) : studio.blue) : press.hovered ? "#2d3340" : studio.field }
        contentItem: Words { id: caption; text: press.text; color: press.strong ? "#0b1220" : studio.ink; font.variableAxes: ({ "wght": 650 }); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    component Head: Words { font.pixelSize: 11; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2; color: studio.quiet; Layout.topMargin: 6 }
    component Choice: RowLayout {
        id: choice
        property var options: []
        property var current
        signal chosen(var key)
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: choice.options
            Press { required property var modelData; Layout.fillWidth: true; implicitWidth: 40; text: modelData.label; strong: choice.current === modelData.key; onClicked: choice.chosen(modelData.key) }
        }
    }
    // one colour: its dot, its name, where it is used; opens the picker under it
    component Colour: ColumnLayout {
        id: colour
        property int role
        property string name
        property string use
        Layout.fillWidth: true
        spacing: 0
        AbstractButton {
            id: line
            Layout.fillWidth: true
            implicitHeight: 54
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onClicked: studio.picking = studio.picking === colour.role ? -1 : colour.role
            Accessible.name: colour.name
            background: Rectangle { radius: 14; color: studio.picking === colour.role ? studio.field : line.hovered ? "#1e222b" : "transparent" }
            contentItem: Item {
                Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 36; height: 36; radius: 18; color: studio.colors[colour.role] ?? "black"; border.width: 2; border.color: "#3a404c" }
                Column {
                    anchors { left: parent.left; leftMargin: 58; right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Words { width: parent.width; text: colour.name; font.pixelSize: 14; font.variableAxes: ({ "wght": 650 }); elide: Text.ElideRight }
                    Words { width: parent.width; text: colour.use; color: studio.quiet; font.pixelSize: 11; elide: Text.ElideRight }
                }
                Words { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } text: studio.picking === colour.role ? "▴" : "▾"; color: studio.quiet }
            }
        }
        Loader {
            Layout.fillWidth: true
            Layout.margins: active ? 10 : 0
            active: studio.picking === colour.role
            visible: active
            sourceComponent: Component {
                StudioPicker { calc: math; value: studio.colors[colour.role] ?? "#000000"; onPicked: v => studio.setColor(colour.role, v) }
            }
        }
    }

    background: Rectangle { color: studio.back }
    contentItem: RowLayout {
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(430, studio.width * 0.46)
            color: studio.panel

            ColumnLayout {
                anchors { fill: parent; margins: 18 }
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Column {
                        Layout.fillWidth: true
                        Words { text: Lang.t("Tema Stüdyosu", "Theme Studio"); font.pixelSize: 22; font.variableAxes: ({ "wght": 800 }) }
                        Words { text: Lang.t("Uygula diyene kadar hiçbir şey değişmez.", "Nothing changes until you apply."); color: studio.quiet; font.pixelSize: 12 }
                    }
                    Press { text: "✕"; implicitWidth: 38; onClicked: studio.close(); Accessible.name: Lang.t("Vazgeç", "Cancel") }
                }
                Choice { options: [{ key: 0, label: Lang.t("Renkler", "Colours") }, { key: 1, label: Lang.t("Şekil", "Shape") }, { key: 2, label: Lang.t("Yazı", "Lettering") }]; current: studio.tab; onChosen: key => studio.tab = key }

                Flickable {
                    id: scroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: body.implicitHeight + 8
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}

                    ColumnLayout {
                        id: body
                        width: scroll.width - 10
                        spacing: 6

                        // ---- colours ----
                        ColumnLayout {
                            visible: studio.tab === 0
                            Layout.fillWidth: true
                            spacing: 6
                            Head { text: Lang.t("Bir yerden başla", "Start from") }
                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                Repeater {
                                    model: Theme.builtIn
                                    AbstractButton {
                                        id: base
                                        required property var modelData
                                        width: 44; height: 44
                                        hoverEnabled: true
                                        onClicked: studio.useBase(modelData.key)
                                        Accessible.name: modelData.label
                                        scale: hovered ? 1.1 : 1
                                        background: Rectangle {
                                            radius: 22; color: Theme.colorOf(base.modelData.key, 2); border.width: 2; border.color: "#3a404c"
                                            Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: Theme.colorOf(base.modelData.key, 8) }
                                        }
                                        ToolTip.visible: hovered
                                        ToolTip.text: modelData.label
                                    }
                                }
                            }
                            Head { text: Lang.t("Dört ana renk", "The four main colours") }
                            Colour { role: 2; name: Lang.t("Arka plan", "Background"); use: Lang.t("Ana sayfa ve Velum'un kendi sayfaları", "The home page and Velum's own pages") }
                            Colour { role: 1; name: Lang.t("Çubuklar", "Bars"); use: Lang.t("Araç çubuğu, yan panel, menüler", "Toolbar, side bar, menus") }
                            Colour { role: 6; name: Lang.t("Yazı", "Writing"); use: Lang.t("Bütün yazılar ve simgeler", "All text and icons") }
                            Colour { role: 8; name: Lang.t("Vurgu", "Accent"); use: Lang.t("Seçili olanlar, düğmeler, saat", "What is chosen, buttons, the clock") }
                            Press { Layout.fillWidth: true; Layout.topMargin: 8; text: studio.fine ? Lang.t("İnce ayarı gizle", "Hide the fine tuning") : Lang.t("İnce ayar: tek tek renkler", "Fine tuning: every colour"); onClicked: { studio.fine = !studio.fine; studio.picking = -1 } }
                            ColumnLayout {
                                visible: studio.fine
                                Layout.fillWidth: true
                                spacing: 4
                                Words { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: studio.quiet; font.pixelSize: 12; text: Lang.t("Burada bir rengi değiştirince yalnızca o değişir. Ana renklerden birini ince ayar açıkken değiştirsen de diğerleri korunur.", "Here a change touches one colour only, main ones included.") }
                                Colour { role: 3; name: Lang.t("Düğme zemini", "Button face"); use: Lang.t("Düğmeler, adres çubuğu, kartlar", "Buttons, address field, cards") }
                                Colour { role: 4; name: Lang.t("Üzerine gelince", "Under the pointer"); use: Lang.t("Fare üstündeyken düğmeler", "Buttons you point at") }
                                Colour { role: 5; name: Lang.t("Çizgiler", "Lines"); use: Lang.t("Ayraçlar ve kenarlıklar", "Dividers and borders") }
                                Colour { role: 7; name: Lang.t("Soluk yazı", "Quiet writing"); use: Lang.t("Açıklamalar, ipuçları", "Notes and hints") }
                                Colour { role: 9; name: Lang.t("Vurgunun üstündeki yazı", "Writing on the accent"); use: Lang.t("Seçili düğmenin yazısı", "Text of a chosen button") }
                                Colour { role: 0; name: Lang.t("Sekme şeridi", "Tab strip"); use: Lang.t("Sekmelerin arkası", "Behind the tabs") }
                                Colour { role: 10; name: Lang.t("Süs rengi 1", "Extra colour 1"); use: Lang.t("Kalkan kartı, uyuyan sekme", "Shield card, sleeping tab") }
                                Colour { role: 11; name: Lang.t("Süs rengi 2", "Extra colour 2"); use: Lang.t("Site simgeleri", "Site marks") }
                                Colour { role: 12; name: Lang.t("Süs rengi 3", "Extra colour 3"); use: Lang.t("Olumlu işaretler", "Good news") }
                                Colour { role: 13; name: Lang.t("Süs rengi 4", "Extra colour 4"); use: Lang.t("Sabitlenmiş sekme", "Pinned tab") }
                                Colour { role: 14; name: Lang.t("Uyarı", "Warning"); use: Lang.t("Hatalar ve silme", "Errors and deleting") }
                            }
                        }

                        // ---- shape ----
                        ColumnLayout {
                            visible: studio.tab === 1
                            Layout.fillWidth: true
                            spacing: 8
                            Head { text: Lang.t("Köşeler", "Corners") }
                            Choice { options: [{ key: 0, label: Lang.t("Keskin", "Square") }, { key: 0.5, label: Lang.t("Az", "Slight") }, { key: 1, label: Lang.t("Yuvarlak", "Round") }, { key: 1.6, label: Lang.t("Yumuşak", "Soft") }]; current: studio.roundness; onChosen: key => studio.setShape("roundness", key) }
                            Head { text: Lang.t("Sekmeler", "Tabs") }
                            Choice { options: [{ key: "rounded", label: Lang.t("Kutu", "Box") }, { key: "pill", label: Lang.t("Hap", "Pill") }, { key: "square", label: Lang.t("Kare", "Square") }, { key: "line", label: Lang.t("Çizgi", "Line") }]; current: studio.tabShape; onChosen: key => studio.setShape("tabShape", key) }
                            Head { text: Lang.t("Yoğunluk", "Density") }
                            Choice { options: [{ key: "compact", label: Lang.t("Sıkı", "Compact") }, { key: "normal", label: "Normal" }, { key: "roomy", label: Lang.t("Ferah", "Roomy") }]; current: studio.density; onChosen: key => studio.setShape("density", key) }
                        }

                        // ---- lettering, each shown in itself ----
                        ColumnLayout {
                            id: letters
                            visible: studio.tab === 2
                            Layout.fillWidth: true
                            spacing: 8
                            property bool head: false
                            Choice { options: [{ key: false, label: Lang.t("Arayüz", "Browser") }, { key: true, label: Lang.t("Başlık ve saat", "Headline and clock") }]; current: letters.head; onChosen: key => letters.head = key }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                Repeater {
                                    model: studio.tab !== 2 ? [] : [{ name: "", body: true }].concat(Theme.bundled.filter(f => letters.head || f.body))
                                    AbstractButton {
                                        id: font
                                        required property var modelData
                                        readonly property bool chosen: (letters.head ? studio.headFamily : studio.fontFamily) === modelData.name
                                        readonly property string shown: modelData.name !== "" ? modelData.name : letters.head ? Lang.t("Arayüzle aynı", "Same as the rest") : "Inter"
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 62
                                        hoverEnabled: true
                                        onClicked: studio.setShape(letters.head ? "headFamily" : "fontFamily", modelData.name)
                                        Accessible.name: shown
                                        FontLoader { id: sample; source: Theme.fontFile(font.modelData.name) || Theme.sansFont.source }
                                        background: Rectangle { radius: 14; color: font.hovered ? "#2d3340" : studio.field; border.width: font.chosen ? 2 : 0; border.color: studio.blue }
                                        contentItem: Column {
                                            topPadding: 8; leftPadding: 12
                                            Words { width: font.width - 24; elide: Text.ElideRight; text: Lang.t("Sakin ağ", "Quiet web"); font.family: sample.name; font.pixelSize: 18 }
                                            Words { width: font.width - 24; elide: Text.ElideRight; text: font.shown; color: studio.quiet; font.pixelSize: 11 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: studio.hard
                    implicitHeight: 52
                    radius: 14
                    color: "#4a2b17"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                        Words { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#ffd9b8"; text: Lang.t("Bu renklerle yazılar zor okunuyor.", "Writing is hard to read in these colours.") }
                        Press { text: Lang.t("Düzelt", "Fix it"); onClicked: studio.repair() }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Press { text: "↶ " + Lang.t("Geri al", "Undo"); enabled: studio.past.length > 0; onClicked: studio.undo() }
                    Press { text: Lang.t("Baştan", "Start over"); enabled: studio.past.length > 0; onClicked: studio.startOver() }
                    Item { Layout.fillWidth: true }
                    Press { strong: true; text: studio.hard ? Lang.t("Yine de uygula", "Apply anyway") : Lang.t("Uygula", "Apply"); onClicked: studio.apply() }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ThemePreview {
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 900)
                height: Math.min(parent.height - 80, width * 0.68)
                colors: studio.colors
                roundness: studio.roundness
                tabShape: studio.tabShape
                uiFont: face.name
                headFont: studio.headFamily === "" ? face.name : head.name
                border.width: 1
                border.color: "#333946"
                FontLoader { id: face; source: Theme.fontFile(studio.fontFamily) || Theme.sansFont.source }
                FontLoader { id: head; source: Theme.fontFile(studio.headFamily) || Theme.sansFont.source }
            }
            Words { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 } text: Lang.t("Önizleme", "Preview"); color: studio.quiet; font.pixelSize: 12 }
        }
    }
}
