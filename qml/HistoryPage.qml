import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The history (Ctrl+H): by day, searchable, removable one by one or by age.
Popup {
    id: page
    property var rows: []        // [{ url, title, last }], newest first
    property int shown: 200
    signal chosen(url target)

    function reload() { rows = History.browse(search.text, shown) }
    function dayOf(seconds) {
        const d = new Date(seconds * 1000), today = new Date()
        const days = Math.round((new Date(today.getFullYear(), today.getMonth(), today.getDate()) - new Date(d.getFullYear(), d.getMonth(), d.getDate())) / 86400000)
        return days === 0 ? Lang.t("Bugün", "Today") : days === 1 ? Lang.t("Dün", "Yesterday")
             : d.toLocaleDateString(Qt.locale(Lang.turkish ? "tr_TR" : "en_GB"), "d MMMM yyyy, dddd")
    }
    // 0 removes everything
    function removeSince(seconds) {
        History.removeSince(seconds === 0 ? 0 : Math.floor(Date.now() / 1000) - seconds)
        reload()
    }
    onAboutToShow: { shown = 200; search.text = ""; reload() }
    onOpened: search.forceActiveFocus()

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(820, Overlay.overlay.width - 32)
    height: Math.min(620, Overlay.overlay.height - 32)
    padding: 14
    topPadding: 42
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("geçmiş", "history"); stripe: Theme.pink }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 34
                leftPadding: 12
                placeholderText: Lang.t("Geçmişte ara", "Search the history")
                placeholderTextColor: Theme.dim
                color: Theme.text
                font.family: Theme.ui; font.pixelSize: Theme.size(17)
                background: Rectangle { radius: Theme.radius; color: Theme.frame; border.color: search.activeFocus ? Theme.accent : Theme.line }
                onTextEdited: { page.shown = 200; page.reload() }
            }
            Dropdown {
                implicitWidth: 190
                options: [{ key: -1, label: Lang.t("Sil…", "Delete…") }, { key: 3600, label: Lang.t("Son bir saat", "Last hour") }, { key: 86400, label: Lang.t("Son bir gün", "Last day") },
                          { key: 604800, label: Lang.t("Son bir hafta", "Last week") }, { key: 0, label: Lang.t("Tüm geçmiş", "All history") }]
                current: -1
                onChosen: key => { if (key >= 0) page.removeSince(key) }
            }
        }
        Text { visible: page.rows.length === 0; text: search.text !== "" ? Lang.t("Eşleşen sayfa yok.", "No page matches.") : Lang.t("Geçmiş boş.", "The history is empty."); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 14 }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            model: page.rows
            // more rows when the end comes near
            onAtYEndChanged: if (atYEnd && page.rows.length === page.shown && page.shown < 5000) { const at = contentY; page.shown += 200; page.reload(); contentY = at }
            delegate: Column {
                id: row
                required property var modelData
                required property int index
                readonly property string day: page.dayOf(modelData.last)
                width: ListView.view.width
                Text { visible: row.index === 0 || page.dayOf(page.rows[row.index - 1].last) !== row.day; text: row.day; color: Theme.accent; font.family: Theme.ui; font.pixelSize: 13; font.variableAxes: Theme.axes(700); topPadding: 8; bottomPadding: 4; leftPadding: 4 }
                AbstractButton {
                    id: entry
                    width: parent.width
                    height: 34
                    hoverEnabled: true
                    onClicked: { page.close(); page.chosen(row.modelData.url) }
                    Accessible.name: row.modelData.title || row.modelData.url
                    background: Rectangle { radius: Theme.radius; color: entry.hovered ? Theme.raised : "transparent" }
                    contentItem: RowLayout {
                        spacing: 10
                        Text { Layout.leftMargin: 6; text: Qt.formatTime(new Date(row.modelData.last * 1000), "HH:mm"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
                        Text { Layout.fillWidth: true; Layout.preferredWidth: 3; text: row.modelData.title || row.modelData.url; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.ui; font.pixelSize: 13 }
                        Text { Layout.fillWidth: true; Layout.preferredWidth: 2; text: row.modelData.url; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
                        IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 12; symbol: "close"; hint: Lang.t("Geçmişten sil", "Remove from history"); onClicked: { const at = list.contentY; History.remove(row.modelData.url); page.reload(); list.contentY = at } }
                    }
                }
            }
        }
    }
}
