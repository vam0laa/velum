pragma Singleton
import QtQuick
// Stand-in for the store downloader; the real one is tested in C++.
QtObject {
    property var fetched: []
    function idFrom(text) { const m = String(text).match(/^(?:https:\/\/chromewebstore\.google\.com\/detail\/(?:[^\/]+\/)?)?([a-p]{32})(?:[\/?]|$)/); return m ? m[1] : "" }
    function fetch(text, done) { fetched = fetched.concat([String(text)]); done("", "network") }
    function discard(path) {}
}
