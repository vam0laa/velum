pragma Singleton
import QtCore
import QtQuick

// The keyboard shortcuts, yours where you changed them ("Keymap").
QtObject {
    id: map
    readonly property var actions: [
        { id: "newTab", keys: "Ctrl+T", name: Lang.t("Yeni sekme", "New tab") },
        { id: "commandBox", keys: "Ctrl+K", name: Lang.t("Komut kutusu", "Command box") },
        { id: "address", keys: "Ctrl+L", also: "Alt+D", name: Lang.t("Adres", "Address") },
        { id: "closeTab", keys: "Ctrl+W", name: Lang.t("Sekmeyi kapat", "Close the tab") },
        { id: "reopen", keys: "Ctrl+Shift+T", name: Lang.t("Kapatılanı geri aç", "Reopen closed tab") },
        { id: "nextTab", keys: "Ctrl+Tab", name: Lang.t("Sonraki sekme", "Next tab") },
        { id: "previousTab", keys: "Ctrl+Shift+Tab", also: "Ctrl+Shift+Backtab", name: Lang.t("Önceki sekme", "Previous tab") },
        { id: "pin", keys: "Ctrl+Shift+P", name: Lang.t("Sekmeyi sabitle", "Pin the tab") },
        { id: "back", keys: "Alt+Left", name: Lang.t("Geri", "Back") },
        { id: "forward", keys: "Alt+Right", name: Lang.t("İleri", "Forward") },
        { id: "reload", keys: "Ctrl+R", also: "F5", name: Lang.t("Yenile", "Reload") },
        { id: "find", keys: "Ctrl+F", name: Lang.t("Sayfada ara", "Find in page") },
        { id: "zoomIn", keys: "Ctrl++", also: "Ctrl+=", name: Lang.t("Yakınlaştır", "Zoom in") },
        { id: "zoomOut", keys: "Ctrl+-", name: Lang.t("Uzaklaştır", "Zoom out") },
        { id: "zoomReset", keys: "Ctrl+0", name: Lang.t("Yakınlaştırmayı sıfırla", "Reset zoom") },
        { id: "bookmark", keys: "Ctrl+D", name: Lang.t("Yer imi", "Bookmark") },
        { id: "bookmarks", keys: "Ctrl+Shift+O", name: Lang.t("Yer imi yöneticisi", "Bookmark manager") },
        { id: "history", keys: "Ctrl+H", name: Lang.t("Geçmiş", "History") },
        { id: "downloads", keys: "Ctrl+J", name: Lang.t("İndirmeler", "Downloads") },
        { id: "reader", keys: "Alt+R", name: Lang.t("Okuma modu", "Reading mode") },
        { id: "mini", keys: "Alt+P", name: Lang.t("Küçük video penceresi", "Mini video window") },
        { id: "split", keys: "Ctrl+\\", name: Lang.t("Bölünmüş ekran", "Split view") },
        { id: "fill", keys: "Ctrl+Shift+L", name: Lang.t("Parolayı doldur", "Fill the password") },
        { id: "sidebar", keys: "Ctrl+B", name: Lang.t("Yan paneli daralt", "Narrow the side bar") },
        { id: "gameMode", keys: "Ctrl+Shift+G", name: Lang.t("Oyun modu", "Game mode") },
        { id: "resources", keys: "Shift+Esc", name: Lang.t("Kaynaklar", "Resources") },
        { id: "settings", keys: "Ctrl+,", name: Lang.t("Ayarlar", "Settings") },
        { id: "pdf", keys: "Ctrl+P", name: Lang.t("PDF olarak kaydet", "Save as PDF") },
        { id: "savePage", keys: "Ctrl+S", name: Lang.t("Sayfayı kaydet", "Save page") },
        { id: "source", keys: "Ctrl+U", name: Lang.t("Sayfa kaynağı", "Page source") },
        { id: "devTools", keys: "F12", also: "Ctrl+Shift+I", name: Lang.t("Geliştirici araçları", "Developer tools") },
        { id: "mute", keys: "Ctrl+M", name: Lang.t("Sekmenin sesini kapat ya da aç", "Mute or unmute the tab") },
        { id: "resetLook", keys: "Ctrl+Shift+0", name: Lang.t("Görünümü sıfırla", "Reset the look") },
        { id: "clear", keys: "Ctrl+Shift+Del", name: Lang.t("Gezinme verilerini sil", "Delete browsing data") },
        { id: "fullScreen", keys: "F11", name: Lang.t("Tam ekran", "Full screen") },
        { id: "quit", keys: "Ctrl+Q", name: Lang.t("Çıkış", "Quit") }
    ]

    // your changes: { action: "Ctrl+Y" }, or "" for none
    property var changed: ({})
    property Settings saved: Settings {
        category: "keys"
        property string changed: "{}"
    }
    Component.onCompleted: {
        try {
            const read = JSON.parse(saved.changed)
            const clean = {}
            for (const a of actions)
                if (typeof read?.[a.id] === "string")
                    clean[a.id] = read[a.id].slice(0, 40)
            changed = clean
        } catch (e) {
        }
    }

    // the key shown for an action, "" if it has none
    function text(id) {
        const mine = changed[id]
        return mine !== undefined ? mine : actions.find(a => a.id === id)?.keys ?? ""
    }
    // " (Ctrl+T)" for a hint, or nothing
    function hint(id) {
        const key = text(id)
        return key === "" ? "" : " (" + key + ")"
    }
    // everything that triggers the action
    function sequences(id) {
        if (changed[id] !== undefined)
            return changed[id] === "" ? [] : [changed[id]]
        const a = actions.find(a => a.id === id)
        return a ? (a.also ? [a.keys, a.also] : [a.keys]) : []
    }

    function keep(next) {
        changed = next
        saved.changed = JSON.stringify(next)
    }
    // Gives `sequence` to the action. An action that had it loses it; its name is returned.
    function assign(id, sequence) {
        const next = Object.assign({}, changed)
        let lost = ""
        for (const a of actions) {
            if (a.id !== id && sequence !== "" && sequences(a.id).some(s => s.toLowerCase() === sequence.toLowerCase())) {
                next[a.id] = ""
                lost = a.name
            }
        }
        next[id] = sequence
        keep(next)
        return lost
    }
    function reset(id) {
        const usual = actions.find(a => a.id === id)?.keys ?? ""
        assign(id, usual)
        const next = Object.assign({}, changed)
        delete next[id]
        keep(next)
    }
    function resetAll() { keep({}) }

    // A key press written as a sequence; "" while it is not one that can be a shortcut:
    // it needs Ctrl, Alt or Meta, unless it is an F key. Alt+1…6 belong to workspaces.
    function fromEvent(key, modifiers) {
        const named = ({ [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down", [Qt.Key_Tab]: "Tab",
                         [Qt.Key_Backtab]: "Tab", [Qt.Key_Delete]: "Del", [Qt.Key_Insert]: "Ins", [Qt.Key_Backspace]: "Backspace", [Qt.Key_Space]: "Space",
                         [Qt.Key_PageUp]: "PgUp", [Qt.Key_PageDown]: "PgDown", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_Return]: "Return", [Qt.Key_Escape]: "Esc" })
        const f = key >= Qt.Key_F1 && key <= Qt.Key_F12
        const name = f ? "F" + (key - Qt.Key_F1 + 1) : named[key] ?? (key > 32 && key < 127 ? String.fromCharCode(key) : "")
        const strong = modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)
        if (name === "" || (!strong && !f && !(name === "Esc" && (modifiers & Qt.ShiftModifier))))
            return ""
        if ((modifiers & Qt.AltModifier) && !(modifiers & Qt.ControlModifier) && key >= Qt.Key_1 && key <= Qt.Key_6)
            return ""
        if (modifiers === Qt.ControlModifier && key >= Qt.Key_1 && key <= Qt.Key_9)     // these go to a tab
            return ""
        return (modifiers & Qt.ControlModifier ? "Ctrl+" : "") + (modifiers & Qt.AltModifier ? "Alt+" : "")
             + (modifiers & Qt.ShiftModifier ? "Shift+" : "") + (modifiers & Qt.MetaModifier ? "Meta+" : "") + name
    }
}
