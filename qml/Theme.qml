pragma Singleton
import QtQuick

// One place for every colour and size. The colours follow the desktop theme when there is one;
// the values after each name are used otherwise (Catppuccin Mocha).
QtObject {
    function pick(name, fallback) { return DesktopColors.colors[name] ?? fallback }

    readonly property color frame: pick("surface_container_low", "#181825")      // window background
    readonly property color surface: pick("surface_container", "#1e1e2e")        // fields, hovered rows
    readonly property color raised: pick("surface_container_highest", "#313244") // the current tab
    readonly property color line: pick("outline_variant", "#45475a")
    readonly property color text: pick("on_surface", "#cdd6f4")
    readonly property color dim: pick("outline", "#7f849c")
    readonly property color accent: pick("primary", "#89b4fa")
    readonly property color onAccent: pick("on_primary", "#181825")

    readonly property int radius: 10
    readonly property int gap: 8
    readonly property int sidebar: 264
    readonly property int strip: 52               // the narrow side bar
    readonly property int quick: 120              // animation lengths in milliseconds
    readonly property int smooth: 220
}
