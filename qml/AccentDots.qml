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
            onClicked: Theme.accentChoice = modelData === "blue" ? "" : modelData
            Accessible.name: modelData
            contentItem: Item {
                Rectangle { anchors.centerIn: parent; width: 24; height: 24; radius: 0; color: "transparent"; border.width: dot.current ? 2 : 0; border.color: Theme.pick(Theme.accents[dot.modelData]) }
                Rectangle { anchors.centerIn: parent; width: 14; height: 14; radius: 0; color: Theme.pick(Theme.accents[dot.modelData]) }
            }
        }
    }
}
