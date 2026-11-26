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
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("onay", "confirm"); stripe: Theme.danger }
    topPadding: 42

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 12
        Text { Layout.fillWidth: true; text: dialog.heading; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(20); font.weight: Font.Normal; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; text: dialog.detail; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(17); wrapMode: Text.WordWrap }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            TextButton { text: Lang.t("Vazgeç", "Cancel"); onClicked: dialog.close() }
            TextButton { text: dialog.action; strong: true; onClicked: { dialog.close(); dialog.confirmed() } }
        }
    }
}
