import QtQuick

// A raised (or sunken) block with a light edge on one side and a dark edge on the other.
Rectangle {
    id: bevel
    property bool sunken: false
    property int edge: 2
    property color light: Theme.bevelHi
    property color shade: Theme.bevelLo

    color: Theme.raised
    radius: Theme.radius

    Rectangle { x: 0; y: 0; width: parent.width; height: bevel.edge; color: bevel.sunken ? bevel.shade : bevel.light }
    Rectangle { x: 0; y: 0; width: bevel.edge; height: parent.height; color: bevel.sunken ? bevel.shade : bevel.light }
    Rectangle { x: 0; y: parent.height - bevel.edge; width: parent.width; height: bevel.edge; color: bevel.sunken ? bevel.light : bevel.shade }
    Rectangle { x: parent.width - bevel.edge; y: 0; width: bevel.edge; height: parent.height; color: bevel.sunken ? bevel.light : bevel.shade }
}
