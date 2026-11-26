import QtQuick
import QtQuick.Controls

// One choice among many: the chosen one on a button, the rest in a list under it.
AbstractButton {
    id: drop
    property var options: []         // [{ key, label, color? }]
    property var current
    readonly property var chosenOption: options.find(o => o.key === current) ?? null
    signal chosen(var key)
    implicitHeight: 34
    implicitWidth: 168
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    onClicked: list.open()
    Accessible.name: chosenOption?.label ?? ""

    background: Rectangle { radius: Theme.radius; color: drop.hovered || list.opened ? Theme.title : Theme.raised }
    contentItem: Item {
        Rectangle { id: swatch; visible: drop.chosenOption?.color !== undefined; x: 12; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: Theme.radius; color: drop.chosenOption?.color ?? "transparent" }
        Text { anchors { left: parent.left; leftMargin: swatch.visible ? 32 : 12; right: arrow.left; rightMargin: 6; verticalCenter: parent.verticalCenter } text: drop.chosenOption?.label ?? ""; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17); elide: Text.ElideRight }
        Icon { id: arrow; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } name: "down"; size: 14; color: Theme.dim }
    }

    Popup {
        id: list
        y: drop.height + 4
        x: drop.width - width
        width: Math.max(drop.width, 180)
        height: Math.min(rows.contentHeight + 12, 320)
        padding: 6
        margins: 8
        enter: PopIn {}
        exit: PopOut {}
        background: Rectangle { radius: Theme.radius; color: Theme.window; border.color: Theme.line; Shadow { radius: Theme.radius } }
        contentItem: ListView {
            id: rows
            clip: true
            model: drop.options
            boundsBehavior: Flickable.StopAtBounds
            delegate: ItemDelegate {
                id: row
                required property var modelData
                width: ListView.view.width
                height: 32
                padding: 0
                onClicked: { list.close(); drop.chosen(modelData.key) }
                background: Rectangle { radius: Theme.radius; color: row.hovered ? Theme.raised : "transparent" }
                contentItem: Item {
                    Rectangle { id: mark; visible: row.modelData.color !== undefined; x: 10; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: Theme.radius; color: row.modelData.color ?? "transparent" }
                    Text { x: mark.visible ? 30 : 10; anchors.verticalCenter: parent.verticalCenter; text: row.modelData.label; color: drop.current === row.modelData.key ? Theme.accent : Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(17); font.weight: drop.current === row.modelData.key ? Font.Bold : Font.Normal }
                }
            }
        }
    }
}
