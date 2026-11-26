import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The bookmark manager (Ctrl+Shift+O): folders on the left, bookmarks on the right.
// It only shows and asks; the window keeps the list and makes the changes.
Popup {
    id: page
    property var items: []              // [{ title, url, folder }], the first ten are on the start page
    property string folder: "*"         // the folder shown; "*" is everything
    property string query: ""
    property int editing: -2            // the row being edited; -1 is a new bookmark, -2 none
    property bool renaming: false
    property string error: ""
    property var undo: null             // the last deleted bookmark: { item, index }

    // returns true when the change was accepted
    property var save: (index, title, address, folder) => false
    signal removed(int index)
    signal restored(var item, int index)
    signal moved(int from, int to)
    signal folderRenamed(string from, string to)
    signal chosen(url target)

    readonly property var folders: [...new Set(items.map(b => b.folder ?? "").filter(f => f !== ""))].sort((a, b) => a.localeCompare(b))
    readonly property var rows: filtered(items, folder, query)

    function filtered(list, inFolder, text) {
        const q = text.trim().toLocaleLowerCase()
        const out = []
        for (let i = 0; i < list.length; i++) {
            const b = list[i]
            if (inFolder !== "*" && (b.folder ?? "") !== inFolder)
                continue
            if (q !== "" && (b.title + " " + b.url).toLocaleLowerCase().indexOf(q) < 0)
                continue
            out.push({ index: i, title: b.title, url: b.url, folder: b.folder ?? "" })
        }
        return out
    }

    function edit(index) {
        const b = index >= 0 ? items[index] : null
        error = ""
        editing = index
        nameField.text = b?.title ?? ""
        addressField.text = b?.url ?? ""
        folderField.text = b ? (b.folder ?? "") : (folder === "*" ? "" : folder)
        ;(b ? nameField : addressField).forceActiveFocus()
    }

    function commit() {
        if (save(editing, nameField.text, addressField.text, folderField.text))
            editing = -2
        else
            error = Lang.t("Bu adres geçersiz ya da zaten kayıtlı.", "That address is not valid, or is already saved.")
    }

    function remove(index) {
        undo = { item: items[index], index: index }
        editing = -2
        removed(index)
    }

    // a folder that emptied or was renamed is no longer there to be shown
    onFoldersChanged: if (folder !== "*" && folder !== "" && folders.indexOf(folder) < 0) folder = "*"
    onFolderChanged: { renaming = false; editing = -2 }
    onOpened: { editing = -2; renaming = false; undo = null; query = ""; search.text = ""; search.forceActiveFocus() }

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(820, Overlay.overlay.width - 32)
    height: Math.min(600, Overlay.overlay.height - 32)
    padding: 4
    topPadding: 34
    background: WindowBackground { title: Lang.t("yer imleri", "bookmarks"); stripe: Theme.peach }

    component Field: TextField {
        id: field
        implicitHeight: 34
        leftPadding: 12
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        placeholderTextColor: Theme.dim
        font.pixelSize: 13
        selectByMouse: true
        background: Rectangle { radius: height / 2; color: Theme.frame; border.color: field.activeFocus ? Theme.accent : Theme.line }
    }

    component Entry: AbstractButton {
        id: entry
        property bool current: false
        Layout.fillWidth: true
        implicitHeight: 32
        hoverEnabled: true
        contentItem: Text { text: entry.text; textFormat: Text.PlainText; elide: Text.ElideRight; color: entry.current ? Theme.text : Theme.dim; font.pixelSize: 13; leftPadding: 10; rightPadding: 8; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: Theme.radius; color: entry.current ? Theme.raised : entry.hovered ? Theme.surface : "transparent" }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Flickable {
            Layout.fillWidth: false
            Layout.preferredWidth: 170
            Layout.fillHeight: true
            Layout.margins: 10
            contentHeight: names.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: names
                width: parent.width
                spacing: 4
                Entry { text: Lang.t("Tümü", "All") + "  (" + page.items.length + ")"; current: page.folder === "*"; onClicked: page.folder = "*" }
                Entry { text: Lang.t("Klasörsüz", "No folder"); visible: page.folders.length > 0; current: page.folder === ""; onClicked: page.folder = "" }
                Repeater {
                    model: page.folders
                    Entry {
                        required property string modelData
                        text: modelData
                        current: page.folder === modelData
                        onClicked: page.folder = modelData
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            color: Theme.surface
            radius: Theme.radius + 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Field {
                        id: search
                        Layout.fillWidth: true
                        placeholderText: Lang.t("Yer imlerinde ara", "Search bookmarks")
                        onTextEdited: page.query = text
                    }
                    TextButton { text: Lang.t("Yeni ekle", "Add new"); strong: true; onClicked: page.edit(-1) }
                }

                // the chosen folder can be renamed, or dissolved
                RowLayout {
                    Layout.fillWidth: true
                    visible: page.folder !== "*" && page.folder !== ""
                    spacing: 8
                    Field { id: folderName; Layout.fillWidth: true; visible: page.renaming; maximumLength: 40; onAccepted: { page.renaming = false; const to = text.trim(); if (to !== "") { const from = page.folder; page.folderRenamed(from, to); page.folder = to } } }
                    Item { Layout.fillWidth: true; visible: !page.renaming }
                    TextButton { visible: !page.renaming; text: Lang.t("Klasörün adını değiştir", "Rename folder"); onClicked: { folderName.text = page.folder; page.renaming = true; folderName.forceActiveFocus(); folderName.selectAll() } }
                    TextButton { visible: !page.renaming; text: Lang.t("Klasörü dağıt", "Dissolve folder"); onClicked: page.folderRenamed(page.folder, "") }
                }

                // adding and editing
                Rectangle {
                    Layout.fillWidth: true
                    visible: page.editing > -2
                    implicitHeight: form.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.window
                    border.color: Theme.accent
                    ColumnLayout {
                        id: form
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 6
                        Field { id: nameField; Layout.fillWidth: true; placeholderText: Lang.t("Ad", "Name"); maximumLength: 120; onAccepted: page.commit(); Keys.onEscapePressed: page.editing = -2 }
                        Field { id: addressField; Layout.fillWidth: true; placeholderText: Lang.t("Adres", "Address"); onAccepted: page.commit(); Keys.onEscapePressed: page.editing = -2 }
                        Field { id: folderField; Layout.fillWidth: true; placeholderText: Lang.t("Klasör (boş kalabilir, yeni ad yazabilirsin)", "Folder (optional; type a new name to make one)"); maximumLength: 40; onAccepted: page.commit(); Keys.onEscapePressed: page.editing = -2 }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: page.folders.length > 0
                            Repeater {
                                model: page.folders
                                TextButton { required property string modelData; implicitHeight: 26; text: modelData; strong: folderField.text === modelData; onClicked: folderField.text = modelData }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: page.error; color: Theme.danger; font.pixelSize: 12; wrapMode: Text.WordWrap }
                            TextButton { text: Lang.t("Vazgeç", "Cancel"); onClicked: page.editing = -2 }
                            TextButton { text: Lang.t("Kaydet", "Save"); strong: true; onClicked: page.commit() }
                        }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: page.rows
                    // a changed list starts at the top again; stay where you were
                    property real kept: 0
                    onMovementEnded: kept = contentY
                    onModelChanged: Qt.callLater(() => contentY = Math.max(0, Math.min(kept, contentHeight - height)))
                    ScrollBar.vertical: ScrollBar { onPressedChanged: if (!pressed) list.kept = list.contentY }
                    delegate: ItemDelegate {
                        id: row
                        required property int index
                        required property var modelData
                        width: ListView.view.width
                        height: 48
                        padding: 0
                        hoverEnabled: true
                        onClicked: { page.close(); page.chosen(modelData.url) }
                        background: Rectangle { radius: Theme.radius; color: row.hovered ? Theme.raised : Theme.window }
                        contentItem: RowLayout {
                            spacing: 10
                            Rectangle {
                                Layout.leftMargin: 8
                                implicitWidth: 30; implicitHeight: 30; radius: 9
                                color: Theme.rainbow[row.modelData.index % Theme.rainbow.length]
                                Text { anchors.centerIn: parent; text: String(row.modelData.title).charAt(0).toLocaleUpperCase(); textFormat: Text.PlainText; color: Theme.onAccent; font.pixelSize: 14; font.weight: Font.ExtraBold }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { width: parent.width; text: row.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.pixelSize: 13 }
                                Text { width: parent.width; text: (row.modelData.folder !== "" && page.folder === "*" ? row.modelData.folder + "  ·  " : "") + Address.display(row.modelData.url); textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 11 }
                            }
                            Row {
                                Layout.rightMargin: 6
                                visible: row.hovered
                                IconButton { symbol: "up"; implicitWidth: 28; implicitHeight: 28; iconSize: 14; hint: Lang.t("Yukarı", "Up"); enabled: row.index > 0; onClicked: page.moved(row.modelData.index, page.rows[row.index - 1].index) }
                                IconButton { symbol: "down"; implicitWidth: 28; implicitHeight: 28; iconSize: 14; hint: Lang.t("Aşağı", "Down"); enabled: row.index < page.rows.length - 1; onClicked: page.moved(row.modelData.index, page.rows[row.index + 1].index) }
                                IconButton { symbol: "settings"; implicitWidth: 28; implicitHeight: 28; iconSize: 14; hint: Lang.t("Düzenle", "Edit"); onClicked: page.edit(row.modelData.index) }
                                IconButton { symbol: "close"; implicitWidth: 28; implicitHeight: 28; iconSize: 14; hint: Lang.t("Sil", "Delete"); onClicked: page.remove(row.modelData.index) }
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: page.query !== "" ? Lang.t("Eşleşen yer imi yok.", "No bookmark matches.") : Lang.t("Henüz yer imi yok. Bir sayfada Ctrl+D'ye bas.", "No bookmarks yet. Press Ctrl+D on a page.")
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: page.undo ? Lang.t("Silindi: ", "Deleted: ") + page.undo.item.title : Lang.t("İlk 10 yer imi başlangıç sayfasında görünür.", "The first 10 bookmarks appear on the start page.")
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                    TextButton { visible: page.undo !== null; implicitHeight: 28; text: Lang.t("Geri al", "Undo"); onClicked: { const u = page.undo; page.undo = null; page.restored(u.item, u.index) } }
                }
            }
        }
    }
}
