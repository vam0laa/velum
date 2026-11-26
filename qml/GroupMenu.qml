import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A group's menu (right click on its name): rename, colour, fold, take apart, close.
Popup {
    id: menu
    property var app
    property int group: 0
    readonly property var info: app ? app.groups.find(g => g.id === group) ?? null : null

    function showFor(id, at) {
        group = id
        name.text = info?.name ?? ""
        const point = at.mapToItem(parent, 0, at.height + 4)
        x = Math.min(point.x, parent.width - width - 8)
        y = point.y
        open()
    }

    width: 250
    padding: 12
    enter: PopIn {}
    exit: PopOut {}
    background: Rectangle { radius: Theme.radius; color: Theme.window; border.color: Theme.line }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 8
        TextField {
            id: name
            Layout.fillWidth: true
            implicitHeight: 32
            leftPadding: 10
            maximumLength: 24
            color: Theme.text
            font.family: Theme.ui; font.pixelSize: 13
            background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: name.activeFocus ? Theme.accent : Theme.line }
            onTextEdited: if (text.trim() !== "") menu.app.changeGroup(menu.group, { name: text.trim() })
            onAccepted: menu.close()
        }
        Row {
            spacing: 8
            Repeater {
                model: ["accent", "mauve", "pink", "green", "peach", "danger"]
                AbstractButton {
                    required property string modelData
                    width: 26; height: 26
                    Accessible.name: modelData
                    onClicked: menu.app.changeGroup(menu.group, { colour: modelData })
                    background: Rectangle { radius: 13; color: Theme[parent.modelData]; border.width: menu.info?.colour === parent.modelData ? 3 : 0; border.color: Theme.text }
                }
            }
        }
        TextButton { Layout.fillWidth: true; text: menu.info?.collapsed ? Lang.t("Grubu aç", "Unfold the group") : Lang.t("Grubu katla", "Fold the group"); onClicked: { menu.app.toggleGroup(menu.group); menu.close() } }
        TextButton { Layout.fillWidth: true; text: Lang.t("Grubu dağıt", "Take the group apart"); onClicked: { menu.app.dissolveGroup(menu.group); menu.close() } }
        TextButton { Layout.fillWidth: true; text: Lang.t("Gruptaki sekmeleri kapat", "Close the group's tabs"); onClicked: { menu.app.closeGroup(menu.group); menu.close() } }
    }
}
