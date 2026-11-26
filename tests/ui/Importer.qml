pragma Singleton
import QtQuick
// Stand-in for the C++ importer, which has its own tests.
QtObject {
    function sources() { return [{ path: "/fake", name: "Fox (test)" }] }
    function read(path, history) {
        return { ok: path === "/fake",
                 bookmarks: [{ url: "https://one.example/", title: "One", folder: "İş" }, { url: "https://two.example/", title: "", folder: "" }],
                 visits: history ? [{ url: "https://v.example/", title: "V", visits: 3, last: 100 }] : [] }
    }
}
