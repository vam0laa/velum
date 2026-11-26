pragma Singleton
import QtQuick
// Stand-in for the C++ history, which has its own tests.
QtObject {
    property var pages: []
    function add(u, t) {}
    function setTitle(u, t) {}
    function search(text, limit) { return pages.filter(p => (p.url + p.title).indexOf(text) >= 0).slice(0, limit) }
    property int merged: 0
    function merge(list) { merged += list.length; return list.length }
    function remove(u) { pages = pages.filter(p => p.url !== u) }
    function clear() { pages = [] }
}
