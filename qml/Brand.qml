import QtQuick

// Velum's mark and name, as they stand at the top of its own pages.
Row {
    property bool named: true
    spacing: 10
    Image { source: Qt.resolvedUrl("../data/velum.svg"); sourceSize: Qt.size(64, 64); width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter }
    Text {
        visible: parent.named
        anchors.verticalCenter: parent.verticalCenter
        text: "Velum"
        color: Theme.text
        font.family: Theme.ui; font.pixelSize: 15; font.variableAxes: Theme.axes(560); font.letterSpacing: -0.1
    }
}
