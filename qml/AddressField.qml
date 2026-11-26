import QtQuick
import QtQuick.Controls

// The address and search field: a white line with a prompt in front.
TextField {
    id: field
    property url pageUrl
    property color accent: Theme.accent
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Theme.web ? Lang.t("ara ya da adres yaz_", "search or type an address_") : Lang.t("Ara ya da adres yaz", "Search or enter address")
    placeholderTextColor: Theme.dim
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentInk
    font.family: Theme.ui; font.pixelSize: Theme.size(18)
    leftPadding: Theme.web ? 28 : 34
    rightPadding: 10
    implicitHeight: 34
    selectByMouse: true

    background: Rectangle {
        radius: Theme.web ? 0 : 10
        color: Theme.raised
        border.width: Theme.web || field.activeFocus ? 2 : 1
        border.color: field.activeFocus ? (Theme.web ? Theme.pink : Theme.accent) : Theme.line
        Text { visible: Theme.web; x: 10; anchors.verticalCenter: parent.verticalCenter; text: ">"; color: field.accent; font.family: Theme.ui; font.pixelSize: field.font.pixelSize + 2 }
        Icon { visible: !Theme.web; x: 11; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 15; color: Theme.dim }
    }

    onPageUrlChanged: if (!activeFocus) showAddress()
    onActiveFocusChanged: {
        showAddress()
        if (activeFocus)
            selectAll()
    }
    onAccepted: {
        if (Theme.secret(text)) {
            focus = false
            showAddress()
            return
        }
        const target = Address.resolve(text)
        if (target.toString() !== "")
            go(target)
    }
    Keys.onEscapePressed: { focus = false; showAddress() }
}
