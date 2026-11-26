import QtQuick

// ... and how they leave: quicker, so they are never in the way.
Transition {
    NumberAnimation { property: "opacity"; to: 0; duration: Theme.quick }
    NumberAnimation { property: "scale"; to: 0.96; duration: Theme.quick; easing.type: Easing.InCubic }
}
