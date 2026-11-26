import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Your style sheet for the browser itself.
ColumnLayout {
    id: editor
    spacing: 8
    readonly property string example: ".tabbar { background: #11111b; }\n.toolbar { background: #181825; }\n.tab { color: #a6adc8; border-radius: 4px; }\n.tab-active { background: #cba6f7; color: #11111b; }\n.address { background: #1e1e2e; color: #cdd6f4; border-color: #45475a; border-radius: 18px; }\n.button { color: #cdd6f4; }\n.bookmarks { background: #181825; color: #cdd6f4; }"

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.family: Theme.ui
        font.pixelSize: 12
        text: Lang.t("Seçiciler: ", "Selectors: ") + Theme.sheet.selectors.map(s => "." + s).join(" ")
            + "\n" + Lang.t("Özellikler: ", "Properties: ") + Theme.sheet.properties.join(", ")
    }
    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 190
        TextArea {
            id: source
            text: Theme.css
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            placeholderText: ".tab-active { background: #cba6f7; color: #11111b; }"
            placeholderTextColor: Theme.dim
            font.family: "monospace"
            font.pixelSize: 13
            leftPadding: 12; rightPadding: 12; topPadding: 10; bottomPadding: 10
            background: Rectangle { radius: Theme.round(12); color: Theme.surface; border.color: source.activeFocus ? Theme.accent : Theme.line }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: text !== ""
        wrapMode: Text.WordWrap
        color: Theme.danger
        font.family: Theme.ui
        font.pixelSize: 12
        textFormat: Text.PlainText
        text: Theme.cssErrors.join("\n")
    }
    RowLayout {
        Layout.fillWidth: true
        TextButton { text: Lang.t("Örnek", "Example"); onClicked: source.text = editor.example }
        TextButton { text: Lang.t("Temizle", "Clear"); onClicked: { source.text = ""; Theme.css = "" } }
        Item { Layout.fillWidth: true }
        TextButton { strong: true; text: Lang.t("Uygula", "Apply"); onClicked: Theme.css = source.text.slice(0, 20000) }
    }
    Connections { target: Theme; function onCssChanged() { if (source.text !== Theme.css) source.text = Theme.css } }
}
