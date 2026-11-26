import QtQuick
import QtQuick.Controls

// Over the page: where the link under the pointer leads, and the zoom when it is not 100 %.
Item {
    id: overlay
    property var app

    // drawn by the browser, with the real address as plain text
    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
        visible: overlay.app.hoveredLink !== ""
        width: Math.min(address.implicitWidth + 20, parent.width * 0.7)
        height: 26
        radius: Theme.round(8)
        color: Theme.raised
        border.color: Theme.line
        Text {
            id: address
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            text: overlay.app.hoveredLink
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            verticalAlignment: Text.AlignVCenter
            color: Theme.text
            font.family: Theme.ui
            font.pixelSize: 12
        }
    }
    TextButton {
        readonly property real factor: overlay.app.view?.zoomFactor ?? 1
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        visible: !overlay.app.onStartPage && !overlay.app.onSettings && Math.abs(factor - 1) > 0.001
        text: "%" + Math.round(factor * 100) + "  ✕"
        onClicked: overlay.app.zoom(0)
        Accessible.name: Lang.t("Yakınlaştırmayı sıfırla", "Reset zoom")
    }
}
