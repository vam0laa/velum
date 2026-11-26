import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Choosing one colour in the studio: ready ones, three sliders, or its code.
ColumnLayout {
    id: picker
    property string value: "#000000"
    property ColorMath calc
    signal picked(string value)
    spacing: 10
    // the sliders keep their own numbers: grey has no hue to read back
    property real hue: 0
    property real saturation: 0
    property real light: 0
    function follow() {
        if (calc.fromHsl(hue, saturation, light) !== value) {
            const [h, s, l] = calc.toHsl(value)
            hue = h; saturation = s; light = l
        }
    }
    onValueChanged: follow()
    Component.onCompleted: follow()
    function slide(h, s, l) {
        hue = h; saturation = s; light = l
        picked(calc.fromHsl(h, s, l))
    }

    readonly property var ready: [
        "#0b0d10", "#14161f", "#1e1e2e", "#222b2e", "#2d2a24", "#2b1d2a", "#f7f7f5", "#fdf6e3",
        "#eef1f8", "#fde8ef", "#e9f5ec", "#ffffff", "#ff5c7a", "#ff8a3d", "#ffd23f", "#6ed36e",
        "#35c9c1", "#4aa8ff", "#7a7cff", "#c77dff", "#ff77c8", "#a98467", "#8d99ae", "#000000"]

    Grid {
        columns: 12
        spacing: 6
        Repeater {
            model: picker.ready
            AbstractButton {
                required property string modelData
                width: 24; height: 24
                onClicked: picker.picked(modelData)
                Accessible.name: modelData
                background: Rectangle { radius: 12; color: parent.modelData; border.width: picker.value === parent.modelData ? 3 : 1; border.color: picker.value === parent.modelData ? "#ffffff" : "#3a404c" }
            }
        }
    }

    component Bar: Slider {
        id: bar
        property var stops: []
        Layout.fillWidth: true
        implicitHeight: 22
        from: 0; to: 1
        background: Rectangle {
            y: (bar.height - height) / 2; width: bar.width; height: 12; radius: 6
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: bar.stops[0] ?? "black" }
                GradientStop { position: 0.17; color: bar.stops[1] ?? "black" }
                GradientStop { position: 0.33; color: bar.stops[2] ?? "black" }
                GradientStop { position: 0.5; color: bar.stops[3] ?? "black" }
                GradientStop { position: 0.67; color: bar.stops[4] ?? "black" }
                GradientStop { position: 0.83; color: bar.stops[5] ?? "black" }
                GradientStop { position: 1; color: bar.stops[6] ?? "white" }
            }
        }
        handle: Rectangle { x: bar.visualPosition * (bar.width - width); y: (bar.height - height) / 2; width: 20; height: 20; radius: 10; color: picker.value; border.width: 3; border.color: "#ffffff" }
    }
    function steps(f) { return [0, 1, 2, 3, 4, 5, 6].map(i => f(i / 6)) }
    component Name: Text { color: "#9aa0ad"; font.family: Theme.ui; font.pixelSize: 12; Layout.preferredWidth: 66 }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 4
        Name { text: Lang.t("Renk", "Hue") }
        Bar { from: 0; to: 359; value: picker.hue; stops: picker.steps(t => picker.calc.fromHsl(t * 359, 0.8, 0.55)); onMoved: picker.slide(value, Math.max(picker.saturation, 0.25), Math.max(0.08, Math.min(0.92, picker.light))) }
        Name { text: Lang.t("Canlılık", "Vividness") }
        Bar { value: picker.saturation; stops: picker.steps(t => picker.calc.fromHsl(picker.hue, t, picker.light)); onMoved: picker.slide(picker.hue, value, picker.light) }
        Name { text: Lang.t("Aydınlık", "Lightness") }
        Bar { value: picker.light; stops: picker.steps(t => picker.calc.fromHsl(picker.hue, picker.saturation, t)); onMoved: picker.slide(picker.hue, picker.saturation, value) }
        Name { text: Lang.t("Kod", "Code") }
        TextField {
            id: code
            Layout.preferredWidth: 110
            implicitHeight: 28
            text: picker.value
            maximumLength: 7
            color: "#eef0f4"
            font.family: "monospace"
            font.pixelSize: 12
            selectByMouse: true
            background: Rectangle { radius: 8; color: "#232730"; border.color: code.activeFocus ? "#8ab4ff" : "#333946" }
            onEditingFinished: {
                if (/^#[0-9a-fA-F]{6}$/.test(text))
                    picker.picked(text.toLowerCase())
                text = Qt.binding(() => picker.value)
            }
        }
    }
}
