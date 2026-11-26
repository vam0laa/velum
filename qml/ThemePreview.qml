import QtQuick

// A large, living drawing of Velum in a look that is not applied yet. It uses only what
// it is given, never the running theme.
Rectangle {
    id: view
    property var colors: []          // the fifteen, in Theme's order
    property real roundness: 1
    property string tabShape: "rounded"
    property string uiFont
    property string headFont
    function c(i) { return colors[i] ?? "#000000" }
    function r(n) { return Math.round(n * roundness) }

    color: c(0)
    radius: r(16)
    clip: true

    component Words: Text { color: view.c(6); font.family: view.uiFont; font.pixelSize: 13; textFormat: Text.PlainText; elide: Text.ElideRight }
    component Spot: Rectangle { width: 12; height: 12; radius: view.r(4) }

    // tabs
    Row {
        x: 12; y: 10; spacing: 6
        Repeater {
            model: [Lang.t("Ana sayfa", "Home"), "vamola.dev", "YouTube"]
            Rectangle {
                id: tab
                required property string modelData
                required property int index
                width: Math.min(150, (view.width - 70) / 3); height: 30
                radius: view.tabShape === "pill" ? height / 2 : view.tabShape === "rounded" ? view.r(9) : 0
                color: index === 0 && view.tabShape !== "line" ? view.c(3) : "transparent"
                Rectangle { visible: tab.index === 0 && view.tabShape === "line"; anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 } height: 3; radius: 1.5; color: view.c(8) }
                Spot { x: 10; anchors.verticalCenter: parent.verticalCenter; color: view.c([8, 10, 14][tab.index]) }
                Words { x: 30; width: parent.width - 38; anchors.verticalCenter: parent.verticalCenter; text: tab.modelData; color: view.c(tab.index === 0 ? 6 : 7); font.pixelSize: 12 }
            }
        }
    }
    // toolbar and bookmarks
    Rectangle {
        id: bars
        y: 46; width: parent.width; height: 74; color: view.c(1)
        Row {
            x: 16; y: 14; spacing: 14
            Repeater { model: 3; Spot { required property int index; color: view.c(index === 1 ? 7 : 6); opacity: 0.8 } }
        }
        Rectangle {
            x: 100; y: 5; width: parent.width - 150; height: 30; radius: view.r(10); color: view.c(3); border.color: view.c(5)
            Words { x: 14; anchors.verticalCenter: parent.verticalCenter; text: Lang.t("Ara ya da adres yaz", "Search or enter address"); color: view.c(7); font.pixelSize: 12 }
        }
        Spot { anchors { right: parent.right; rightMargin: 18 } y: 14; color: view.c(6) }
        Row {
            x: 14; y: 44; spacing: 18
            Repeater {
                model: ["GitHub", "Reddit", Lang.t("Haberler", "News")]
                Row {
                    id: mark
                    required property string modelData
                    required property int index
                    spacing: 6
                    Spot { anchors.verticalCenter: parent.verticalCenter; color: view.c([11, 13, 12][mark.index]) }
                    Words { text: mark.modelData; font.pixelSize: 11 }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: view.c(5) }
    }
    // the page
    Rectangle {
        anchors { top: bars.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: view.c(2)
        Column {
            id: words
            x: 28; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.54
            spacing: 10
            Words { width: parent.width; text: Lang.t("Velum senin", "Velum is your"); font.family: view.headFont; font.pixelSize: Math.max(20, view.width * 0.052); font.variableAxes: Theme.axes(800) }
            Rectangle {
                width: Math.min(parent.width, said.implicitWidth + 28); height: said.implicitHeight + 6; radius: view.r(height / 2.4); color: view.c(8)
                Words { id: said; x: 14; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, words.width - 28); text: Lang.t("sakin alanın.", "quiet place."); color: view.c(9); font.family: view.headFont; font.pixelSize: Math.max(20, view.width * 0.048); font.variableAxes: Theme.axes(800) }
            }
            Rectangle { width: parent.width; height: 38; radius: view.r(19); color: view.c(3); Words { x: 16; anchors.verticalCenter: parent.verticalCenter; text: Lang.t("Ara ya da adres yaz", "Search or enter address"); color: view.c(7) } }
            Row {
                spacing: 8
                Rectangle { width: yes.implicitWidth + 28; height: 32; radius: view.r(10); color: view.c(8); Words { id: yes; anchors.centerIn: parent; text: Lang.t("Düğme", "Button"); color: view.c(9) } }
                Rectangle { width: no.implicitWidth + 28; height: 32; radius: view.r(10); color: view.c(3); Words { id: no; anchors.centerIn: parent; text: Lang.t("İkinci düğme", "Second button") } }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 36; height: 20; radius: view.r(10); color: view.c(8); Rectangle { x: 19; y: 3; width: 14; height: 14; radius: view.r(7); color: view.c(9) } }
            }
        }
        Column {
            anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
            width: parent.width * 0.3
            spacing: 10
            Words { anchors.horizontalCenter: parent.horizontalCenter; text: "09:41"; color: view.c(8); font.family: view.headFont; font.pixelSize: Math.max(24, view.width * 0.06); font.variableAxes: Theme.axes(850) }
            Repeater {
                model: [[10, Lang.t("Kalkan", "Shield"), "311"], [12, Lang.t("Görevler", "Tasks"), "2"], [14, Lang.t("Uyarı", "Warning"), "!"]]
                Rectangle {
                    id: card
                    required property var modelData
                    width: parent.width; height: 52; radius: view.r(16); color: view.c(3); border.color: view.c(5)
                    Words { x: 14; y: 8; text: card.modelData[1]; color: view.c(card.modelData[0]); font.pixelSize: 11; font.variableAxes: Theme.axes(700) }
                    Words { x: 14; y: 24; text: card.modelData[2]; font.pixelSize: 17; font.variableAxes: Theme.axes(800) }
                }
            }
        }
    }
}
