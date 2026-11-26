import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// "Save this password?" after a login. Nothing is saved without a yes.
Rectangle {
    id: bar
    property var offer: null            // { origin, user, password, changed }
    property alias user: name.text
    signal accepted(string user)
    signal later()
    signal never()

    onOfferChanged: name.text = offer?.user ?? ""

    width: 380
    height: column.implicitHeight + 28
    radius: 0
    color: Theme.window
    border.color: Theme.green

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 9
        Text {
            Layout.fillWidth: true
            text: bar.offer?.changed ? Lang.t("Kayıtlı parola güncellensin mi?", "Update the saved password?") : Lang.t("Parola kaydedilsin mi?", "Save this password?")
            color: Theme.text
            font.pixelSize: 18
            font.weight: Font.Normal
        }
        Text { Layout.fillWidth: true; text: bar.offer?.origin ?? ""; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.pixelSize: 16 }
        TextField {
            id: name
            Layout.fillWidth: true
            implicitHeight: 34
            leftPadding: 12
            enabled: !(bar.offer?.changed ?? false)
            placeholderText: Lang.t("Kullanıcı adı", "User name")
            placeholderTextColor: Theme.dim
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.pixelSize: 17
            background: Rectangle { radius: 0; color: Theme.frame; border.color: name.activeFocus ? Theme.accent : Theme.line }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextButton { text: Lang.t("Bu sitede asla", "Never here"); onClicked: bar.never() }
            Item { Layout.fillWidth: true }
            TextButton { text: Lang.t("Şimdi değil", "Not now"); onClicked: bar.later() }
            TextButton { text: bar.offer?.changed ? Lang.t("Güncelle", "Update") : Lang.t("Kaydet", "Save"); strong: true; onClicked: bar.accepted(name.text.trim()) }
        }
    }
}
