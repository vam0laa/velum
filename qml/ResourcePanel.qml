import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Which tab uses how much. Tabs from the same site may share one process;
// they then show the same numbers, marked "ortak".
Popup {
    id: panel
    property var rows: []        // [{ index, title, memory, cpu, state, shared }]
    property var total: ({ memory: 0, cpu: 0 })
    property int mode: 1          // 0 never, 1 early, 2 relaxed
    signal refresh()
    signal sleep(int index)
    signal wake(int index)
    signal choose(int index)
    signal modeChosen(int mode)

    anchors.centerIn: Overlay.overlay
    modal: true
    width: Math.min(560, Overlay.overlay.width - 32)
    padding: 16
    background: Rectangle { radius: 16; color: Theme.frame; border.color: Theme.line }

    Timer { interval: 2000; repeat: true; running: panel.visible; triggeredOnStart: true; onTriggered: panel.refresh() }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right }
        spacing: 10
        RowLayout {
            Text { Layout.fillWidth: true; text: "Kaynaklar"; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
            Text { text: Math.round(panel.total.memory) + " MB · işlemci %" + Math.round(panel.total.cpu); color: Theme.accent; font.pixelSize: 13 }
        }
        ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 360)
            clip: true
            spacing: 4
            model: panel.rows
            delegate: ItemDelegate {
                id: row
                required property var modelData
                width: ListView.view.width
                height: 40
                padding: 0
                focusPolicy: Qt.NoFocus
                hoverEnabled: true
                onClicked: { panel.close(); panel.choose(modelData.index) }
                background: Rectangle { radius: 10; color: row.hovered ? Theme.raised : Theme.surface }
                contentItem: RowLayout {
                    spacing: 10
                    Text { Layout.leftMargin: 12; Layout.fillWidth: true; text: row.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: row.modelData.state === 0 ? Theme.text : Theme.dim; font.pixelSize: 13 }
                    Text { text: row.modelData.state === 2 ? "uyuyor" : row.modelData.state === 1 ? "donduruldu" : row.modelData.shared ? "ortak" : ""; color: Theme.dim; font.pixelSize: 11 }
                    Text { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: row.modelData.state === 2 ? "—" : Math.round(row.modelData.memory) + " MB"; color: Theme.text; font.pixelSize: 12 }
                    Text { Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; text: row.modelData.state === 2 ? "" : "%" + Math.round(row.modelData.cpu); color: Theme.dim; font.pixelSize: 12 }
                    IconButton {
                        Layout.rightMargin: 4
                        implicitWidth: 28; implicitHeight: 28; iconSize: 14
                        symbol: row.modelData.state === 0 ? "moon" : "reload"
                        hint: row.modelData.state === 0 ? "Uyut" : "Uyandır"
                        enabled: !row.modelData.current
                        onClicked: row.modelData.state === 0 ? panel.sleep(row.modelData.index) : panel.wake(row.modelData.index)
                    }
                }
            }
        }
        RowLayout {
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: panel.mode === 0 ? "Otomatik uyutma kapalı." : panel.mode === 1 ? "Boşta sekme 2 dakikada donar, 10 dakikada uyur." : "Boşta sekme 5 dakikada donar, 20 dakikada uyur."
                color: Theme.dim; font.pixelSize: 11; wrapMode: Text.WordWrap
            }
            Repeater {
                model: ["Kapalı", "Erken", "Rahat"]
                TextButton {
                    required property int index
                    required property string modelData
                    text: modelData
                    strong: panel.mode === index
                    onClicked: panel.modeChosen(index)
                }
            }
        }
    }
}
