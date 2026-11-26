import QtQuick
import QtQuick.Controls

// The address and search field, sunk into its window, with a prompt in front.
TextField {
    id: field
    property url pageUrl
    property color accent: Theme.accent
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Lang.t("Ara ya da adres yaz", "Search or type an address")
    placeholderTextColor: Theme.dim
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.onAccent
    font.pixelSize: 13
    leftPadding: 32
    rightPadding: 14
    implicitHeight: 38
    selectByMouse: true

    background: Bevel {
        sunken: true
        color: Theme.frame
        shade: field.activeFocus ? field.accent : Theme.line
        radius: height / 2
        Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 14; color: field.activeFocus ? field.accent : Theme.dim }
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
