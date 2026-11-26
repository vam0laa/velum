import QtQuick
import QtQml
import QtWebEngine

// The pages behind (or ahead of) this one: right click on the back or forward button.
AppMenu {
    id: menu
    property WebEngineView view: null
    property bool ahead: false

    function showFor(page, forward, button) {
        view = page
        ahead = forward
        if (view && (ahead ? view.canGoForward : view.canGoBack))
            popup(button, 0, button.height + 4)
    }

    Instantiator {
        model: menu.view && menu.visible ? (menu.ahead ? menu.view.history.forwardItems : menu.view.history.backItems) : null
        delegate: AppMenuItem {
            required property string title
            required property url url
            required property int offset
            text: title !== "" ? title : String(url)
            onTriggered: menu.view.goBackOrForward(offset)
        }
        // the nearest page on top
        onObjectAdded: (index, item) => menu.insertItem(menu.ahead ? index : 0, item)
        onObjectRemoved: (index, item) => menu.removeItem(item)
    }
}
