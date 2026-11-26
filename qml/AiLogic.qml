import QtQuick
import QtWebEngine

// The assistant and the page: what text is handed to it, and only when you ask.
// "app" is the window these belong to.
QtObject {
    property var app

    // the words you can see on the page: the article if there is one, else the whole body;
    // never what is typed into forms
    readonly property string extract: `(() => {
        const main = document.querySelector('article, main, [itemprop=articleBody]') || document.body;
        if (!main) return '';
        return (main.innerText || '').replace(/\\n{3,}/g, '\\n\\n').trim().slice(0, 16000);
    })()`

    function toggle() {
        if (!Assistant.enabled) {
            app.openSettings("assistant")
            app.say(Lang.t("Yapay zekâ yardımcısı kapalı; buradan açabilirsin.", "The assistant is off; you can switch it on here."))
            return
        }
        app.aiOpen = !app.aiOpen
        if (app.aiOpen)
            Assistant.look()
    }
    // asks about the page being looked at; `withPage` false: just the question
    function ask(question, withPage) {
        const page = app.view
        if (!withPage || !page || app.onStartPage || app.onSettings) {
            Assistant.ask(question, "", Lang.turkish)
            return
        }
        page.runJavaScript(extract, WebEngineScript.ApplicationWorld, text => Assistant.ask(question, String(text ?? ""), Lang.turkish))
    }
    function explain(selection) {
        if (!Assistant.enabled) {
            toggle()
            return
        }
        app.aiOpen = true
        Assistant.ask(Lang.t("Bu metni sade bir dille açıkla.", "Explain this text in plain words."), selection, Lang.turkish)
    }
}
