import QtQuick

// The downloads button: a dot while something is coming down, and the list.
IconButton {
    id: button
    property var downloads: []
    property bool beside: false         // the panel opens to the right
    property bool above: false          // ... or above the button
    readonly property int running: downloads.filter(d => !d.isFinished).length
    signal showFolder(string folder)
    signal clearFinished()
    function show() { panel.open() }
    symbol: "download"
    hint: Lang.t("İndirmeler (Ctrl+J)", "Downloads (Ctrl+J)")
    hintBeside: beside
    onClicked: panel.open()
    Rectangle {
        visible: button.running > 0
        anchors { right: parent.right; top: parent.top }
        width: 9; height: 9; radius: Theme.radius; color: Theme.green
    }
    DownloadsPanel {
        id: panel
        downloads: button.downloads
        x: button.beside ? button.width + 8 : button.width - width
        y: button.beside ? button.height - height : button.above ? -height - 6 : button.height + 6
        onShowFolder: folder => button.showFolder(folder)
        onClearFinished: button.clearFinished()
    }
}
