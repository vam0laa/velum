import QtQuick

// What an empty tab shows. This holds the data; one of two faces draws it: the everyday
// one, or the hidden webcore one. Nothing on it asks the network for anything.
Rectangle {
    id: sheet
    readonly property Item field: face.item?.field ?? null
    property bool hasWidevine
    property var shortcuts: []
    property int total: 0               // all bookmarks, also those not shown here
    property var frequent: []           // [{ url, title }] from the history
    property var recent: []             // [{ url, title, last }], newest first
    property bool showRecent: true
    property bool branded: true         // false: the side bar already shows the mark
    property double blocked: 0          // requests the shield has stopped so far
    property string note: ""
    property string background: "glow"
    property string picture: ""
    property bool showClock: true
    property bool showShield: true
    property bool showNote: false
    property bool showFrequent: false
    property var iconFor: url => ""     // the saved icon of a site
    // your own design of the everyday home page
    property var widgets: ["clock", "date", "calendar", "shield"]
    property string headline: ""
    property var words: []
    property var tasks: []
    property string cssText: ""
    property alias cssReader: reader
    readonly property var parsed: reader.parse(cssText)
    readonly property var cssErrors: parsed.errors
    property int timerMinutes: 25
    property int timerLeft: 25 * 60
    property bool timerRunning: false
    readonly property string timerText: ("0" + Math.floor(timerLeft / 60)).slice(-2) + ":" + ("0" + timerLeft % 60).slice(-2)
    signal widgetsEdited(var list)
    signal wordsEdited(string headline, string words)
    signal cssEdited(string text)
    signal tasksEdited(var list)
    signal timerEdited(int minutes)
    signal timerFinished()
    readonly property Item editor: face.item?.editor ?? null

    // the value your style sheet gives to the first of `names` that has it
    function css(names, property, fallback) {
        // the home page's own sheet first, then the browser's
        for (const sheet of [parsed.sheet, Theme.parsed.sheet]) {
            for (const name of names) {
                const found = sheet[name]?.[property]
                if (found !== undefined)
                    return found
            }
        }
        return fallback
    }
    function setWidget(id, on) {
        const list = widgets.filter(w => w !== id)
        widgetsEdited(on ? list.concat([id]) : list)
    }
    function moveWidget(id, by) {
        const list = widgets.slice(), at = list.indexOf(id), to = at + by
        if (at < 0 || to < 0 || to >= list.length)
            return
        list.splice(at, 1)
        list.splice(to, 0, id)
        widgetsEdited(list)
    }
    function setTimer(minutes) {
        timerRunning = false
        const m = Math.max(5, Math.min(120, minutes))
        timerLeft = m * 60
        timerEdited(m)
    }
    function toggleTimer() {
        if (timerLeft === 0)
            timerLeft = timerMinutes * 60
        timerRunning = !timerRunning
    }
    onTimerMinutesChanged: if (!timerRunning) timerLeft = timerMinutes * 60

    HomeCss { id: reader }
    Timer {
        interval: 1000; repeat: true; running: sheet.timerRunning
        onTriggered: {
            sheet.timerLeft = Math.max(0, sheet.timerLeft - 1)
            if (sheet.timerLeft === 0) {
                sheet.timerRunning = false
                sheet.timerFinished()
            }
        }
    }
    property date now: new Date()
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")
    signal go(url target)
    signal removeShortcut(int index)
    signal askShortcut()
    signal manage()
    signal noteEdited(string text)
    signal customize()

    // "12 min ago" for a time in seconds
    function ago(seconds) {
        const minutes = Math.max(0, Math.floor((now.getTime() / 1000 - seconds) / 60))
        if (minutes < 1) return Lang.t("şimdi", "now")
        if (minutes < 60) return Lang.t(minutes + " dk önce", minutes + "m ago")
        if (minutes < 24 * 60) return Lang.t(Math.floor(minutes / 60) + " sa önce", Math.floor(minutes / 60) + "h ago")
        return Lang.t(Math.floor(minutes / 1440) + " gün önce", Math.floor(minutes / 1440) + "d ago")
    }
    function greeting(hour) {
        if (hour < 5) return Lang.t("iyi geceler", "good night")
        if (hour < 12) return Lang.t("günaydın", "good morning")
        if (hour < 18) return Lang.t("iyi günler", "good afternoon")
        return Lang.t("iyi akşamlar", "good evening")
    }

    color: Theme.sheetBack
    clip: true

    Timer { interval: 1000; repeat: true; running: sheet.visible; triggeredOnStart: true; onTriggered: sheet.now = new Date() }

    Loader {
        id: face
        anchors.fill: parent
        sourceComponent: Theme.web ? webFace : classicFace
    }
    Component { id: classicFace; ClassicStart { page: sheet } }
    Component { id: webFace; WebStart { page: sheet } }
}
