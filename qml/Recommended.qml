import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A few well-known extensions that can be added from the Chrome Web Store. In the
// welcome they are ticked and installed together; in the settings one at a time.
ColumnLayout {
    id: list
    property bool pick: false           // true: tick boxes; false: an "install" button each
    property var picked: []             // ids of the ticked ones
    property var installed: []          // names of the extensions already there
    signal install(string id)
    spacing: 8

    // ids and names as the store gives them
    readonly property var offers: [
        { id: "ddkjiahejlhfcafbddmgiahcphecmpfh", logo: "ublock", name: "uBlock Origin Lite", note: Lang.t("Reklam ve izleyici engelleyici. Velum'un kalkanı da engeller; ikisi birlikte olur.", "Ad and tracker blocker. Velum's shield blocks too; both can run.") },
        { id: "eimadpbcbfnmbkopoojfekhnkhdbieeh", logo: "darkreader", name: "Dark Reader", note: Lang.t("Her siteyi koyu temaya çevirir.", "Turns every site dark.") },
        { id: "mnjggcdmjocbbbhaepdhchncahnbgone", logo: "sponsorblock", name: "SponsorBlock", note: Lang.t("YouTube videolarındaki sponsor bölümlerini atlar.", "Skips sponsored parts of YouTube videos.") }
    ]

    function toggle(id) { picked = picked.includes(id) ? picked.filter(x => x !== id) : picked.concat([id]) }
    function has(name) { return installed.some(n => String(n).indexOf(name) === 0) }

    Repeater {
        model: list.offers
        AbstractButton {
            id: row
            required property var modelData
            required property int index
            readonly property bool there: list.has(modelData.name)
            readonly property bool ticked: list.picked.includes(modelData.id)
            Layout.fillWidth: true
            implicitHeight: 66
            hoverEnabled: true
            onClicked: if (list.pick && !there) list.toggle(modelData.id)
            Accessible.name: modelData.name
            background: Rectangle {
                radius: Theme.corner
                color: row.hovered && list.pick ? Theme.title : Theme.raised
                border.width: row.ticked ? 2 : 0
                border.color: Theme.accent
            }
            contentItem: RowLayout {
                spacing: 12
                // the extension's own icon, from its package
                Image {
                    Layout.leftMargin: 14
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    source: Qt.resolvedUrl("../data/logos/" + row.modelData.logo + ".png")
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { Layout.fillWidth: true; text: row.modelData.name; color: Theme.text; font.family: Theme.ui; font.pixelSize: Theme.web ? 17 : 14; font.variableAxes: Theme.axes(700); elide: Text.ElideRight }
                    Text { Layout.fillWidth: true; text: row.modelData.note; color: Theme.dim; font.family: Theme.ui; font.pixelSize: Theme.web ? 15 : 12; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                }
                Text { Layout.rightMargin: 14; visible: row.there; text: Lang.t("kurulu", "installed"); color: Theme.green; font.family: Theme.ui; font.pixelSize: 12 }
                Rectangle {
                    Layout.rightMargin: 14
                    visible: list.pick && !row.there
                    implicitWidth: 24; implicitHeight: 24
                    radius: Theme.round(12)
                    color: row.ticked ? Theme.accent : "transparent"
                    border.width: row.ticked ? 0 : 2
                    border.color: Theme.line
                    Text { anchors.centerIn: parent; visible: row.ticked; text: "✓"; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 15; font.variableAxes: Theme.axes(800) }
                }
                TextButton { Layout.rightMargin: 14; visible: !list.pick && !row.there; text: Lang.t("Kur", "Install"); onClicked: list.install(row.modelData.id) }
            }
        }
    }
}
