pragma Singleton
import QtQuick
// Stand-in for the C++ shield, which needs the web engine's network.
QtObject {
    property bool enabled: true
    property bool httpsFirst: true
    property bool blockThirdPartyCookies: true
    property bool forgetOnExit: false
    readonly property bool forgettingThisRun: false
    function clearData(p) {}
    property string statusCode: "none"
    function statusText(tr, r, c) { return "" }
    property int revision: 0
    function attach(p) {}
    function blockedCount(h) { return 0 }
    function resetCount(h) {}
    function allowed(h) { return false }
    function setAllowed(h, a) {}
    function pageScript(u) { return "" }
    function updateLists() {}
}
