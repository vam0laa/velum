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

    color: Theme.frame

    Panel {
        anchors.centerIn: parent
        width: Math.min(parent.width - 56, 540)
        height: column.implicitHeight + 76
        title: "error.exe"
        stripe: Theme.danger

        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 12
            RowLayout {
                spacing: 14
                Icon { name: "alert"; size: 44; color: Theme.danger }
                Text { Layout.fillWidth: true; text: page.heading; color: Theme.text; font.pixelSize: 24; font.weight: Font.ExtraBold; wrapMode: Text.WordWrap }
            }
            Text { Layout.fillWidth: true; visible: text !== ""; text: page.address; textFormat: Text.PlainText; color: Theme.accent; font.family: Theme.pixel; font.pixelSize: 19; wrapMode: Text.WrapAnywhere; maximumLineCount: 2; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; visible: text !== ""; text: page.detail; textFormat: Text.PlainText; color: Theme.text; font.pixelSize: 14; wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; visible: text !== ""; text: page.advice; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap }
            TextButton { Layout.topMargin: 6; Layout.alignment: Qt.AlignRight; text: Lang.t("Yeniden dene", "Try again"); strong: true; onClicked: page.retry() }
        }
    }
}
