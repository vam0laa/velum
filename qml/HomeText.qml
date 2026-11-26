import QtQuick

// Text of the home page; colour, size, weight and family follow the style sheet.
Text {
    property Item page
    property var names: []
    property color base: Theme.text
    property real size: 14
    property real weight: 400
    property string face: Theme.ui
    textFormat: Text.PlainText
    color: page.css(names, "color", base)
    font.family: page.css(names, "font-family", face)
    font.pixelSize: page.css(names, "font-size", size)
    font.variableAxes: Theme.axes(page.css(names, "font-weight", weight))
}
