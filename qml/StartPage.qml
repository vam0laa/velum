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
    property double blocked: 0          // requests the shield has stopped so far
    property string note: ""
    property string background: "glow"
    property string picture: ""
    property bool showClock: true
    property bool showShield: true
    property bool showNote: false
    property bool showFrequent: false
    property var iconFor: url => ""     // the saved icon of a site
    property date now: new Date()
    readonly property var locale_: Qt.locale(Lang.turkish ? "tr_TR" : "en_US")
    signal go(url target)
    signal removeShortcut(int index)
    signal addShortcut(string typed)
    signal manage()
    signal noteEdited(string text)
    signal customize()

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
