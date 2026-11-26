import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The everyday home page: a big headline with a word that keeps changing, search and
// your sites on one side; a tall clock and your widgets on the other. Everything can be
// reshaped in the panel behind the top right button, down to your own style sheet.
// "page" holds the data. Nothing here asks the network for anything.
Item {
    id: root
    property Item page
    property alias field: search
    property alias editor: panel
    readonly property bool wide: width >= 1080
    readonly property bool hasClock: page.widgets.includes("clock")
    readonly property var cards: page.widgets.filter(w => w !== "clock")
    function strong(tone) { return Theme.dark ? Qt.lighter(tone, 1.15) : Qt.darker(tone, 1.15) }

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2.5; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Backdrop { anchors.fill: parent; mode: root.page.background; picture: root.page.picture }
    Rectangle { anchors.fill: parent; color: root.page.css(["page"], "background", "transparent") }

    component Words: HomeText { page: root.page }

    Flickable {
        anchors.fill: parent
        anchors.rightMargin: panel.visible && root.width > 900 ? panel.width + 24 : 0
        contentHeight: Math.max(height, grid.implicitHeight + 96)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: grid
            readonly property bool two: root.wide && !(panel.visible && root.width < 1500)
            width: Math.min(parent.width - 48, two ? 1180 : 680)
            x: (parent.width - width) / 2
            y: Math.max(36, (parent.height - implicitHeight) * 0.42)
            columns: two ? 2 : 1
            columnSpacing: 56
            rowSpacing: 28
            opacity: root.arrived
            transform: Translate { y: (1 - root.arrived) * 22 }

            // ---- words, search, sites ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 20

                // a chip with the mark, leading to the settings
                AbstractButton {
                    id: chip
                    hoverEnabled: true
                    visible: root.page.css(["chip"], "display", "block") !== "none"
                    onClicked: root.page.customize()
                    Accessible.name: Lang.t("Ayarlar", "Settings")
                    padding: 5
                    rightPadding: 14
                    background: HomeBox { page: root.page; names: ["chip"]; corner: height / 2; base: chip.hovered ? Theme.title : Theme.raised }
                    contentItem: Row {
                        spacing: 10
                        Rectangle {
                            width: version.implicitWidth + 40; height: 30; radius: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                            Image { x: 6; anchors.verticalCenter: parent.verticalCenter; source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(40, 40); width: 20; height: 20 }
                            Text { id: version; x: 30; anchors.verticalCenter: parent.verticalCenter; text: "v" + Qt.application.version; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 12; font.variableAxes: Theme.axes(700) }
                        }
                        Words { names: ["chip"]; anchors.verticalCenter: parent.verticalCenter; text: root.page.greeting(root.page.now.getHours()) + "  →"; size: 14; weight: 600 }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Words {
                        Layout.fillWidth: true
                        names: ["headline"]
                        visible: root.page.css(["headline"], "display", "block") !== "none"
                        text: root.page.headline !== "" ? root.page.headline : Lang.t("Velum senin", "Velum is your")
                        size: Math.max(40, Math.min(82, root.width * 0.052))
                        weight: 800
                        font.letterSpacing: -2.5
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 24
                    }
                    // the changing word, on its pill
                    HomeBox {
                        id: pill
                        page: root.page
                        names: ["pill"]
                        property int word: 0
                        readonly property var words: root.page.words.length > 0 ? root.page.words
                            : [Lang.t("tarayıcın.", "browser."), Lang.t("sakin alanın.", "quiet place."), Lang.t("gizli köşen.", "private corner."), Lang.t("reklamsız ağın.", "ad-free web.")]
                        base: Theme.accent
                        corner: height / 2.4
                        implicitWidth: Math.min(said.implicitWidth + 52, grid.width)
                        implicitHeight: said.implicitHeight + 10
                        clip: true
                        Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth * 2; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                        Words {
                            id: said
                            x: 26
                            y: 3
                            names: ["pill"]
                            text: pill.words[pill.word % pill.words.length]
                            base: Theme.accentInk
                            size: Math.max(38, Math.min(76, root.width * 0.048))
                            weight: 800
                            font.letterSpacing: -2.5
                        }
                        SequentialAnimation {
                            id: swap
                            ParallelAnimation {
                                NumberAnimation { target: said; property: "y"; to: -said.height * 0.6; duration: Theme.smooth; easing.type: Easing.InCubic }
                                NumberAnimation { target: said; property: "opacity"; to: 0; duration: Theme.smooth }
                            }
                            ScriptAction { script: pill.word++ }
                            PropertyAction { target: said; property: "y"; value: said.height * 0.6 }
                            ParallelAnimation {
                                NumberAnimation { target: said; property: "y"; to: 3; duration: Theme.smooth * 1.6; easing.type: Easing.OutBack }
                                NumberAnimation { target: said; property: "opacity"; to: 1; duration: Theme.smooth }
                            }
                        }
                        Timer { interval: 3400; repeat: true; running: root.visible && root.page.visible && pill.words.length > 1; onTriggered: Theme.motion ? swap.restart() : pill.word++ }
                    }
                }

                AddressField {
                    id: search
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    visible: root.page.css(["search"], "display", "block") !== "none"
                    implicitHeight: 58
                    font.pixelSize: root.page.css(["search"], "font-size", 16)
                    color: root.page.css(["search"], "color", Theme.text)
                    leftPadding: 50
                    placeholderText: Lang.t(Address.engineName + " ile ara ya da adres yaz", "Search with " + Address.engineName + " or enter address")
                    onGo: target => root.page.go(target)
                    background: HomeBox {
                        page: root.page
                        names: ["search"]
                        corner: height / 2
                        border.width: search.activeFocus ? 2 : root.page.css(["search"], "border-width", root.page.css(["search"], "border-color", "") !== "" ? 2 : 0)
                        border.color: search.activeFocus ? Theme.accent : root.page.css(["search"], "border-color", Theme.line)
                        Icon { x: 20; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 18; color: search.activeFocus ? Theme.accent : Theme.dim }
                    }
                }

                // your sites
                Flow {
                    id: tiles
                    Layout.fillWidth: true
                    visible: root.page.css(["tile"], "display", "block") !== "none"
                    spacing: 8
                    Repeater {
                        model: root.page.shortcuts
                        AbstractButton {
                            id: tile
                            required property int index
                            required property var modelData
                            implicitWidth: 80
                            implicitHeight: 98
                            hoverEnabled: true
                            scale: down ? 0.95 : 1
                            onClicked: root.page.go(modelData.url)
                            background: HomeBox { page: root.page; names: ["tile"]; corner: 22; base: tile.hovered ? Theme.title : Theme.raised }
                            contentItem: Item {
                                SiteIcon {
                                    anchors { top: parent.top; topMargin: tile.hovered ? 10 : 14; horizontalCenter: parent.horizontalCenter }
                                    width: 44; height: 44
                                    title: String(tile.modelData.title)
                                    file: root.page.iconFor(tile.modelData.url)
                                    tone: Theme.rainbow[tile.index % Theme.rainbow.length]
                                    Behavior on anchors.topMargin { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
                                }
                                Words { anchors { bottom: parent.bottom; bottomMargin: 12; left: parent.left; right: parent.right; leftMargin: 6; rightMargin: 6 } names: ["tile"]; text: tile.modelData.title; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; size: 12; weight: 550 }
                                IconButton {
                                    anchors { top: parent.top; right: parent.right; margins: 2 }
                                    implicitWidth: 22; implicitHeight: 22; iconSize: 11
                                    symbol: "close"
                                    hint: Lang.t("Yer imini kaldır", "Remove the bookmark")
                                    visible: tile.hovered || hovered
                                    onClicked: root.page.removeShortcut(tile.index)
                                }
                            }
                        }
                    }
                    AbstractButton {
                        id: plus
                        implicitWidth: 80
                        implicitHeight: 98
                        hoverEnabled: true
                        visible: root.page.shortcuts.length < 10
                        onClicked: { adding.visible = true; adding.forceActiveFocus() }
                        Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                        background: Rectangle { radius: root.page.css(["tile"], "border-radius", Theme.web ? 0 : 22); color: plus.hovered ? Theme.raised : "transparent"; border.color: Theme.line; border.width: 1.5 }
                        contentItem: Item {
                            Icon { anchors { top: parent.top; topMargin: 24; horizontalCenter: parent.horizontalCenter } name: "plus"; size: 24; color: Theme.accent }
                            Words { anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter } text: Lang.t("Ekle", "Add"); base: Theme.dim; size: 12 }
                        }
                    }
                }
                AddressField {
                    id: adding
                    visible: false
                    Layout.fillWidth: true
                    placeholderText: Lang.t("Yer imi adresi, örn. vamola.dev (Enter)", "Bookmark address, e.g. vamola.dev (Enter)")
                    onAccepted: { root.page.addShortcut(text); text = ""; visible = false }
                    Keys.onEscapePressed: { text = ""; visible = false }
                    // the base field would navigate; here Enter only adds
                    onGo: {}
                }

                // most visited, when switched on
                Flow {
                    Layout.fillWidth: true
                    visible: root.page.showFrequent && root.page.frequent.length > 0
                    spacing: 8
                    Repeater {
                        model: root.page.frequent
                        TextButton {
                            required property var modelData
                            implicitHeight: 34
                            implicitWidth: Math.min(260, measure.implicitWidth + 34)
                            text: modelData.title
                            onClicked: root.page.go(modelData.url)
                            Text { id: measure; visible: false; text: parent.text; font.family: Theme.ui; font.pixelSize: 13 }
                        }
                    }
                }
            }

            // ---- clock and widgets ----
            GridLayout {
                Layout.fillWidth: !grid.two
                Layout.preferredWidth: grid.two ? 500 : -1
                Layout.alignment: Qt.AlignTop
                visible: root.page.widgets.length > 0
                columns: grid.width >= 480 ? 2 : 1
                columnSpacing: 20
                rowSpacing: 16

                // hours over minutes
                ColumnLayout {
                    visible: root.hasClock && root.page.css(["clock"], "display", "block") !== "none"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    opacity: root.page.css(["clock"], "opacity", 1)
                    spacing: 0
                    component Digits: Words {
                        names: ["clock"]
                        Layout.alignment: Qt.AlignHCenter
                        size: grid.two ? 190 : 150
                        weight: 850
                        font.letterSpacing: -4
                        lineHeight: 0.84
                    }
                    Digits { text: Qt.formatTime(root.page.now, "HH"); base: root.strong(Theme.accent) }
                    Digits { Layout.topMargin: -font.pixelSize * 0.3; text: Qt.formatTime(root.page.now, "mm"); base: Theme.accent }
                    Words { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; text: root.page.now.getDate() + " " + root.page.locale_.monthName(root.page.now.getMonth()) + " " + root.page.locale_.dayName(root.page.now.getDay()); base: Theme.dim; size: 15; weight: 650 }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    Layout.columnSpan: root.hasClock || parent.columns === 1 ? 1 : 2
                    spacing: 14
                    Repeater {
                        model: root.cards
                        HomeWidget { page: root.page }
                    }
                }
            }

            Words {
                Layout.columnSpan: grid.columns
                Layout.alignment: Qt.AlignHCenter
                visible: !root.page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                base: Theme.danger
                size: 12
            }
        }
    }

    TextButton {
        anchors { right: parent.right; top: parent.top; margins: 14 }
        visible: !panel.visible
        text: Lang.t("Düzenle", "Design")
        onClicked: panel.open()
    }
    HomeEditor {
        id: panel
        page: root.page
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12 }
        z: 5
    }
}
