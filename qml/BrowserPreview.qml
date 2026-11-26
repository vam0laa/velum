import QtQuick

// A small drawing of Velum in the chosen colours and layout; it changes as you choose.
Rectangle {
    id: preview
    property bool horizontal: true
    implicitWidth: 420
    implicitHeight: 250
    radius: Theme.round(18)
    color: Theme.frame
    border.color: Theme.line
    clip: true

    component Bar: Rectangle { height: 7; radius: Theme.round(3.5); color: Theme.dim; opacity: 0.55 }
    Behavior on color { ColorAnimation { duration: Theme.smooth } }

    // the tabs: along the top, or down the side
    Item {
        id: tabs
        anchors { left: parent.left; top: parent.top; margins: 10 }
        width: preview.horizontal ? preview.width - 20 : preview.width * 0.24
        height: preview.horizontal ? 24 : preview.height - 20
        Behavior on width { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutCubic } }
        Repeater {
            model: 3
            Rectangle {
                required property int index
                x: preview.horizontal ? index * (width + 6) : 0
                y: preview.horizontal ? 0 : 34 + index * 28
                width: preview.horizontal ? 88 : tabs.width
                height: 22
                radius: Theme.round(8)
                color: index === 0 ? Theme.raised : "transparent"
                Behavior on x { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutBack } }
                Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 9; height: 9; radius: Theme.round(3); color: Theme.rainbow[parent.index] }
                Bar { x: 23; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 36 }
            }
        }
        // the address field sits with the tabs when they are on the side
        Rectangle { visible: !preview.horizontal; width: tabs.width; height: 24; radius: Theme.round(12); color: Theme.window; Bar { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.5 } }
    }

    Rectangle {
        id: sheet
        x: preview.horizontal ? 10 : tabs.width + 18
        y: preview.horizontal ? 40 : 10
        width: preview.width - x - 10
        height: preview.height - y - 10
        radius: Theme.round(12)
        color: Theme.surface
        clip: true
        Behavior on x { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.smooth * 1.6; easing.type: Easing.OutCubic } }

        Rectangle {
            visible: preview.horizontal
            width: parent.width
            height: 28
            color: Theme.window
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.62; height: 16; radius: Theme.round(8); color: Theme.raised }
        }
        // a miniature of the home page: greeting, search, sites, the last pages
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: preview.horizontal ? 42 : 22
            spacing: 9
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Velum"; color: Theme.text; font.family: Theme.ui; font.pixelSize: 17; font.variableAxes: Theme.axes(520) }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: sheet.width * 0.66; height: 20; radius: Theme.round(10); color: Theme.raised; border.color: Theme.line
                Rectangle { x: 7; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: Theme.mauve }
                Bar { x: 20; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.4 }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        width: 22; height: 22; radius: Theme.round(7); color: Theme.raised; border.color: Theme.line
                        Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: Theme.round(3); color: Theme.rainbow[parent.index] }
                    }
                }
            }
            Repeater {
                model: 3
                Item {
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: sheet.width * 0.6; height: 8
                    Rectangle { width: 8; height: 8; radius: Theme.round(2); color: Theme.raised }
                    Bar { x: 16; width: parent.width * (0.5 - parent.index * 0.08); height: 6; y: 1 }
                }
            }
        }
    }
}
