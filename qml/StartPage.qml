import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What an empty tab shows: a greeting, the date and time, search and bookmarks,
// dressed like vamola.dev. It asks the network for nothing, not even site icons.
Rectangle {
    id: page
    property alias field: search
    property bool hasWidevine
    property var shortcuts: []
    property date now: new Date()
    readonly property bool wide: width >= 860
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)

    function greeting(hour) {
        if (hour < 5) return Lang.t("İyi geceler", "Good night")
        if (hour < 12) return Lang.t("Günaydın", "Good morning")
        if (hour < 18) return Lang.t("İyi günler", "Good afternoon")
        return Lang.t("İyi akşamlar", "Good evening")
    }
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")

    color: Theme.frame

    Timer { interval: 1000; repeat: true; running: page.visible; triggeredOnStart: true; onTriggered: page.now = new Date() }

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(height, column.implicitHeight + 64)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(parent.width - 56, 900)
            x: (parent.width - width) / 2
            y: Math.max(32, (parent.height - implicitHeight) / 2)
            spacing: 22

            // headline and widgets
            GridLayout {
                Layout.fillWidth: true
                columns: page.wide ? 2 : 1
                columnSpacing: 30
                rowSpacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Kicker { text: "velum · " + page.locale_.dayName(page.now.getDay()).toLocaleLowerCase() }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        text: page.greeting(page.now.getHours()) + ","
                        color: Theme.text
                        font.pixelSize: 54
                        font.weight: Font.ExtraBold
                        font.letterSpacing: -1.5
                        wrapMode: Text.WordWrap
                        lineHeight: 0.92
                    }
                    Text {
                        id: headline
                        property int word: 0
                        readonly property var words: [Lang.t("sakin gez.", "browse calmly."), Lang.t("iz bırakma.", "leave no trace."), Lang.t("reklamsız oku.", "read without ads.")]
                        Layout.fillWidth: true
                        text: words[word % words.length]
                        color: Theme.rainbow[word % Theme.rainbow.length]
                        font.pixelSize: 54
                        font.weight: Font.ExtraBold
                        font.letterSpacing: -1.5
                        wrapMode: Text.WordWrap
                        Timer { interval: 3200; repeat: true; running: page.visible; onTriggered: headline.word++ }
                    }
                }

                RowLayout {
                    spacing: 14
                    Layout.alignment: page.wide ? Qt.AlignRight : Qt.AlignLeft
                    // the date tile
                    Bevel {
                        implicitWidth: 132
                        implicitHeight: 140
                        color: Theme.accent
                        radius: 18
                        edge: 0
                        Column {
                            anchors.centerIn: parent
                            spacing: -6
                            Text { text: page.locale_.dayName(page.now.getDay(), Locale.ShortFormat); color: Theme.onAccent; font.pixelSize: 15; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: page.now.getDate(); color: Theme.onAccent; font.pixelSize: 66; font.weight: Font.ExtraBold; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: page.locale_.monthName(page.now.getMonth()); color: Theme.onAccent; font.pixelSize: 15; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                    Panel {
                        implicitWidth: 196
                        implicitHeight: 140
                        title: "clock.exe"
                        stripe: Theme.green
                        Rectangle {
                            anchors { fill: parent; margins: 6 }
                            color: Theme.frame
                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatTime(page.now, "HH:mm:ss")
                                color: Theme.green
                                font.family: Theme.pixel
                                font.pixelSize: 46
                            }
                        }
                    }
                }
            }

            // search
            Panel {
                Layout.fillWidth: true
                implicitHeight: 100
                title: "search.exe — " + Address.engineName
                stripe: Theme.pink
                AddressField {
                    id: search
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                    implicitHeight: 44
                    font.pixelSize: 15
                    onGo: target => page.go(target)
                }
            }

            // bookmarks, each a small window
            Panel {
                Layout.fillWidth: true
                implicitHeight: tiles.implicitHeight + 62 + (adding.visible ? 48 : 0)
                title: Lang.t("yer_imleri.dir", "bookmarks.dir")
                stripe: Theme.peach

                ColumnLayout {
                    anchors { fill: parent; margins: 12 }
                    spacing: 10
                    Flow {
                        id: tiles
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: page.shortcuts
                            AbstractButton {
                                id: tile
                                required property int index
                                required property var modelData
                                readonly property color tone: Theme.rainbow[index % Theme.rainbow.length]
                                implicitWidth: 100
                                implicitHeight: 92
                                hoverEnabled: true
                                onClicked: page.go(modelData.url)
                                background: Bevel { sunken: tile.down; color: tile.hovered ? Theme.title : Theme.raised }
                                contentItem: Item {
                                    Rectangle {
                                        id: letter
                                        width: 44; height: 44; radius: 12
                                        anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                                        color: tile.tone
                                        Text { anchors.centerIn: parent; text: String(tile.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.onAccent; font.pixelSize: 22; font.weight: Font.ExtraBold }
                                    }
                                    Text {
                                        anchors { top: letter.bottom; topMargin: 6; left: parent.left; right: parent.right; margins: 6 }
                                        text: tile.modelData.title
                                        textFormat: Text.PlainText
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        color: Theme.text
                                        font.family: Theme.pixel
                                        font.pixelSize: 17
                                    }
                                    IconButton {
                                        anchors { top: parent.top; right: parent.right; margins: 3 }
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
                            implicitWidth: 100
                            implicitHeight: 92
                            hoverEnabled: true
                            visible: page.shortcuts.length < 10
                            onClicked: { adding.visible = true; adding.forceActiveFocus() }
                            Accessible.name: Lang.t("Yer imi ekle", "Add a bookmark")
                            background: Bevel { sunken: true; color: plus.hovered ? Theme.surface : Theme.frame }
                            contentItem: Column {
                                topPadding: 20
                                spacing: 6
                                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "plus"; size: 26; color: Theme.accent }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Lang.t("ekle", "add"); color: Theme.dim; font.family: Theme.pixel; font.pixelSize: 17 }
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
                }
            }

            // the little buttons
            Flow {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(column.width, 4 * 96 + 3 * 8)
                spacing: 8
                Badge88 { upper: "NO ADS"; lower: "NO TRACKERS"; tone: Theme.green }
                Badge88 { upper: "ARCH"; lower: "LINUX"; tone: Theme.accent }
                Badge88 { upper: "QT + RUST"; lower: "OPEN SOURCE"; tone: Theme.peach }
                Badge88 { upper: "MADE BY"; lower: "VAMOLA"; tone: Theme.mauve }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !page.hasWidevine
                text: Lang.t("Widevine bulunamadı: Netflix gibi korumalı yayınlar açılmaz.", "Widevine not found: protected video such as Netflix will not play.")
                color: Theme.danger
                font.family: Theme.pixel
                font.pixelSize: 18
            }
        }
    }
}
