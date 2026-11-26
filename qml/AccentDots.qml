import QtQuick
import QtQuick.Controls

// The accent colours as dots.
Row {
    spacing: 6
    Repeater {
        model: ["blue", "mauve", "pink", "green", "peach", "red"]
        AbstractButton {
            id: dot
            required property string modelData
            readonly property bool current: (Theme.accentChoice || "blue") === modelData
            implicitWidth: 24
            implicitHeight: 24
            onClicked: if (!current) Theme.change(() => Theme.accentChoice = dot.modelData === "blue" ? "" : dot.modelData)
            Accessible.name: modelData
            contentItem: Item {
                Rectangle { anchors.centerIn: parent; width: 24; height: 24; radius: Theme.radius; color: "transparent"; border.width: dot.current ? 2 : 0; border.color: Theme.pick(Theme.accents[dot.modelData]) }
                Rectangle { anchors.centerIn: parent; width: 14; height: 14; radius: Theme.radius; color: Theme.pick(Theme.accents[dot.modelData]) }
            }
        }
    }
}
