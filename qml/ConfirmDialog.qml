import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// "Are you sure?" for things that cannot be taken back.
Popup {
    id: dialog
    property string heading
    property string detail
    property string action
    signal confirmed()

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 380
    padding: 18
    background: Rectangle { radius: 16; color: Theme.frame; border.color: Theme.line }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 12
        Text { Layout.fillWidth: true; text: dialog.heading; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; text: dialog.detail; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            TextButton { text: "Vazgeç"; onClicked: dialog.close() }
            TextButton { text: dialog.action; strong: true; onClicked: { dialog.close(); dialog.confirmed() } }
        }
    }
}
