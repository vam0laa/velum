import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What an empty tab shows: the time, search and your sites, in the middle. Anything
// more is switched on in the settings. It asks the network for nothing.
Rectangle {
    id: page
    property alias field: search
    property bool hasWidevine
    property var shortcuts: []
    property int total: 0               // all bookmarks, also those not shown here
    property var frequent: []           // [{ url, title }] from the history
    property double blocked: 0          // requests the shield has stopped so far
    property string note: ""
    property string background: "glow"
    property string picture: ""
    property bool showClock: true
    property bool showShield: false
    property bool showNote: false
    property bool showFrequent: false
    property var iconFor: url => ""     // the saved icon of a site
    property date now: new Date()
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)
    signal manage()
    signal noteEdited(string text)
    signal customize()

    color: Theme.sheetBack

    // 0 → 1 each time the page is shown
    property real arrived: 1
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 2; easing.type: Easing.OutCubic }
    onVisibleChanged: if (visible) entrance.restart()

    Timer { interval: 1000; repeat: true; running: page.visible; triggeredOnStart: true; onTriggered: page.now = new Date() }

    Backdrop { anchors.fill: parent; mode: page.background; picture: page.picture }

    component Box: Rectangle {
        Layout.fillWidth: true
        radius: Theme.corner
        color: Qt.alpha(Theme.window, 0.82)
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 96)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 40, 580)
            x: (parent.width - width) / 2
            // a little above the middle, where the eye rests
            y: Math.max(32, (parent.height - implicitHeight) * 0.42)
            spacing: 24
            opacity: page.arrived
            transform: Translate { y: (1 - page.arrived) * 16 }

            Column {
                Layout.alignment: Qt.AlignHCenter
                visible: page.showClock
                spacing: -4
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(page.now, "HH:mm"); color: Theme.text; font.pixelSize: 64; font.weight: Font.ExtraBold; font.letterSpacing: -2 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.locale_.dayName(page.now.getDay()) + ", " + page.now.getDate() + " " + page.locale_.monthName(page.now.getMonth()); color: Theme.dim; font.pixelSize: 15 }
            }

            AddressField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50
                font.pixelSize: 15
                onGo: target => page.go(target)
            }

            // your sites: icons with their names, in the middle
            Flow {
                id: tiles
                readonly property int cell: 76
                readonly property int count: page.shortcuts.length + (page.shortcuts.length < 10 ? 1 : 0)
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.max(1, Math.min(count, Math.floor((column.width + spacing) / (cell + spacing)))) * (cell + spacing) - spacing
                spacing: 8

                Repeater {
                    model: page.shortcuts
                    AbstractButton {
                        id: tile
                        required property int index
                        required property var modelData
                        implicitWidth: tiles.cell
                        implicitHeight: 82
                        hoverEnabled: true
                        scale: down ? 0.95 : 1
                        onClicked: page.go(modelData.url)
                        background: Rectangle { radius: Theme.corner; color: tile.hovered ? Qt.alpha(Theme.raised, 0.85) : "transparent"; Behavior on color { ColorAnimation { duration: Theme.quick } } }
                        contentItem: Item {
                            SiteIcon {
                                id: letter
                                anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                                title: String(tile.modelData.title)
                                file: page.iconFor(tile.modelData.url)
                                tone: Theme.rainbow[tile.index % Theme.rainbow.length]
                            }
                            Text {
                                anchors { top: letter.bottom; topMargin: 6; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
                                text: tile.modelData.title
                                textFormat: Text.PlainText
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: Theme.text
                                font.pixelSize: 12
                            }
                            IconButton {
                                anchors { top: parent.top; right: parent.right; margins: 1 }
                                implicitWidth: 20; implicitHeight: 20; iconSize: 11
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
                    implicitHeight: 82
                    hoverEnabled: true
                    visible: page.shortcuts.length < 10
                    onClicked: { adding.visible = true; adding.forceActiveFocus() }
                    Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                    background: Rectangle { radius: Theme.corner; color: plus.hovered ? Qt.alpha(Theme.raised, 0.85) : "transparent" }
                    contentItem: Item {
                        Rectangle {
                            id: ring
                            anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                            width: 44; height: 44; radius: 14
                            color: "transparent"
                            border.color: Theme.line
                            Icon { anchors.centerIn: parent; name: "plus"; size: 20; color: Theme.dim }
                        }
                        Text { anchors { top: ring.bottom; topMargin: 6; horizontalCenter: parent.horizontalCenter } text: Lang.t("Ekle", "Add"); color: Theme.dim; font.pixelSize: 12 }
                    }
                }
            }
            AddressField {
                id: adding
                visible: false
                Layout.fillWidth: true
                accent: Theme.peach
                placeholderText: Lang.t("Yer imi adresi, örn. vamola.dev (Enter)", "Bookmark address, e.g. vamola.dev (Enter)")
                onAccepted: { page.addShortcut(text); text = ""; visible = false }
                Keys.onEscapePressed: { text = ""; visible = false }
                // the base field would navigate; here Enter only adds
                onGo: {}
            }

            // the extras, each only if switched on
            Box {
                visible: page.showShield
                implicitHeight: 52
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon { name: "shield"; size: 18; color: Theme.green; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Number(page.blocked).toLocaleString(page.locale_, "f", 0); color: Theme.text; font.pixelSize: 17; font.weight: Font.ExtraBold; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Lang.t("reklam ve izleyici engellendi", "ads and trackers blocked"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Box {
                visible: page.showFrequent && page.frequent.length > 0
                implicitHeight: places.implicitHeight + 16
                Column {
                    id: places
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                    Repeater {
                        model: page.frequent
                        AbstractButton {
                            id: place
                            required property var modelData
                            width: places.width
                            height: 30
                            hoverEnabled: true
                            onClicked: page.go(modelData.url)
                            background: Rectangle { radius: 8; color: place.hovered ? Theme.raised : "transparent" }
                            contentItem: Text { leftPadding: 10; rightPadding: 10; text: place.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; color: Theme.text; font.pixelSize: 12 }
                        }
                    }
                }
            }
            Box {
                visible: page.showNote
                implicitHeight: Math.max(88, Math.min(220, memo.implicitHeight + 8))
                ScrollView {
                    anchors { fill: parent; margins: 4 }
                    TextArea {
                        id: memo
                        text: page.note
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.onAccent
                        placeholderText: Lang.t("Not: aklındakini yaz, bu bilgisayarda kalır.", "Note: jot something down, it stays on this computer.")
                        placeholderTextColor: Theme.dim
                        font.pixelSize: 13
                        background: null
                        onTextChanged: if (activeFocus) page.noteEdited(text.slice(0, 4000))
                    }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                color: Theme.danger
                font.pixelSize: 12
            }
        }
    }

    // quiet corner buttons
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        spacing: 4
        IconButton { visible: page.total > 0; symbol: "star"; hint: Lang.t("Bütün yer imleri (", "All bookmarks (") + page.total + ")"; tone: Theme.dim; onClicked: page.manage() }
        IconButton { symbol: "settings"; hint: Lang.t("Bu sayfayı özelleştir", "Customise this page"); tone: Theme.dim; onClicked: page.customize() }
    }
}
