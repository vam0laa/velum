pragma Singleton
import QtQuick
// Stand-in for the graphics setting.
QtObject {
    property string mode: "auto"
    property bool changed: mode !== "auto"
    property bool fellBack: false
}
