import QtQuick
import QtQuick.Layouts

// Asks before a site may use the camera, microphone, location and the like.
// It is drawn by the browser, with the site's real address, never with words the page chose.
Bevel {
    id: bar
    property string site
    property string wish          // what is asked for, in words
    signal answered(bool allow)

    // a click that was already on its way must not grant anything
    property bool armed: false
    onVisibleChanged: { armed = false; if (visible) arm.restart() }
    onSiteChanged: { armed = false; if (visible) arm.restart() }
    onWishChanged: { armed = false; if (visible) arm.restart() }
    Timer { id: arm; interval: 600; onTriggered: bar.armed = true }

    implicitWidth: 360
    implicitHeight: column.implicitHeight + 28
    color: Theme.window
    light: Theme.peach
    radius: Theme.radius

    ColumnLayout {
        id: column
        anchors { fill: parent; margins: 14 }
        spacing: 10
        Text { Layout.fillWidth: true; text: bar.site; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(18); font.weight: Font.Normal }
        Text { Layout.fillWidth: true; text: bar.wish; wrapMode: Text.WordWrap; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.size(17) }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            TextButton { text: Lang.t("Reddet", "Block"); onClicked: bar.answered(false) }
            TextButton { text: Lang.t("İzin ver", "Allow"); strong: true; enabled: bar.armed; onClicked: bar.answered(true) }
        }
    }
}
