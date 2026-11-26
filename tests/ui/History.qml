pragma Singleton
import QtQuick
// Stand-in for the C++ history, which has its own tests.
QtObject {
    property var pages: []
    function add(u, t) {}
    function setTitle(u, t) {}
    function search(text, limit) { return pages.filter(p => (p.url + p.title).indexOf(text) >= 0).slice(0, limit) }
    function remove(u) { pages = pages.filter(p => p.url !== u) }
    function clear() { pages = [] }
}
