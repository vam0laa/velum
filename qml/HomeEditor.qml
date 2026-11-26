import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The panel that reshapes the home page: its widgets, its words and your style sheet.
Rectangle {
    id: editor
    property Item page
    property int tab: 0
    readonly property var all: [
        { id: "clock", name: Lang.t("Büyük saat", "Big clock") }, { id: "date", name: Lang.t("Tarih", "Date") },
        { id: "calendar", name: Lang.t("Takvim", "Calendar") }, { id: "shield", name: Lang.t("Kalkan sayacı", "Shield counter") },
        { id: "tasks", name: Lang.t("Görev listesi", "Task list") }, { id: "timer", name: Lang.t("Odak zamanlayıcısı", "Focus timer") },
        { id: "note", name: Lang.t("Not defteri", "Note") }
    ]
    // shown ones first, in their order; the rest after them
    readonly property var rows: page.widgets.map(id => all.find(w => w.id === id)).filter(w => w !== undefined)
                                .concat(all.filter(w => !page.widgets.includes(w.id)))

    function open(which) {
        tab = which ?? tab
        head.text = page.headline
        said.text = page.words.join("\n")
        sheet.text = page.cssText
        visible = true
    }

    visible: false
    width: Math.min(400, parent.width - 24)
    radius: Theme.round(24)
    color: Theme.window
    border.color: Theme.line

    component Label: Text { color: Theme.text; font.family: Theme.ui; font.pixelSize: 13; textFormat: Text.PlainText }
    component Area: ScrollView {
        id: area
        property alias text: input.text
        property alias placeholder: input.placeholderText
        property bool code: false
        Layout.fillWidth: true
        TextArea {
            id: input
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            placeholderTextColor: Theme.dim
            font.family: area.code ? "monospace" : Theme.ui
            font.pixelSize: 13
            leftPadding: 12; rightPadding: 12; topPadding: 10; bottomPadding: 10
            background: Rectangle { radius: Theme.round(12); color: Theme.surface; border.color: input.activeFocus ? Theme.accent : Theme.line }
        }
    }

    // clicks on the panel stay on the panel
    MouseArea { anchors.fill: parent }

    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: Lang.t("Ana sayfayı düzenle", "Design the home page"); font.pixelSize: 18; font.variableAxes: Theme.axes(800) }
            IconButton { symbol: "close"; hint: Lang.t("Kapat", "Close"); onClicked: editor.visible = false }
        }
        Segments {
            options: [{ key: 0, label: "Widget" }, { key: 1, label: Lang.t("Yazılar", "Words") }, { key: 2, label: "CSS" }]
            current: editor.tab
            onChosen: key => editor.tab = key
        }

        // widgets: switch on and off, move up and down
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: editor.tab === 0
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: editor.rows
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property int at: editor.page.widgets.indexOf(modelData.id)
                width: ListView.view.width
                height: 50
                radius: Theme.round(14)
                color: Theme.surface
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                    spacing: 4
                    Label { Layout.fillWidth: true; text: row.modelData.name; color: row.at >= 0 ? Theme.text : Theme.dim; elide: Text.ElideRight }
                    IconButton { visible: row.at >= 0; enabled: row.at > 0; implicitWidth: 30; implicitHeight: 30; iconSize: 14; symbol: "up"; hint: Lang.t("Yukarı", "Up"); onClicked: editor.page.moveWidget(row.modelData.id, -1) }
                    IconButton { visible: row.at >= 0; enabled: row.at < editor.page.widgets.length - 1; implicitWidth: 30; implicitHeight: 30; iconSize: 14; symbol: "down"; hint: Lang.t("Aşağı", "Down"); onClicked: editor.page.moveWidget(row.modelData.id, 1) }
                    TextButton { implicitHeight: 30; strong: row.at < 0; text: row.at >= 0 ? Lang.t("Kaldır", "Remove") : Lang.t("Ekle", "Add"); onClicked: editor.page.setWidget(row.modelData.id, row.at < 0) }
                }
            }
        }

        // the headline
        ColumnLayout {
            visible: editor.tab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            Label { text: Lang.t("Büyük başlık (boşsa varsayılan)", "Headline (empty: the usual one)"); color: Theme.dim }
            TextField {
                id: head
                Layout.fillWidth: true
                implicitHeight: 36
                leftPadding: 12
                maximumLength: 40
                color: Theme.text
                font.family: Theme.ui
                font.pixelSize: 13
                background: Rectangle { radius: Theme.round(12); color: Theme.surface; border.color: head.activeFocus ? Theme.accent : Theme.line }
            }
            Label { text: Lang.t("Dönen kelimeler, her satıra bir tane", "Changing words, one per line"); color: Theme.dim }
            Area { id: said; Layout.preferredHeight: 150; placeholder: Lang.t("tarayıcın.\nsakin alanın.", "browser.\nquiet place.") }
            TextButton { Layout.alignment: Qt.AlignRight; strong: true; text: Lang.t("Uygula", "Apply"); onClicked: editor.page.wordsEdited(head.text, said.text) }
            Item { Layout.fillHeight: true }
        }

        // your own style sheet
        ColumnLayout {
            visible: editor.tab === 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.dim
                font.pixelSize: 12
                text: Lang.t("Seçiciler: ", "Selectors: ") + editor.page.cssReader.selectors.map(s => "." + s).join(" ")
                    + "\n" + Lang.t("Özellikler: ", "Properties: ") + editor.page.cssReader.properties.join(", ")
            }
            Area { id: sheet; code: true; Layout.fillHeight: true; placeholder: ".pill { background: #cba6f7; border-radius: 8px; }\n.clock { color: #f5c2e7; }\n.widget { border-color: #45475a; }" }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.WordWrap
                color: Theme.danger
                font.pixelSize: 12
                text: editor.page.cssErrors.join("\n")
            }
            RowLayout {
                Layout.fillWidth: true
                TextButton { text: Lang.t("Örnek", "Example"); onClicked: sheet.text = ".page { background: #11111b; }\n.pill { background: #cba6f7; color: #11111b; border-radius: 14px; }\n.clock { color: #f5c2e7; }\n.widget { border-color: #45475a; border-radius: 12px; }\n.chip { display: none; }" }
                TextButton { text: Lang.t("Temizle", "Clear"); onClicked: { sheet.text = ""; editor.page.cssEdited("") } }
                Item { Layout.fillWidth: true }
                TextButton { strong: true; text: Lang.t("Uygula", "Apply"); onClicked: editor.page.cssEdited(sheet.text) }
            }
        }
    }
}
