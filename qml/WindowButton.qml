import QtQuick
import QtQuick.Controls

// [_] [□] [×], drawn so that they look the same with every font.
AbstractButton {
    id: button
    property string kind          // "min", "max" or "close"
    property string hint
    property color ink: Theme.barInk
    implicitWidth: 22
    implicitHeight: 20
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    Accessible.name: hint
    background: Rectangle { color: button.hovered ? (button.kind === "close" ? Theme.danger : Qt.alpha("#ffffff", 0.28)) : "transparent"; border.color: button.ink; border.width: 1 }
    contentItem: Item {
        Rectangle { visible: button.kind === "min"; width: 10; height: 2; x: (parent.width - width) / 2; y: parent.height - 6; color: button.ink }
        Rectangle { visible: button.kind === "max"; anchors.centerIn: parent; width: 10; height: 9; color: "transparent"; border.color: button.ink; Rectangle { width: parent.width; height: 3; color: button.ink } }
        Text { visible: button.kind === "close"; anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: "x"; color: button.ink; font.pixelSize: 21 }
    }
    Hint { text: button.hint; shown: button.hovered; y: button.height + 6; x: button.width - width }
}
