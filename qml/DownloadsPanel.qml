import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

// The downloads of this run. Velum never opens a downloaded file by itself;
// it only shows the folder it is in.
Popup {
    id: panel
    property var downloads: []
    signal showFolder(string folder)
    signal clearFinished()

    width: 340
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

    function describe(state, received, total) {
        switch (state) {
        case WebEngineDownloadRequest.DownloadCompleted: return Lang.t("Bitti · ", "Done · ") + size(received)
        case WebEngineDownloadRequest.DownloadCancelled: return Lang.t("İptal edildi", "Cancelled")
        case WebEngineDownloadRequest.DownloadInterrupted: return Lang.t("Yarıda kaldı", "Interrupted")
        }
        return total > 0 ? size(received) + " / " + size(total) : size(received)
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 8
        RowLayout {
            Item { Layout.fillWidth: true }
            TextButton { text: Lang.t("Bitenleri temizle", "Clear finished"); visible: panel.downloads.length > 0; onClicked: panel.clearFinished() }
        }
        Text { visible: panel.downloads.length === 0; text: Lang.t("Henüz bir şey indirmedin.", "Nothing downloaded yet."); color: Theme.dim; font.pixelSize: 12 }
        ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 320)
            clip: true
            spacing: 6
            model: panel.downloads
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool running: modelData.state === WebEngineDownloadRequest.DownloadInProgress
                width: ListView.view.width
                height: 54
                radius: Theme.radius
                color: Theme.frame
                ColumnLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
                    spacing: 2
                    RowLayout {
                        Text { Layout.fillWidth: true; text: row.modelData.downloadFileName; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.pixelSize: 12 }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 14; symbol: "folder"; hint: Lang.t("Klasörde göster", "Show in folder"); onClicked: panel.showFolder(row.modelData.downloadDirectory) }
                        IconButton { implicitWidth: 26; implicitHeight: 26; iconSize: 13; symbol: "close"; hint: Lang.t("İptal", "Cancel"); visible: row.running; onClicked: row.modelData.cancel() }
                    }
                    Text { text: panel.describe(row.modelData.state, row.modelData.receivedBytes, row.modelData.totalBytes); color: Theme.dim; font.pixelSize: 11 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.rightMargin: 4
                        implicitHeight: 3
                        radius: 2
                        color: Theme.raised
                        visible: row.running
                        Rectangle { height: parent.height; radius: 2; color: Theme.accent; width: row.modelData.totalBytes > 0 ? parent.width * row.modelData.receivedBytes / row.modelData.totalBytes : 0 }
                    }
                }
            }
        }
    }
}
