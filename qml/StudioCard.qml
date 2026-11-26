import QtQuick
import QtQuick.Layouts

// The door to the theme studio, in the settings.
ColumnLayout {
    id: card
    signal openStudio()
    spacing: 10
    ThemePreview {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(330, width * 0.55)
        colors: { const list = []; for (let i = 0; i < 15; i++) list.push(String(i === 8 ? Theme.accent : Theme.pick(i))); return list }
        roundness: Theme.roundness
        tabShape: Theme.tabShape
        uiFont: Theme.ui
        headFont: Theme.display
        border.width: 1
        border.color: Theme.line
    }
    TextButton { Layout.fillWidth: true; implicitHeight: 44; strong: true; text: Lang.t("Tema Stüdyosu'nu aç", "Open the Theme Studio"); onClicked: card.openStudio() }
    RowLayout {
        Layout.fillWidth: true
        visible: mine.visible || back.visible
        TextButton { id: mine; Layout.fillWidth: true; visible: Theme.palette !== "custom" && Theme.custom.length === 15; text: Lang.t("Benim temama dön", "Back to my theme"); onClicked: Theme.change(() => { Theme.accentChoice = ""; Theme.palette = "custom" }) }
        TextButton { id: back; Layout.fillWidth: true; visible: Theme.previous !== null; text: Lang.t("Son uygulamayı geri al", "Undo the last apply"); onClicked: Theme.change(() => Theme.goBack()) }
    }
}
