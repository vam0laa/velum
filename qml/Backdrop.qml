import QtQuick

// What lies behind the start page: Velum's sky, a plain sheet, a dot grid or your picture.
Item {
    id: backdrop
    property string mode: "glow"       // "glow", "plain", "dots", "image", or webcore's "sky"
    property string picture: ""        // a file path, for "image"
    property real middle: 0.32         // how far down the light of "glow" has its middle

    Image {
        anchors.fill: parent
        visible: backdrop.mode === "sky"
        source: Qt.resolvedUrl(Theme.night ? "../data/sky-night.jpg" : "../data/sky.jpg")
        fillMode: Image.PreserveAspectCrop
        opacity: Theme.seeThrough ? Theme.solidity : 1
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

    // one wide, quiet light behind the middle of the page, a fainter one from the top,
    // and a grain of dots that fades out around the middle
    Canvas {
        id: light
        anchors.fill: parent
        visible: backdrop.mode === "glow"
        property color tone: Theme.accent
        property color soft: Theme.mauve
        property color shade: Theme.raised
        property color grain: Theme.text
        property real middle: backdrop.middle
        onToneChanged: requestPaint()
        onShadeChanged: requestPaint()
        onSoftChanged: requestPaint()
        onGrainChanged: requestPaint()
        onMiddleChanged: requestPaint()
        onVisibleChanged: requestPaint()
        function veil(c, colour, a) { return "rgba(" + Math.round(colour.r * 255) + "," + Math.round(colour.g * 255) + "," + Math.round(colour.b * 255) + "," + a + ")" }
        function spot(c, x, y, rx, ry, stops) {
            c.save()
            c.translate(x, y)
            c.scale(rx, ry)
            const g = c.createRadialGradient(0, 0, 0, 0, 0, 1)
            for (const s of stops)
                g.addColorStop(s[0], veil(c, s[1], s[2]))
            c.fillStyle = g
            c.fillRect(-1, -1, 2, 2)
            c.restore()
        }
        onPaint: {
            const c = getContext("2d")
            c.reset()
            if (width <= 0 || height <= 0)
                return
            const far = Math.hypot(width / 2, height)
            spot(c, width / 2, 0, far / 2, far / 2, [[0, soft, 0.04], [1, soft, 0]])
            spot(c, width / 2, height * middle, width * 0.64, height * 0.4, [[0, tone, 0.11], [0.46, shade, 0.28], [0.76, shade, 0]])
            c.fillStyle = grain
            for (let y = 0; y < height; y += 24)
                for (let x = 0; x < width; x += 24) {
                    const d = Math.hypot((x - width / 2) / (width * 0.65), (y - height * 0.4) / (height * 0.6))
                    const a = d <= 0.2 ? 1 : (0.78 - d) / 0.58
                    if (a > 0) {
                        c.globalAlpha = 0.045 * a
                        c.fillRect(x, y, 1.5, 1.5)
                    }
                }
        }
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
        source: backdrop.mode === "image" && backdrop.picture !== "" ? Files.toUrl(backdrop.picture) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 2560
    }
}
