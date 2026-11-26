import QtQuick

// How much of the day has passed: a ring whose filled part ripples, as on Lucid.
Item {
    id: ring
    property real part: 0               // 0 to 1
    property color tone: Theme.accent
    property color track: Theme.line
    property real phase: 0
    implicitWidth: 150
    implicitHeight: 150
    onPartChanged: canvas.requestPaint()
    onPhaseChanged: canvas.requestPaint()
    onToneChanged: canvas.requestPaint()
    onTrackChanged: canvas.requestPaint()
    NumberAnimation on phase { running: Theme.motion && ring.visible; from: 0; to: Math.PI * 2; duration: 2600; loops: Animation.Infinite }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const x = width / 2, y = height / 2, r = Math.min(x, y) - 10
            const start = -Math.PI / 2, end = start + Math.PI * 2 * Math.max(0.01, Math.min(1, ring.part))
            c.lineWidth = 9
            c.lineCap = "round"
            c.strokeStyle = ring.track
            c.beginPath()
            c.arc(x, y, r, end + 0.14, start + Math.PI * 2 - 0.14, false)
            if (end + 0.14 < start + Math.PI * 2 - 0.14)
                c.stroke()
            c.strokeStyle = ring.tone
            c.beginPath()
            for (let a = start; ; a += 0.03) {
                const at = Math.min(a, end)
                const wave = r + Math.sin((at - start) * 17 - ring.phase) * 3
                if (a === start)
                    c.moveTo(x + Math.cos(at) * wave, y + Math.sin(at) * wave)
                else
                    c.lineTo(x + Math.cos(at) * wave, y + Math.sin(at) * wave)
                if (at >= end)
                    break
            }
            c.stroke()
        }
    }
}
