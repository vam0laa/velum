import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Brings bookmarks and history over from another browser.
Popup {
    id: panel
    // returns the sentence that says what happened
    property var run: (path, withHistory) => ""
    property var sources: []
    property bool withHistory: true
    property string result: ""

    // other browsers are only looked for while this panel is open
    onAboutToShow: { result = ""; sources = Importer.sources() }

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(440, Overlay.overlay.width - 32)
    padding: 18
    topPadding: 42
    enter: PopIn {}
    exit: PopOut {}
    background: WindowBackground { title: Lang.t("içe aktar", "import"); stripe: Theme.green }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: Lang.t("Dosyalar yalnızca okunur; öbür tarayıcıda hiçbir şey değişmez. Parolalar ve çerezler alınmaz.", "Files are only read; nothing changes in the other browser. Passwords and cookies are not taken.")
            color: Theme.dim
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        Toggle {
            label: Lang.t("Geçmişi de al", "Take the history too")
            note: Lang.t("Son 90 gün", "The last 90 days")
            on: panel.withHistory
            onClicked: panel.withHistory = !panel.withHistory
        }
        Repeater {
            model: panel.sources
            TextButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 38
                text: modelData.name
                onClicked: panel.result = panel.run(modelData.path, panel.withHistory)
            }
        }
        Text {
            Layout.fillWidth: true
            visible: panel.sources.length === 0
            text: Lang.t("Bu bilgisayarda tanınan başka bir tarayıcı bulunamadı.", "No other browser that Velum knows was found on this computer.")
            color: Theme.text
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: panel.result !== ""
            text: panel.result
            color: Theme.green
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        TextButton { Layout.alignment: Qt.AlignRight; text: Lang.t("Kapat", "Close"); onClicked: panel.close() }
    }
}
