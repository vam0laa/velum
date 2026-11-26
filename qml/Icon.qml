import QtQuick
import QtQuick.Shapes

// Velum's icons, drawn as lines on a 24×24 grid so they stay sharp at any size
// and take any colour.
Item {
    id: icon
    property string name
    property color color: Theme.text
    property real size: 18

    readonly property var paths: ({
        back: "M19 12H5 M11 6l-6 6 6 6",
        forward: "M5 12h14 M13 6l6 6-6 6",
        reload: "M20 12a8 8 0 1 1-2.34-5.66 M20 4v4.5h-4.5",
        stop: "M6 6l12 12 M18 6L6 18",
        close: "M7 7l10 10 M17 7L7 17",
        plus: "M12 5v14 M5 12h14",
        panel: "M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z M9 4v16",
        pin: "M9 4h6l-1 6 4 3v2H6v-2l4-3z M12 15v6",
        star: "M12 4l2.4 5 5.4.7-4 3.800 1 5.400-4.8-2.700-4.8 2.700 1-5.4-4-3.8 5.4-.7z",
        command: "M5 8l4 4-4 4 M12 17h7",
        shield: "M12 3l8 3v6c0 5-3.500 8-8 9c-4.5-1-8-4-8-9V6z",
        download: "M12 4v11 M7 11l5 5 5-5 M5 20h14",
        folder: "M3 7a2 2 0 0 1 2-2h4l2 3h8a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
        history: "M12 3a9 9 0 1 1 0 18a9 9 0 0 1 0-18z M12 7v5l3 2",
        moon: "M20 14.500A8.500 8.500 0 0 1 9.5 4a8.500 8.500 0 1 0 10.5 10.500z",
        up: "M6 15l6-6 6 6",
        down: "M6 9l6 6 6-6",
        alert: "M12 3l10 18H2z M12 10v5 M12 18v.200",
        settings: "M4 7h10 M18 7h2 M16 5v4 M4 17h4 M12 17h8 M10 15v4 M4 12h2 M10 12h10 M8 10v4",
        pip: "M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z M12.5 12h5.5v4h-5.5z",
        palette: "M12 3a9 9 0 1 0 0 18c1.500 0 2-1 2-2s-1-1.500-1-2.500s1-1.500 2-1.500h3c2 0 3-1.500 3-3.500c0-5-4-8.500-9-8.500z M7.500 11v.100 M10 7.500v.100 M14.500 7.500v.100 M17 11v.100",
        puzzle: "M5 8h4a2.500 2.500 0 1 1 5 0h4a1 1 0 0 1 1 1v3a2.500 2.500 0 1 0 0 5v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z",
        key: "M8 8a4 4 0 1 1 0 8a4 4 0 0 1 0-8z M12 12h9 M18 12v4 M21 12v3",
        book: "M12 6c-2-1.500-5-2-8-1.500v13c3-.5 6 0 8 1.500 2-1.500 5-2 8-1.500v-13c-3-.5-6 0-8 1.500z M12 6v13",
        play: "M8 5l11 7-11 7z",
        pause: "M9 5v14 M15 5v14",
        search: "M11 4a7 7 0 1 1 0 14a7 7 0 0 1 0-14z M20 20l-4-4",
        globe: "M12 3a9 9 0 1 1 0 18a9 9 0 0 1 0-18z M3 12h18 M12 3c5 5 5 13 0 18c-5-5-5-13 0-18z"
    })

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: icon.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.color
            strokeWidth: 1.8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.paths[icon.name] ?? "" }
        }
    }
}
