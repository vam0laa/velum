import QtQuick
import QtQuick.Controls

// The address and search field: a white line with a prompt in front.
TextField {
    id: field
    property url pageUrl
    property color accent: Theme.accent
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Lang.t("ara ya da adres yaz_", "search or type an address_")
    placeholderTextColor: Theme.dim
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentInk
    font.pixelSize: 18
    leftPadding: 28
    rightPadding: 10
    implicitHeight: 34
    selectByMouse: true

    background: Rectangle {
        color: Theme.raised
        border.width: 2
        border.color: field.activeFocus ? Theme.pink : Theme.line
        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: ">"; color: field.accent; font.pixelSize: field.font.pixelSize + 2 }
    }

    onPageUrlChanged: if (!activeFocus) showAddress()
    onActiveFocusChanged: {
        showAddress()
        if (activeFocus)
            selectAll()
    }
    onAccepted: {
        const target = Address.resolve(text)
        if (target.toString() !== "")
            go(target)
    }
    Keys.onEscapePressed: { focus = false; showAddress() }
}
