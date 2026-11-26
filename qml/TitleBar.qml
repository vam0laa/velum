import QtQuick
import QtQuick.Layouts

// The blue, finely striped strip on top of a window, with its name and old window buttons.
Rectangle {
    id: bar
    property string title
    property bool minimizable: false
    property bool maximizable: false
    property bool closable: false
    signal minimize()
    signal maximize()
    signal closeRequested()
    property bool storeButton: false      // the page is an extension in the Web Store
    signal store()
    property bool keyButton: false        // a saved login fits the form on the page
    signal fill()
    property bool readerButton: false     // there is an article that can be read
    property bool readerOn: false
    signal reader()
    property bool videoButton: false      // there is a video that can go to the small window
    property bool videoOut: false
    signal video()

    implicitHeight: 28
    color: Theme.bar

    // the stripes
    Column {
        anchors.fill: parent
        spacing: 2
        Repeater {
            model: Math.ceil(bar.height / 4)
            Rectangle { width: bar.width; height: 2; color: "#ffffff"; opacity: 0.1 }
        }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 9; rightMargin: 4 }
        spacing: 4
        Text {
            Layout.fillWidth: true
            text: bar.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.barInk
            font.pixelSize: 20
        }
        PageButtons {
            storeButton: bar.storeButton
            keyButton: bar.keyButton
            readerButton: bar.readerButton
            readerOn: bar.readerOn
            videoButton: bar.videoButton
            videoOut: bar.videoOut
            onStore: bar.store()
            onFill: bar.fill()
            onReader: bar.reader()
            onVideo: bar.video()
        }
        WindowButton { visible: bar.minimizable; kind: "min"; hint: Lang.t("Yan paneli daralt", "Narrow the side bar"); onClicked: bar.minimize() }
        WindowButton { visible: bar.maximizable; kind: "max"; hint: Lang.t("Tam ekran", "Full screen"); onClicked: bar.maximize() }
        WindowButton { visible: bar.closable; kind: "close"; hint: Lang.t("Kapat", "Close"); onClicked: bar.closeRequested() }
    }
}
