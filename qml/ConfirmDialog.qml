import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// "Are you sure?" for things that cannot be taken back.
Popup {
    id: dialog
    property string heading
    property string detail
    property string action
    property string cancel: Lang.t("Vazgeç", "Cancel")
    signal confirmed()

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 380
    padding: 18
    enter: PopIn {}
    exit: PopOut {}
    background: Rectangle { radius: 16; color: "#171a20"; border.color: "#ff8a8a" }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 12
        Text { Layout.fillWidth: true; text: dialog.heading; textFormat: Text.PlainText; color: "#eef0f4"; font.family: Theme.sansFont.name; font.pixelSize: Theme.size(20); font.weight: Font.Normal; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; text: dialog.detail; textFormat: Text.PlainText; color: "#a8aebb"; font.family: Theme.sansFont.name; font.pixelSize: Theme.size(17); wrapMode: Text.WordWrap }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            SafeButton { text: dialog.cancel; onClicked: dialog.close() }
            SafeButton { text: dialog.action; strong: true; onClicked: { dialog.close(); dialog.confirmed() } }
        }
    }
}
