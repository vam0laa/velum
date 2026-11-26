import QtQuick

// The hard shadow of an old window: a dark copy of the box, moved down and right.
Rectangle {
    property int reach: 6
    x: reach
    y: reach
    width: parent.width
    height: parent.height
    z: -1
    color: Theme.hardShadow
    visible: Theme.web && !Theme.glass
}
