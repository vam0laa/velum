import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Corners, room, tabs, lettering and the toolbar's buttons.
ColumnLayout {
    id: shape
    property bool horizontalTabs: true
    spacing: 8

    readonly property var buttonNames: ({
        back: Lang.t("Geri", "Back"), forward: Lang.t("İleri", "Forward"), reload: Lang.t("Yenile", "Reload"), home: Lang.t("Ana sayfa", "Home"),
        downloads: Lang.t("İndirmeler", "Downloads"), extensions: Lang.t("Eklentiler", "Extensions"), bookmarks: Lang.t("Yer imleri", "Bookmarks"),
        history: Lang.t("Geçmiş", "History"), game: Lang.t("Oyun modu", "Game mode"), settings: Lang.t("Ayarlar", "Settings") })
    // the shown ones in their order, then the hidden ones
    readonly property var rows: Theme.barLeft.concat(Theme.barRight, Theme.buttonIds.filter(b => !Theme.barLeft.includes(b) && !Theme.barRight.includes(b)))
    // Velum's own lettering, and what is installed here
    readonly property var installed: {
        const here = Qt.fontFamilies()
        return ["Inter", "Roboto", "Noto Sans", "Ubuntu", "Cantarell", "Fira Sans", "Segoe UI", "Arial", "Noto Serif", "Fira Code", "Comic Sans MS"].filter(f => here.includes(f))
    }
    readonly property var bodyFonts: [{ key: "", label: "Google Sans Flex" }].concat(Theme.bundled.filter(f => f.body).map(f => ({ key: f.name, label: f.name })), installed.map(f => ({ key: f, label: f })))
    readonly property var headFonts: [{ key: "", label: Lang.t("Arayüzle aynı", "Same as the rest") }].concat(Theme.bundled.map(f => ({ key: f.name, label: f.name })), installed.map(f => ({ key: f, label: f })))

    component Name: Text { Layout.fillWidth: true; color: Theme.text; font.family: Theme.ui; font.pixelSize: 14; elide: Text.ElideRight }
    component Row_: RowLayout { Layout.fillWidth: true; Layout.minimumHeight: 38; spacing: 10 }

    Row_ {
        Name { text: Lang.t("Köşeler", "Corners") }
        Segments { options: [{ key: 0, label: Lang.t("Keskin", "Square") }, { key: 0.5, label: Lang.t("Az", "Slight") }, { key: 1, label: Lang.t("Yuvarlak", "Round") }, { key: 1.6, label: Lang.t("Yumuşak", "Soft") }]; current: Theme.roundness; onChosen: key => Theme.roundness = key }
    }
    Row_ {
        Name { text: Lang.t("Yoğunluk", "Density") }
        Segments { options: [{ key: "compact", label: Lang.t("Sıkı", "Compact") }, { key: "normal", label: "Normal" }, { key: "roomy", label: Lang.t("Ferah", "Roomy") }]; current: Theme.density; onChosen: key => Theme.density = key }
    }
    Row_ {
        Name { text: Lang.t("Sekme biçimi", "Tab shape") }
        Segments { options: [{ key: "rounded", label: Lang.t("Kutu", "Box") }, { key: "pill", label: Lang.t("Hap", "Pill") }, { key: "square", label: Lang.t("Kare", "Square") }, { key: "line", label: Lang.t("Çizgi", "Line") }]; current: Theme.tabShape; onChosen: key => Theme.tabShape = key }
    }
    Row_ {
        Name { text: Lang.t("Arayüz yazı tipi", "Browser lettering") }
        Dropdown { implicitWidth: 220; options: shape.bodyFonts; current: Theme.fontFamily; onChosen: key => Theme.fontFamily = key }
    }
    Row_ {
        Name { text: Lang.t("Başlık ve saat yazı tipi", "Headline and clock lettering") }
        Dropdown { implicitWidth: 220; options: shape.headFonts; current: Theme.headFamily; onChosen: key => Theme.headFamily = key }
    }

    Name { Layout.topMargin: 10; text: Lang.t("Araç çubuğu düğmeleri", "Toolbar buttons"); font.variableAxes: Theme.axes(700) }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.dim
        font.family: Theme.ui
        font.pixelSize: 13
        text: shape.horizontalTabs ? Lang.t("Adresin solunda ya da sağında; oklar sırayı değiştirir. Menü hep en sağda.", "Left or right of the address; the arrows change the order. The menu stays last.")
                                   : Lang.t("Bu düzen yalnızca sekmeler üstteyken kullanılır.", "This applies when the tabs are along the top.")
    }
    Repeater {
        model: shape.rows
        Row_ {
            id: line
            required property string modelData
            readonly property string side: Theme.barLeft.includes(modelData) ? "left" : Theme.barRight.includes(modelData) ? "right" : ""
            readonly property var list: side === "left" ? Theme.barLeft : Theme.barRight
            spacing: 4
            Name { text: shape.buttonNames[line.modelData]; color: line.side === "" ? Theme.dim : Theme.text }
            IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 13; symbol: "up"; hint: Lang.t("Öne al", "Earlier"); opacity: line.side !== "" ? 1 : 0; enabled: line.side !== "" && line.list.indexOf(line.modelData) > 0; onClicked: Theme.moveButton(line.modelData, -1) }
            IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 13; symbol: "down"; hint: Lang.t("Arkaya al", "Later"); opacity: line.side !== "" ? 1 : 0; enabled: line.side !== "" && line.list.indexOf(line.modelData) < line.list.length - 1; onClicked: Theme.moveButton(line.modelData, 1) }
            Segments { options: [{ key: "left", label: Lang.t("Solda", "Left") }, { key: "right", label: Lang.t("Sağda", "Right") }, { key: "", label: Lang.t("Gizli", "Hidden") }]; current: line.side; onChosen: key => Theme.placeButton(line.modelData, key) }
        }
    }
    TextButton { Layout.fillWidth: true; implicitHeight: 38; text: Lang.t("Şekli ve CSS'i varsayılana döndür", "Reset shape and CSS"); onClicked: Theme.resetShape() }
}
