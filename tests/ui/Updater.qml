pragma Singleton
import QtQuick
// Stand-in for the updater, whose checks are tested in C++.
QtObject {
    property string status: "off"
    property string version: ""
    function check() { status = "current" }
}
