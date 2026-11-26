import QtQuick
import QtQuick.Controls

// What can be done with this page: add the extension, fill the password, read, watch.
Row {
    id: row
    property bool storeButton: false
    property bool keyButton: false
    property bool readerButton: false
    property bool readerOn: false
    property bool videoButton: false
    property bool videoOut: false
    signal store()
    signal fill()
    signal reader()
    signal video()
    spacing: 4

    component Pill: AbstractButton {
        id: pill
        property string symbol
        property string hint
        implicitWidth: label.implicitWidth + 32
        implicitHeight: 20
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        Accessible.name: text
        background: Rectangle { radius: Theme.web ? 0 : 10; color: pill.hovered ? Theme.title : Theme.web ? Theme.raised : Qt.alpha(Theme.accent, 0.16); border.width: Theme.web ? 1 : 0; border.color: Theme.line }
        contentItem: Item {
            Icon { x: 6; anchors.verticalCenter: parent.verticalCenter; name: pill.symbol; size: 13; color: Theme.text }
            Text { id: label; x: 25; anchors.verticalCenter: parent.verticalCenter; text: pill.text; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.size(16) }
        }
        Hint { text: pill.hint; shown: pill.hovered; y: 26 }
    }

    Pill { visible: row.storeButton; symbol: "puzzle"; text: Lang.t("Velum'a ekle", "add to Velum"); hint: Lang.t("Bu eklentiyi kur", "Install this extension"); onClicked: row.store() }
    Pill { visible: row.keyButton; symbol: "key"; text: Lang.t("parolayı doldur", "fill password"); hint: "Ctrl+Shift+L"; onClicked: row.fill() }
    Pill { visible: row.readerButton; symbol: "book"; text: row.readerOn ? Lang.t("sayfaya dön", "back to page") : Lang.t("okuma modu", "reader"); hint: "Alt+R"; onClicked: row.reader() }
    Pill { visible: row.videoButton; symbol: "pip"; text: row.videoOut ? Lang.t("videoyu geri al", "bring video back") : Lang.t("küçük pencere", "mini player"); hint: "Alt+P"; onClicked: row.video() }
}
