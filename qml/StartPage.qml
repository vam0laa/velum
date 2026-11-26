import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What an empty tab shows: a greeting, the time and date, search and bookmarks.
// It asks the network for nothing, not even site icons.
Rectangle {
    id: page
    property alias field: search
    property bool hasWidevine
    property var shortcuts: []
    property date now: new Date()
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)

    function greeting(hour) {
        if (hour < 5) return Lang.t("İyi geceler", "Good night")
        if (hour < 12) return Lang.t("Günaydın", "Good morning")
        if (hour < 18) return Lang.t("İyi günler", "Good afternoon")
        return Lang.t("İyi akşamlar", "Good evening")
    }

    color: Theme.surface

    Timer { interval: 1000; repeat: true; running: page.visible; triggeredOnStart: true; onTriggered: page.now = new Date() }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 64)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 56, 640)
            x: (parent.width - width) / 2
            y: Math.max(32, (parent.height - implicitHeight) / 2)
            spacing: 20

            ColumnLayout {
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: page.greeting(page.now.getHours()) + ","
                    color: Theme.text
                    font.pixelSize: 48
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -1.5
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: headline
                    property int word: 0
                    readonly property var words: [Lang.t("sakin gez.", "browse calmly."), Lang.t("iz bırakma.", "leave no trace."), Lang.t("reklamsız oku.", "read without ads.")]
                    Layout.fillWidth: true
                    Layout.topMargin: -6
                    text: words[word % words.length]
                    color: Theme.rainbow[word % Theme.rainbow.length]
                    font.pixelSize: 48
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -1.5
                    wrapMode: Text.WordWrap
                    Behavior on color { ColorAnimation { duration: 400 } }
                    Timer { interval: 3600; repeat: true; running: page.visible; onTriggered: headline.word++ }
                }
            }

            // two small windows: time and date
            RowLayout {
                spacing: 14
                Panel {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    title: Lang.t("saat", "clock")
                    stripe: Theme.green
                    fill: Theme.window
                    Text { anchors.centerIn: parent; text: Qt.formatTime(page.now, "HH:mm"); color: Theme.text; font.pixelSize: 46; font.weight: Font.ExtraBold; font.letterSpacing: -1 }
                }
                Panel {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    title: Lang.t("tarih", "date")
                    stripe: Theme.mauve
                    fill: Theme.window
                    Row {
                        anchors.centerIn: parent
                        spacing: 14
                        Text { text: page.now.getDate(); color: Theme.mauve; font.pixelSize: 46; font.weight: Font.ExtraBold; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: page.locale_.monthName(page.now.getMonth()); color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                            Text { text: page.locale_.dayName(page.now.getDay()); color: Theme.dim; font.pixelSize: 13 }
                        }
                    }
                }
            }

            AddressField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50
                font.pixelSize: 15
                onGo: target => page.go(target)
            }

            // bookmarks
            Flow {
                id: tiles
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: page.shortcuts
                    AbstractButton {
                        id: tile
                        required property int index
                        required property var modelData
                        readonly property color tone: Theme.rainbow[index % Theme.rainbow.length]
                        implicitWidth: 98
                        implicitHeight: 92
                        hoverEnabled: true
                        onClicked: page.go(modelData.url)
                        background: Rectangle {
                            radius: Theme.corner
                            color: tile.hovered ? Theme.raised : Theme.window
                            border.color: Theme.line
                            Behavior on color { ColorAnimation { duration: Theme.quick } }
                        }
                        contentItem: Item {
                            Rectangle {
                                id: letter
                                width: 42; height: 42; radius: 13
                                anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
                                color: tile.tone
                                Text { anchors.centerIn: parent; text: String(tile.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.onAccent; font.pixelSize: 20; font.weight: Font.ExtraBold }
                            }
                            Text {
                                anchors { top: letter.bottom; topMargin: 7; left: parent.left; right: parent.right; margins: 6 }
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
                    implicitWidth: 98
                    implicitHeight: 92
                    hoverEnabled: true
                    visible: page.shortcuts.length < 10
                    onClicked: { adding.visible = true; adding.forceActiveFocus() }
                    Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                    background: Rectangle { radius: Theme.corner; color: plus.hovered ? Theme.raised : "transparent"; border.color: Theme.line }
                    contentItem: Column {
                        topPadding: 24
                        spacing: 8
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
