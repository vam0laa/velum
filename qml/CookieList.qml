import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The sites that keep cookies here; each site's can be deleted.
ColumnLayout {
    id: list
    property bool open: false
    readonly property var sites: open ? Shield.cookieSites(search.text, Shield.cookieRevision) : []
    spacing: 6

    TextButton { Layout.fillWidth: true; implicitHeight: 38; text: list.open ? Lang.t("Listeyi gizle", "Hide the list") : Lang.t("Çerez tutan siteleri göster", "Show sites that keep cookies"); onClicked: list.open = !list.open }
    TextField {
        id: search
        Layout.fillWidth: true
        visible: list.open
        implicitHeight: 34
        leftPadding: 12
        placeholderText: Lang.t("Site ara", "Search sites")
        placeholderTextColor: Theme.dim
        color: Theme.text
        font.family: Theme.ui; font.pixelSize: 13
        background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: search.activeFocus ? Theme.accent : Theme.line }
    }
    ListView {
        Layout.fillWidth: true
        visible: list.open
        implicitHeight: Math.min(contentHeight, 260)
        clip: true
        model: list.sites
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        delegate: RowLayout {
            id: row
            required property var modelData
            width: ListView.view.width
            Text { Layout.fillWidth: true; text: row.modelData.site; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.ui; font.pixelSize: 13 }
            Text { text: row.modelData.count + Lang.t(" çerez", " cookies"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
            IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 12; symbol: "close"; hint: Lang.t("Bu sitenin çerezlerini sil", "Delete this site's cookies"); onClicked: Shield.removeCookies(row.modelData.site) }
        }
    }
    Text { visible: list.open && list.sites.length === 0; text: Lang.t("Çerez yok.", "No cookies."); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 13 }
}
