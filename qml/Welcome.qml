import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    // [title, what this page is for]
    readonly property var pages: [
        [Lang.t("Velum'a hoş geldin", "Welcome to Velum"), Lang.t("Sakin, gizlilik odaklı tarayıcın. Birkaç kısa adımda sana göre ayarlayalım.", "Your calm, private browser. A few short steps and it is yours.")],
        [Lang.t("Rengini seç", "Pick your colours"), Lang.t("Tıkladığın anda her şey değişir; küçük Velum da.", "Everything changes as you click, the little Velum too.")],
        [Lang.t("Sekmeler nerede dursun?", "Where do tabs go?"), Lang.t("Üstte, alışık olduğun gibi; ya da yanda, daha çok sığsın diye.", "Along the top as you know them, or down the side to fit more.")],
        [Lang.t("Aramayı sen seç", "Choose your search"), Lang.t("Adres çubuğuna yazdıkların bu motora gider. Eski tarayıcından yer imlerini de alabilirsin.", "What you type in the address bar goes here. You can bring your bookmarks along too.")],
        [Lang.t("Birkaç eklenti?", "A few extensions?"), Lang.t("İşaretlediklerin Chrome Web Store'dan (Google) indirilip kurulur. Eklentiler gezdiğin sayfaları okuyabilir. Hiçbiri zorunlu değil. Reklamları Velum'un kalkanı zaten engeller.", "Ticked ones are fetched from the Chrome Web Store (Google) and installed. Extensions can read the pages you visit. None is required. Velum's shield already blocks ads.")],
        [Lang.t("Her şey hazır", "All set"), Lang.t("Hepsi ayarlarda durur (Ctrl+,). Her şey için komut kutusu: Ctrl+K.", "All of this stays in the settings (Ctrl+,). The command box does everything else: Ctrl+K.")]
    ]
    readonly property color tone: Theme.accent

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

        Backdrop { anchors.fill: parent; mode: "glow"; middle: 0.24; visible: !Theme.web }

        Brand { x: 32; y: 20 }
        AbstractButton {
            anchors { right: parent.right; rightMargin: 32; top: parent.top; topMargin: 26 }
            visible: welcome.step < welcome.steps - 1
            focusPolicy: Qt.NoFocus
            hoverEnabled: true
            onClicked: welcome.finish()
            contentItem: Label { text: Lang.t("Atla", "Skip"); color: parent.hovered ? Theme.text : Theme.dim; font.pixelSize: 13; font.variableAxes: Theme.axes(500) }
            background: null
        }

        ColumnLayout {
            anchors { top: parent.top; bottom: parent.bottom; topMargin: 76; bottomMargin: 28 }
            width: Math.min(parent.width - 48, 624)
            x: (parent.width - width) / 2
            spacing: 20

            ColumnLayout {
                id: words
                Layout.fillWidth: true
                spacing: 8
                transform: Translate { id: lift }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: welcome.pages[welcome.step][0]
                    font.pixelSize: welcome.height < 700 ? 30 : 40
                    font.variableAxes: Theme.axes(500)
                    font.letterSpacing: -1
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 22
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: welcome.pages[welcome.step][1]
                    color: Theme.dim
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    lineHeight: 1.2
                }
            }

            // ---- the choices ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors { fill: area; margins: -20 }
                    radius: Theme.round(16)
                    color: Qt.alpha(Theme.window, 0.85)
                    border.color: Qt.alpha(Theme.line, 0.8)
                }
                Flickable {
                    id: area
                    readonly property int room: parent.height - 40
                    x: 20
                    width: parent.width - 40
                    height: Math.min(room, content.implicitHeight)
                    y: 20 + Math.max(0, (room - height) / 2)
                    contentHeight: content.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: content
                        width: area.width
                        spacing: 14
                        transform: Translate { id: slide }

                        // 0: language
                        ColumnLayout {
                            visible: welcome.step === 0
                            Layout.fillWidth: true
                            spacing: 12
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(380, content.width); Layout.preferredHeight: 214; horizontal: welcome.horizontalTabs; visible: area.room > 520 }
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
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(380, content.width); Layout.preferredHeight: 214; horizontal: welcome.horizontalTabs; visible: area.room > 520 }
                            ThemePicker { Layout.fillWidth: true }
                        }

                        // 2: layout
                        ColumnLayout {
                            visible: welcome.step === 2
                            Layout.fillWidth: true
                            spacing: 16
                            BrowserPreview { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(460, content.width); Layout.preferredHeight: 250; horizontal: welcome.horizontalTabs; visible: area.room > 420 }
                            ChoiceCard {
                                mark: "↑"
                                label: Lang.t("Sekmeler üstte", "Tabs on top")
                                note: Lang.t("Firefox ve Chrome gibi; altında yer imi çubuğu", "Like Firefox and Chrome, with a bookmarks bar")
                                chosen: welcome.horizontalTabs
                                onClicked: welcome.layoutChosen(true)
                            }
                            ChoiceCard {
                                mark: "←"
                                label: Lang.t("Sekmeler yanda", "Tabs on the side")
                                note: Lang.t("Dikey liste; çok sekme açanlar için", "A vertical list, for many tabs")
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
                                    chosen: Address.engine === modelData.key
                                    onClicked: Address.engine = modelData.key
                                }
                            }
                            TextButton { Layout.fillWidth: true; Layout.topMargin: 8; implicitHeight: 40; text: Lang.t("Başka tarayıcıdan yer imlerimi al…", "Bring my bookmarks from another browser…"); onClicked: welcome.importRequested() }
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
                            // asked in plain words, on unless you untick it
                            AbstractButton {
                                id: gpu
                                Layout.fillWidth: true
                                implicitHeight: gpuWords.implicitHeight + 32
                                focusPolicy: Qt.NoFocus
                                hoverEnabled: true
                                onClicked: Gpu.on = !Gpu.on
                                Accessible.name: Lang.t("Ekran kartını kullan", "Use graphics acceleration")
                                background: Rectangle { radius: Theme.round(12); color: gpu.hovered ? Theme.title : Theme.raised; border.width: 1; border.color: Gpu.on ? welcome.tone : Theme.line }
                                contentItem: Item {
                                    Rectangle {
                                        x: 18; anchors.verticalCenter: parent.verticalCenter; width: 26; height: 26; radius: Theme.round(8)
                                        color: Gpu.on ? welcome.tone : "transparent"; border.width: Gpu.on ? 0 : 2; border.color: Theme.dim
                                        Label { anchors.centerIn: parent; visible: Gpu.on; text: "✓"; color: Theme.accentInk; font.pixelSize: 17; font.variableAxes: Theme.axes(800) }
                                    }
                                    Column {
                                        id: gpuWords
                                        anchors { left: parent.left; leftMargin: 60; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                        spacing: 2
                                        Label { width: parent.width; wrapMode: Text.WordWrap; text: Lang.t("Videolar ve kaydırma daha akıcı olsun", "Smoother videos and scrolling"); font.pixelSize: 16; font.variableAxes: Theme.axes(550) }
                                        Label { width: parent.width; wrapMode: Text.WordWrap; text: Lang.t("Velum bilgisayarının ekran kartını kullanır (önerilir). Görüntü bozulursa Ayarlar → Performans'tan kapatabilirsin.", "Velum uses your computer's graphics card (recommended). If the picture looks wrong, switch it off in Settings → Performance."); color: Theme.dim; font.pixelSize: 13 }
                                    }
                                }
                            }
                            Image { Layout.alignment: Qt.AlignHCenter; source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(240, 240); Layout.preferredWidth: 64; Layout.preferredHeight: 64 }
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
                                        implicitHeight: 72
                                        radius: Theme.round(12)
                                        color: Theme.raised
                                        border.color: Theme.line
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[0]; color: Theme.mauve; font.pixelSize: 16; font.variableAxes: Theme.axes(550) }
                                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: tip.modelData[1]; color: Theme.dim; font.pixelSize: 13 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // where you are, and the way on
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Row {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: welcome.steps
                        AbstractButton {
                            id: mark
                            required property int index
                            width: index === welcome.step ? 24 : 8
                            height: 8
                            enabled: index < welcome.step
                            onClicked: welcome.step = index
                            Accessible.name: String(index + 1)
                            background: Rectangle { radius: Theme.round(4); color: mark.index <= welcome.step ? welcome.tone : Theme.line; opacity: mark.index < welcome.step ? 0.55 : 1 }
                            Behavior on width { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                TextButton { visible: welcome.step > 0; implicitHeight: 40; text: Lang.t("Geri", "Back"); onClicked: welcome.back() }
                TextButton {
                    strong: true
                    implicitHeight: 40
                    implicitWidth: Math.max(120, measure.implicitWidth + 48)
                    text: welcome.step === welcome.steps - 1 ? Lang.t("Gezinmeye başla", "Start browsing")
                        : welcome.step === 4 && offers.picked.length > 0 ? Lang.t("Kur ve devam et", "Install and continue") : Lang.t("Devam", "Continue")
                    onClicked: welcome.next()
                    Text { id: measure; visible: false; text: parent.text; font.family: Theme.ui; font.pixelSize: Theme.size(18) }
                }
            }
        }
    }

    ParallelAnimation {
        id: arrive
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.smooth * 1.6 }
        NumberAnimation { target: slide; property: "x"; from: 20; to: 0; duration: Theme.smooth * 1.8; easing.type: Easing.OutCubic }
        NumberAnimation { target: words; property: "opacity"; from: 0; to: 1; duration: Theme.smooth * 1.6 }
        NumberAnimation { target: lift; property: "y"; from: 12; to: 0; duration: Theme.smooth * 1.8; easing.type: Easing.OutCubic }
    }
}
