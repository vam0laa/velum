import QtQuick

// A soft block with a thin outline. "sunken" is for fields and pressed buttons.
Rectangle {
    id: bevel
    property bool sunken: false
    property int edge: 1
    property color light: Theme.line       // outline of a raised block
    property color shade: Theme.line       // outline of a sunken block

    color: Theme.raised
    radius: Theme.radius
    border.width: edge
    border.color: sunken ? shade : light
}
