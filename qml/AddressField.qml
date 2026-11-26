import QtQuick
import QtQuick.Controls

// The address and search field: a white line with a prompt in front.
TextField {
    id: field
    property url pageUrl
    property color accent: Theme.accent
    property bool bare: false          // no mark in front: the owner puts its own there
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Theme.web ? Lang.t("ara ya da adres yaz_", "search or type an address_") : Lang.t("Ara ya da adres yaz", "Search or enter address")
    placeholderTextColor: Theme.dim
    color: Theme.styled("address", "color", Theme.text)
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentInk
    font.family: Theme.ui; font.pixelSize: Theme.size(18)
    leftPadding: Theme.web ? 28 : 34
    rightPadding: 10
    implicitHeight: Theme.dense(34)
    selectByMouse: true

    background: Rectangle {
        radius: Theme.styled("address", "border-radius", Theme.round(10))
        color: Theme.styled("address", "background", Theme.raised)
        border.width: Theme.web || field.activeFocus ? 2 : Theme.styled("address", "border-width", 1)
        border.color: field.activeFocus ? (Theme.web ? Theme.pink : Theme.accent) : Theme.styled("address", "border-color", Theme.line)
        Text { visible: Theme.web && !field.bare; x: 10; anchors.verticalCenter: parent.verticalCenter; text: ">"; color: field.accent; font.family: Theme.ui; font.pixelSize: field.font.pixelSize + 2 }
        Icon { visible: !Theme.web && !field.bare; x: 11; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 15; color: Theme.dim }
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
