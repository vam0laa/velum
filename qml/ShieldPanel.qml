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
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("koruma", "shield"); stripe: Theme.green }
    topPadding: 42
    readonly property bool siteAllowed: Shield.allowed(host, Shield.revision)

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
            text: Lang.t("istek engellendi", "requests blocked") + (panel.host === "" ? "" : " · " + panel.host)
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.dim
            font.pixelSize: 12
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        Toggle {
            label: Lang.t("Bu sitede engelle", "Block on this site")
            note: Lang.t("Bir site bozulursa kapat", "Turn off if a site breaks")
            visible: panel.host !== ""
            enabled: Shield.enabled
            on: Shield.enabled && !panel.siteAllowed
            onClicked: { Shield.setAllowed(panel.host, !panel.siteAllowed); panel.reload() }
        }
        Toggle {
            label: Lang.t("Reklam ve izleyici engelleme", "Block ads and trackers")
            note: Lang.t("Bütün sitelerde", "On every site")
            on: Shield.enabled
            onClicked: { Shield.enabled = !Shield.enabled; panel.reload() }
        }
        Toggle {
            label: Lang.t("Önce HTTPS", "HTTPS first")
            note: Lang.t("http adreslerini şifreli aç", "Open http addresses encrypted")
            on: Shield.httpsFirst
            onClicked: { Shield.httpsFirst = !Shield.httpsFirst; panel.reload() }
        }
        Toggle {
            label: Lang.t("Üçüncü taraf çerezleri engelle", "Block third party cookies")
            note: Lang.t("Siteler arası takibi zorlaştırır", "Makes cross-site tracking harder")
            on: Shield.blockThirdPartyCookies
            onClicked: { Shield.blockThirdPartyCookies = !Shield.blockThirdPartyCookies; panel.reload() }
        }
        Toggle {
            label: Lang.t("Çıkışta çerezleri unut", "Forget cookies on exit")
            note: Lang.t("Sonraki açılıştan itibaren", "From the next start")
            on: Shield.forgetOnExit
            onClicked: Shield.forgetOnExit = !Shield.forgetOnExit
        }
        TextButton { Layout.fillWidth: true; text: Lang.t("Çerezleri ve önbelleği sil…", "Delete cookies and cache…"); onClicked: { panel.close(); panel.clearRequested() } }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        RowLayout {
            Text { Layout.fillWidth: true; text: Shield.statusText(Lang.turkish, Shield.revision, Shield.statusCode); color: Theme.dim; font.pixelSize: 11; elide: Text.ElideRight }
            IconButton { symbol: "reload"; iconSize: 14; implicitWidth: 28; implicitHeight: 28; hint: Lang.t("Listeleri güncelle", "Update lists"); onClicked: Shield.updateLists() }
        }
    }
}
