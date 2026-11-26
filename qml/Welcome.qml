import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

// The first start, over the whole window: language, colours, layout, search and a few
// extensions, one page at a time, with the choices shown as you make them.
// Everything chosen here can be changed later in the settings.
Popup {
    id: welcome
    property int step: 0
    readonly property int steps: 6
    property var installed: []          // names of the extensions already there
    property alias wanted: offers.picked
    signal extensionsChosen(var ids)    // asked for by ticking them and going on
    property bool horizontalTabs
    signal layoutChosen(bool horizontal)
    signal importRequested()
    signal finished()

    function next() {
        // leaving the extensions page with ticks is the "yes"
        if (step === 4 && offers.picked.length > 0) {
            extensionsChosen(offers.picked)
            offers.picked = []
        }
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
    onAboutToShow: { step = 0; offers.picked = [] }
    onStepChanged: { area.contentY = 0; arrive.restart() }

    // [first line, the words on the pill, what this page is for]
    readonly property var pages: [
        [Lang.t("Velum'a", "Welcome"), Lang.t("hoş geldin.", "to Velum."), Lang.t("Sakin, gizlilik odaklı tarayıcın. Birkaç kısa adımda sana göre ayarlayalım.", "Your calm, private browser. A few short steps and it is yours.")],
        [Lang.t("Rengini", "Pick your"), Lang.t("seç.", "colours."), Lang.t("Tıkladığın anda her şey değişir; yandaki küçük Velum da.", "Everything changes as you click, the little Velum too.")],
        [Lang.t("Sekmeler", "Where do"), Lang.t("nerede dursun?", "tabs go?"), Lang.t("Üstte, alışık olduğun gibi; ya da yanda, daha çok sığsın diye.", "Along the top as you know them, or down the side to fit more.")],
        [Lang.t("Aramayı", "Choose your"), Lang.t("sen seç.", "search."), Lang.t("Adres çubuğuna yazdıkların bu motora gider. Eski tarayıcından yer imlerini de alabilirsin.", "What you type in the address bar goes here. You can bring your bookmarks along too.")],
        [Lang.t("Birkaç", "A few"), Lang.t("eklenti?", "extensions?"), Lang.t("İşaretlediklerin Chrome Web Store'dan (Google) indirilip kurulur. Eklentiler gezdiğin sayfaları okuyabilir. Hiçbiri zorunlu değil; bazıları bu motorda eksik çalışabilir.", "Ticked ones are fetched from the Chrome Web Store (Google) and installed. Extensions can read the pages you visit. None is required; some may work only partly on this engine.")],
        [Lang.t("Her şey", "All"), Lang.t("hazır.", "set."), Lang.t("Hepsi ayarlarda durur (Ctrl+,). Her şey için komut kutusu: Ctrl+K.", "All of this stays in the settings (Ctrl+,). The command box does everything else: Ctrl+K.")]
    ]
    readonly property var tones: [Theme.accent, Theme.mauve, Theme.pink, Theme.green, Theme.peach, Theme.accent]
    readonly property color tone: tones[step]
    readonly property bool wide: width >= 1040

    parent: Overlay.overlay
    x: 0
    y: 0
    width: parent?.width ?? 800
    height: parent?.height ?? 600
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    onClosed: finished()
    padding: 0
    background: Rectangle { color: Theme.surface }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.smooth * 2 } }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.smooth } }

    component Label: Text { color: Theme.text; font.family: Theme.ui; textFormat: Text.PlainText }

    contentItem: Item {
        // its own sheet, so that a photograph of it is complete
        Rectangle { anchors.fill: parent; color: Theme.surface }
        focus: true
        Keys.onReturnPressed: welcome.next()
        Keys.onEnterPressed: welcome.next()
        Keys.onRightPressed: if (welcome.step < welcome.steps - 1) welcome.next()
        Keys.onLeftPressed: welcome.back()

        // slow soft light behind everything, in the colour of the page
        component Light: Shape {
            id: light
            property color glow
            property real size: 700
            width: size
            height: size
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: light.size / 2; centerY: light.size / 2; focalX: centerX; focalY: centerY
                    centerRadius: light.size / 2
                    GradientStop { position: 0; color: Qt.alpha(light.glow, 0.2) }
                    GradientStop { position: 1; color: Qt.alpha(light.glow, 0) }
                }
                PathAngleArc { centerX: light.size / 2; centerY: light.size / 2; radiusX: light.size / 2; radiusY: light.size / 2; startAngle: 0; sweepAngle: 360 }
            }
        }
        Item {
            anchors.fill: parent
            clip: true
            visible: !Theme.web
            Light {
                glow: welcome.tone
                x: -size * 0.45; y: -size * 0.4
                Behavior on glow { ColorAnimation { duration: 600 } }
                SequentialAnimation on y {
                    running: welcome.opened && Theme.moving
                    loops: Animation.Infinite
                    NumberAnimation { to: -180; duration: 7000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -300; duration: 7000; easing.type: Easing.InOutSine }
                }
            }
            Light { glow: Theme.mauve; size: 600; x: parent.width * 0.34; y: parent.height - size * 0.35 }
        }

        GridLayout {
            anchors { fill: parent; margins: welcome.wide ? 44 : 22 }
            columns: welcome.wide ? 2 : 1
            columnSpacing: 48
            rowSpacing: 16

            // ---- words and the way forward ----
            ColumnLayout {
                Layout.fillWidth: !welcome.wide
                Layout.fillHeight: welcome.wide
                Layout.preferredWidth: welcome.wide ? Math.min(520, welcome.width * 0.38) : -1
                Layout.maximumWidth: welcome.wide ? Math.min(520, welcome.width * 0.38) : -1
                spacing: 14

                Row {
                    spacing: 12
                    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(88, 88); width: 38; height: 38; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Velum"; font.pixelSize: 22; font.variableAxes: Theme.axes(800); anchors.verticalCenter: parent.verticalCenter }
                }
                Item { Layout.fillHeight: true; visible: welcome.wide }

                // where you are
                Row {
                    Layout.topMargin: welcome.wide ? 0 : 4
                    spacing: 7
                    Repeater {
                        model: welcome.steps
                        AbstractButton {
                            id: mark
                            required property int index
                            width: index === welcome.step ? 44 : 12
                            height: 12
                            enabled: index < welcome.step
                            onClicked: welcome.step = index
                            Accessible.name: String(index + 1)
                            background: Rectangle { radius: Theme.round(6); color: mark.index <= welcome.step ? welcome.tone : Theme.line; opacity: mark.index < welcome.step ? 0.55 : 1 }
                            Behavior on width { NumberAnimation { duration: Theme.smooth * 1.5; easing.type: Easing.OutBack } }
                        }
                    }
                }

                ColumnLayout {
                    id: words
                    Layout.fillWidth: true
                    spacing: 4
                    transform: Translate { id: lift }
                    Label {
                        Layout.fillWidth: true
                        text: welcome.pages[welcome.step][0]
                        font.pixelSize: welcome.wide ? Math.min(76, welcome.width * 0.046) : 40
                        font.variableAxes: Theme.axes(850)
                        font.letterSpacing: -2
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 26
                    }
                    Rectangle {
                        implicitWidth: Math.min(pill.implicitWidth + 44, words.width)
                        implicitHeight: pill.height + 8
                        radius: Theme.round(height / 2.4)
                        color: welcome.tone
                        Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth * 2; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
                        Behavior on color { ColorAnimation { duration: Theme.smooth * 2 } }
                        Label {
                            id: pill
                            x: 22; y: 4
                            width: parent.width - 44
                            text: welcome.pages[welcome.step][1]
                            color: Theme.accentInk
                            font.pixelSize: welcome.wide ? Math.min(70, welcome.width * 0.042) : 36
                            font.variableAxes: Theme.axes(850)
                            font.letterSpacing: -2
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 24
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        text: welcome.pages[welcome.step][2]
                        color: Theme.dim
                        font.pixelSize: welcome.wide ? 17 : 14
                        wrapMode: Text.WordWrap
                        lineHeight: 1.15
                    }
                }
                Item { Layout.fillHeight: true; visible: welcome.wide }

                // on a narrow window these move below the choices
                LayoutItemProxy { target: buttons; visible: welcome.wide; Layout.fillWidth: true }
            }

            // ---- the choices ----
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.round(36)
                color: Qt.alpha(Theme.window, 0.9)
                border.color: Theme.line

                Flickable {
                    id: area
                    anchors { fill: parent; margins: welcome.wide ? 28 : 14 }
                    contentHeight: Math.max(height, content.implicitHeight)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: content
                        width: Math.min(area.width, 640)
                        x: (area.width - width) / 2
                        y: Math.max(0, (area.height - implicitHeight) / 2)
                        spacing: 14
                        transform: Translate { id: slide }

                        // 0: language
                        ColumnLayout {
                            visible: welcome.step === 0
                            Layout.fillWidth: true
                            spacing: 12
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(460, content.width); horizontal: welcome.horizontalTabs; visible: area.height > 520 }
                            Repeater {
                                model: [{ key: "auto", mark: "◎", flag: "", label: Lang.t("Sistem dili", "System language"), note: Lang.t("Bilgisayarın hangi dildeyse", "Whatever your computer speaks") },
                                        { key: "tr", mark: "TR", flag: "tr", label: "Türkçe", note: "Arayüz Türkçe olur" },
                                        { key: "en", mark: "EN", flag: "gb", label: "English", note: "The interface in English" }]
                                ChoiceCard {
                                    required property var modelData
                                    required property int index
                                    mark: modelData.mark
                                    flag: modelData.flag !== ""
                                    picture: modelData.flag !== "" ? Qt.resolvedUrl("../data/logos/" + modelData.flag + ".svg") : ""
                                    label: modelData.label
                                    note: modelData.note
                                    tone: Theme.rainbow[index]
                                    chosen: Lang.choice === modelData.key
                                    onClicked: Lang.choice = modelData.key
                                }
                            }
                        }

                        // 1: colours
                        ColumnLayout {
                            visible: welcome.step === 1
                            Layout.fillWidth: true
                            spacing: 18
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(460, content.width); horizontal: welcome.horizontalTabs; visible: area.height > 520 }
                            ThemePicker { Layout.fillWidth: true }
                        }

                        // 2: layout
                        ColumnLayout {
                            visible: welcome.step === 2
                            Layout.fillWidth: true
                            spacing: 16
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(520, content.width); Layout.preferredHeight: 280; horizontal: welcome.horizontalTabs; visible: area.height > 480 }
                            ChoiceCard {
                                mark: "↑"
                                label: Lang.t("Sekmeler üstte", "Tabs on top")
                                note: Lang.t("Firefox ve Chrome gibi; altında yer imi çubuğu", "Like Firefox and Chrome, with a bookmarks bar")
                                tone: Theme.mauve
                                chosen: welcome.horizontalTabs
                                onClicked: welcome.layoutChosen(true)
                            }
                            ChoiceCard {
                                mark: "←"
                                label: Lang.t("Sekmeler yanda", "Tabs on the side")
                                note: Lang.t("Dikey liste; çok sekme açanlar için", "A vertical list, for many tabs")
                                tone: Theme.pink
                                chosen: !welcome.horizontalTabs
                                onClicked: welcome.layoutChosen(false)
                            }
                        }

                        // 3: search
                        ColumnLayout {
                            visible: welcome.step === 3
                            Layout.fillWidth: true
                            spacing: 12
                            readonly property var notes: ({ duckduckgo: Lang.t("Seni takip etmediğini söyler; varsayılan", "Says it does not track you; the default"),
                                                           brave: Lang.t("Kendi dizini olan, gizlilik odaklı", "Privacy minded, with its own index"),
                                                           startpage: Lang.t("Google sonuçları, aracı üzerinden", "Google's results through a go-between"),
                                                           google: Lang.t("En bilinen; arama geçmişini kullanır", "The best known; uses your searches") })
                            Repeater {
                                model: Address.engines
                                ChoiceCard {
                                    required property var modelData
                                    required property int index
                                    mark: String(modelData.label).charAt(0)
                                    picture: Qt.resolvedUrl("../data/logos/" + modelData.key + (modelData.key === "startpage" ? ".svg" : ".png"))
                                    label: modelData.label
                                    note: parent.notes[modelData.key] ?? ""
                                    tone: Theme.rainbow[index % Theme.rainbow.length]
                                    chosen: Address.engine === modelData.key
                                    onClicked: Address.engine = modelData.key
                                }
                            }
                            TextButton { Layout.fillWidth: true; Layout.topMargin: 8; implicitHeight: 46; text: Lang.t("Başka tarayıcıdan yer imlerimi al…", "Bring my bookmarks from another browser…"); onClicked: welcome.importRequested() }
                        }

                        // 4: extensions
                        Recommended {
                            id: offers
                            visible: welcome.step === 4
                            Layout.fillWidth: true
                            pick: true
                            installed: welcome.installed
                        }

                        // 5: ready, with the keys worth knowing
                        ColumnLayout {
                            visible: welcome.step === 5
                            Layout.fillWidth: true
                            spacing: 16
                            Image { Layout.alignment: Qt.AlignHCenter; source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(240, 240); Layout.preferredWidth: 104; Layout.preferredHeight: 104 }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: content.width >= 480 ? 3 : 2
                                columnSpacing: 10
                                rowSpacing: 10
                                Repeater {
                                    model: [["Ctrl+T", Lang.t("yeni sekme", "new tab")], ["Ctrl+K", Lang.t("komut kutusu", "command box")], ["Alt+R", Lang.t("okuma modu", "reader")], ["Alt+P", Lang.t("küçük video", "mini video")], ["Ctrl+\\", Lang.t("bölünmüş ekran", "split view")], ["Ctrl+,", Lang.t("ayarlar", "settings")]]
                                    Rectangle {
                                        id: tip
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 92
                                        radius: Theme.round(24)
                                        color: Qt.tint(Theme.surface, Qt.alpha(Theme.rainbow[index % Theme.rainbow.length], 0.2))
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[0]; color: Theme.rainbow[tip.index % Theme.rainbow.length]; font.pixelSize: 24; font.variableAxes: Theme.axes(850) }
                                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[1]; color: Theme.dim; font.pixelSize: 13 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            LayoutItemProxy { target: buttons; visible: !welcome.wide; Layout.fillWidth: true }
        }

        // the buttons live in one place and are shown by one of the two proxies above
        RowLayout {
            id: buttons
            spacing: 10
            component Round: AbstractButton {
                id: round
                property bool strong: false
                implicitHeight: 54
                implicitWidth: caption.implicitWidth + 52
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                scale: down ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: Theme.quick } }
                background: Rectangle { radius: Theme.round(height / 2); color: round.strong ? (round.hovered ? Qt.lighter(welcome.tone, 1.08) : welcome.tone) : round.hovered ? Theme.title : Theme.raised }
                contentItem: Label { id: caption; text: round.text; color: round.strong ? Theme.accentInk : Theme.text; font.pixelSize: 16; font.variableAxes: Theme.axes(750); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Round {
                strong: true
                text: welcome.step === welcome.steps - 1 ? Lang.t("Gezinmeye başla  →", "Start browsing  →")
                    : welcome.step === 4 && offers.picked.length > 0 ? Lang.t("Kur ve devam et  →", "Install and continue  →") : Lang.t("Devam  →", "Continue  →")
                onClicked: welcome.next()
            }
            Round { visible: welcome.step > 0; text: Lang.t("Geri", "Back"); onClicked: welcome.back() }
            Item { Layout.fillWidth: true }
            AbstractButton {
                visible: welcome.step < welcome.steps - 1
                focusPolicy: Qt.NoFocus
                onClicked: welcome.finish()
                contentItem: Label { text: Lang.t("Atla", "Skip"); color: Theme.dim; font.pixelSize: 14; font.underline: parent.hovered }
                hoverEnabled: true
                background: null
            }
        }
    }

    ParallelAnimation {
        id: arrive
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.smooth * 1.6 }
        NumberAnimation { target: slide; property: "x"; from: 40; to: 0; duration: Theme.smooth * 1.8; easing.type: Easing.OutCubic }
        NumberAnimation { target: words; property: "opacity"; from: 0; to: 1; duration: Theme.smooth * 1.6 }
        NumberAnimation { target: lift; property: "y"; from: 22; to: 0; duration: Theme.smooth * 1.8; easing.type: Easing.OutCubic }
    }
}
