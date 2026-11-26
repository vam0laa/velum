import QtQuick
import QtWebEngine

// The right click menu of a web page. It shows only what applies to the thing clicked.
AppMenu {
    id: menu
    property var view                  // the page that was clicked
    property string link
    property string media
    property string selection
    property bool image: false
    property bool editable: false
    readonly property bool plain: link === "" && !image && selection === "" && !editable

    signal openInTab(string url)
    signal searchFor(string text)
    signal find()

    // takes what the engine reports about the click
    function describe(request) {
        link = String(request.linkUrl ?? "")
        media = String(request.mediaUrl ?? "")
        image = request.mediaType === ContextMenuRequest.MediaTypeImage && media !== ""
        selection = String(request.selectedText ?? "").trim()
        editable = request.isContentEditable === true
    }

    function act(action) { view.triggerWebAction(action) }

    AppMenuItem { shown: menu.link !== ""; text: Lang.t("Bağlantıyı yeni sekmede aç", "Open link in a new tab"); onTriggered: menu.openInTab(menu.link) }
    AppMenuItem { shown: menu.link !== ""; text: Lang.t("Bağlantıyı kopyala", "Copy link"); onTriggered: menu.act(WebEngineView.CopyLinkToClipboard) }
    AppMenuItem { shown: menu.link !== ""; text: Lang.t("Bağlantıyı indir", "Download link"); onTriggered: menu.act(WebEngineView.DownloadLinkToDisk) }
    AppMenuLine { shown: menu.link !== "" && (menu.image || menu.selection !== "" || menu.editable) }
    AppMenuItem { shown: menu.image; text: Lang.t("Resmi yeni sekmede aç", "Open image in a new tab"); onTriggered: menu.openInTab(menu.media) }
    AppMenuItem { shown: menu.image; text: Lang.t("Resmi kopyala", "Copy image"); onTriggered: menu.act(WebEngineView.CopyImageToClipboard) }
    AppMenuItem { shown: menu.image; text: Lang.t("Resmi indir", "Download image"); onTriggered: menu.act(WebEngineView.DownloadImageToDisk) }
    AppMenuItem { shown: menu.editable; text: Lang.t("Kes", "Cut"); enabled: menu.selection !== ""; onTriggered: menu.act(WebEngineView.Cut) }
    AppMenuItem { shown: menu.editable || menu.selection !== ""; text: Lang.t("Kopyala", "Copy"); enabled: menu.selection !== ""; onTriggered: menu.act(WebEngineView.Copy) }
    AppMenuItem { shown: menu.editable; text: Lang.t("Yapıştır", "Paste"); onTriggered: menu.act(WebEngineView.Paste) }
    AppMenuItem { shown: menu.editable; text: Lang.t("Tümünü seç", "Select all"); onTriggered: menu.act(WebEngineView.SelectAll) }
    AppMenuItem {
        shown: menu.selection !== "" && !menu.editable
        text: Lang.t("Ara: ", "Search for: ") + (menu.selection.length > 28 ? menu.selection.slice(0, 27) + "…" : menu.selection)
        onTriggered: menu.searchFor(menu.selection)
    }
    AppMenuItem { shown: menu.plain; text: Lang.t("Geri", "Back"); enabled: menu.view?.canGoBack ?? false; onTriggered: menu.view.goBack() }
    AppMenuItem { shown: menu.plain; text: Lang.t("İleri", "Forward"); enabled: menu.view?.canGoForward ?? false; onTriggered: menu.view.goForward() }
    AppMenuItem { shown: menu.plain; text: Lang.t("Yenile", "Reload"); onTriggered: menu.view.reload() }
    AppMenuLine { shown: menu.plain }
    AppMenuItem { shown: menu.plain; text: Lang.t("Sayfada ara", "Find in page"); onTriggered: menu.find() }
    AppMenuItem { shown: menu.plain; text: Lang.t("Sayfa adresini kopyala", "Copy page address"); onTriggered: menu.copyText(String(menu.view.url)) }

    // copying a text of our own goes through a hidden field
    function copyText(text) { hidden.text = text; hidden.selectAll(); hidden.copy(); hidden.text = "" }
    property TextEdit hidden: TextEdit { visible: false }
}
