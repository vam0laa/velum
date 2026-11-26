import QtQuick
import QtQuick.Layouts

// One choice among a few, side by side.
RowLayout {
    id: segments
    property var options: []         // [{ key, label }]
    property var current
    signal chosen(var key)
    spacing: 6
    Repeater {
        model: segments.options
        TextButton {
            required property var modelData
            text: modelData.label
            strong: segments.current === modelData.key
            onClicked: segments.chosen(modelData.key)
        }
    }
}
