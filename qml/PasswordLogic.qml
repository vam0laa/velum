import QtQuick
import QtWebEngine

// Passwords: noticing logins, offering to save them, filling them when asked.
// "app" is the window these belong to.
QtObject {
    property var app

    // every page gets the watcher, in the separate world only Velum's code runs in
    function watchLogins() {
        const channel = WebEngine.script()
        channel.name = "velum-channel"
        channel.sourceUrl = "qrc:///qtwebchannel/qwebchannel.js"
        channel.injectionPoint = WebEngineScript.DocumentCreation
        channel.worldId = WebEngineScript.ApplicationWorld
        const watch = WebEngine.script()
        watch.name = "velum-login"
        watch.sourceCode = app.login.watch
        watch.injectionPoint = WebEngineScript.DocumentReady
        watch.worldId = WebEngineScript.ApplicationWorld
        app.profile.userScripts.collection = [channel, watch]
    }

    // a login was sent: ask whether to keep it
    function offerPassword(origin, user, password) {
        if (origin === "" || Passwords.origin(origin) !== origin || password === "" || app.neverSave.includes(origin))
            return
        Passwords.check(origin, user, password, state => {
            if (state === "new" || state === "changed")
                app.passwordOffer = { origin: origin, user: user, password: password, changed: state === "changed" }
        })
    }

    function savePassword(user) {
        const offer = app.passwordOffer
        if (!offer)
            return
        app.passwordOffer = null
        Passwords.save(offer.origin, user, offer.password, ok => {
            app.say(ok ? Lang.t("Parola anahtarlığa kaydedildi.", "The password is in the keyring.")
                   : Lang.t("Parola kaydedilemedi. Anahtarlığın kilidi açık mı?", "The password could not be saved. Is the keyring unlocked?"))
            for (let i = 0; i < app.tabs.count; i++)
                app.findAccounts(app.pageViewAt(i))
        })
    }

    function neverFor(origin) {
        app.passwordOffer = null
        if (!app.neverSave.includes(origin)) {
            app.neverSave = app.neverSave.concat([origin])
            app.saved.neverSave = JSON.stringify(app.neverSave)
        }
    }

    function askAgainFor(origin) {
        app.neverSave = app.neverSave.filter(o => o !== origin)
        app.saved.neverSave = JSON.stringify(app.neverSave)
    }

    // which saved logins fit the form on this page, if it has one
    function findAccounts(page) {
        if (!page || page.loginOrigin === "") {
            if (page)
                page.accounts = []
            return
        }
        const origin = page.loginOrigin
        Passwords.accounts(origin, found => {
            if (page.loginOrigin === origin)
                page.accounts = found ?? []
        })
    }

    // Ctrl+Shift+L and the title bar button; with several accounts you pick one
    function fillPassword() {
        const page = app.view
        if (!page || page.accounts.length === 0) {
            app.say(Lang.t("Bu sayfa için kayıtlı parola ya da giriş formu yok.", "No saved password or login form for this page."))
            return
        }
        if (page.accounts.length === 1)
            app.fillAccount(page, page.accounts[0].user)
        else
            app.accountMenu.popup(app.width - app.accountMenu.width - 20, app.horizontalTabs ? app.topBar.height + 40 : 40)
    }

    function fillAccount(page, user) {
        const origin = page.loginOrigin
        // the address bar's page and the form's page must be the same site
        if (origin === "" || Passwords.origin(page.url) !== origin)
            return
        Passwords.password(origin, user, secret => {
            if (secret === null) {
                app.say(Lang.t("Parola anahtarlıktan okunamadı.", "The password could not be read from the keyring."))
                return
            }
            page.runJavaScript(app.login.fill(origin, user, secret), WebEngineScript.ApplicationWorld, done => {
                if (done !== true)
                    app.say(Lang.t("Doldurulacak giriş formu bulunamadı.", "No login form to fill was found."))
            })
        })
    }
}
