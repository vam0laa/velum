import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// One widget of the home page, chosen by name: "date", "calendar", "shield", "note",
// "tasks" or "timer".
HomeBox {
    id: widget
    required property string modelData
    names: [modelData, "widget"]
    Layout.fillWidth: true
    base: modelData === "date" ? Qt.tint(Theme.surface, Qt.alpha(Theme.accent, 0.3))
        : modelData === "shield" ? Qt.tint(Theme.surface, Qt.alpha(Theme.mauve, 0.3)) : Theme.raised
    implicitHeight: inside.item ? inside.item.implicitHeight : 0

    // the writing colour on this widget
    readonly property color ink: page.css(names, "color", Theme.text)
    function strong(tone) { return Theme.dark ? Qt.lighter(tone, 1.15) : Qt.darker(tone, 1.15) }

    component Words: HomeText { page: widget.page; names: widget.names }

    Loader {
        id: inside
        anchors { left: parent.left; right: parent.right; top: parent.top }
        sourceComponent: ({ date: dateFace, calendar: calendarFace, shield: shieldFace, note: noteFace, tasks: tasksFace, timer: timerFace })[widget.modelData] ?? null
    }

    Component {
        id: dateFace
        Item {
            implicitHeight: 138
            Column {
                anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                spacing: -4
                Words { text: widget.page.locale_.dayName(widget.page.now.getDay()); base: Theme.accent; size: 15; weight: 700 }
                Words { text: widget.page.now.getDate(); base: widget.strong(Theme.accent); size: 58; weight: 850 }
                Words { text: widget.page.locale_.monthName(widget.page.now.getMonth()) + "  •"; base: Theme.accent; size: 14; weight: 700 }
            }
        }
    }
    Component {
        id: calendarFace
        Item {
            implicitHeight: calendar.implicitHeight + 32
            MonthCard {
                id: calendar
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                now: widget.page.now
                names: widget.page.locale_
                mondayFirst: Lang.turkish
                ink: widget.ink
            }
        }
    }
    Component {
        id: shieldFace
        Item {
            implicitHeight: 138
            Column {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: -2
                Row {
                    spacing: 8
                    Icon { name: "shield"; size: 16; color: Theme.mauve; anchors.verticalCenter: parent.verticalCenter }
                    Words { text: Lang.t("Kalkan", "Shield"); base: Theme.mauve; size: 15; weight: 700 }
                }
                Words { text: Number(widget.page.blocked).toLocaleString(widget.page.locale_, "f", 0); base: widget.strong(Theme.mauve); size: 46; weight: 850 }
                Words { width: parent.width; elide: Text.ElideRight; text: Lang.t("reklam ve izleyici engellendi", "ads and trackers blocked"); base: Theme.mauve; size: 12 }
            }
        }
    }
    Component {
        id: noteFace
        Item {
            implicitHeight: Math.max(120, Math.min(240, memo.implicitHeight + 24))
            ScrollView {
                anchors { fill: parent; margins: 12 }
                TextArea {
                    id: memo
                    text: widget.page.note
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                    color: widget.ink
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentInk
                    placeholderText: Lang.t("Not: aklındakini yaz, bu bilgisayarda kalır.", "Note: jot something down, it stays on this computer.")
                    placeholderTextColor: Qt.alpha(widget.ink, 0.55)
                    font.family: widget.page.css(widget.names, "font-family", Theme.ui)
                    font.pixelSize: widget.page.css(widget.names, "font-size", 14)
                    background: null
                    onTextChanged: if (activeFocus) widget.page.noteEdited(text.slice(0, 4000))
                }
            }
        }
    }
    // a short list of things to do: [{ text, done }]
    Component {
        id: tasksFace
        Item {
            implicitHeight: list.implicitHeight + 32
            Column {
                id: list
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 4
                Words { leftPadding: 4; text: Lang.t("Görevler", "Tasks"); size: 15; weight: 700 }
                Repeater {
                    model: widget.page.tasks
                    RowLayout {
                        id: task
                        required property var modelData
                        required property int index
                        width: list.width
                        spacing: 8
                        AbstractButton {
                            implicitWidth: 20; implicitHeight: 20
                            onClicked: widget.page.tasksEdited(widget.page.tasks.map((t, i) => i === task.index ? { text: t.text, done: !t.done } : t))
                            Accessible.name: task.modelData.text
                            background: Rectangle { radius: Theme.web ? 0 : 10; color: task.modelData.done ? Theme.accent : "transparent"; border.width: task.modelData.done ? 0 : 2; border.color: Theme.dim }
                            contentItem: Text { visible: task.modelData.done; text: "✓"; color: Theme.accentInk; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 13; font.family: Theme.ui }
                        }
                        Words { Layout.fillWidth: true; text: task.modelData.text; wrapMode: Text.WordWrap; size: 13; opacity: task.modelData.done ? 0.5 : 1; font.strikeout: task.modelData.done }
                        IconButton { implicitWidth: 22; implicitHeight: 22; iconSize: 11; symbol: "close"; hint: Lang.t("Sil", "Delete"); onClicked: widget.page.tasksEdited(widget.page.tasks.filter((t, i) => i !== task.index)) }
                    }
                }
                TextField {
                    width: list.width
                    visible: widget.page.tasks.length < 12
                    implicitHeight: 32
                    leftPadding: 12
                    placeholderText: Lang.t("Görev ekle (Enter)", "Add a task (Enter)")
                    placeholderTextColor: Qt.alpha(widget.ink, 0.55)
                    color: widget.ink
                    maximumLength: 120
                    font.family: Theme.ui
                    font.pixelSize: 13
                    background: Rectangle { radius: Theme.web ? 0 : 16; color: Qt.alpha(widget.ink, 0.08); border.color: parent.activeFocus ? Theme.accent : "transparent" }
                    onAccepted: {
                        if (text.trim() !== "")
                            widget.page.tasksEdited(widget.page.tasks.concat([{ text: text.trim(), done: false }]))
                        text = ""
                    }
                }
            }
        }
    }
    // a focus timer; it counts only while this page is kept open
    Component {
        id: timerFace
        Item {
            implicitHeight: 150
            Column {
                anchors.centerIn: parent
                spacing: 8
                Words { anchors.horizontalCenter: parent.horizontalCenter; text: widget.page.timerText; base: widget.strong(Theme.accent); size: 46; weight: 850 }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    TextButton { implicitHeight: 28; text: "−"; enabled: !widget.page.timerRunning; onClicked: widget.page.setTimer(widget.page.timerMinutes - 5) }
                    TextButton { implicitHeight: 28; strong: true; text: widget.page.timerRunning ? Lang.t("Duraklat", "Pause") : Lang.t("Başlat", "Start"); onClicked: widget.page.toggleTimer() }
                    TextButton { implicitHeight: 28; text: "+"; enabled: !widget.page.timerRunning; onClicked: widget.page.setTimer(widget.page.timerMinutes + 5) }
                    IconButton { implicitWidth: 28; implicitHeight: 28; iconSize: 14; symbol: "reload"; hint: Lang.t("Sıfırla", "Reset"); onClicked: widget.page.setTimer(widget.page.timerMinutes) }
                }
            }
        }
    }
}
