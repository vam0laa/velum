import QtQuick

// A window in the webcore manner: bevelled frame, title bar and a body for the content.
Item {
    id: panel
    property alias title: bar.title
    property alias stripe: bar.stripe
    property alias minimizable: bar.minimizable
    property alias maximizable: bar.maximizable
    property alias closable: bar.closable
    property color fill: Theme.window
    property bool chrome: true            // false hides the frame (page full screen)
    default property alias content: body.data
    signal minimize()
    signal maximize()
    signal closeRequested()

    // the hard shadow under the window
    Rectangle { visible: panel.chrome; x: 5; y: 5; width: parent.width; height: parent.height; color: Theme.bevelLo; opacity: 0.55; radius: Theme.radius }
    Bevel { anchors.fill: parent; visible: panel.chrome; color: panel.fill }
    TitleBar {
        id: bar
        visible: panel.chrome
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
        onMinimize: panel.minimize()
        onMaximize: panel.maximize()
        onCloseRequested: panel.closeRequested()
    }
    Item {
        id: body
        clip: true
        anchors {
            fill: parent
            topMargin: panel.chrome ? bar.height + 5 : 0
            leftMargin: panel.chrome ? 3 : 0
            rightMargin: panel.chrome ? 3 : 0
            bottomMargin: panel.chrome ? 3 : 0
        }
    }
}
