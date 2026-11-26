pragma Singleton
import QtQuick
// Stand-in for the graphics card switch.
QtObject {
    property bool on: true
    property bool changed: !on
    property bool careful: false
}
