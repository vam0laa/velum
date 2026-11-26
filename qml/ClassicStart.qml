import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The everyday home page, after Lucid: a big headline with a word that keeps changing,
// search and your sites on one side; a tall clock and a few widgets on the other.
// "page" holds the data. Nothing here asks the network for anything.
Item {
    id: root
    property Item page
    property alias field: search
    readonly property bool wide: width >= 1080
    // a brighter shade stands out on dark themes, a deeper one on light themes
    function strong(tone) { return Theme.dark ? Qt.lighter(tone, 1.15) : Qt.darker(tone, 1.15) }

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2.5; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Backdrop { anchors.fill: parent; mode: root.page.background; picture: root.page.picture }

    component Label: Text { color: Theme.text; font.family: Theme.ui; textFormat: Text.PlainText }
    component Widget: Rectangle {
        Layout.fillWidth: true
        radius: 28
        color: Theme.raised
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, grid.implicitHeight + 96)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: grid
            width: Math.min(parent.width - 48, root.wide ? 1180 : 680)
            x: (parent.width - width) / 2
            y: Math.max(36, (parent.height - implicitHeight) * 0.42)
            columns: root.wide ? 2 : 1
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
                    onClicked: root.page.customize()
                    Accessible.name: Lang.t("Bu sayfayı özelleştir", "Customise this page")
                    padding: 5
                    rightPadding: 14
                    background: Rectangle { radius: height / 2; color: chip.hovered ? Theme.title : Theme.raised }
                    contentItem: Row {
                        spacing: 10
                        Rectangle {
                            width: version.implicitWidth + 40; height: 30; radius: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                            Image { x: 6; anchors.verticalCenter: parent.verticalCenter; source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(40, 40); width: 20; height: 20 }
                            Label { id: version; x: 30; anchors.verticalCenter: parent.verticalCenter; text: "v" + Qt.application.version; color: Theme.accentInk; font.pixelSize: 12; font.variableAxes: Theme.axes(700) }
                        }
                        Label { anchors.verticalCenter: parent.verticalCenter; text: root.page.greeting(root.page.now.getHours()) + "  →"; font.pixelSize: 14; font.variableAxes: Theme.axes(600) }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: Lang.t("Velum senin", "Velum is your")
                        font.pixelSize: Math.max(40, Math.min(82, root.width * 0.052))
                        font.variableAxes: Theme.axes(800)
                        font.letterSpacing: -2.5
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 28
                    }
                    // the changing word, on its pill
                    Rectangle {
                        id: pill
                        property int word: 0
                        readonly property var words: [Lang.t("tarayıcın.", "browser."), Lang.t("sakin alanın.", "quiet place."), Lang.t("gizli köşen.", "private corner."), Lang.t("reklamsız ağın.", "ad-free web.")]
                        implicitWidth: Math.min(said.implicitWidth + 52, grid.width)
                        implicitHeight: said.implicitHeight + 10
                        radius: height / 2.4
                        color: Theme.accent
                        clip: true
                        Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth * 2; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                        Label {
                            id: said
                            x: 26
                            y: 3
                            text: pill.words[pill.word % pill.words.length]
                            color: Theme.accentInk
                            font.pixelSize: Math.max(38, Math.min(76, root.width * 0.048))
                            font.variableAxes: Theme.axes(800)
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
                        Timer { interval: 3400; repeat: true; running: root.visible && root.page.visible; onTriggered: Theme.motion ? swap.restart() : pill.word++ }
                    }
                }

                AddressField {
                    id: search
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    implicitHeight: 58
                    font.pixelSize: 16
                    leftPadding: 50
                    placeholderText: Lang.t(Address.engineName + " ile ara ya da adres yaz", "Search with " + Address.engineName + " or enter address")
                    onGo: target => root.page.go(target)
                    background: Rectangle {
                        radius: height / 2
                        color: Theme.raised
                        border.width: search.activeFocus ? 2 : 0
                        border.color: Theme.accent
                        Icon { x: 20; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 18; color: search.activeFocus ? Theme.accent : Theme.dim }
                    }
                }

                // your sites
                Flow {
                    id: tiles
                    Layout.fillWidth: true
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
                            background: Rectangle { radius: 22; color: tile.hovered ? Theme.title : Theme.raised; Behavior on color { ColorAnimation { duration: Theme.quick } } }
                            contentItem: Item {
                                SiteIcon {
                                    anchors { top: parent.top; topMargin: tile.hovered ? 10 : 14; horizontalCenter: parent.horizontalCenter }
                                    width: 44; height: 44
                                    title: String(tile.modelData.title)
                                    file: root.page.iconFor(tile.modelData.url)
                                    tone: Theme.rainbow[tile.index % Theme.rainbow.length]
                                    Behavior on anchors.topMargin { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
                                }
                                Label { anchors { bottom: parent.bottom; bottomMargin: 12; left: parent.left; right: parent.right; leftMargin: 6; rightMargin: 6 } text: tile.modelData.title; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.pixelSize: 12; font.variableAxes: Theme.axes(550) }
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
                        background: Rectangle { radius: 22; color: plus.hovered ? Theme.raised : "transparent"; border.color: Theme.line; border.width: 1.5 }
                        contentItem: Item {
                            Icon { anchors { top: parent.top; topMargin: 24; horizontalCenter: parent.horizontalCenter } name: "plus"; size: 24; color: Theme.accent }
                            Label { anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter } text: Lang.t("Ekle", "Add"); color: Theme.dim; font.pixelSize: 12 }
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
                            implicitWidth: Math.min(260, label.implicitWidth + 34)
                            text: modelData.title
                            onClicked: root.page.go(modelData.url)
                            Label { id: label; visible: false; text: parent.text; font.pixelSize: 13 }
                        }
                    }
                }
            }

            // ---- clock and widgets ----
            GridLayout {
                Layout.fillWidth: !root.wide
                Layout.preferredWidth: root.wide ? 500 : -1
                Layout.alignment: Qt.AlignTop
                visible: root.page.showClock || root.page.showShield || root.page.showNote
                columns: grid.width >= 480 ? 2 : 1
                columnSpacing: 20
                rowSpacing: 16

                // hours over minutes
                ColumnLayout {
                    visible: root.page.showClock
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 0
                    component Digits: Label {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: root.wide ? 190 : 150
                        font.variableAxes: Theme.axes(850)
                        font.letterSpacing: -4
                        lineHeight: 0.84
                    }
                    Digits { text: Qt.formatTime(root.page.now, "HH"); color: root.strong(Theme.accent) }
                    Digits { Layout.topMargin: -font.pixelSize * 0.3; text: Qt.formatTime(root.page.now, "mm"); color: Theme.accent }
                    Label { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; text: root.page.now.getDate() + " " + root.page.locale_.monthName(root.page.now.getMonth()) + " " + root.page.locale_.dayName(root.page.now.getDay()); color: Theme.dim; font.pixelSize: 15; font.variableAxes: Theme.axes(650) }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 14

                    Widget {
                        visible: root.page.showClock
                        implicitHeight: 138
                        color: Qt.tint(Theme.surface, Qt.alpha(Theme.accent, 0.3))
                        Column {
                            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                            spacing: -4
                            Label { text: root.page.locale_.dayName(root.page.now.getDay()); color: Theme.accent; font.pixelSize: 15; font.variableAxes: Theme.axes(700) }
                            Label { text: root.page.now.getDate(); color: root.strong(Theme.accent); font.pixelSize: 58; font.variableAxes: Theme.axes(850) }
                            Label { text: root.page.locale_.monthName(root.page.now.getMonth()) + "  •"; color: Theme.accent; font.pixelSize: 14; font.variableAxes: Theme.axes(700) }
                        }
                    }
                    Widget {
                        visible: root.page.showClock
                        implicitHeight: calendar.implicitHeight + 32
                        MonthCard {
                            id: calendar
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                            now: root.page.now
                            names: root.page.locale_
                            mondayFirst: Lang.turkish
                        }
                    }
                    Widget {
                        visible: root.page.showShield
                        implicitHeight: 138
                        color: Qt.tint(Theme.surface, Qt.alpha(Theme.mauve, 0.3))
                        Column {
                            anchors { left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: -2
                            Row {
                                spacing: 8
                                Icon { name: "shield"; size: 16; color: Theme.mauve; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: Lang.t("Kalkan", "Shield"); color: Theme.mauve; font.pixelSize: 15; font.variableAxes: Theme.axes(700) }
                            }
                            Label { text: Number(root.page.blocked).toLocaleString(root.page.locale_, "f", 0); color: root.strong(Theme.mauve); font.pixelSize: 46; font.variableAxes: Theme.axes(850) }
                            Label { width: parent.width; elide: Text.ElideRight; text: Lang.t("reklam ve izleyici engellendi", "ads and trackers blocked"); color: Theme.mauve; font.pixelSize: 12 }
                        }
                    }
                }

                Widget {
                    visible: root.page.showNote
                    Layout.columnSpan: parent.columns
                    implicitHeight: Math.max(110, Math.min(220, memo.implicitHeight + 24))
                    ScrollView {
                        anchors { fill: parent; margins: 12 }
                        TextArea {
                            id: memo
                            text: root.page.note
                            textFormat: TextEdit.PlainText
                            wrapMode: TextEdit.Wrap
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentInk
                            placeholderText: Lang.t("Not: aklındakini yaz, bu bilgisayarda kalır.", "Note: jot something down, it stays on this computer.")
                            placeholderTextColor: Theme.dim
                            font.family: Theme.ui
                            font.pixelSize: 14
                            background: null
                            onTextChanged: if (activeFocus) root.page.noteEdited(text.slice(0, 4000))
                        }
                    }
                }
            }

            Label {
                Layout.columnSpan: grid.columns
                Layout.alignment: Qt.AlignHCenter
                visible: !root.page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                color: Theme.danger
                font.pixelSize: 12
            }
        }
    }

    IconButton {
        anchors { right: parent.right; top: parent.top; margins: 14 }
        symbol: "settings"
        hint: Lang.t("Bu sayfayı özelleştir", "Customise this page")
        onClicked: root.page.customize()
    }
}
