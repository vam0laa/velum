import QtQuick
import QtQuick.Controls

// Where the tabs go: down the side, or along the top.
Row {
    id: picker
    property bool horizontal
    signal chosen(bool horizontal)
    spacing: 12

    Repeater {
        model: [false, true]
        AbstractButton {
            id: card
            required property bool modelData
            readonly property bool current: picker.horizontal === modelData
            implicitWidth: 176
            implicitHeight: 138
            hoverEnabled: true
            onClicked: picker.chosen(modelData)
            Accessible.name: label.text
            background: Rectangle {
                radius: Theme.radius
                color: card.hovered || card.current ? Theme.raised : Theme.window
                border.width: card.current ? 2 : 1
                border.color: card.current ? Theme.accent : Theme.line
            }
            contentItem: Item {
                Rectangle {
                    anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
                    width: 150
                    height: 90
                    radius: Theme.radius
                    color: Theme.frame
                    // the bar with the tabs, then the page
                    Rectangle {
                        x: 6; y: 6
                        width: card.modelData ? 138 : 40
                        height: card.modelData ? 24 : 78
                        radius: Theme.radius
                        color: Theme.surface
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                x: card.modelData ? 6 + index * 36 : 6
                                y: card.modelData ? 6 : 10 + index * 13
                                width: card.modelData ? 30 : 28
                                height: card.modelData ? 6 : 7
                                radius: Theme.radius
                                color: Theme.rainbow[index]
                            }
                        }
                        Rectangle { visible: card.modelData; x: 6; y: 15; width: 126; height: 5; radius: Theme.radius; color: Theme.line }
                    }
                    Rectangle {
                        x: card.modelData ? 6 : 52
                        y: card.modelData ? 35 : 6
                        width: card.modelData ? 138 : 92
                        height: card.modelData ? 49 : 78
                        radius: Theme.radius
                        color: Theme.surface
                        Rectangle { x: 10; y: 10; width: parent.width * 0.5; height: 6; radius: Theme.radius; color: Theme.text; opacity: 0.8 }
                        Rectangle { x: 10; y: 22; width: parent.width * 0.7; height: 4; radius: Theme.radius; color: Theme.dim; opacity: 0.7 }
                    }
                }
                Text {
                    id: label
                    anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
                    text: card.modelData ? Lang.t("Yatay sekmeler", "Tabs on top") : Lang.t("Dikey sekmeler", "Tabs on the side")
                    color: card.current ? Theme.text : Theme.dim
                    font.family: Theme.ui; font.pixelSize: Theme.size(16)
                    font.weight: card.current ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
