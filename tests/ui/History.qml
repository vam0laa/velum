pragma Singleton
import QtQuick
// Stand-in for the C++ history, which has its own tests.
QtObject {
    property var pages: []
    property var added: []
    function add(u, t) { added.push(String(u)) }
    function setTitle(u, t) {}
    function search(text, limit) { return pages.filter(p => (p.url + p.title).indexOf(text) >= 0).slice(0, limit) }
    property int merged: 0
    function merge(list) { merged += list.length; return list.length }
    function frequent(limit) { return pages.slice(0, limit) }
    function remove(u) { pages = pages.filter(p => p.url !== u) }
    function clear() { pages = [] }
    function browse(text, limit) { return pages.filter(p => (p.url + " " + p.title).toLowerCase().indexOf(String(text).toLowerCase()) >= 0).slice(0, limit).map(p => ({ url: p.url, title: p.title, last: p.last ?? 1795600000 })) }
    function removeSince(when) { pages = pages.filter(p => (p.last ?? 1795600000) < when) }
}
