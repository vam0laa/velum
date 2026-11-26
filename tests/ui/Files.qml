pragma Singleton
import QtQuick
// Stand-in for the C++ path helper.
QtObject {
    function toUrl(path) { return path === "" ? "" : "file://" + String(path).split("/").map(encodeURIComponent).join("/") }
    function toPath(url) { return decodeURIComponent(String(url).replace("file://", "")) }
}
