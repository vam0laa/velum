import QtQuick
import QtQuick.Layouts

// On an extension's page in the Chrome Web Store. The store's own button only works
// in Chrome, so Velum puts its own where it cannot be missed. It is drawn by the
// browser; nothing is fetched before the question that follows is answered.
Rectangle {
    id: bar
    signal add()
    implicitWidth: row.implicitWidth + 24
    implicitHeight: 52
    radius: Theme.radius
    color: Theme.raised
    border.color: Theme.line
    Shadow { radius: Theme.radius }

    RowLayout {
        id: row
        anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
        spacing: 14
        Text {
            text: Lang.t("Mağazanın düğmesi yalnızca Chrome'da çalışır.", "The store's own button only works in Chrome.")
            textFormat: Text.PlainText
            color: Theme.text
            font.family: Theme.ui; font.pixelSize: Theme.size(18)
        }
        TextButton { strong: true; text: Lang.t("Velum'a ekle", "Add to Velum"); onClicked: bar.add() }
    }
}
