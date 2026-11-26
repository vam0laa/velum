import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What an empty tab shows: a greeting, widgets, search, bookmarks and the places you go
// most. Everything on it comes from this computer; it asks the network for nothing.
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
    property bool showShield: true
    property bool showNote: true
    property bool showFrequent: true
    property var iconFor: url => ""     // the saved icon of a site
    property date now: new Date()
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")
    readonly property bool wide: column.width >= 600
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)
    signal manage()
    signal noteEdited(string text)
    signal customize()

    function greeting(hour) {
        if (hour < 5) return Lang.t("İyi geceler", "Good night")
        if (hour < 12) return Lang.t("Günaydın", "Good morning")
        if (hour < 18) return Lang.t("İyi günler", "Good afternoon")
        return Lang.t("İyi akşamlar", "Good evening")
    }

    color: Theme.sheetBack

    // 0 → 1 each time the page is shown; part i rises when its turn comes
    property real arrived: 1
    function rise(i) { return Math.max(0, Math.min(1, arrived * 2.6 - i * 0.28)) }
    NumberAnimation on arrived { id: entrance; running: false; from: 0; to: 1; duration: Theme.smooth * 3 }
    onVisibleChanged: if (visible) entrance.restart()

    component Rise: Translate {
        property int order
        y: (1 - page.rise(order)) * 26
    }

    Timer { interval: 1000; repeat: true; running: page.visible; triggeredOnStart: true; onTriggered: page.now = new Date() }

    Backdrop { anchors.fill: parent; mode: page.background; picture: page.picture }

    component Widget: Panel {
        Layout.fillWidth: true
        implicitHeight: 118
        Layout.preferredWidth: 1
        fill: Qt.alpha(Theme.window, 0.86)
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 72)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 48, 780)
            x: (parent.width - width) / 2
            y: Math.max(30, (parent.height - implicitHeight) / 2)
            spacing: 20

            ColumnLayout {
                spacing: 0
                opacity: page.rise(0)
                transform: Rise { order: 0 }
                Text {
                    Layout.fillWidth: true
                    text: page.greeting(page.now.getHours()) + ","
                    color: Theme.text
                    font.pixelSize: page.wide ? 56 : 40
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -1.5
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: headline
                    property int word: 0
                    readonly property var words: [Lang.t("sakin gez.", "browse calmly."), Lang.t("iz bırakma.", "leave no trace."), Lang.t("reklamsız oku.", "read without ads.")]
                    Layout.fillWidth: true
                    Layout.topMargin: -8
                    text: words[word % words.length]
                    color: Theme.rainbow[word % Theme.rainbow.length]
                    font.pixelSize: page.wide ? 56 : 40
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -1.5
                    wrapMode: Text.WordWrap
                    Behavior on color { ColorAnimation { duration: 400 } }
                    Timer { interval: 3600; repeat: true; running: page.visible; onTriggered: headline.word++ }
                }
            }

            AddressField {
                id: search
                opacity: page.rise(1)
                transform: Rise { order: 1 }
                Layout.fillWidth: true
                implicitHeight: 52
                font.pixelSize: 15
                onGo: target => page.go(target)
            }

            // widgets, each a small window
            GridLayout {
                Layout.fillWidth: true
                columns: page.wide ? 3 : 2
                columnSpacing: 14
                rowSpacing: 14
                visible: page.showClock || page.showShield
                opacity: page.rise(2)
                transform: Rise { order: 2 }

                Widget {
                    visible: page.showClock
                    title: Lang.t("saat", "clock")
                    stripe: Theme.green
                    Text { anchors.centerIn: parent; text: Qt.formatTime(page.now, "HH:mm"); color: Theme.text; font.pixelSize: 46; font.weight: Font.ExtraBold; font.letterSpacing: -1 }
                }
                Widget {
                    visible: page.showClock
                    title: Lang.t("tarih", "date")
                    stripe: Theme.mauve
                    Row {
                        anchors.centerIn: parent
                        spacing: 12
                        Text { text: page.now.getDate(); color: Theme.mauve; font.pixelSize: 46; font.weight: Font.ExtraBold; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: page.locale_.monthName(page.now.getMonth()); color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                            Text { text: page.locale_.dayName(page.now.getDay()); color: Theme.dim; font.pixelSize: 13 }
                        }
                    }
                }
                Widget {
                    Layout.columnSpan: page.wide ? 1 : 2
                    visible: page.showShield
                    title: Lang.t("kalkan", "shield")
                    stripe: Theme.peach
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Number(page.blocked).toLocaleString(page.locale_, "f", 0); color: Theme.peach; font.pixelSize: 40; font.weight: Font.ExtraBold; font.letterSpacing: -1 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Lang.t("reklam ve izleyici engellendi", "ads and trackers blocked"); color: Theme.dim; font.pixelSize: 12 }
                    }
                }
            }

            // bookmarks
            Flow {
                id: tiles
                opacity: page.rise(3)
                transform: Rise { order: 3 }
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: page.shortcuts
                    AbstractButton {
                        id: tile
                        required property int index
                        required property var modelData
                        readonly property color tone: Theme.rainbow[index % Theme.rainbow.length]
                        implicitWidth: 104
                        implicitHeight: 100
                        hoverEnabled: true
                        scale: down ? 0.96 : hovered ? 1.05 : 1
                        z: hovered ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutBack } }
                        onClicked: page.go(modelData.url)
                        background: Rectangle {
                            radius: Theme.corner
                            color: tile.hovered ? Theme.raised : Qt.alpha(Theme.window, 0.86)
                            border.color: tile.hovered ? tile.tone : Theme.line
                            Behavior on color { ColorAnimation { duration: Theme.quick } }
                        }
                        contentItem: Item {
                            SiteIcon {
                                id: letter
                                anchors { top: parent.top; topMargin: tile.hovered ? 10 : 13; horizontalCenter: parent.horizontalCenter }
                                title: String(tile.modelData.title)
                                file: page.iconFor(tile.modelData.url)
                                tone: tile.tone
                                Behavior on anchors.topMargin { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
                            }
                            Text {
                                anchors { bottom: parent.bottom; bottomMargin: 12; left: parent.left; right: parent.right; margins: 6 }
                                text: tile.modelData.title
                                textFormat: Text.PlainText
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: Theme.text
                                font.pixelSize: 12
                            }
                            IconButton {
                                anchors { top: parent.top; right: parent.right; margins: 3 }
                                implicitWidth: 22; implicitHeight: 22; iconSize: 12
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
                    implicitWidth: 104
                    implicitHeight: 100
                    hoverEnabled: true
                    visible: page.shortcuts.length < 10
                    onClicked: { adding.visible = true; adding.forceActiveFocus() }
                    Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                    background: Rectangle { radius: Theme.corner; color: plus.hovered ? Theme.raised : "transparent"; border.color: Theme.line }
                    contentItem: Column {
                        topPadding: 26
                        spacing: 10
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "plus"; size: 22; color: Theme.dim }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Lang.t("Ekle", "Add"); color: Theme.dim; font.pixelSize: 12 }
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

            GridLayout {
                opacity: page.rise(4)
                transform: Rise { order: 4 }
                Layout.fillWidth: true
                columns: page.wide ? 2 : 1
                columnSpacing: 14
                rowSpacing: 14

                Panel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    visible: page.showFrequent && page.frequent.length > 0
                    implicitHeight: places.implicitHeight + 52
                    fill: Qt.alpha(Theme.window, 0.86)
                    title: Lang.t("sık gidilenler", "most visited")
                    stripe: Theme.pink
                    Column {
                        id: places
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                        Repeater {
                            model: page.frequent
                            AbstractButton {
                                id: place
                                required property var modelData
                                required property int index
                                width: places.width
                                height: 30
                                hoverEnabled: true
                                onClicked: page.go(modelData.url)
                                background: Rectangle { radius: 8; color: place.hovered ? Theme.raised : "transparent" }
                                contentItem: Item {
                                    Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.rainbow[place.index % Theme.rainbow.length] }
                                    Text { anchors { left: parent.left; leftMargin: 26; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } text: place.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.pixelSize: 12 }
                                }
                            }
                        }
                    }
                }
                Panel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    visible: page.showNote
                    implicitHeight: Math.max(150, Math.min(260, memo.implicitHeight + 52))
                    fill: Qt.alpha(Theme.window, 0.86)
                    title: Lang.t("not", "note")
                    stripe: Theme.accent
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
                            placeholderText: Lang.t("Aklındakini yaz; bu bilgisayarda kalır.", "Jot something down; it stays on this computer.")
                            placeholderTextColor: Theme.dim
                            font.pixelSize: 13
                            background: null
                            onTextChanged: if (activeFocus) page.noteEdited(text.slice(0, 4000))
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                TextButton { visible: page.total > 0; text: Lang.t("Bütün yer imleri (", "All bookmarks (") + page.total + ")"; onClicked: page.manage() }
                TextButton { text: Lang.t("Bu sayfayı özelleştir", "Customise this page"); onClicked: page.customize() }
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
}
