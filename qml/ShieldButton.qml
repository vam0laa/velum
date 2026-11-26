import QtQuick

// The shield: how much was blocked here, and its panel.
IconButton {
    id: button
    property string host                // of the current page
    property bool beside: false         // the panel opens to the right instead of below
    signal reload()
    signal clearRequested()
    readonly property int blocked: Shield.blockedCount(host, Shield.revision)
    symbol: "shield"
    hint: Lang.t("Koruma", "Protection")
    hintBeside: beside
    opacity: Shield.enabled && !Shield.allowed(host, Shield.revision) ? 1 : 0.45
    onClicked: panel.open()
    Rectangle {
        visible: button.blocked > 0
        anchors { right: parent.right; top: parent.top; rightMargin: -2; topMargin: -2 }
        height: 14
        width: Math.max(14, count.implicitWidth + 6)
        radius: 0
        color: Theme.green
        Text { id: count; anchors.centerIn: parent; text: button.blocked > 99 ? "99+" : button.blocked; color: Theme.accentInk; font.pixelSize: 12; font.weight: Font.Normal }
    }
    ShieldPanel {
        id: panel
        host: button.host
        x: button.beside ? button.width + 8 : button.width - width
        y: button.beside ? 0 : button.height + 6
        onReload: button.reload()
        onClearRequested: button.clearRequested()
    }
}
