pragma Singleton
import QtQuick
// Stand-in for the bookmark and locked files.
QtObject {
    property var files: ({})
    function writeBookmarks(file, list) { files[String(file)] = JSON.stringify(list); return true }
    function readBookmarks(file) { return files[String(file)] ? JSON.parse(files[String(file)]) : [] }
    function writeLocked(file, text, password) { if (password === "") return false; files[String(file)] = JSON.stringify({ p: password, t: text }); return true }
    function readLocked(file, password) {
        const f = files[String(file)]
        if (!f) return { found: false, opened: false, text: "" }
        const d = JSON.parse(f)
        return { found: true, opened: d.p === password, text: d.p === password ? d.t : "" }
    }
}
