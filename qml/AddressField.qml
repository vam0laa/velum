import QtQuick
import QtQuick.Controls

// The address and search field, sunk into its window, with a prompt in front.
TextField {
    id: field
    property url pageUrl
    property color accent: Theme.green
    signal go(url target)

    function showAddress() { text = activeFocus ? (pageUrl.toString() === "about:blank" ? "" : pageUrl.toString()) : Address.display(pageUrl) }

    placeholderText: Lang.t("Ara ya da adres yaz", "Search or type an address")
    placeholderTextColor: Theme.dim
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.onAccent
    font.pixelSize: 13
    leftPadding: 26
    rightPadding: 10
    implicitHeight: 38
    selectByMouse: true

    background: Bevel {
        sunken: true
        color: Theme.frame
        shade: field.activeFocus ? field.accent : Theme.bevelLo
        light: field.activeFocus ? field.accent : Theme.bevelHi
        Text { x: 9; anchors.verticalCenter: parent.verticalCenter; text: ">"; color: field.accent; font.family: Theme.pixel; font.pixelSize: 22 }
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
