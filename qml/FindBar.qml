import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Ctrl+F: find text in the page.
Bevel {
    id: bar
    property int matches: 0
    property int current: 0
    property alias text: field.text
    signal search(string text, bool backwards)
    signal closed()

    function open() {
        visible = true
        field.forceActiveFocus()
        field.selectAll()
        if (field.text !== "")
            search(field.text, false)
    }

    function close() {
        if (!visible)
            return
        visible = false
        matches = 0
        current = 0
        closed()
    }

    visible: false
    implicitWidth: 340
    implicitHeight: 44
    color: Theme.window

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 5 }
        spacing: 2
        TextField {
            id: field
            Layout.fillWidth: true
            placeholderText: Lang.t("Sayfada ara", "Find in page")
            placeholderTextColor: Theme.dim
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: Theme.ui; font.pixelSize: Theme.size(17)
            background: null
            onTextEdited: bar.search(text, false)
            Keys.onReturnPressed: event => bar.search(text, event.modifiers & Qt.ShiftModifier)
            Keys.onEscapePressed: bar.close()
        }
        Text { Layout.rightMargin: 6; visible: field.text !== ""; text: bar.matches === 0 ? Lang.t("yok", "none") : bar.current + "/" + bar.matches; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
        IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 14; symbol: "up"; hint: Lang.t("Önceki (Shift+Enter)", "Previous (Shift+Enter)"); enabled: bar.matches > 0; onClicked: bar.search(field.text, true) }
        IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 14; symbol: "down"; hint: Lang.t("Sonraki (Enter)", "Next (Enter)"); enabled: bar.matches > 0; onClicked: bar.search(field.text, false) }
        IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 13; symbol: "close"; hint: Lang.t("Kapat (Esc)", "Close (Esc)"); onClicked: bar.close() }
    }
}
