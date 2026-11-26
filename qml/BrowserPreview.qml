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
        // a miniature of the home page
        Column {
            x: 18
            y: preview.horizontal ? 46 : 28
            spacing: 8
            Text { text: "Velum"; color: Theme.text; font.family: Theme.ui; font.pixelSize: 20; font.variableAxes: Theme.axes(850) }
            Rectangle { width: sheet.width * 0.42; height: 22; radius: Theme.round(11); color: Theme.accent }
            Rectangle { width: sheet.width * 0.5; height: 18; radius: Theme.round(9); color: Theme.raised }
            Row {
                spacing: 6
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 30; height: 30; radius: Theme.round(9); color: Theme.raised
                        Rectangle { anchors.centerIn: parent; width: 14; height: 14; radius: Theme.round(4); color: Theme.rainbow[parent.index] }
                    }
                }
            }
        }
        Column {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            visible: sheet.width > 260
            spacing: -10
            Text { text: "09"; color: Theme.accent; font.family: Theme.ui; font.pixelSize: 46; font.variableAxes: Theme.axes(850) }
            Text { text: "41"; color: Theme.mauve; font.family: Theme.ui; font.pixelSize: 46; font.variableAxes: Theme.axes(850) }
        }
    }
}
