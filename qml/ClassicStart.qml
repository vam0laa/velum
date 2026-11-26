import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The everyday start page, in the layout people know: the name, a wide search box, your
// sites as cards, and below them whatever else you switched on. "page" holds the data.
Item {
    id: root
    property Item page
    property alias field: search

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Backdrop { anchors.fill: parent; mode: root.page.background; picture: root.page.picture }

    component Section: Text {
        Layout.fillWidth: true
        Layout.topMargin: 10
        color: Theme.text
        font.family: Theme.ui
        font.pixelSize: 15
        font.weight: Font.Bold
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 96)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 48, 780)
            x: (parent.width - width) / 2
            y: Math.max(40, (parent.height - implicitHeight) * 0.34)
            spacing: 18
            opacity: root.arrived
            transform: Translate { y: (1 - root.arrived) * 14 }

            // the mark and the name
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(160, 160); width: 76; height: 76; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Velum"; color: Theme.text; font.family: Theme.ui; font.pixelSize: 54; font.weight: Font.ExtraBold; font.letterSpacing: -1.5; anchors.verticalCenter: parent.verticalCenter }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.page.showClock
                Layout.topMargin: -8
                text: Qt.formatTime(root.page.now, "HH:mm") + "  ·  " + root.page.now.getDate() + " " + root.page.locale_.monthName(root.page.now.getMonth()) + " " + root.page.locale_.dayName(root.page.now.getDay())
                color: Theme.dim
                font.family: Theme.ui
                font.pixelSize: 14
            }

            AddressField {
                id: search
                Layout.fillWidth: true
                Layout.maximumWidth: 640
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                implicitHeight: 52
                font.pixelSize: 15
                leftPadding: 44
                placeholderText: Lang.t(Address.engineName + " ile ara ya da adres yaz", "Search with " + Address.engineName + " or enter address")
                onGo: target => root.page.go(target)
            }

            // your sites as cards
            Flow {
                id: tiles
                readonly property int cell: 86
                readonly property int count: root.page.shortcuts.length + (root.page.shortcuts.length < 10 ? 1 : 0)
                readonly property int across: Math.max(1, Math.min(count, 8, Math.floor((column.width + spacing) / (cell + spacing))))
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: across * (cell + spacing) - spacing
                Layout.topMargin: 12
                spacing: 12

                Repeater {
                    model: root.page.shortcuts
                    AbstractButton {
                        id: tile
                        required property int index
                        required property var modelData
                        implicitWidth: tiles.cell
                        implicitHeight: 112
                        hoverEnabled: true
                        onClicked: root.page.go(modelData.url)
                        contentItem: Item {
                            Rectangle {
                                id: card
                                width: tiles.cell
                                height: tiles.cell
                                radius: 12
                                y: tile.hovered && !tile.down ? -3 : 0
                                color: tile.hovered ? Theme.raised : Qt.alpha(Theme.raised, 0.62)
                                border.color: tile.hovered ? Theme.accent : Qt.alpha(Theme.line, 0.6)
                                Behavior on y { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.quick } }
                                SiteIcon {
                                    anchors.centerIn: parent
                                    width: 46; height: 46
                                    title: String(tile.modelData.title)
                                    file: root.page.iconFor(tile.modelData.url)
                                    tone: Theme.rainbow[tile.index % Theme.rainbow.length]
                                }
                                IconButton {
                                    anchors { top: parent.top; right: parent.right; margins: 3 }
                                    implicitWidth: 22; implicitHeight: 22; iconSize: 11
                                    symbol: "close"
                                    hint: Lang.t("Yer imini kaldır", "Remove the bookmark")
                                    visible: tile.hovered || hovered
                                    onClicked: root.page.removeShortcut(tile.index)
                                }
                            }
                            Text {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                text: tile.modelData.title
                                textFormat: Text.PlainText
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: Theme.text
                                font.family: Theme.ui
                                font.pixelSize: 12
                            }
                        }
                        background: null
                    }
                }
                AbstractButton {
                    id: plus
                    implicitWidth: tiles.cell
                    implicitHeight: 112
                    hoverEnabled: true
                    visible: root.page.shortcuts.length < 10
                    onClicked: { adding.visible = true; adding.forceActiveFocus() }
                    Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                    background: null
                    contentItem: Item {
                        Rectangle {
                            id: empty
                            width: tiles.cell
                            height: tiles.cell
                            radius: 12
                            color: plus.hovered ? Qt.alpha(Theme.raised, 0.62) : "transparent"
                            border.color: Qt.alpha(Theme.line, 0.9)
                            Icon { anchors.centerIn: parent; name: "plus"; size: 24; color: Theme.dim }
                        }
                        Text { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } text: Lang.t("Ekle", "Add"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
                    }
                }
            }
            AddressField {
                id: adding
                visible: false
                Layout.fillWidth: true
                Layout.maximumWidth: 640
                Layout.alignment: Qt.AlignHCenter
                placeholderText: Lang.t("Yer imi adresi, örn. vamola.dev (Enter)", "Bookmark address, e.g. vamola.dev (Enter)")
                onAccepted: { root.page.addShortcut(text); text = ""; visible = false }
                Keys.onEscapePressed: { text = ""; visible = false }
                // the base field would navigate; here Enter only adds
                onGo: {}
            }

            // where you go most, from your own history
            Section { visible: root.page.showFrequent && root.page.frequent.length > 0; text: Lang.t("Sık gidilenler", "Most visited") }
            GridLayout {
                Layout.fillWidth: true
                visible: root.page.showFrequent && root.page.frequent.length > 0
                columns: column.width >= 620 ? 3 : column.width >= 400 ? 2 : 1
                columnSpacing: 12
                rowSpacing: 12
                Repeater {
                    model: root.page.frequent
                    AbstractButton {
                        id: place
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 76
                        hoverEnabled: true
                        onClicked: root.page.go(modelData.url)
                        background: Rectangle { radius: 12; color: place.hovered ? Theme.raised : Qt.alpha(Theme.raised, 0.55); border.color: place.hovered ? Theme.accent : "transparent" }
                        contentItem: Item {
                            Rectangle { x: 14; anchors.verticalCenter: parent.verticalCenter; width: 5; height: 40; radius: 3; color: Theme.rainbow[place.index % Theme.rainbow.length] }
                            Column {
                                anchors { left: parent.left; leftMargin: 30; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                spacing: 3
                                Text { width: parent.width; text: place.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.ui; font.pixelSize: 13 }
                                Text { width: parent.width; text: Address.display(place.modelData.url); textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }

            Section { visible: root.page.showNote; text: Lang.t("Not", "Note") }
            Rectangle {
                Layout.fillWidth: true
                visible: root.page.showNote
                implicitHeight: Math.max(90, Math.min(220, memo.implicitHeight + 12))
                radius: 12
                color: Qt.alpha(Theme.raised, 0.55)
                ScrollView {
                    anchors { fill: parent; margins: 6 }
                    TextArea {
                        id: memo
                        text: root.page.note
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentInk
                        placeholderText: Lang.t("Aklındakini yaz; bu bilgisayarda kalır.", "Jot something down; it stays on this computer.")
                        placeholderTextColor: Theme.dim
                        font.family: Theme.ui
                        font.pixelSize: 13
                        background: null
                        onTextChanged: if (activeFocus) root.page.noteEdited(text.slice(0, 4000))
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                visible: root.page.showShield
                spacing: 7
                Icon { name: "shield"; size: 15; color: Theme.green; anchors.verticalCenter: parent.verticalCenter }
                Text { text: Number(root.page.blocked).toLocaleString(root.page.locale_, "f", 0) + Lang.t(" reklam ve izleyici engellendi", " ads and trackers blocked"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                color: Theme.danger
                font.family: Theme.ui
                font.pixelSize: 12
            }
        }
    }

    Row {
        anchors { right: parent.right; top: parent.top; margins: 14 }
        spacing: 8
        TextButton { visible: root.page.total > 0; text: Lang.t("Yer imleri", "Bookmarks"); onClicked: root.page.manage() }
        TextButton { text: Lang.t("Özelleştir", "Customise"); onClicked: root.page.customize() }
    }
}
