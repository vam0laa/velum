import QtQuick

// A rounded window: a thin title bar and a body for the content.
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
    property alias videoButton: bar.videoButton
    property alias videoOut: bar.videoOut
    signal video()
    property alias readerButton: bar.readerButton
    property alias readerOn: bar.readerOn
    signal reader()

    Rectangle { anchors.fill: parent; visible: panel.chrome; color: panel.fill; radius: Theme.corner; border.width: 1; border.color: Theme.line }
    TitleBar {
        id: bar
        visible: panel.chrome
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 1 }
        onMinimize: panel.minimize()
        onMaximize: panel.maximize()
        onCloseRequested: panel.closeRequested()
        onVideo: panel.video()
        onReader: panel.reader()
    }
    // a hairline under the title
    Rectangle { visible: panel.chrome; anchors { left: parent.left; right: parent.right; top: bar.bottom; leftMargin: 1; rightMargin: 1 } height: 1; color: Theme.line; opacity: 0.6 }
    Item {
        id: body
        clip: true
        // The bottom margin keeps square web pages clear of the rounded corners.
        anchors {
            fill: parent
            topMargin: panel.chrome ? bar.height + 2 : 0
            leftMargin: panel.chrome ? 2 : 0
            rightMargin: panel.chrome ? 2 : 0
            bottomMargin: panel.chrome ? 6 : 0
        }
    }
}
