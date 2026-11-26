pragma Singleton
import QtQuick
// Stand-in for the C++ shield, which needs the web engine's network.
QtObject {
    property bool enabled: true
    signal changed()
    signal countsChanged()
    property bool httpsFirst: true
    property bool blockThirdPartyCookies: true
    property bool forgetOnExit: false
    readonly property bool forgettingThisRun: false
    function clearData(p) {}
    property string statusCode: "none"
    function statusText(tr, r, c) { return "" }
    property int revision: 0
    property real total: 1234
    function attach(p) {}
    function blockedCount(h) { return 0 }
    function resetCount(h) {}
    function allowed(h) { return false }
    function setAllowed(h, a) {}
    function pageScript(u) { return "" }
    function earlySites() { return [] }
    function earlyScript(h) { return "" }
    property string converter: ""
    function takeScriptlets(j) {}
    function updateLists() {}
    property bool safeBrowsing: true
    property string secureDns: "off"
    property int cookieRevision: 0
    property var sites: [{ site: "a.example", count: 2 }, { site: "b.example", count: 1 }]
    function harmful(h) { return h === "kotu.example" }
    function blockedHosts(h) { return h === "a.example" ? [{ host: "ads.example", count: 3 }] : [] }
    function cookieSites(text) { return sites.filter(s => s.site.indexOf(text) >= 0) }
    function removeCookies(site) { sites = sites.filter(s => s.site !== site); cookieRevision++ }
}
