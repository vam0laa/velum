import QtQuick
import QtQuick.Controls

// A context menu in Velum's colours; its entries are AppMenuItem and AppMenuLine.
Menu {
    margins: 8
    padding: 6
    enter: PopIn {}
    exit: PopOut {}
    background: Rectangle { implicitWidth: 260; radius: 14; color: Theme.window; border.color: Theme.line }
}
