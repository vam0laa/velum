import QtQuick

// The background of a floating box (popups): a window with its title, behind the content.
Panel {
    skin: "popup"
    fill: Theme.styled("popup", "background", Theme.window)
}
