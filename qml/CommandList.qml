import QtQuick

// What the command box can do besides going somewhere: a name, its keys, what it runs.
QtObject {
    required property var app
    readonly property var list: [
        { name: Lang.t("Sekmeyi sabitle ya da çöz", "Pin or unpin the tab"), keys: Keymap.text("pin"), run: () => app.togglePin(app.current) },
        { name: Lang.t("Kapatılan sekmeyi geri aç", "Reopen the closed tab"), keys: Keymap.text("reopen"), run: () => app.reopenClosed() },
        { name: Lang.t("Yer imi ekle ya da kaldır", "Add or remove a bookmark"), keys: Keymap.text("bookmark"), run: () => app.toggleBookmark() },
        { name: Lang.t("Yer imleri: düzenle, klasörle", "Bookmarks: edit and sort"), keys: Keymap.text("bookmarks"), run: () => Qt.callLater(app.openBookmarks) },
        { name: Lang.t("Başka tarayıcıdan aktar", "Import from another browser"), keys: "", run: () => Qt.callLater(app.openImport) },
        { name: Lang.t("Eklentiler", "Extensions"), keys: "", run: () => app.openSettings("extensions") },
        { name: Lang.t("Geçmiş", "History"), keys: Keymap.text("history"), run: () => Qt.callLater(app.showCommandHistory) },
        { name: Lang.t("İndirmeler", "Downloads"), keys: Keymap.text("downloads"), run: () => app.openDownloads() },
        { name: app.horizontalTabs ? Lang.t("Dikey sekmelere geç", "Move the tabs to the side") : Lang.t("Yatay sekmelere geç", "Move the tabs to the top"), keys: "", run: () => app.horizontalTabs = !app.horizontalTabs },
        { name: Lang.t("Kaynaklar: hangi sekme ne kadar yiyor", "Resources: what each tab uses"), keys: Keymap.text("resources"), run: () => app.resources.open() },
        { name: Lang.t("Diğer sekmeleri uyut", "Put other tabs to sleep"), keys: "", run: () => app.sleepOthers() },
        { name: Lang.t("Yan paneli daralt ya da genişlet", "Narrow or widen the side bar"), keys: Keymap.text("sidebar"), run: () => app.compactSidebar = !app.compactSidebar },
        { name: Lang.t("Sekmeyi kapat", "Close the tab"), keys: Keymap.text("closeTab"), run: () => app.closeTab(app.current) },
        { name: Lang.t("Diğer sekmeleri kapat", "Close other tabs"), keys: "", run: () => app.closeOthers(app.current) },
        { name: Lang.t("Ekranı böl ya da birleştir", "Split or join the view"), keys: Keymap.text("split"), run: () => app.toggleSplit() },
        { name: Lang.t("Videoyu küçük pencereye al ya da geri getir", "Video in a small window, or back"), keys: Keymap.text("mini"), run: () => app.toggleMini() },
        { name: Lang.t("Parolayı doldur", "Fill in the password"), keys: Keymap.text("fill"), run: () => app.fillPassword() },
        { name: Lang.t("Kayıtlı parolalar", "Saved passwords"), keys: "", run: () => Qt.callLater(app.openPasswords) },
        { name: Lang.t("Okuma modu", "Reading mode"), keys: Keymap.text("reader"), run: () => app.toggleReader() },
        { name: Lang.t("Yeni çalışma alanı", "New workspace"), keys: "", run: () => app.spaceDialog.show(0, "", false) },
        { name: Lang.t("Sayfada ara", "Find in page"), keys: Keymap.text("find"), run: () => Qt.callLater(app.findInPage) },
        { name: app.restoreSession ? Lang.t("Açılışta sekmeleri geri getirme", "Do not reopen tabs at start") : Lang.t("Açılışta sekmeleri geri getir", "Reopen tabs at start"), keys: "", run: () => app.restoreSession = !app.restoreSession },
        { name: Lang.t("Gezinme verilerini sil", "Delete browsing data"), keys: Keymap.text("clear"), run: () => app.clearDialog.open() },
        { name: Lang.t("Ayarlar", "Settings"), keys: Keymap.text("settings"), run: () => Qt.callLater(app.openSettings) },
        { name: Lang.t("Tam ekran", "Full screen"), keys: Keymap.text("fullScreen"), run: () => app.toggleWindowFullScreen() },
        { name: Lang.t("Velum'dan çık", "Quit Velum"), keys: Keymap.text("quit"), run: () => app.quit() }
    ].concat(app.spaces.map((s, i) => ({ name: Lang.t("Çalışma alanı: ", "Workspace: ") + app.spaceName(s), keys: "Alt+" + (i + 1), run: () => app.switchSpace(s.id) })))
}
