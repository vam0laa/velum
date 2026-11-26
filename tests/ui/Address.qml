pragma Singleton
import QtQuick
// Stand-in for the C++ address rules, which have their own tests.
QtObject {
    function resolve(t) { t = String(t).trim(); return t === "" ? "" : t.indexOf(":") > 0 ? t : t.indexOf(" ") >= 0 || t.indexOf(".") < 0 ? "https://search/?q=" + t : "https://" + t }
    function isSearch(t) { return String(resolve(t)).indexOf("https://search/") === 0 }
    function display(u) { return String(u).replace("https://", "") }
}
