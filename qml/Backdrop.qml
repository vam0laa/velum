import QtQuick
import QtQuick.Shapes

// What lies behind the start page: nothing, soft colour glows, a dot grid or your picture.
Item {
    id: backdrop
    property string mode: "glow"       // "plain", "glow", "dots" or "image"
    property string picture: ""        // a file path, for "image"

    // large soft spots of the theme's colours
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
                GradientStop { position: 0; color: Qt.alpha(glow.tone, 0.26) }
                GradientStop { position: 0.6; color: Qt.alpha(glow.tone, 0.08) }
                GradientStop { position: 1; color: Qt.alpha(glow.tone, 0) }
            }
            PathAngleArc { centerX: glow.size / 2; centerY: glow.size / 2; radiusX: glow.size / 2; radiusY: glow.size / 2; startAngle: 0; sweepAngle: 360 }
        }
    }

    Item {
        anchors.fill: parent
        clip: true
        visible: backdrop.mode === "glow"
        Glow { tone: Theme.accent; size: Math.max(parent.width, 500) * 0.9; x: -size * 0.35; y: -size * 0.4 }
        Glow { tone: Theme.mauve; size: Math.max(parent.width, 500) * 0.8; x: parent.width - size * 0.6; y: parent.height * 0.15 }
        Glow { tone: Theme.pink; size: Math.max(parent.width, 500) * 0.7; x: parent.width * 0.1; y: parent.height - size * 0.45 }
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
    // keeps the words readable over a picture
    Rectangle { anchors.fill: parent; visible: photo.visible; color: Qt.alpha(Theme.surface, 0.45) }
}
