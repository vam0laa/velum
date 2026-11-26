import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// What the shield did on this site, and the switches for it.
Popup {
    id: panel
    property string host
    signal reload()
    signal clearRequested()

    width: 290
    padding: 14
    margins: 8                 // never leaves the window
    background: Rectangle { radius: 14; color: Theme.surface; border.color: Theme.line }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.quick } }

    readonly property bool siteAllowed: Shield.allowed(host, Shield.revision)

    component Choice: AbstractButton {
        id: choice
        property bool on
        property string label
        property string note
        Layout.fillWidth: true
        implicitHeight: 40
        focusPolicy: Qt.NoFocus
        contentItem: RowLayout {
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: choice.label; color: choice.enabled ? Theme.text : Theme.dim; font.pixelSize: 13 }
                Text { text: choice.note; visible: text !== ""; color: Theme.dim; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            }
            Rectangle {
                implicitWidth: 34; implicitHeight: 20; radius: 10
                color: choice.on ? Theme.accent : Theme.raised
                Rectangle {
                    width: 14; height: 14; radius: 7; y: 3
                    x: choice.on ? 17 : 3
                    color: choice.on ? Theme.onAccent : Theme.dim
                    Behavior on x { NumberAnimation { duration: Theme.quick } }
                }
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8
        Text {
            text: Shield.blockedCount(panel.host, Shield.revision)
            color: Theme.accent
            font.pixelSize: 34
            font.weight: Font.Bold
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: -8
            text: panel.host === "" ? "istek engellendi" : "istek engellendi · " + panel.host
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.dim
            font.pixelSize: 12
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        Choice {
            label: "Bu sitede engelle"
            note: "Bir site bozulursa kapat"
            visible: panel.host !== ""
            enabled: Shield.enabled
            on: Shield.enabled && !panel.siteAllowed
            onClicked: { Shield.setAllowed(panel.host, !panel.siteAllowed); panel.reload() }
        }
        Choice {
            label: "Reklam ve izleyici engelleme"
            note: "Bütün sitelerde"
            on: Shield.enabled
            onClicked: { Shield.enabled = !Shield.enabled; panel.reload() }
        }
        Choice {
            label: "Önce HTTPS"
            note: "http adreslerini şifreli aç"
            on: Shield.httpsFirst
            onClicked: { Shield.httpsFirst = !Shield.httpsFirst; panel.reload() }
        }
        Choice {
            label: "Üçüncü taraf çerezleri engelle"
            note: "Siteler arası takibi zorlaştırır"
            on: Shield.blockThirdPartyCookies
            onClicked: { Shield.blockThirdPartyCookies = !Shield.blockThirdPartyCookies; panel.reload() }
        }
        Choice {
            label: "Çıkışta çerezleri unut"
            note: "Sonraki açılıştan itibaren"
            on: Shield.forgetOnExit
            onClicked: Shield.forgetOnExit = !Shield.forgetOnExit
        }
        TextButton { Layout.fillWidth: true; text: "Çerezleri ve önbelleği sil…"; onClicked: { panel.close(); panel.clearRequested() } }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        RowLayout {
            Text { Layout.fillWidth: true; text: Shield.status; color: Theme.dim; font.pixelSize: 11; elide: Text.ElideRight }
            IconButton { symbol: "reload"; iconSize: 14; implicitWidth: 28; implicitHeight: 28; hint: "Listeleri güncelle"; onClicked: Shield.updateLists() }
        }
    }
}
