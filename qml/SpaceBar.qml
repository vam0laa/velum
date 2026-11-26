import QtQuick
import QtQuick.Controls

// The workspaces as coloured chips: the chosen one shows its name.
// Click to switch, right click to rename or delete, "+" to add.
Flow {
    id: bar
    property var spaces: []
    property int space
    property bool compact: false
    signal chosen(int id)
    signal edit(int id)
    signal add()
    spacing: 6

    Repeater {
        model: bar.spaces
        AbstractButton {
            id: chip
            required property int index
            required property var modelData
            readonly property bool current: modelData.id === bar.space
            readonly property color tone: Theme.rainbow[index % Theme.rainbow.length]
            readonly property string label: modelData.name || Lang.t("Genel", "General")
            readonly property bool wide: current && !bar.compact
            implicitHeight: 28
            implicitWidth: wide ? Math.min(words.implicitWidth + 24, 150) : 28
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onClicked: bar.chosen(modelData.id)
            Accessible.name: label
            Behavior on implicitWidth { NumberAnimation { duration: Theme.smooth; easing.type: Easing.OutCubic } }
            background: Rectangle {
                radius: height / 2
                color: chip.current ? chip.tone : Qt.alpha(chip.tone, chip.hovered ? 0.35 : 0.18)
            }
            contentItem: Text {
                id: words
                text: chip.wide ? chip.label : chip.label.charAt(0).toLocaleUpperCase()
                textFormat: Text.PlainText
                elide: Text.ElideRight
                leftPadding: chip.wide ? 8 : 0
                rightPadding: chip.wide ? 8 : 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: chip.current ? Theme.onAccent : chip.tone
                font.pixelSize: 12
                font.weight: Font.Bold
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: bar.edit(chip.modelData.id)
            }
            Hint {
                text: chip.label + "  ·  Alt+" + (chip.index + 1) + Lang.t("  ·  sağ tık: düzenle", "  ·  right click: edit")
                shown: chip.hovered
                y: -height - 6
            }
        }
    }
    IconButton {
        visible: bar.spaces.length < 6
        implicitWidth: 28
        implicitHeight: 28
        iconSize: 14
        symbol: "plus"
        hint: Lang.t("Yeni çalışma alanı", "New workspace")
        hintBeside: true
        onClicked: bar.add()
    }
}
