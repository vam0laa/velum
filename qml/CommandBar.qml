import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// One box for everything: type an address or a search, jump to an open tab, or run a command.
// It floats over the page; a new tab is only made once something is chosen.
Item {
    id: bar
    property var tabModel
    property var shortcuts: []
    property var commands: []          // [{ name, keys, run }]
    property bool forNewTab: false
    property bool historyOnly: false   // Ctrl+H: the box becomes the history
    property var history: null         // anything with search(text, limit) and remove(url)
    property bool open: false
    property alias query: input.text
    property var results: []

    signal opened(url target, bool inNewTab)
    signal tabChosen(int index)
    signal dismissed()

    function show(newTab, text, onlyHistory) {
        historyOnly = onlyHistory === true
        forNewTab = newTab
        input.text = text ?? ""
        open = true
        refresh()
        input.forceActiveFocus()
        input.selectAll()
    }

    function hide() {
        if (!open)
            return
        open = false
        historyOnly = false
        dismissed()
    }

    // What matches the typed text, best first.
    function find(text) {
        const q = text.trim().toLocaleLowerCase()
        const has = s => String(s).toLocaleLowerCase().indexOf(q) >= 0
        const out = []
        const visited = limit => (history ? history.search(text.trim(), limit) : []).map(p => (
            { kind: "history", icon: "history", title: p.title === "" ? Address.display(p.url) : p.title, note: Address.display(p.url).slice(0, 48), url: p.url }))
        if (historyOnly)
            return visited(60)
        if (q !== "") {
            const target = Address.resolve(text)
            const searching = Address.isSearch(text)
            out.push({ kind: "go", icon: searching ? "search" : "globe", title: searching ? text.trim() : Address.display(target),
                       note: searching ? Lang.t(Address.engineName + " ile ara", "Search with " + Address.engineName) : Lang.t("Aç", "Open"), url: target })
        }
        for (let i = 0; i < (tabModel ? tabModel.count : 0); i++) {
            const t = tabModel.get(i)
            const name = t.kind === "settings" ? Lang.t("Ayarlar", "Settings") : t.title
            if (name !== "" && (q === "" || has(name) || has(t.pageUrl)))
                out.push({ kind: "tab", icon: "panel", title: name, note: Lang.t("Sekmeye geç", "Switch to tab"), index: i })
        }
        for (const s of shortcuts)
            if (q !== "" && (has(s.title) || has(s.url)))
                out.push({ kind: "shortcut", icon: "star", title: s.title, note: Lang.t("Yer imi", "Bookmark"), url: s.url })
        for (const c of commands)
            if (q === "" || has(c.name))
                out.push({ kind: "command", icon: "command", title: c.name, note: c.keys, run: c.run })
        // history fills what is left, without repeating an address already offered
        if (q !== "") {
            const seen = new Set(out.map(r => String(r.url)))
            for (const p of visited(6))
                if (!seen.has(String(p.url)))
                    out.push(p)
        }
        return out.slice(0, 8)
    }

    function refresh() {
        results = find(input.text)
        list.currentIndex = 0
    }

    function forget(i) {
        const r = results[i]
        if (r && r.kind === "history") {
            history.remove(r.url)
            refresh()
        }
    }

    function choose(i) {
        const r = results[i]
        if (!r)
            return
        const newTab = forNewTab
        open = false
        if (r.kind === "tab")
            tabChosen(r.index)
        else if (r.kind === "command")
            r.run()
        else if (String(r.url) !== "")
            opened(r.url, newTab)
        dismissed()
    }

    visible: opacity > 0
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.quick } }

    // dim the page; a click outside closes the box
    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        MouseArea { anchors.fill: parent; onClicked: bar.hide(); onWheel: wheel => wheel.accepted = true }
    }

    Rectangle {
        id: panel
        width: Math.min(parent.width - 48, 620)
        height: column.implicitHeight + 48
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, parent.height * 0.18) - (bar.open ? 0 : 10)
        color: "transparent"
        WindowBackground { anchors.fill: parent; title: bar.historyOnly ? Lang.t("geçmiş", "history") : Lang.t("ara ve çalıştır", "search and run"); stripe: Theme.pink }
        Behavior on y { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }   // clicks inside stay inside

        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; topMargin: 38 }
            spacing: 4

            RowLayout {
                spacing: 10
                Layout.leftMargin: 10
                Icon { name: bar.historyOnly ? "history" : bar.forNewTab ? "plus" : "search"; color: Theme.accent }
                TextField {
                    id: input
                    Layout.fillWidth: true
                    implicitHeight: 44
                    placeholderText: bar.historyOnly ? Lang.t("Geçmişte ara (Shift+Delete: sil)", "Search history (Shift+Delete: remove)") : bar.forNewTab ? Lang.t("Yeni sekmede aç: adres, arama ya da komut", "Open in a new tab: address, search or command") : Lang.t("Adres, arama ya da komut", "Address, search or command")
                    placeholderTextColor: Theme.dim
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.onAccent
                    font.pixelSize: 16
                    selectByMouse: true
                    background: null
                    onTextEdited: bar.refresh()
                    onAccepted: bar.choose(list.currentIndex)
                    Keys.onEscapePressed: bar.hide()
                    Keys.onDeletePressed: event => {
                        if (event.modifiers & Qt.ShiftModifier)
                            bar.forget(list.currentIndex)
                        else
                            event.accepted = false
                    }
                    Keys.onDownPressed: list.currentIndex = (list.currentIndex + 1) % Math.max(1, list.count)
                    Keys.onUpPressed: list.currentIndex = (list.currentIndex - 1 + list.count) % Math.max(1, list.count)
                    Keys.onTabPressed: list.currentIndex = (list.currentIndex + 1) % Math.max(1, list.count)
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line; visible: list.count > 0 }
            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, Math.max(120, bar.height * 0.6))
                interactive: contentHeight > height
                clip: true
                model: bar.results
                delegate: ItemDelegate {
                    id: row
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    height: 40
                    padding: 0
                    focusPolicy: Qt.NoFocus
                    hoverEnabled: true
                    onHoveredChanged: if (hovered) list.currentIndex = index
                    onClicked: bar.choose(index)
                    background: Rectangle { radius: Theme.radius; color: row.ListView.isCurrentItem ? Theme.raised : "transparent" }
                    contentItem: RowLayout {
                        spacing: 10
                        Icon { Layout.leftMargin: 10; name: row.modelData.icon; size: 16; color: row.ListView.isCurrentItem ? Theme.accent : Theme.dim }
                        Text { Layout.fillWidth: true; text: row.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.pixelSize: 13 }
                        Text { Layout.rightMargin: 12; Layout.maximumWidth: row.width * 0.4; text: row.modelData.note; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 11 }
                    }
                }
            }
        }
    }
}
