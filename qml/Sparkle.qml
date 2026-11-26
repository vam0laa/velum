import QtQuick
import QtQuick.Shapes

// A four-pointed star that twinkles.
Item {
    id: star
    property real size: 24
    property color tone: "#ffffff"
    property int delay: 0
    width: size
    height: size
    Shape {
        width: 20
        height: 20
        anchors.centerIn: parent
        scale: star.size / 20
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillColor: star.tone
            PathSvg { path: "M10 0C11 7 13 9 20 10C13 11 11 13 10 20C9 13 7 11 0 10C7 9 9 7 10 0Z" }
        }
    }
    SequentialAnimation on opacity {
        running: Theme.motion && star.visible
        loops: Animation.Infinite
        PauseAnimation { duration: star.delay }
        NumberAnimation { to: 0.25; duration: 900 }
        NumberAnimation { to: 1; duration: 900 }
        PauseAnimation { duration: 1400 }
    }
}
