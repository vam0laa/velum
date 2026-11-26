import QtQuick

// A block of the home page that your style sheet can reshape. Its names are looked up
// in order, so ".calendar" wins over ".widget".
Rectangle {
    id: box
    property Item page
    property var names: ["widget"]
    property color base: Theme.raised
    property real corner: 28
    visible: page.css(names, "display", "block") !== "none"
    opacity: page.css(names, "opacity", 1)
    color: page.css(names, "background", base)
    radius: page.css(names, "border-radius", Theme.web ? 0 : corner)
    border.width: page.css(names, "border-width", page.css(names, "border-color", "") !== "" ? 2 : 0)
    border.color: page.css(names, "border-color", Theme.line)
}
