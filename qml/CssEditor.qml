import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Your style sheet for the browser itself.
ColumnLayout {
    id: editor
    spacing: 8
    readonly property string example: ".tabbar { background: #11111b; }\n.toolbar { background: #181825; }\n.tab { color: #a6adc8; border-radius: 4px; }\n.tab-active { background: #cba6f7; color: #11111b; }\n.address { background: #1e1e2e; color: #cdd6f4; border-color: #45475a; border-radius: 18px; }\n.button { color: #cdd6f4; }\n.bookmarks { background: #181825; color: #cdd6f4; }\n.card { background: #181825; border-radius: 6px; }\n.nav-active { background: #cba6f7; color: #11111b; }\n.menu { background: #181825; border-color: #cba6f7; }\n.clock { color: #f5c2e7; }\n.widget { background: #181825; }"

    // what each name means; pressing one writes its rule for you
    readonly property var parts: [
        ["all", Lang.t("her yerdeki yazı", "writing everywhere")], ["window", Lang.t("pencerenin zemini", "window background")], ["tabbar", Lang.t("sekme şeridi", "tab strip")],
        ["tab", Lang.t("sekmeler", "tabs")], ["tab-active", Lang.t("açık sekme", "current tab")], ["newtab", Lang.t("yeni sekme düğmesi", "new tab button")], ["window-button", Lang.t("kapat ve tam ekran", "close and full screen")],
        ["toolbar", Lang.t("araç çubuğu", "toolbar")], ["address", Lang.t("adres çubuğu", "address field")], ["button", Lang.t("simge düğmeleri", "icon buttons")], ["action", Lang.t("yazılı düğmeler", "text buttons")], ["primary", Lang.t("seçili düğme", "chosen button")],
        ["toggle", Lang.t("kapalı anahtar", "switch off")], ["toggle-on", Lang.t("açık anahtar", "switch on")], ["bookmarks", Lang.t("yer imi çubuğu", "bookmarks bar")], ["bookmark", Lang.t("tek yer imi", "one bookmark")],
        ["sidebar", Lang.t("yan panel", "side bar")], ["menu", Lang.t("menüler", "menus")], ["popup", Lang.t("açılan kutular", "popups")], ["tooltip", Lang.t("ipuçları", "hints")], ["notice", Lang.t("alttaki bildirim", "bottom notice")], ["findbar", Lang.t("sayfada arama", "find bar")],
        ["settings", Lang.t("ayarlar zemini", "settings background")], ["nav", Lang.t("ayar bölümleri", "settings sections")], ["nav-active", Lang.t("açık bölüm", "current section")], ["card", Lang.t("ayar kartları", "settings cards")], ["input", Lang.t("ayarlarda arama", "settings search")],
        ["page", Lang.t("ana sayfa zemini", "home background")], ["headline", Lang.t("büyük başlık", "headline")], ["pill", Lang.t("dönen kelime", "changing word")], ["chip", Lang.t("selam etiketi", "greeting chip")], ["search", Lang.t("ana sayfa araması", "home search")], ["tile", Lang.t("site kutuları", "site tiles")],
        ["clock", Lang.t("büyük saat", "big clock")], ["widget", Lang.t("bütün widget'lar", "all widgets")], ["date", Lang.t("tarih", "date")], ["calendar", Lang.t("takvim", "calendar")], ["shield", Lang.t("kalkan sayacı", "shield counter")], ["note", Lang.t("not", "note")], ["tasks", Lang.t("görevler", "tasks")], ["timer", Lang.t("zamanlayıcı", "timer")]]

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.family: Theme.ui
        font.pixelSize: 12
        text: Lang.t("Bir parçaya bas, kuralı yazılsın. Özellikler: ", "Press a part to write its rule. Properties: ") + Theme.sheet.properties.filter(p => p !== "background-color").join(", ")
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: editor.parts
            TextButton {
                required property var modelData
                implicitHeight: 26
                text: modelData[1]
                onClicked: {
                    source.text = source.text.replace(/\s*$/, "") + (source.text.trim() === "" ? "" : "\n") + "." + modelData[0] + " {  }"
                    source.forceActiveFocus()
                    source.cursorPosition = source.length - 2
                }
            }
        }
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
