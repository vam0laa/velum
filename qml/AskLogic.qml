import QtQuick
import QtWebEngine

// What pages ask for: new windows and permissions.
// "app" is the window these belong to.
QtObject {
    property var app

    // A page asks for a new window: it becomes a tab. Without a click of yours you are
    // asked first. `fill` puts the request's page into the new tab.
    function newWindowFrom(from, clicked, background, fill) {
        const site = app.hostOf(from.url)
        if (!clicked && !app.popupSites.includes(site)) {
            if (!app.asks.some(a => a.page === from && a.popup))
                app.asks = app.asks.concat([{ page: from, popup: true, site: site, wish: Lang.t("Açılır pencere açmak istedi. İzin verirsen bir daha dene.", "tried to open a window. If you allow it, try again."),
                                      permission: { grant: () => app.popupSites = app.popupSites.concat([site]), deny: () => {} } }])
            return null
        }
        const here = app.view
        const page = app.openTab("")
        page.popup = true       // an empty address here is its content, not the home page
        fill(page)
        if (background && here)
            app.current = app.tabIndexOf(here)
        return page
    }

    // what a permission means, in words; empty for the ones Velum always refuses
    function wishFor(type) {
        switch (type) {
        case WebEnginePermission.PermissionType.MediaAudioCapture: return Lang.t("Mikrofonunu kullanmak istiyor.", "wants to use your microphone.")
        case WebEnginePermission.PermissionType.MediaVideoCapture: return Lang.t("Kameranı kullanmak istiyor.", "wants to use your camera.")
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture: return Lang.t("Kameranı ve mikrofonunu kullanmak istiyor.", "wants to use your camera and microphone.")
        case WebEnginePermission.PermissionType.Geolocation: return Lang.t("Konumunu öğrenmek istiyor.", "wants to know your location.")
        case WebEnginePermission.PermissionType.ClipboardReadWrite: return Lang.t("Panonu okumak ve değiştirmek istiyor.", "wants to read and change your clipboard.")
        case WebEnginePermission.PermissionType.Notifications: return Qt.platform.os === "windows" ? "" : Lang.t("Sana bildirim göndermek istiyor.", "wants to send you notifications.")     // not shown on Windows yet
        case WebEnginePermission.PermissionType.MouseLock: return Lang.t("Fare imlecini kilitlemek istiyor.", "wants to lock the mouse pointer.")
        }
        return ""
    }

    function answer(item, allow) {
        app.asks = app.asks.filter(a => a !== item)
        if (allow)
            item.permission.grant()
        else
            item.permission.deny()
    }

    // what sites were allowed or refused, for the settings
    function listPermissions() {
        const out = []
        for (const p of app.profile.listAllPermissions()) {
            const what = app.wishFor(p.permissionType)
            if (what !== "" && (p.state === WebEnginePermission.State.Granted || p.state === WebEnginePermission.State.Denied))
                out.push({ site: app.hostOf(p.origin) || String(p.origin), what: what, allowed: p.state === WebEnginePermission.State.Granted, permission: p })
        }
        app.permissions = out
    }
    function resetPermission(item) {
        item.permission.reset()
        listPermissions()
    }

    // a page that is leaving or closing takes its questions with it
    function dropAsks(page) {
        for (const item of app.asks.filter(a => a.page === page))
            app.answer(item, false)
    }
}
