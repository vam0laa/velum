import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The everyday home page: a greeting, one wide search field, your sites and the pages
// you saw last. Widgets, your own headline and your style sheet can be added in the
// panel behind the top right button.
// "page" holds the data. Nothing here asks the network for anything.
Item {
    id: root
    property Item page
    property alias field: search
    property alias editor: panel

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Backdrop { anchors.fill: parent; mode: root.page.background; picture: root.page.picture }
    Rectangle { anchors.fill: parent; color: root.page.css(["page"], "background", "transparent") }

    component Words: HomeText { page: root.page }

    Flickable {
        id: scroll
        anchors.fill: parent
        anchors.rightMargin: panel.visible && root.width > 900 ? panel.width + 24 : 0
        contentHeight: Math.max(height, column.y + column.implicitHeight + 48)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 48, 640)
            x: (parent.width - width) / 2
            y: Math.max(88, (scroll.height - implicitHeight) * 0.4)
            spacing: 44
            opacity: root.arrived
            transform: Translate { y: (1 - root.arrived) * 16 }

            // ---- greeting and search ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Words {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    face: Theme.display
                    names: ["headline"]
                    visible: root.page.css(["headline"], "display", "block") !== "none"
                    readonly property string hello: root.page.greeting(root.page.now.getHours())
                    text: root.page.headline !== "" ? root.page.headline : hello.charAt(0).toLocaleUpperCase(Lang.turkish ? "tr_TR" : "en_US") + hello.slice(1)
                    size: root.width < 640 ? 34 : 50
                    weight: 500
                    font.letterSpacing: -1.4
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 22
                }
                Words {
                    Layout.alignment: Qt.AlignHCenter
                    names: ["date"]
                    text: root.page.now.getDate() + " " + root.page.locale_.monthName(root.page.now.getMonth()) + " " + root.page.locale_.dayName(root.page.now.getDay())
                    base: Theme.dim
                    size: 14
                }

                HomeBox {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    page: root.page
                    names: ["search"]
                    visible: root.page.css(["search"], "display", "block") !== "none"
                    implicitHeight: 56
                    corner: height / 2
                    base: Qt.alpha(Theme.raised, 0.9)
                    border.width: root.page.css(["search"], "border-width", 1)
                    border.color: search.activeFocus ? Theme.accent : root.page.css(["search"], "border-color", Theme.line)
                    // a soft halo while you type
                    Rectangle { anchors { fill: parent; margins: -4 } z: -1; radius: height / 2; color: "transparent"; border.width: 4; border.color: Qt.alpha(Theme.accent, 0.18); visible: search.activeFocus }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 10 }
                        spacing: 8
                        Dropdown {
                            implicitHeight: 38
                            implicitWidth: engine.implicitWidth + 52
                            options: Address.engines
                            current: Address.engine
                            onChosen: key => Address.engine = key
                            Text { id: engine; visible: false; text: Address.engineName; font.family: Theme.ui; font.pixelSize: Theme.size(17) }
                        }
                        AddressField {
                            id: search
                            Layout.fillWidth: true
                            implicitHeight: 44
                            bare: true
                            leftPadding: 8
                            font.pixelSize: root.page.css(["search"], "font-size", 15)
                            color: root.page.css(["search"], "color", Theme.text)
                            placeholderText: Lang.t("Web'de ara ya da adres yaz", "Search the web or enter a URL")
                            background: null
                            onGo: target => root.page.go(target)
                        }
                        Rectangle {
                            visible: search.text === "" && root.width >= 560 && Keymap.text("address") !== ""
                            implicitWidth: hint.implicitWidth + 18
                            implicitHeight: 24
                            radius: height / 2
                            color: Theme.surface
                            border.color: Theme.line
                            Text { id: hint; anchors.centerIn: parent; text: Keymap.text("address"); color: Theme.dim; font.family: "monospace"; font.pixelSize: 11 }
                        }
                        IconButton { symbol: "search"; hint: Lang.t("Ara", "Search"); onClicked: if (search.text.trim() !== "") search.accepted() }
                    }
                }
            }

            // ---- your sites ----
            Flow {
                id: tiles
                readonly property int count: Math.min(root.page.shortcuts.length + (plus.visible ? 1 : 0), Math.max(1, Math.floor((column.width + spacing) / (76 + spacing))))
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: count * 76 + (count - 1) * spacing
                visible: root.page.css(["tile"], "display", "block") !== "none"
                spacing: 4
                component Face: Rectangle {
                    property bool lit
                    anchors { top: parent.top; topMargin: lit ? 2 : 4; horizontalCenter: parent.horizontalCenter }
                    width: 48; height: 48
                    radius: root.page.css(["tile"], "border-radius", Theme.round(16))
                    color: root.page.css(["tile"], "background", lit ? Theme.title : Theme.raised)
                    border.width: 1
                    border.color: lit ? Qt.alpha(Theme.accent, 0.55) : root.page.css(["tile"], "border-color", Theme.line)
                    Behavior on anchors.topMargin { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
                }
                Repeater {
                    model: root.page.shortcuts
                    AbstractButton {
                        id: tile
                        required property int index
                        required property var modelData
                        implicitWidth: 76
                        implicitHeight: 84
                        hoverEnabled: true
                        onClicked: root.page.go(modelData.url)
                        Accessible.name: modelData.title
                        contentItem: Item {
                            Face {
                                lit: tile.hovered
                                SiteIcon {
                                    anchors.centerIn: parent
                                    width: 22; height: 22
                                    plain: true
                                    title: String(tile.modelData.title)
                                    file: root.page.iconFor(tile.modelData.url)
                                    tone: Theme.rainbow[tile.index % Theme.rainbow.length]
                                }
                            }
                            Words { anchors { bottom: parent.bottom; bottomMargin: 6; left: parent.left; right: parent.right; leftMargin: 2; rightMargin: 2 } names: ["tile"]; text: tile.modelData.title; base: tile.hovered ? Theme.text : Theme.dim; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; size: 12; weight: 500 }
                            IconButton {
                                anchors { top: parent.top; right: parent.right; margins: -2 }
                                implicitWidth: 20; implicitHeight: 20; iconSize: 10
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
                    implicitWidth: 76
                    implicitHeight: 84
                    hoverEnabled: true
                    visible: root.page.shortcuts.length < 10
                    onClicked: root.page.askShortcut()
                    Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                    contentItem: Item {
                        Face {
                            lit: plus.hovered
                            color: plus.hovered ? Theme.title : "transparent"
                            Icon { anchors.centerIn: parent; name: "plus"; size: 20; color: plus.hovered ? Theme.text : Theme.dim }
                        }
                        Words { anchors { bottom: parent.bottom; bottomMargin: 6; horizontalCenter: parent.horizontalCenter } text: Lang.t("Ekle", "Add"); base: plus.hovered ? Theme.text : Theme.dim; size: 12; weight: 500 }
                    }
                }
            }

            // ---- most visited, when switched on ----
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
                        Text { id: measure; visible: false; text: parent.text; textFormat: Text.PlainText; font.family: Theme.ui; font.pixelSize: 13 }
                    }
                }
            }

            // ---- recently visited ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 580
                Layout.alignment: Qt.AlignHCenter
                visible: root.page.recent.length > 0
                spacing: 4
                Words { Layout.leftMargin: 12; text: Lang.t("Son ziyaret edilenler", "Recently visited"); base: Theme.dim; size: 12; weight: 500 }
                Rectangle { Layout.fillWidth: true; Layout.bottomMargin: 4; implicitHeight: 1; color: Theme.line; opacity: 0.6 }
                Repeater {
                    model: root.page.recent
                    AbstractButton {
                        id: row
                        required property var modelData
                        readonly property string site: String(modelData.url).replace(/^[a-z]+:\/\/(www\.)?/, "").split("/")[0]
                        Layout.fillWidth: true
                        implicitHeight: 40
                        hoverEnabled: true
                        onClicked: root.page.go(modelData.url)
                        Accessible.name: modelData.title
                        background: Rectangle { radius: Theme.round(12); color: row.hovered ? Qt.alpha(Theme.raised, 0.8) : "transparent" }
                        contentItem: RowLayout {
                            spacing: 12
                            Rectangle {
                                Layout.leftMargin: 12
                                implicitWidth: 24; implicitHeight: 24
                                radius: Theme.round(6)
                                color: Theme.raised
                                border.color: Theme.line
                                SiteIcon { anchors.centerIn: parent; width: 14; height: 14; plain: true; title: row.site; file: root.page.iconFor(row.modelData.url); tone: Theme.mauve }
                            }
                            Words { Layout.fillWidth: true; text: row.modelData.title || row.site; elide: Text.ElideRight; size: 14; weight: 500 }
                            Words { Layout.maximumWidth: 160; visible: root.width >= 560; text: row.site; base: Theme.dim; elide: Text.ElideRight; size: 13 }
                            Words { Layout.rightMargin: 12; text: root.page.ago(row.modelData.last); base: Theme.dim; size: 12 }
                        }
                    }
                }
            }

            // ---- widgets you added ----
            GridLayout {
                Layout.fillWidth: true
                visible: root.page.widgets.length > 0
                columns: column.width >= 520 ? 2 : 1
                columnSpacing: 16
                rowSpacing: 16
                Repeater {
                    model: root.page.widgets
                    Loader {
                        id: slot
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        sourceComponent: modelData === "clock" ? clock : card
                        Component {
                            id: clock
                            Words { visible: root.page.css(["clock"], "display", "block") !== "none"; horizontalAlignment: Text.AlignHCenter; face: Theme.display; names: ["clock"]; text: Qt.formatTime(root.page.now, "HH:mm"); size: 72; weight: 500; font.letterSpacing: -2; opacity: root.page.css(["clock"], "opacity", 1) }
                        }
                        Component {
                            id: card
                            ColumnLayout { HomeWidget { page: root.page; modelData: slot.modelData } }
                        }
                    }
                }
            }

            Words {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                base: Theme.danger
                size: 12
            }
        }
    }

    Brand { x: 28; y: 20; visible: root.page.branded }
    Row {
        anchors { right: parent.right; top: parent.top; rightMargin: 24; topMargin: 16 }
        visible: !panel.visible
        spacing: 6
        IconButton { symbol: "palette"; hint: Lang.t("Ana sayfayı düzenle", "Design the home page"); onClicked: panel.open() }
        IconButton { symbol: "settings"; hint: Lang.t("Ayarlar", "Settings"); onClicked: root.page.customize() }
    }
    HomeEditor {
        id: panel
        page: root.page
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12 }
        z: 5
    }
}
