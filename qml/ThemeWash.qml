import QtQuick
import QtQuick.Effects

// A change of colours that spreads from the middle: a photograph of the old look is
// laid on top, the new colours are applied underneath, and a growing round hole in the
// photograph lets them through.
Item {
    id: wash
    property Item target                // what is photographed
    property int duration: 750
    property real spread: 0
    property var held: null             // keeps the photograph alive
    readonly property real reach: Math.hypot(width, height) / 2 + 24
    anchors.fill: parent
    visible: false

    function run(change) {
        if (grow.running)
            grow.complete()
        const asked = target !== null && target.grabToImage(result => {
            held = result
            photo.source = result.url
            spread = 0
            visible = true
            change()
            grow.restart()
        })
        if (!asked)
            change()
    }

    Image { id: photo; anchors.fill: parent; visible: false; cache: false }
    Item {
        id: hole
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.centerIn: parent; width: wash.spread * 2; height: width; radius: width / 2 }
    }
    MultiEffect {
        anchors.fill: parent
        source: photo
        maskEnabled: true
        maskInverted: true
        maskSource: hole
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
    // the bright edge of the spreading colour
    Rectangle {
        anchors.centerIn: parent
        width: wash.spread * 2
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 4
        border.color: Theme.accent
        opacity: 0.7 * Math.max(0, 1 - wash.spread / wash.reach)
    }

    NumberAnimation {
        id: grow
        target: wash
        property: "spread"
        from: 0
        to: wash.reach
        duration: wash.duration
        easing.type: Easing.InOutCubic
        onFinished: { wash.visible = false; photo.source = ""; wash.held = null }
    }
}
