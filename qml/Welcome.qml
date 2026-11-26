import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The first start: language, theme, layout and search, one page at a time.
// Everything chosen here can be changed later in the settings.
Popup {
    id: welcome
    property int step: 0
    readonly property int steps: 5
    property bool horizontalTabs
    signal layoutChosen(bool horizontal)
    signal importRequested()
    signal finished()

    function next() {
        if (step < steps - 1)
            step++
        else
            finish()
    }
    function back() { step = Math.max(0, step - 1) }
    function finish() {
        close()
        finished()
    }
    onAboutToShow: step = 0

    readonly property var headlines: [
        [Lang.t("Hoş geldin.", "Welcome."), Lang.t("Velum'u dört kısa adımda sana göre ayarlayalım.", "Four short steps to make Velum yours.")],
        [Lang.t("Rengini seç.", "Pick your colours."), Lang.t("Tema ve vurgu rengi anında değişir.", "The theme and accent change as you click.")],
        [Lang.t("Sekmeler nerede?", "Where do tabs go?"), Lang.t("Yanda ya da üstte.", "Down the side or along the top.")],
        [Lang.t("Arama ve veriler.", "Search and your things."), Lang.t("Hangi motorla arayacaksın? Eski tarayıcından yer imlerini de alabilirsin.", "Which search engine? You can also bring bookmarks from your old browser.")],
        [Lang.t("Hazırsın.", "You are set."), Lang.t("Hepsi ayarlarda durur (Ctrl+,). Her şey için komut kutusu: Ctrl+K.", "All of this stays in the settings (Ctrl+,). The command box does everything else: Ctrl+K.")]
    ]

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(700, parent.width - 24)
    height: Math.min(660, parent.height - 24)
    modal: true
    closePolicy: Popup.CloseOnEscape
    onClosed: finished()
    padding: 0
    Overlay.modal: Rectangle { color: Qt.alpha(Theme.frame, 0.94) }
    background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: Theme.line }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.smooth } }

    ColumnLayout {
        anchors { fill: parent; margins: 30 }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: welcome.steps
                Rectangle {
                    required property int index
                    implicitWidth: index === welcome.step ? 28 : 8
                    implicitHeight: 8
                    radius: Theme.radius
                    color: index <= welcome.step ? Theme.rainbow[index % Theme.rainbow.length] : Theme.raised
                    Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
                }
            }
            Item { Layout.fillWidth: true }
            Text { text: "velum"; color: Theme.mauve; font.family: Theme.ui; font.pixelSize: Theme.size(29) }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 6
            text: welcome.headlines[welcome.step][0]
            color: Theme.text
            font.family: Theme.ui; font.pixelSize: Theme.size(52)
            font.weight: Font.Normal
            font.letterSpacing: 0
            wrapMode: Text.WordWrap
        }
        Text { Layout.fillWidth: true; text: welcome.headlines[welcome.step][1]; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(18); wrapMode: Text.WordWrap }

        Flickable {
            id: area
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            contentHeight: pages.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: pages
                width: area.width
                spacing: 16

                ColumnLayout {
                    visible: welcome.step === 0
                    spacing: 16
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(192, 192); Layout.preferredWidth: 96; Layout.preferredHeight: 96 }
                    Segments {
                        options: [{ key: "auto", label: Lang.t("Sistem dili", "System language") }, { key: "tr", label: "Türkçe" }, { key: "en", label: "English" }]
                        current: Lang.choice
                        onChosen: key => Lang.choice = key
                    }
                }
                ThemePicker { visible: welcome.step === 1; Layout.fillWidth: true }
                LayoutPicker { visible: welcome.step === 2; horizontal: welcome.horizontalTabs; onChosen: h => welcome.layoutChosen(h) }
                ColumnLayout {
                    visible: welcome.step === 3
                    spacing: 14
                    Segments {
                        options: Address.engines
                        current: Address.engine
                        onChosen: key => Address.engine = key
                    }
                    TextButton { text: Lang.t("Başka tarayıcıdan içe aktar…", "Import from another browser…"); onClicked: welcome.importRequested() }
                }
                Flow {
                    visible: welcome.step === 4
                    Layout.fillWidth: true
                    spacing: 10
                    Repeater {
                        model: [["Ctrl+T", Lang.t("yeni sekme", "new tab")], ["Ctrl+K", Lang.t("komut kutusu", "command box")], ["Alt+R", Lang.t("okuma modu", "reader")], ["Alt+P", Lang.t("küçük video", "mini video")], ["Ctrl+\\", Lang.t("bölünmüş ekran", "split view")], ["Ctrl+,", Lang.t("ayarlar", "settings")]]
                        Rectangle {
                            id: tip
                            required property var modelData
                            required property int index
                            width: 190
                            height: 70
                            radius: Theme.radius
                            color: Theme.window
                            border.color: Theme.line
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[0]; color: Theme.rainbow[tip.index % Theme.rainbow.length]; font.family: Theme.ui; font.pixelSize: Theme.size(31) }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[1]; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextButton { visible: welcome.step < welcome.steps - 1; text: Lang.t("Atla", "Skip"); onClicked: welcome.finish() }
            Item { Layout.fillWidth: true }
            TextButton { visible: welcome.step > 0; text: Lang.t("Geri", "Back"); onClicked: welcome.back() }
            TextButton { text: welcome.step === welcome.steps - 1 ? Lang.t("Gezinmeye başla", "Start browsing") : Lang.t("Devam", "Continue"); strong: true; implicitHeight: 38; onClicked: welcome.next() }
        }
    }
}
