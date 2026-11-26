pragma Singleton
import QtCore
import QtQuick

// One place for every colour, font and size. The look is vamola.dev's: Catppuccin,
// bevelled windows and pixel lettering.
QtObject {
    id: theme
    property string palette: "mocha"     // "mocha", "gruvbox", "nord", "tokyo" or "desktop"

    property Settings saved: Settings {
        category: "look"
        property alias palette: theme.palette
    }

    // names: frame, window, card, raised, title, line, text, dim, accent, onAccent, c1…c4, danger, hi, lo
    readonly property var palettes: ({
        mocha:   ["#11111b", "#181825", "#1e1e2e", "#313244", "#45475a", "#45475a", "#cdd6f4", "#a6adc8", "#89b4fa", "#11111b", "#cba6f7", "#f5c2e7", "#a6e3a1", "#fab387", "#f38ba8", "#6c7086", "#05050a"],
        gruvbox: ["#1d2021", "#232627", "#282828", "#3c3836", "#504945", "#504945", "#ebdbb2", "#bdae93", "#83a598", "#1d2021", "#d3869b", "#fe8019", "#b8bb26", "#fabd2f", "#fb4934", "#7c6f64", "#0c0d0e"],
        nord:    ["#1b2027", "#242933", "#2e3440", "#434c5e", "#4c566a", "#434c5e", "#eceff4", "#c0c8d8", "#88c0d0", "#1b2027", "#b48ead", "#81a1c1", "#a3be8c", "#ebcb8b", "#bf616a", "#6a7590", "#0b0d10"],
        tokyo:   ["#101014", "#16161e", "#1a1b26", "#292e42", "#363b54", "#363b54", "#c0caf5", "#9aa5ce", "#7aa2f7", "#101014", "#bb9af7", "#ff9eca", "#9ece6a", "#ff9e64", "#f7768e", "#565f89", "#050507"]
    })

    readonly property var desktopRoles: ["surface_container_lowest", "surface_container_low", "surface_container", "surface_container_high", "surface_container_highest", "outline_variant", "on_surface", "on_surface_variant", "primary", "on_primary", "tertiary", "secondary", "primary_fixed", "tertiary_fixed", "error", "outline"]

    function pick(i) {
        const base = palettes[palette] ?? palettes.mocha
        if (palette === "desktop" && i < desktopRoles.length)
            return DesktopColors.colors[desktopRoles[i]] ?? base[i]
        return base[i]
    }

    readonly property color frame: pick(0)       // behind everything
    readonly property color window: pick(1)      // the body of a window
    readonly property color surface: pick(2)     // pages of our own, fields
    readonly property color raised: pick(3)      // buttons
    readonly property color title: pick(4)       // title bars
    readonly property color line: pick(5)
    readonly property color text: pick(6)
    readonly property color dim: pick(7)
    readonly property color accent: pick(8)
    readonly property color onAccent: pick(9)
    readonly property color mauve: pick(10)
    readonly property color pink: pick(11)
    readonly property color green: pick(12)
    readonly property color peach: pick(13)
    readonly property color danger: pick(14)
    readonly property color bevelHi: pick(15)
    readonly property color bevelLo: palettes.mocha[16]
    readonly property var rainbow: [accent, mauve, pink, green, peach]

    property FontLoader pixelFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/VT323-Regular.ttf") }
    property FontLoader brandFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/Silkscreen-Regular.ttf") }
    property FontLoader uiFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/GoogleSansFlex.woff") }
    readonly property string pixel: pixelFont.name      // has the Turkish letters
    readonly property string brand: brandFont.name      // for English words only
    readonly property string ui: uiFont.name

    readonly property int radius: 3
    readonly property int gap: 8
    readonly property int sidebar: 280
    readonly property int strip: 60
    readonly property int quick: 120
    readonly property int smooth: 220
}
