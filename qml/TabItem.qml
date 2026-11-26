import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// One tab: a row with icon and title, or only the icon when the side bar is narrow.
ItemDelegate {
    id: row
    required property int index
    required property string title
    required property string siteIcon
    required property bool loading
    required property bool audible
    required property bool muted
    signal muteToggled(int index)
    required property string pageUrl
    required property int group          // 0: none
    required property bool lead          // the first of its group carries the name
    required property bool folded        // hidden in a folded group
    required property bool chosen        // one of several selected
    property var groups: []
    readonly property var info: group > 0 ? groups.find(g => g.id === group) ?? null : null
    readonly property color groupColour: info ? Theme[info.colour] : "transparent"
    // a folded group shows only its name, on its first tab
    readonly property bool onlyName: lead && folded
    // the room the name takes, worked out from its letters alone
    readonly property string chipLabel: info ? (info.collapsed ? "▸ " : "") + info.name : ""
    readonly property real chipWidth: Math.min(130, Math.ceil(measure.advanceWidth) + 20)
    property TextMetrics measure: TextMetrics { text: row.chipLabel; font.family: Theme.ui; font.pixelSize: 11 }
    readonly property real chipRoom: lead && info && horizontal ? chipWidth + 6 : 0
    signal selected(int index, bool stretch)
    signal groupToggled(int id)
    signal groupMenu(int id, Item at)
    required property bool pinned
    required property int asleep       // 0 awake, 1 frozen, 2 discarded
    required property int space        // the workspace it belongs to
    property bool shown: true          // false: it belongs to another workspace
    property bool current: false
    property bool compact: false
    required property string kind      // "" a web page, "settings" Velum's settings
    property bool horizontal: false    // in the bar along the top
    property real wide: 200            // how wide a horizontal tab may be
    readonly property string label: kind === "settings" ? Lang.t("Ayarlar", "Settings") : title === "" ? Lang.t("Ana sayfa", "Home") : title
    readonly property color tone: Theme.rainbow[Math.max(0, index) % Theme.rainbow.length]
    signal picked(int index)
    signal closed(int index)
    signal menuRequested(int index)
    signal dragged(int index, point at)
    // set by the list: the last pinned tab draws a divider under itself
    property bool lastPinned: false

    width: !horizontal ? (ListView.view?.width ?? 0) : !shown || (folded && !lead) ? 0 : onlyName ? chipRoom + 4 : (compact ? 48 : wide) + chipRoom
    height: horizontal ? Theme.dense(36) : !shown || (folded && !lead) ? 0 : Theme.dense(40) + (lead && info ? 24 : 0)
    // your style sheet: ".tab", and ".tab-active" over it for the current one
    function styled(property, fallback) {
        const usual = Theme.styled("tab", property, fallback)
        return current ? Theme.styled("tab-active", property, usual) : usual
    }
    readonly property real tabRadius: Theme.web ? 0 : Theme.tabShape === "pill" ? height / 2 : Theme.tabShape === "square" ? 0
        : Theme.tabShape === "line" ? 0 : Theme.round(9)
    readonly property bool lined: !Theme.web && Theme.tabShape === "line"
    visible: shown && !(folded && !lead)
    padding: 0
    leftPadding: chipRoom
    leftInset: chipRoom
    topPadding: !horizontal && lead && info ? 24 : 0
    topInset: !horizontal && lead && info ? 24 : 0
    clip: false
    bottomPadding: horizontal ? 0 : 4
    bottomInset: horizontal ? 0 : 4
    rightPadding: horizontal ? 4 : 0
    rightInset: horizontal ? 4 : 0
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    onClicked: picked(index)
    Accessible.name: label

    // on the blue strip an idle tab is a darker folder; the current one joins the toolbar
    readonly property color ink: styled("color", current ? Theme.text : horizontal && Theme.web ? "#dbe6ff" : Theme.dim)

    background: Item {
        // vertical: a row, outlined when chosen
        Rectangle {
            anchors.fill: parent
            visible: !row.horizontal
            radius: row.styled("border-radius", Theme.web ? 0 : row.tabRadius > 0 ? Math.min(height / 2, Theme.tabShape === "pill" ? height / 2 : Theme.radius) : 0)
            color: row.styled("background", row.current && !row.lined ? Theme.raised : row.hovered ? (Theme.web ? Theme.title : Qt.alpha(Theme.raised, 0.5)) : "transparent")
            border.width: Theme.web && row.current ? 2 : row.styled("border-width", row.styled("border-color", "") !== "" ? 1 : 0)
            border.color: row.styled("border-color", Theme.line)
            Rectangle { visible: row.lined && row.current; width: 3; height: parent.height - 10; y: 5; radius: 1.5; color: Theme.accent }
        }
        // everyday look: a rounded tab, filled when it is the current one
        Rectangle {
            anchors { fill: parent; topMargin: 1; bottomMargin: 3 }
            visible: row.horizontal && !Theme.web
            radius: row.styled("border-radius", row.tabRadius)
            color: row.styled("background", row.current && !row.lined ? Theme.raised : row.hovered ? Qt.alpha(Theme.raised, 0.45) : "transparent")
            border.width: row.styled("border-width", row.styled("border-color", "") !== "" ? 1 : 0)
            border.color: row.styled("border-color", Theme.line)
            Behavior on color { ColorAnimation { duration: Theme.quick } }
            Rectangle { visible: row.lined && row.current; anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 } height: 3; radius: 1.5; color: Theme.accent }
        }
        Shape {
            id: folder
            anchors.fill: parent
            visible: row.horizontal && Theme.web
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 2
                strokeColor: Theme.edge
                fillColor: row.current ? Theme.window : row.hovered ? Theme.bar : Theme.barDeep
                startX: 1; startY: folder.height
                PathLine { x: 1; y: 1 }
                PathLine { x: folder.width - 13; y: 1 }
                PathLine { x: folder.width - 1; y: 13 }
                PathLine { x: folder.width - 1; y: folder.height }
            }
        }
    }

    // the name of the group, before its first tab; press to fold it
    AbstractButton {
        id: chip
        visible: row.lead && row.info !== null
        x: row.horizontal ? 2 : 6
        y: row.horizontal ? (row.height - height) / 2 : 2
        height: 22
        width: row.chipWidth
        z: 2
        onClicked: row.groupToggled(row.group)
        Accessible.name: row.info?.name ?? ""
        background: Rectangle { radius: Theme.round(8); color: row.groupColour }
        contentItem: Text { id: chipText; text: row.chipLabel; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.accentInk; font.family: Theme.ui; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: row.groupMenu(row.group, chip) }
    }
    // a line in the group's colour under each of its tabs
    Rectangle {
        visible: row.info !== null && !row.onlyName
        x: row.horizontal ? row.chipRoom + 6 : 0
        y: row.horizontal ? row.height - 3 : row.topPadding + 4
        width: row.horizontal ? row.width - row.chipRoom - 16 : 3
        height: row.horizontal ? 3 : row.height - row.topPadding - 12
        radius: 1.5
        color: row.groupColour
        z: 2
    }
    // selected with others
    Rectangle {
        visible: row.chosen
        anchors { fill: parent; leftMargin: row.chipRoom; topMargin: row.topPadding; rightMargin: row.horizontal ? 4 : 0; bottomMargin: row.horizontal ? 3 : 4 }
        radius: Theme.round(9)
        color: Qt.alpha(Theme.accent, 0.18)
        border.color: Theme.accent
        z: 1
    }
    // Ctrl+click and Shift+click select; a plain click goes on to the tab
    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: row.chipRoom
        anchors.topMargin: row.topPadding
        z: 3
        onPressed: mouse => mouse.accepted = (mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) !== 0
        onClicked: mouse => row.selected(row.index, (mouse.modifiers & Qt.ShiftModifier) !== 0)
    }

    contentItem: Item {
        visible: !row.onlyName
        Item {
            id: mark
            width: 18
            height: 18
            x: row.compact ? (parent.width - width) / 2 : 14
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: favicon
                anchors.fill: parent
                source: row.siteIcon
                sourceSize: Qt.size(36, 36)
                visible: !row.loading && row.kind === "" && status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                name: row.kind === "settings" ? "settings" : "globe"
                size: 17
                color: row.horizontal ? row.ink : row.tone
                visible: !row.loading && !favicon.visible
            }
            // loading: four squares lighting up in turn
            Grid {
                id: blocks
                anchors.centerIn: parent
                columns: 2
                spacing: 2
                visible: row.loading
                property int step: 0
                Timer { interval: 140; repeat: true; running: blocks.visible; onTriggered: blocks.step = (blocks.step + 1) % 4 }
                Repeater {
                    model: [0, 1, 3, 2]
                    Rectangle { required property int modelData; width: 6; height: 6; color: row.tone; opacity: blocks.step === modelData ? 1 : 0.25 }
                }
            }
        }
        Text {
            anchors { left: mark.right; leftMargin: 10; right: sound.visible ? sound.left : close.visible ? close.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.label
            textFormat: Text.PlainText     // a page title is never treated as markup
            color: row.ink
            opacity: row.asleep > 0 ? 0.55 : 1
            font.family: row.styled("font-family", Theme.ui); font.pixelSize: row.styled("font-size", Theme.size(17))
            font.weight: row.styled("font-weight", row.current ? Font.DemiBold : Font.Normal)
            elide: Text.ElideRight
            visible: !row.compact
        }
        // sound: press to silence or let be heard
        IconButton {
            id: sound
            anchors { right: close.visible ? close.left : parent.right; rightMargin: close.visible ? 0 : 7; verticalCenter: parent.verticalCenter }
            visible: (row.audible || row.muted) && !row.compact
            flat: true
            tone: row.muted ? Theme.dim : row.ink
            implicitWidth: 22; implicitHeight: 22; iconSize: 13
            symbol: row.muted ? "muted" : "sound"
            hint: row.muted ? Lang.t("Sesi aç", "Unmute") : Lang.t("Sesi kapat", "Mute")
            onClicked: row.muteToggled(row.index)
        }
        Icon {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            name: "pin"
            size: 14
            color: Theme.peach
            visible: !row.compact && row.pinned && row.asleep < 2 && !sound.visible
        }
        Icon {
            anchors { right: parent.right; rightMargin: row.compact ? 3 : 12; top: row.compact ? parent.top : undefined; verticalCenter: row.compact ? undefined : parent.verticalCenter }
            name: "moon"
            size: row.compact ? 11 : 14
            color: Theme.mauve
            visible: row.asleep === 2 && !(row.hovered && !row.compact && !row.pinned)
        }
        IconButton {
            id: close
            anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
            flat: true
            tone: row.ink
            implicitWidth: 22
            implicitHeight: 22
            iconSize: 13
            symbol: "close"
            hint: Lang.t("Sekmeyi kapat", "Close the tab") + Keymap.hint("closeTab")
            visible: !row.compact && !row.pinned && (row.hovered || row.current)
            onClicked: row.closed(row.index)
        }
    }

    // a small card about the tab: its name, where it is, whether it sleeps
    Hint {
        text: row.label + (row.pageUrl !== "" && row.kind === "" ? "\n" + (row.pageUrl.length > 70 ? row.pageUrl.slice(0, 69) + "…" : row.pageUrl) : "")
              + (row.asleep > 0 ? "\n" + Lang.t("Uyuyor", "Asleep") : "")
        shown: row.hovered && !row.onlyName
        x: row.horizontal ? 0 : row.width + 8
        y: row.horizontal ? row.height + 6 : (row.height - height) / 2
    }

    // the middle mouse button closes a tab, as in other browsers; pinned tabs are safe from it
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: if (!row.pinned) row.closed(row.index)
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: row.menuRequested(row.index)
    }
    // drag a tab up or down to move it
    DragHandler {
        id: drag
        target: null
        xAxis.enabled: row.horizontal
        yAxis.enabled: !row.horizontal
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onCentroidChanged: if (active) row.dragged(row.index, centroid.scenePosition)
    }
    opacity: (drag.active ? 0.7 : 1) * styled("opacity", 1)

    Rectangle {
        visible: row.lastPinned
        x: row.horizontal ? row.width - 3 : 6
        y: row.horizontal ? 8 : row.height - 3
        width: row.horizontal ? 2 : row.width - 12
        height: row.horizontal ? row.height - 16 : 2
        color: Theme.peach
        opacity: 0.6
    }
}
