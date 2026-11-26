import QtQuick
import QtQuick.Layouts

// Shown instead of an empty page when a site cannot be opened or a tab has crashed.
Rectangle {
    id: page
    property string heading
    property string detail
    property string address
    property string advice
    signal retry()

    color: Theme.surface

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 480)
        spacing: 12
        Icon { name: "alert"; size: 44; color: Theme.accent }
        Text { Layout.fillWidth: true; text: page.heading; color: Theme.text; font.pixelSize: 24; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; visible: text !== ""; text: page.address; textFormat: Text.PlainText; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WrapAnywhere; maximumLineCount: 2; elide: Text.ElideRight }
        Text { Layout.fillWidth: true; visible: text !== ""; text: page.detail; textFormat: Text.PlainText; color: Theme.text; font.pixelSize: 14; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; visible: text !== ""; text: page.advice; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap }
        TextButton { Layout.topMargin: 6; text: "Yeniden dene"; strong: true; onClicked: page.retry() }
    }
}
