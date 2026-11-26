pragma Singleton
import QtCore
import QtQuick

// The interface language. Every visible text is written as Lang.t("Türkçe", "English"),
// so changing the language redraws everything at once.
QtObject {
    id: lang
    property string choice: "auto"       // "auto" (system), "tr" or "en"
    readonly property bool turkish: choice === "tr" || (choice !== "en" && Qt.locale().name.startsWith("tr"))
    function t(tr, en) { return turkish ? tr : en }

    property Settings saved: Settings {
        category: "ui"
        property alias language: lang.choice
    }
}
