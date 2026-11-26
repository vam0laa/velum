import QtQuick
import QtWebEngine

// The home page you design, and your look written to and read from files.
// "app" is the window these belong to.
QtObject {
    property var app

    function keepWidgets(list) {
        app.homeWidgets = Array.from(list).filter((w, i, a) => app.widgetNames.includes(w) && a.indexOf(w) === i)
        app.saved.homeWidgets = JSON.stringify(app.homeWidgets)
    }

    function keepTasks(list) {
        app.homeTasks = list.slice(0, 12)
        app.saved.homeTasks = JSON.stringify(app.homeTasks)
    }

    function keepWords(headline, words) {
        app.homeHeadline = String(headline).trim().slice(0, 40)
        app.homeWords = String(words).split("\n").map(w => w.trim().slice(0, 40)).filter(w => w !== "").slice(0, 12)
        app.saved.homeWords = JSON.stringify(app.homeWords)
    }

    function readHome() {
        try {
            // the redesigned home page starts clean: earlier widgets can be added again,
            // and what was written in them is kept
            if (app.saved.homeDesign >= 2 && app.saved.homeWidgets !== "")
                app.keepWidgets(JSON.parse(app.saved.homeWidgets))
            else
                app.keepWidgets([])
            app.saved.homeDesign = 2
        } catch (e) {
        }
        app.homeWords = app.readStrings(app.saved.homeWords)
        try {
            const list = JSON.parse(app.saved.homeTasks)
            app.homeTasks = Array.isArray(list) ? list.filter(t => t && typeof t.text === "string").slice(0, 12) : []
        } catch (e) {
        }
    }

    function openStudio() {
        if (!app.studio)
            app.studio = app.studioScreen.createObject(app.scene)
        app.studio.begin()
    }

    // the way out of a look gone wrong
    function resetLook() {
        Theme.resetAll()
        app.homeCss = ""
        app.say(Lang.t("Görünüm sıfırlandı.", "The look was reset."))
    }

    function themeText() {
        return JSON.stringify({ velumTheme: 1, look: Theme.bundle(),
                                home: { widgets: app.homeWidgets, headline: app.homeHeadline, words: app.homeWords, css: app.homeCss, background: app.startBackground === "image" ? "" : app.startBackground } }, null, 1)
    }

    // true when `text` was a theme; only what is valid in it is taken over
    function applyThemeText(text) {
        let d = null
        try {
            d = JSON.parse(text)
        } catch (e) {
        }
        if (!d || d.velumTheme !== 1)
            return false
        Theme.change(() => Theme.applyBundle(d.look))
        const home = d.home ?? {}
        if (Array.isArray(home.widgets))
            app.keepWidgets(home.widgets)
        if (typeof home.headline === "string" && Array.isArray(home.words))
            app.keepWords(home.headline, home.words.map(String).join("\n"))
        if (typeof home.css === "string")
            app.homeCss = home.css.slice(0, 20000)
        if (["dots", "glow", "plain"].includes(home.background))
            app.startBackground = home.background
        return true
    }

    function exportTheme(file) {
        app.say(Files.write(file, app.themeText()) ? Lang.t("Tema kaydedildi.", "The theme was saved.") : Lang.t("Tema kaydedilemedi.", "The theme could not be saved."))
    }

    function importTheme(file) {
        const before = app.themeText()
        if (!app.applyThemeText(Files.read(file))) {
            app.say(Lang.t("Bu dosya bir Velum teması değil.", "This file is not a Velum theme."))
            return
        }
        app.beforeImport = before
        app.say(Lang.t("Tema yüklendi. Ayarlar → Görünüm'den geri alabilirsin.", "The theme was loaded. You can undo it in Settings → Appearance."))
    }

    function undoImport() {
        if (app.beforeImport !== "" && app.applyThemeText(app.beforeImport))
            app.beforeImport = ""
    }

    // a switch in the settings
    function setStart(name, value) {
        const widget = { showClock: "clock", showShield: "shield", showNote: "note" }[name]
        if (!widget) {
            app[name] = value
            return
        }
        const list = app.homeWidgets.filter(w => w !== widget)
        app.keepWidgets(value ? list.concat([widget]) : list)
    }
}
