import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The accent colours, and every theme as a small picture of the browser.
ColumnLayout {
    id: picker
    spacing: 12

    RowLayout {
        spacing: 10
        Text { text: Lang.t("Vurgu rengi", "Accent colour"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
        AccentDots {}
    }

    Flow {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: Theme.themes
            AbstractButton {
                id: card
                required property var modelData
                readonly property bool current: Theme.palette === modelData.key
                function color(i) { return Theme.colorOf(modelData.key, i) }
                implicitWidth: 118
                implicitHeight: 100
                hoverEnabled: true
                onClicked: if (!current) Theme.change(() => Theme.palette = modelData.key)
                Accessible.name: modelData.label
                background: Rectangle {
                    radius: Theme.radius
                    color: card.hovered || card.current ? Theme.raised : "transparent"
                    border.width: card.current ? 2 : 0
                    border.color: Theme.accent
                }
                contentItem: Item {
                    // a tiny window: frame, side bar, page and three coloured marks
                    Rectangle {
                        anchors { top: parent.top; topMargin: 7; horizontalCenter: parent.horizontalCenter }
                        width: 104
                        height: 62
                        radius: Theme.radius
                        color: card.color(0)
                        border.color: Theme.line
                        Rectangle {
                            x: 5; y: 5; width: 28; height: 52; radius: Theme.radius; color: card.color(1)
                            Column {
                                x: 4; y: 6; spacing: 4
                                Repeater {
                                    model: [8, 10, 12]
                                    Rectangle { required property int modelData; width: 20; height: 5; radius: Theme.radius; color: card.color(modelData) }
                                }
                            }
                        }
                        Rectangle {
                            x: 37; y: 5; width: 62; height: 52; radius: Theme.radius; color: card.color(2)
                            Rectangle { x: 7; y: 9; width: 36; height: 6; radius: Theme.radius; color: card.color(6) }
                            Rectangle { x: 7; y: 20; width: 46; height: 4; radius: Theme.radius; color: card.color(7) }
                            Rectangle { x: 7; y: 35; width: 26; height: 10; radius: Theme.radius; color: card.color(8) }
                        }
                    }
                    Text {
                        anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter }
                        text: card.modelData.label
                        color: card.current ? Theme.text : Theme.dim
                        font.family: Theme.ui; font.pixelSize: Theme.size(16)
                        font.weight: card.current ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
