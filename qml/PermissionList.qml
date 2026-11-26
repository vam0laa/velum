import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// What sites were allowed or refused since Velum started; each can be taken back.
ColumnLayout {
    id: list
    property var items: []          // [{ site, what, allowed, permission }]
    property var popups: []         // sites allowed to open windows
    signal reset(var item)
    signal forgetPopup(string site)
    spacing: 4

    Text {
        Layout.fillWidth: true
        visible: list.items.length === 0 && list.popups.length === 0
        text: Lang.t("Henüz hiçbir siteye izin verilmedi. Verilen izinler Velum kapanana kadar sürer.", "No site was given a permission yet. Permissions last until Velum closes.")
        wrapMode: Text.WordWrap
        color: Theme.dim; font.family: Theme.ui; font.pixelSize: 13
    }
    Repeater {
        model: list.items
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            Column {
                Layout.fillWidth: true
                Text { width: parent.width; text: row.modelData.site; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.ui; font.pixelSize: 14 }
                Text { width: parent.width; text: (row.modelData.allowed ? Lang.t("İzinli: ", "Allowed: ") : Lang.t("Engelli: ", "Blocked: ")) + row.modelData.what; elide: Text.ElideRight; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
            }
            TextButton { implicitHeight: 28; text: Lang.t("Geri al", "Take back"); onClicked: list.reset(row.modelData) }
        }
    }
    Repeater {
        model: list.popups
        RowLayout {
            id: popup
            required property string modelData
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: popup.modelData + Lang.t(" · pencere açabilir", " · may open windows"); textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.ui; font.pixelSize: 14 }
            TextButton { implicitHeight: 28; text: Lang.t("Geri al", "Take back"); onClicked: list.forgetPopup(popup.modelData) }
        }
    }
}
