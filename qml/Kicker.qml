import QtQuick

// A small pixel heading.
Text {
    property int size: 19
    textFormat: Text.PlainText
    color: Theme.accent
    font.family: Theme.pixel
    font.pixelSize: size
}
