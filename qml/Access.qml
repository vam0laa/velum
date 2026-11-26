pragma Singleton
import QtQuick

// What an extension may do, in words ("Access.words(path)").
QtObject {
    readonly property var meanings: ({
        tabs: Lang.t("açık sekmelerinin adreslerini görür", "sees the addresses of your tabs"),
        history: Lang.t("geçmişine erişir", "reads your history"),
        bookmarks: Lang.t("yer imlerine erişir", "reads your bookmarks"),
        cookies: Lang.t("çerezlerine erişir", "reads your cookies"),
        downloads: Lang.t("indirmeleri yönetir", "manages downloads"),
        webRequest: Lang.t("ağ isteklerini izler", "watches network requests"),
        declarativeNetRequest: Lang.t("ağ isteklerini engeller ya da değiştirir", "blocks or changes network requests"),
        clipboardRead: Lang.t("panonu okur", "reads your clipboard"),
        scripting: Lang.t("sayfalarda kod çalıştırır", "runs code in pages"),
        nativeMessaging: Lang.t("bilgisayarındaki programlarla konuşur", "talks to programs on your computer"),
        geolocation: Lang.t("konumunu öğrenir", "knows your location")
    })

    // one line per thing worth knowing; the harmless ones are not listed
    function list(access) {
        const out = []
        const hosts = access.hosts ?? []
        if (hosts.some(h => h === "<all_urls>" || /^(\*|https?):\/\/\*\/\*?$/.test(h)))
            out.push(Lang.t("her sitede gördüklerini okuyup değiştirebilir", "can read and change what you see on every site"))
        else if (hosts.length > 0)
            out.push(Lang.t("şu sitelerde okuyup değiştirebilir: ", "can read and change these sites: ")
                     + [...new Set(hosts.map(h => h.replace(/^[^:]*:\/\//, "").split("/")[0]))].slice(0, 6).join(", "))
        for (const p of access.permissions ?? [])
            if (meanings[p])
                out.push(meanings[p])
        return out
    }
    function words(folder) {
        const found = list(Library.extensionAccess(folder))
        return found.length > 0 ? found.join(" · ") : Lang.t("Özel bir erişim istemiyor.", "Asks for nothing special.")
    }
}
