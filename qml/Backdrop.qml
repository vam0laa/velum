import QtQuick
import QtQuick.Shapes

// What lies behind the start page: Velum's sky, a plain sheet, a dot grid or your picture.
Item {
    id: backdrop
    property string mode: "glow"       // "glow", "plain", "dots", "image", or webcore's "sky"
    property string picture: ""        // a file path, for "image"

    Image {
        anchors.fill: parent
        visible: backdrop.mode === "sky"
        source: Qt.resolvedUrl(Theme.night ? "../data/sky-night.jpg" : "../data/sky.jpg")
        fillMode: Image.PreserveAspectCrop
        opacity: Theme.glass ? Theme.solidity : 1
    }
    Item {
        anchors.fill: parent
        visible: backdrop.mode === "sky"
        opacity: Theme.night ? 0.75 : 1
        Sparkle { x: parent.width * 0.16; y: parent.height * 0.14; size: 38 }
        Sparkle { x: parent.width * 0.80; y: parent.height * 0.18; size: 26; delay: 700 }
        Sparkle { x: parent.width * 0.72; y: parent.height * 0.06; size: 16; tone: "#9ff5ff"; delay: 1500 }
        Sparkle { x: parent.width * 0.09; y: parent.height * 0.48; size: 16; tone: "#ffb0ee"; delay: 400 }
        Sparkle { x: parent.width * 0.91; y: parent.height * 0.57; size: 20; delay: 2000 }
    }

    // soft spots of the theme's colours
    component Glow: Shape {
        id: glow
        property color tone
        property real size: 600
        width: size
        height: size
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: glow.size / 2; centerY: glow.size / 2; focalX: centerX; focalY: centerY
                centerRadius: glow.size / 2
                GradientStop { position: 0; color: Qt.alpha(glow.tone, 0.2) }
                GradientStop { position: 0.6; color: Qt.alpha(glow.tone, 0.06) }
                GradientStop { position: 1; color: Qt.alpha(glow.tone, 0) }
            }
            PathAngleArc { centerX: glow.size / 2; centerY: glow.size / 2; radiusX: glow.size / 2; radiusY: glow.size / 2; startAngle: 0; sweepAngle: 360 }
        }
    }
    Item {
        anchors.fill: parent
        clip: true
        visible: backdrop.mode === "glow"
        Glow { tone: Theme.accent; size: Math.max(parent.width, 500) * 0.8; x: -size * 0.35; y: -size * 0.45 }
        Glow { tone: Theme.mauve; size: Math.max(parent.width, 500) * 0.7; x: parent.width - size * 0.6; y: parent.height * 0.25 }
    }

    Canvas {
        id: dots
        anchors.fill: parent
        visible: backdrop.mode === "dots"
        property color tone: Theme.line
        onToneChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.reset()
            c.fillStyle = tone
            c.globalAlpha = 0.35
            for (let y = 14; y < height; y += 24)
                for (let x = 14; x < width; x += 24)
                    c.fillRect(x, y, 2, 2)
        }
    }

    Image {
        id: photo
        anchors.fill: parent
        visible: backdrop.mode === "image" && status === Image.Ready
        source: backdrop.mode === "image" && backdrop.picture !== "" ? "file://" + backdrop.picture.split("/").map(encodeURIComponent).join("/") : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 2560
    }
}
