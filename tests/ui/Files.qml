pragma Singleton
import QtQuick
// Stand-in for the C++ path helper.
QtObject {
    function toUrl(path) { return path === "" ? "" : "file://" + String(path).split("/").map(encodeURIComponent).join("/") }
    property var kept: ({})
    function read(url) { return kept[String(url)] ?? "" }
    function write(url, text) { if (!String(url).endsWith(".velumtheme")) return false; kept[String(url)] = text; return true }
    property var settled: []
    function heldEnding() { return ".velum-hold" }
    function release(folder, file) { settled.push("release " + file); return file.replace(".velum-hold", "") }
    function discard(folder, file) { settled.push("discard " + file); return true }
    function toPath(url) { return decodeURIComponent(String(url).replace("file://", "")) }
}
