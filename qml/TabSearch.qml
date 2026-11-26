import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Every open tab and the recently closed ones, found by name or address (Ctrl+Shift+A).
Popup {
    id: finder
    property var app
    property var rows: []

    function reload() {
        const q = field.text.trim().toLocaleLowerCase()
        const hit = (title, url) => q === "" || (title + " " + url).toLocaleLowerCase().indexOf(q) >= 0
        const out = []
        for (let i = 0; i < app.tabs.count; i++) {
            const tab = app.tabs.get(i)
            const title = tab.kind === "settings" ? Lang.t("Ayarlar", "Settings") : tab.title || Lang.t("Ana sayfa", "Home")
            if (hit(title, tab.pageUrl))
                out.push({ open: true, index: i, title: title, url: tab.pageUrl, space: app.spaces.length > 1 && !tab.pinned ? app.spaceName(app.spaces.find(s => s.id === tab.space) ?? {}) : "" })
        }
        for (let i = app.closedTabs.length - 1; i >= 0; i--) {
            const c = app.closedTabs[i]
            if (hit("", c.url))
                out.push({ open: false, index: i, title: c.url, url: c.url, space: "" })
        }
        rows = out
        list.currentIndex = 0
    }
    function choose(row) {
        if (!row)
            return
        close()
        if (row.open) {
            app.current = row.index
        } else {
            const c = app.closedTabs[row.index]
            app.closedTabs = app.closedTabs.filter((x, i) => i !== row.index)
            app.openTab(c.url)
        }
    }

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(620, Overlay.overlay.width - 32)
    height: Math.min(520, Overlay.overlay.height - 32)
    padding: 14
    topPadding: 42
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("sekmeler", "tabs"); stripe: Theme.mauve }
    onAboutToShow: { field.text = ""; reload() }
    onOpened: field.forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        TextField {
            id: field
            Layout.fillWidth: true
            implicitHeight: 36
            leftPadding: 12
            placeholderText: Lang.t("Sekmelerde ara", "Search tabs")
            placeholderTextColor: Theme.dim
            color: Theme.text
            font.family: Theme.ui; font.pixelSize: 14
            background: Rectangle { radius: Theme.radius; color: Theme.frame; border.color: field.activeFocus ? Theme.accent : Theme.line }
            onTextEdited: finder.reload()
            onAccepted: finder.choose(finder.rows[list.currentIndex])
            Keys.onDownPressed: list.currentIndex = Math.min(finder.rows.length - 1, list.currentIndex + 1)
            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: finder.rows
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            delegate: AbstractButton {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 46
                hoverEnabled: true
                onClicked: finder.choose(modelData)
                background: Rectangle { radius: Theme.radius; color: row.ListView.isCurrentItem || row.hovered ? Theme.raised : "transparent" }
                contentItem: RowLayout {
                    spacing: 8
                    Icon { Layout.leftMargin: 8; name: row.modelData.open ? "globe" : "history"; size: 15; color: Theme.dim }
                    Column {
                        Layout.fillWidth: true
                        Text { width: parent.width; text: row.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.ui; font.pixelSize: 14 }
                        Text { width: parent.width; text: row.modelData.open ? (row.modelData.space !== "" ? row.modelData.space + " · " : "") + row.modelData.url : Lang.t("Kapatıldı", "Closed"); textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
                    }
                    IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 12; visible: row.modelData.open; symbol: "close"; hint: Lang.t("Sekmeyi kapat", "Close the tab"); onClicked: { finder.app.closeTab(row.modelData.index); finder.reload() } }
                }
            }
        }
    }
}
