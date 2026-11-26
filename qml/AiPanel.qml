import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The assistant beside the page. It answers in plain words and can do nothing else:
// no clicking, no opening, no filling in.
Rectangle {
    id: panel
    property var app
    color: Theme.styled("popup", "background", Theme.window)
    border.color: Theme.line

    readonly property string trouble: ({
        server: Lang.t("Yerel sunucuya ulaşılamadı. Ollama çalışıyor mu?", "The local server cannot be reached. Is Ollama running?"),
        model: Lang.t("Model bulunamadı. Ayarlar → Yapay zekâ'dan seç; yoksa \"ollama pull\" ile indir.", "No such model. Pick one in Settings → Assistant, or fetch one with \"ollama pull\"."),
        address: Lang.t("Sunucu adresi bu bilgisayarda olmalı.", "The server address must be on this computer."),
        broken: Lang.t("Yanıt yarıda kaldı.", "The answer broke off.")
    })[Assistant.problem] ?? ""

    ColumnLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 8
        RowLayout {
            Text { Layout.fillWidth: true; text: Lang.t("Yardımcı", "Assistant"); color: Theme.text; font.family: Theme.ui; font.pixelSize: 17; font.variableAxes: Theme.axes(750) }
            Rectangle { implicitWidth: here.implicitWidth + 16; implicitHeight: 22; radius: 11; color: Qt.alpha(Theme.green, 0.25); Text { id: here; anchors.centerIn: parent; text: Lang.t("bu bilgisayarda", "on this computer"); color: Theme.text; font.family: Theme.ui; font.pixelSize: 11 } }
            IconButton { symbol: "close"; hint: Lang.t("Kapat", "Close"); onClicked: { Assistant.cancel(); panel.app.aiOpen = false } }
        }
        Text { Layout.fillWidth: true; text: Assistant.model !== "" ? Assistant.model : Lang.t("model seçilmedi", "no model chosen"); textFormat: Text.PlainText; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12 }
        TextButton { Layout.fillWidth: true; implicitHeight: 36; strong: true; enabled: !Assistant.busy && !panel.app.onStartPage && !panel.app.onSettings; text: Lang.t("Bu sayfayı özetle", "Summarise this page"); onClicked: panel.app.askAssistant(Lang.t("Bu sayfayı beş maddede özetle.", "Summarise this page in five points."), true) }
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea {
                id: out
                readOnly: true
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText      // an answer is only ever words
                text: Assistant.answer
                placeholderText: Assistant.busy ? Lang.t("Düşünüyor…", "Thinking…") : Lang.t("Yanıt burada görünür. Yanlış olabilir; önemliyse kontrol et.", "Answers appear here. They can be wrong; check what matters.")
                placeholderTextColor: Theme.dim
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentInk
                font.family: Theme.ui; font.pixelSize: 13
                background: null
            }
        }
        Text { Layout.fillWidth: true; visible: text !== ""; text: panel.trouble; wrapMode: Text.WordWrap; color: Theme.danger; font.family: Theme.ui; font.pixelSize: 12 }
        CheckBox {
            id: withPage
            checked: true
            padding: 0
            indicator: Rectangle { y: (withPage.height - height) / 2; width: 18; height: 18; radius: 5; color: withPage.checked ? Theme.accent : "transparent"; border.color: Theme.line; border.width: 2 }
            contentItem: Text { leftPadding: 26; text: Lang.t("Soruyla birlikte sayfanın metnini ver", "Send the page's text with the question"); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
        }
        RowLayout {
            TextField {
                id: question
                Layout.fillWidth: true
                implicitHeight: 36
                leftPadding: 12
                maximumLength: 2000
                placeholderText: Lang.t("Bir şey sor", "Ask something")
                placeholderTextColor: Theme.dim
                color: Theme.text
                font.family: Theme.ui; font.pixelSize: 13
                background: Rectangle { radius: Theme.radius; color: Theme.surface; border.color: question.activeFocus ? Theme.accent : Theme.line }
                onAccepted: if (text.trim() !== "" && !Assistant.busy) { panel.app.askAssistant(text.trim(), withPage.checked); text = "" }
            }
            TextButton { visible: Assistant.busy; implicitHeight: 36; text: Lang.t("Durdur", "Stop"); onClicked: Assistant.cancel() }
        }
    }
}
