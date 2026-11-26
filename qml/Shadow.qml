import QtQuick

// A soft shadow under a rounded box: three faint rounded sheets, each a bit larger.
// Cheaper than blurring, and left out on glass, where it would show through.
Item {
    id: shadow
    property real radius: Theme.corner
    anchors.fill: parent
    z: -1
    visible: !Theme.glass
    Repeater {
        model: 3
        Rectangle {
            required property int index
            x: -(index + 1) * 2
            y: -(index + 1) * 2 + 3
            width: shadow.width + (index + 1) * 4
            height: shadow.height + (index + 1) * 4
            radius: shadow.radius + (index + 1) * 2
            color: "#000000"
            opacity: (Theme.dark ? 0.09 : 0.035) - index * (Theme.dark ? 0.022 : 0.009)
        }
    }
}
