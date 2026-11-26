import QtQuick
import QtQuick.Layouts

// The thin strip on top of a window: its name in pixel letters and three round buttons.
Item {
    id: bar
    property string title
    property color stripe: Theme.accent
    property bool minimizable: false
    property bool maximizable: false
    property bool closable: false
    signal minimize()
    signal maximize()
    signal closeRequested()
    property bool videoButton: false      // there is a video that can go to the small window
    property bool videoOut: false
    signal video()

    implicitHeight: 28

    component Dot: Rectangle {
        id: dot
        property color tone
        property string hint
        signal pressed()
        implicitWidth: 12
        implicitHeight: 12
        radius: 6
        color: area.containsMouse ? tone : "transparent"
        border.width: 1.5
        border.color: tone
        MouseArea { id: area; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; onClicked: dot.pressed() }
        Hint { text: dot.hint; shown: area.containsMouse; y: 20; x: dot.width - width }
        Accessible.role: Accessible.Button
        Accessible.name: hint
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
        spacing: 9
        Text {
            Layout.fillWidth: true
            text: bar.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: bar.stripe
            font.family: Theme.pixel
            font.pixelSize: 18
        }
        Rectangle {
            visible: bar.videoButton
            implicitWidth: label.implicitWidth + 36
            implicitHeight: 20
            radius: 10
            color: videoArea.containsMouse ? Theme.title : Theme.raised
            Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: "pip"; size: 13; color: Theme.mauve }
            Text { id: label; x: 27; anchors.verticalCenter: parent.verticalCenter; text: bar.videoOut ? Lang.t("videoyu geri al", "bring video back") : Lang.t("küçük pencere", "mini player"); color: Theme.text; font.pixelSize: 11 }
            MouseArea { id: videoArea; anchors.fill: parent; hoverEnabled: true; onClicked: bar.video() }
            Hint { text: "Alt+P"; shown: videoArea.containsMouse; y: 26 }
            Accessible.role: Accessible.Button
            Accessible.name: label.text
        }
        Dot { visible: bar.minimizable; tone: Theme.peach; hint: Lang.t("Yan paneli daralt", "Narrow the side bar"); onPressed: bar.minimize() }
        Dot { visible: bar.maximizable; tone: Theme.green; hint: Lang.t("Tam ekran", "Full screen"); onPressed: bar.maximize() }
        Dot { visible: bar.closable; tone: Theme.danger; hint: Lang.t("Kapat", "Close"); onPressed: bar.closeRequested() }
    }
}
