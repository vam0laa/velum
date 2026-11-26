pragma Singleton
import QtQuick
// Stand-in: tests must not change which browser is the default.
QtObject {
    property bool current: false
    function refresh() {}
    function make() { current = true }
}
