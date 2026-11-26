import QtQuick
import QtQuick.Shapes

// Velum's mark and name, as they stand at the top of its own pages.
Row {
    id: brand
    property bool named: true
    spacing: 12
    Rectangle {
        width: 28; height: 28
        radius: Theme.round(6)
        color: Theme.raised
        border.color: Theme.line
        anchors.verticalCenter: parent.verticalCenter
        // the veil drawn aside in the shape of a V, as in data/velum.svg
        Shape {
            width: 128; height: 128
            scale: 0.215
            anchors.centerIn: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath { strokeColor: "transparent"; fillColor: Theme.mauve; PathSvg { path: "M26 32 C52 34 62 56 64 98 C72 62 82 40 102 32 C86 48 76 68 64 98 C50 64 42 44 26 32 Z" } }
        }
    }
    Text {
        visible: brand.named
        anchors.verticalCenter: parent.verticalCenter
        text: "Velum"
        color: Theme.text
        font.family: Theme.ui; font.pixelSize: 14; font.variableAxes: Theme.axes(520); font.letterSpacing: -0.1
    }
}
