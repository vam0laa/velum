import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// Downloads: those of this run (pause, resume, cancel), then what earlier runs fetched.
// A file is opened only when you ask, and never one that can run programs.
Popup {
    id: panel
    property var downloads: []          // the engine's requests of this run
    property var past: []               // [{ name, folder, url, size, ok, when }], newest first
    property var canOpen: name => true
    signal showFolder(string folder)
    signal clearFinished()
    signal openFile(string folder, string name)
    signal again(string url)
    signal forget(int index)

    width: 400
    padding: 12
    margins: 8                 // never leaves the window
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("indirmeler", "downloads"); stripe: Theme.peach }
    topPadding: 42

    function size(bytes) {
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1).replace(".", Lang.t(",", ".")) + " GB"
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1).replace(".", Lang.t(",", ".")) + " MB"
        return Math.max(0, Math.round(bytes / 1024)) + " KB"
    }

    function describe(state, received, total, paused) {
        switch (state) {
        case WebEngineDownloadRequest.DownloadCompleted: return Lang.t("Bitti · ", "Done · ") + size(received)
        case WebEngineDownloadRequest.DownloadCancelled: return Lang.t("İptal edildi", "Cancelled")
        case WebEngineDownloadRequest.DownloadInterrupted: return Lang.t("Yarıda kaldı", "Interrupted")
        }
        return (paused ? Lang.t("Duraklatıldı · ", "Paused · ") : "") + (total > 0 ? size(received) + " / " + size(total) : size(received))
    }

    // the rows: live ones first, then older ones that are not among them
    readonly property var rows: downloads.map(d => ({ live: d, name: String(d.downloadFileName).replace(/\.velum-hold$/, ""), folder: d.downloadDirectory, url: String(d.url ?? ""), index: -1 }))
        .concat(past.map((p, i) => ({ live: null, name: p.name, folder: p.folder, url: p.url, size: p.size, ok: p.ok, when: p.when, index: i }))
                    .filter(p => !downloads.some(d => String(d.downloadFileName).replace(/\.velum-hold$/, "") === p.name && d.downloadDirectory === p.folder)))

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 8
        RowLayout {
            Item { Layout.fillWidth: true }
            TextButton { text: Lang.t("Listeyi temizle", "Clear the list"); visible: panel.rows.length > 0; onClicked: panel.clearFinished() }
        }
        Text { visible: panel.rows.length === 0; text: Lang.t("Henüz bir şey indirmedin.", "Nothing downloaded yet."); color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
        ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 360)
            clip: true
            spacing: 6
            model: panel.rows
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var live: modelData.live
                readonly property bool running: live !== null && live.state === WebEngineDownloadRequest.DownloadInProgress
                readonly property bool whole: live ? live.state === WebEngineDownloadRequest.DownloadCompleted : modelData.ok === true
                width: ListView.view.width
                height: 56
                radius: Theme.radius
                color: Theme.frame
                ColumnLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
                    spacing: 2
                    RowLayout {
                        spacing: 2
                        Text { Layout.fillWidth: true; text: row.modelData.name; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 13; visible: row.running; symbol: row.live?.isPaused ? "play" : "pause"; hint: row.live?.isPaused ? Lang.t("Sürdür", "Resume") : Lang.t("Duraklat", "Pause"); onClicked: row.live.isPaused ? row.live.resume() : row.live.pause() }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 13; visible: row.running; symbol: "close"; hint: Lang.t("İptal", "Cancel"); onClicked: row.live.cancel() }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 14; visible: row.whole && panel.canOpen(row.modelData.name); symbol: "book"; hint: Lang.t("Dosyayı aç", "Open the file"); onClicked: panel.openFile(row.modelData.folder, row.modelData.name) }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 13; visible: !row.running && !row.whole && row.modelData.url !== ""; symbol: "reload"; hint: Lang.t("Yeniden indir", "Download again"); onClicked: panel.again(row.modelData.url) }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 14; symbol: "folder"; hint: Lang.t("Klasörde göster", "Show in folder"); onClicked: panel.showFolder(row.modelData.folder) }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 12; visible: row.live === null; symbol: "close"; hint: Lang.t("Listeden kaldır (dosya kalır)", "Remove from the list (the file stays)"); onClicked: panel.forget(row.modelData.index) }
                    }
                    Text {
                        text: row.live ? panel.describe(row.live.state, row.live.receivedBytes, row.live.totalBytes, row.live.isPaused)
                                       : (row.modelData.ok ? panel.size(row.modelData.size) : Lang.t("Tamamlanmadı", "Not completed")) + " · " + new Date(row.modelData.when).toLocaleDateString(Qt.locale(Lang.turkish ? "tr_TR" : "en_GB"), Locale.ShortFormat)
                        color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(14)
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.rightMargin: 4
                        implicitHeight: 3
                        radius: Theme.radius
                        color: Theme.raised
                        visible: row.running
                        Rectangle { height: parent.height; radius: Theme.radius; color: Theme.accent; width: row.live && row.live.totalBytes > 0 ? parent.width * row.live.receivedBytes / row.live.totalBytes : 0 }
                    }
                }
            }
        }
    }
}
