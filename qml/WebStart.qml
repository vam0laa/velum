import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The webcore start page (the easter egg): the time over a sky, and small windows for
// searching, your sites and, if wanted, a few extras. "page" holds the data.
Item {
    id: root
    property Item page
    property alias field: search

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Backdrop { anchors.fill: parent; mode: "sky" }

    component Window_: Panel {
        Layout.fillWidth: true
        fill: Qt.alpha(Theme.surface, 0.94)
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 96)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 48, 640)
            x: (parent.width - width) / 2
            y: Math.max(24, (parent.height - implicitHeight) * 0.4)
            spacing: 22
            opacity: root.arrived
            transform: Translate { y: (1 - root.arrived) * 18 }

            // the clock, with the colours of a badly tuned screen
            ColumnLayout {
                Layout.fillWidth: true
                visible: page.showClock
                spacing: 0
                Item {
                    id: clock
                    readonly property string time: Qt.formatTime(page.now, "HH:mm")
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: face.implicitWidth
                    implicitHeight: face.implicitHeight
                    component Digits: Text { text: clock.time; font.family: Theme.ui; font.pixelSize: Theme.size(128); font.letterSpacing: 4 }
                    Digits { y: 7; color: Theme.night ? "#00031c" : "#000a66" }
                    Digits { x: -5; color: Theme.night ? "#3a9fb8" : "#3ff5ff" }
                    Digits { x: 5; color: Theme.night ? "#b0479c" : "#ff3fd0" }
                    Digits { id: face; color: Theme.night ? "#dfe8ff" : "#ffffff" }
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "★ " + page.locale_.dayName(page.now.getDay()).toLocaleLowerCase() + " · " + page.now.getDate() + " " + page.locale_.monthName(page.now.getMonth()).toLocaleLowerCase() + " · " + page.greeting(page.now.getHours()) + " ★"
                    color: !true ? Theme.text : Theme.night ? "#b9c8ee" : "#eef5ff"
                    style: true ? Text.Raised : Text.Normal
                    styleColor: "#000a66"
                    font.family: Theme.ui; font.pixelSize: Theme.size(24)
                    wrapMode: Text.WordWrap
                }
            }

            Window_ {
                implicitHeight: 88
                title: "ara.exe"
                RowLayout {
                    anchors { fill: parent; margins: 11 }
                    spacing: 12
                    AddressField {
                        id: search
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.family: Theme.ui; font.pixelSize: Theme.size(20)
                        onGo: target => page.go(target)
                    }
                    TextButton { Layout.fillHeight: true; Layout.rightMargin: 3; text: "ENTER"; strong: true; onClicked: search.accepted() }
                }
            }

            Window_ {
                title: Lang.t("favoriler", "favourites")
                implicitHeight: 28 + tiles.height + 30 + (adding.visible ? 44 : 0)

                Flow {
                    id: tiles
                    readonly property int cell: 88
                    readonly property int count: page.shortcuts.length + (page.shortcuts.length < 10 ? 1 : 0)
                    readonly property int across: Math.max(1, Math.min(count, Math.floor((parent.width - 24 + spacing) / (cell + spacing))))
                    anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }
                    width: across * (cell + spacing) - spacing
                    spacing: 6

                    Repeater {
                        model: page.shortcuts
                        AbstractButton {
                            id: tile
                            required property int index
                            required property var modelData
                            implicitWidth: tiles.cell
                            implicitHeight: 86
                            hoverEnabled: true
                            onClicked: page.go(modelData.url)
                            background: Rectangle { color: tile.hovered ? Theme.title : "transparent" }
                            contentItem: Item {
                                SiteIcon {
                                    id: letter
                                    anchors { top: parent.top; topMargin: tile.down ? 10 : 6; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: tile.down ? 3 : 0 }
                                    title: String(tile.modelData.title)
                                    file: page.iconFor(tile.modelData.url)
                                    lifted: !tile.down
                                }
                                Text {
                                    anchors { bottom: parent.bottom; bottomMargin: 3; left: parent.left; right: parent.right; leftMargin: 3; rightMargin: 3 }
                                    text: tile.modelData.title
                                    textFormat: Text.PlainText
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: Theme.text
                                    font.family: Theme.ui; font.pixelSize: Theme.size(17)
                                }
                                IconButton {
                                    anchors { top: parent.top; right: parent.right }
                                    flat: true
                                    implicitWidth: 20; implicitHeight: 20; iconSize: 12
                                    symbol: "close"
                                    hint: Lang.t("Yer imini kaldır", "Remove the bookmark")
                                    visible: tile.hovered || hovered
                                    onClicked: page.removeShortcut(tile.index)
                                }
                            }
                        }
                    }
                    AbstractButton {
                        id: plus
                        implicitWidth: tiles.cell
                        implicitHeight: 86
                        hoverEnabled: true
                        visible: page.shortcuts.length < 10
                        onClicked: { adding.visible = true; adding.forceActiveFocus() }
                        Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                        background: Rectangle { color: plus.hovered ? Theme.title : "transparent" }
                        contentItem: Item {
                            Rectangle {
                                anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
                                width: 52; height: 52
                                color: "transparent"
                                border.width: 2
                                border.color: Theme.line
                                Icon { anchors.centerIn: parent; name: "plus"; size: 22; color: Theme.accent }
                            }
                            Text { anchors { bottom: parent.bottom; bottomMargin: 3; horizontalCenter: parent.horizontalCenter } text: Lang.t("ekle", "add"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(17) }
                        }
                    }
                }
                AddressField {
                    id: adding
                    visible: false
                    anchors { left: parent.left; right: parent.right; top: tiles.bottom; margins: 12; topMargin: 8 }
                    accent: Theme.pink
                    placeholderText: Lang.t("yer imi adresi, örn. vamola.dev (Enter)_", "bookmark address, e.g. vamola.dev (Enter)_")
                    onAccepted: { page.addShortcut(text); text = ""; visible = false }
                    Keys.onEscapePressed: { text = ""; visible = false }
                    // the base field would navigate; here Enter only adds
                    onGo: {}
                }
            }

            // the extras, side by side while there is room
            GridLayout {
                Layout.fillWidth: true
                columns: column.width >= 520 ? 2 : 1
                columnSpacing: 22
                rowSpacing: 22

                Window_ {
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    visible: page.showShield
                    implicitHeight: 100
                    title: Lang.t("uyarı", "notice")
                    RowLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 12
                        Rectangle { implicitWidth: 42; implicitHeight: 42; color: Theme.accent; Text { anchors.centerIn: parent; text: "!"; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: Theme.size(38) } }
                        Text { Layout.fillWidth: true; text: Number(page.blocked).toLocaleString(page.locale_, "f", 0) + Lang.t(" izleyici ve reklam içeri alınmadı.", " trackers and ads were kept out."); color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(19); wrapMode: Text.WordWrap }
                    }
                }
                Window_ {
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    visible: page.showFrequent && page.frequent.length > 0
                    implicitHeight: places.implicitHeight + 44
                    title: Lang.t("sık gidilenler", "most visited")
                    Column {
                        id: places
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                        Repeater {
                            model: page.frequent
                            AbstractButton {
                                id: place
                                required property var modelData
                                width: places.width
                                height: 24
                                hoverEnabled: true
                                onClicked: page.go(modelData.url)
                                background: Rectangle { color: place.hovered ? Theme.title : "transparent" }
                                contentItem: Text { leftPadding: 6; rightPadding: 6; text: "> " + place.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17) }
                            }
                        }
                    }
                }
                Window_ {
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    visible: page.showNote
                    implicitHeight: Math.max(120, Math.min(240, memo.implicitHeight + 44))
                    title: "not.txt"
                    ScrollView {
                        anchors { fill: parent; margins: 4 }
                        TextArea {
                            id: memo
                            text: page.note
                            textFormat: TextEdit.PlainText
                            wrapMode: TextEdit.Wrap
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentInk
                            placeholderText: Lang.t("aklındakini yaz, bu bilgisayarda kalır_", "jot something down, it stays here_")
                            placeholderTextColor: Theme.dim
                            font.family: Theme.ui; font.pixelSize: Theme.size(18)
                            background: null
                            onTextChanged: if (activeFocus) page.noteEdited(text.slice(0, 4000))
                        }
                    }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                color: true ? "#ffffff" : Theme.danger
                font.family: Theme.ui; font.pixelSize: Theme.size(17)
            }
        }
    }

    // scan lines over the sky
    Image { anchors.fill: parent; visible: true; opacity: Theme.night ? 0.6 : 1; source: Qt.resolvedUrl("../data/scanline.png"); fillMode: Image.Tile; smooth: false }

    // corner buttons
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 12 }
        spacing: 10
        IconButton { visible: page.total > 0; symbol: "star"; hint: Lang.t("Bütün yer imleri (", "All bookmarks (") + page.total + ")"; onClicked: page.manage() }
        IconButton { symbol: "settings"; hint: Lang.t("Bu sayfayı özelleştir", "Customise this page"); onClicked: page.customize() }
    }
}
