import QtQuick

// How panels and dialogs arrive: they grow a little and fade in.
Transition {
    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.quick }
    NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Theme.smooth; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
}
