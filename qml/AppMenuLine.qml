import QtQuick
import QtQuick.Controls

// A thin line between groups of menu entries.
MenuSeparator {
    property bool shown: true
    visible: shown
    height: shown ? implicitHeight : 0
    padding: 4
    contentItem: Rectangle { implicitHeight: 1; color: Theme.line }
}
