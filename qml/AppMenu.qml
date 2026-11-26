import QtQuick
import QtQuick.Controls

// A context menu in Velum's colours; its entries are AppMenuItem and AppMenuLine.
Menu {
    margins: 8
    padding: 6
    background: Rectangle { implicitWidth: 250; radius: 12; color: Theme.surface; border.color: Theme.line }
}
