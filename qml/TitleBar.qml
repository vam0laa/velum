import QtQuick
import QtQuick.Layouts

// The strip on top of a window: a small square, the name in pixel letters, and window buttons.
Rectangle {
    id: bar
    property string title
    property color stripe: Theme.accent
    property bool minimizable: false
    property bool maximizable: false
    property bool closable: false
    signal minimize()
    signal maximize()
    signal closeRequested()

    implicitHeight: 28
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.tint(Theme.title, Qt.alpha(bar.stripe, 0.38)) }
        GradientStop { position: 1; color: Theme.title }
    }

    component Control: Bevel {
        id: control
        property string glyph
        property string hint
        signal pressed()
        implicitWidth: 20
        implicitHeight: 18
        sunken: area.pressed
        color: area.containsMouse ? Theme.title : Theme.window
        // drawn, not typed: the pixel font has no window symbols
        Rectangle { visible: control.glyph === "min"; width: 8; height: 2; x: 6; y: 12; color: Theme.text }
        Rectangle { visible: control.glyph === "max"; width: 10; height: 8; x: 5; y: 5; color: "transparent"; border.color: Theme.text; border.width: 1; Rectangle { width: parent.width; height: 2; color: Theme.text } }
        Icon { visible: control.glyph === "close"; anchors.centerIn: parent; name: "close"; size: 14; color: Theme.text }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: control.pressed() }
        Hint { text: control.hint; shown: area.containsMouse; y: control.height + 6; x: control.width - width }
        Accessible.role: Accessible.Button
        Accessible.name: hint
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 8; rightMargin: 5 }
        spacing: 6
        Rectangle { implicitWidth: 9; implicitHeight: 9; color: bar.stripe; border.color: Theme.bevelLo }
        Text {
            Layout.fillWidth: true
            text: bar.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.pixel
            font.pixelSize: 19
            font.capitalization: Font.MixedCase
        }
        Control { visible: bar.minimizable; glyph: "min"; hint: Lang.t("Yan paneli daralt", "Narrow the side bar"); onPressed: bar.minimize() }
        Control { visible: bar.maximizable; glyph: "max"; hint: Lang.t("Tam ekran", "Full screen"); onPressed: bar.maximize() }
        Control { visible: bar.closable; glyph: "close"; hint: Lang.t("Kapat", "Close"); onPressed: bar.closeRequested() }
    }
}
