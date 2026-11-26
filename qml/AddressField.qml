import QtQuick
import QtQuick.Controls

// The address and search field. It shows a short address until you click it.
TextField {
    id: field
    property url pageUrl
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Lang.t("Ara ya da adres yaz", "Search or type an address")
    placeholderTextColor: Theme.dim
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.frame
    font.pixelSize: 13
    leftPadding: 12
    rightPadding: 12
    implicitHeight: 36
    selectByMouse: true

    background: Rectangle {
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: field.activeFocus ? Theme.accent : "transparent"
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
