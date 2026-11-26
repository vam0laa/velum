import QtQuick

// An old window: white and blue outline, hard shadow, blue title bar and a body.
Item {
    id: panel
    property alias title: bar.title
    property color stripe: Theme.bar        // kept so callers may tint a window
    property alias minimizable: bar.minimizable
    property alias maximizable: bar.maximizable
    property alias closable: bar.closable
    property color fill: Theme.styled("sidebar", "background", Theme.paneBack)
    property bool chrome: true            // false hides the frame (page full screen, top tabs)
    property bool shadow: true
    default property alias content: body.data
    signal minimize()
    signal maximize()
    signal closeRequested()
    property alias storeButton: bar.storeButton
    signal store()
    property alias keyButton: bar.keyButton
    signal fill_()
    property alias readerButton: bar.readerButton
    property alias readerOn: bar.readerOn
    signal reader()
    property alias videoButton: bar.videoButton
    property alias videoOut: bar.videoOut
    signal video()

    Shadow { visible: panel.chrome && panel.shadow && !Theme.seeThrough }
    Rectangle { anchors.fill: parent; visible: panel.chrome; color: panel.fill; radius: Theme.styled("sidebar", "border-radius", Theme.corner); border.width: Theme.web ? 2 : Theme.styled("sidebar", "border-width", 1); border.color: Theme.web ? Theme.edge : Theme.styled("sidebar", "border-color", Theme.line) }
    Rectangle { anchors { fill: parent; margins: -2 } visible: panel.chrome && Theme.web; color: "transparent"; border.width: 2; border.color: Theme.line }
    TitleBar {
        id: bar
        visible: panel.chrome
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
        onMinimize: panel.minimize()
        onMaximize: panel.maximize()
        onCloseRequested: panel.closeRequested()
        onVideo: panel.video()
        onReader: panel.reader()
        onFill: panel.fill_()
        onStore: panel.store()
    }
    Item {
        id: body
        clip: true
        anchors {
            fill: parent
            topMargin: panel.chrome ? bar.height + 2 : 0
            leftMargin: panel.chrome ? 2 : 0
            rightMargin: panel.chrome ? 2 : 0
            // square web pages stay clear of rounded corners
            bottomMargin: panel.chrome ? (Theme.web ? 2 : 6) : 0
        }
    }
}
