import QtQuick
import QtWebEngine

// Chromium's developer tools for one page, in their own window.
Window {
    id: tools
    property WebEngineView page: null
    width: 960
    height: 640
    minimumWidth: 400
    minimumHeight: 300
    title: Lang.t("Geliştirici araçları", "Developer tools") + (page ? " · " + page.title : "")
    color: Theme.surface

    function inspect(view) {
        page = view
        inside.inspectedView = view
        show()
        raise()
        requestActivate()
    }
    onClosing: { inside.inspectedView = null; page = null }

    WebEngineView {
        id: inside
        anchors.fill: parent
        onWindowCloseRequested: tools.close()
    }
}
