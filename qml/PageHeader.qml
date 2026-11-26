import QtQuick
import QtQuick.Controls

// The top of Velum's own pages: the mark on the left; on the right the settings and a
// round button for the workspace you are in.
Item {
    id: header
    property bool branded: true          // false: the side bar already shows the mark
    property var spaces: []
    property int space
    signal settings()
    signal spaceChosen(int id)
    signal spaceAdd()
    signal privateWindow()
    implicitHeight: 68
    // an empty name reads "General"
    readonly property string spaceName: spaces.find(s => s.id === space)?.name || Lang.t("Genel", "General")

    Brand { x: 32; anchors.verticalCenter: parent.verticalCenter; visible: header.branded }
    Row {
        anchors { right: parent.right; rightMargin: 32; verticalCenter: parent.verticalCenter }
        spacing: 8
        AbstractButton {
            id: tune
            width: 36; height: 36
            hoverEnabled: true
            onClicked: header.settings()
            Accessible.name: Lang.t("Ayarlar", "Settings")
            background: Rectangle { radius: height / 2; color: tune.hovered ? Theme.raised : "transparent"; border.color: tune.hovered ? Theme.line : "transparent" }
            contentItem: Item { Icon { anchors.centerIn: parent; name: "settings"; size: 19; color: tune.hovered ? Theme.text : Theme.dim } }
        }
        AbstractButton {
            id: avatar
            width: 32; height: 32
            anchors.verticalCenter: parent.verticalCenter
            hoverEnabled: true
            onClicked: menu.popup(avatar, avatar.width - menu.width, avatar.height + 6)
            Accessible.name: Lang.t("Çalışma alanı: ", "Workspace: ") + header.spaceName
            background: Rectangle { radius: height / 2; color: avatar.hovered ? Theme.title : Theme.raised; border.color: avatar.hovered ? Qt.alpha(Theme.accent, 0.6) : Theme.line }
            contentItem: Text { text: header.spaceName.slice(0, 2).toLocaleUpperCase(Lang.turkish ? "tr_TR" : "en_US"); textFormat: Text.PlainText; color: Theme.text; font.family: Theme.ui; font.pixelSize: 11; font.variableAxes: Theme.axes(550); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
    AppMenu {
        id: menu
        Instantiator {
            model: header.spaces
            delegate: AppMenuItem {
                required property var modelData
                text: (modelData.id === header.space ? "● " : "   ") + (modelData.name || Lang.t("Genel", "General"))
                onTriggered: header.spaceChosen(modelData.id)
            }
            onObjectAdded: (i, item) => menu.insertItem(i, item)
            onObjectRemoved: (i, item) => menu.removeItem(item)
        }
        AppMenuItem { text: Lang.t("Yeni çalışma alanı…", "New workspace…"); onTriggered: header.spaceAdd() }
        AppMenuItem { text: Lang.t("Yeni gizli pencere", "New private window"); onTriggered: header.privateWindow() }
    }
}
