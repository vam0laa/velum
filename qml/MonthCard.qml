import QtQuick

// This month at a glance, with today marked.
Item {
    id: month
    property date now: new Date()
    property var names: Qt.locale("tr_TR")
    property bool mondayFirst: true
    // only the day matters; the grid is not rebuilt every second
    readonly property int year: now.getFullYear()
    readonly property int number: now.getMonth()
    readonly property int today: now.getDate()
    readonly property int offset: (new Date(year, number, 1).getDay() - (mondayFirst ? 1 : 0) + 7) % 7
    readonly property int days: new Date(year, number + 1, 0).getDate()
    readonly property real cell: Math.min(34, Math.floor((width - 8) / 7))
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        Text {
            leftPadding: 6
            text: month.names.standaloneMonthName(month.number) + " " + month.year
            color: Theme.text
            font.family: Theme.ui
            font.pixelSize: 15
            font.variableAxes: Theme.axes(700)
        }
        Grid {
            columns: 7
            Repeater {
                model: 7
                Text {
                    required property int index
                    width: month.cell
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: month.names.standaloneDayName((index + (month.mondayFirst ? 1 : 0)) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Theme.dim
                    font.family: Theme.ui
                    font.pixelSize: 11
                }
            }
            Repeater {
                model: month.offset + month.days
                Item {
                    id: box
                    required property int index
                    readonly property int day: index - month.offset + 1
                    width: month.cell
                    height: Math.min(month.cell, 28)
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: Theme.web ? 0 : width / 2
                        color: Theme.accent
                        visible: box.day === month.today
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: box.day > 0
                        text: box.day
                        color: box.day === month.today ? Theme.accentInk : box.day < month.today ? Theme.dim : Theme.text
                        font.family: Theme.ui
                        font.pixelSize: 12
                        font.variableAxes: Theme.axes(box.day === month.today ? 800 : 450)
                    }
                }
            }
        }
    }
}
