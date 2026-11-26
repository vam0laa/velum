import QtQuick
import QtQuick.Controls

// A context menu in Velum's colours; its entries are AppMenuItem and AppMenuLine.
Menu {
    margins: 8
    padding: 6
    enter: PopIn {}
    exit: PopOut {}
    background: Rectangle {
        implicitWidth: 260
        radius: Theme.styled("menu", "border-radius", Theme.radius)
        color: Theme.styled("menu", "background", Theme.window)
        border.width: Theme.styled("menu", "border-width", 1)
        border.color: Theme.styled("menu", "border-color", Theme.line)
    }
}
