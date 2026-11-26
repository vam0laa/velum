import QtQuick

// What lies behind the start page: Velum's sky, a plain sheet, a dot grid or your picture.
Item {
    id: backdrop
    property string mode: "sky"        // "sky", "plain", "dots" or "image"
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
