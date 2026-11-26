pragma Singleton
import QtCore
import QtQuick

// One place for every colour, font and size: Catppuccin and friends, rounded windows
// with thin title bars, and a little pixel lettering, after vamola.dev.
QtObject {
    id: theme
    property string palette: "mocha"       // a key of "palettes", or "desktop"
    property string accentChoice: ""       // "" keeps the palette's own accent
    property bool glass: false             // see-through windows; the desktop blurs behind them
    property real solidity: 0.72           // how opaque the glass is: 0.55, 0.72 or 0.88

    property Settings saved: Settings {
        category: "look"
        property alias palette: theme.palette
        property alias accent: theme.accentChoice
        property alias glass: theme.glass
        property alias solidity: theme.solidity
    }

    // frame, window, card, raised, title, line, text, dim, accent, onAccent, mauve, pink, green, peach, danger
    readonly property var palettes: ({
        mocha:      ["#11111b", "#181825", "#1e1e2e", "#313244", "#45475a", "#45475a", "#cdd6f4", "#a6adc8", "#89b4fa", "#11111b", "#cba6f7", "#f5c2e7", "#a6e3a1", "#fab387", "#f38ba8"],
        macchiato:  ["#181926", "#1e2030", "#24273a", "#363a4f", "#494d64", "#494d64", "#cad3f5", "#a5adcb", "#8aadf4", "#181926", "#c6a0f6", "#f5bde6", "#a6da95", "#f5a97f", "#ed8796"],
        frappe:     ["#232634", "#292c3c", "#303446", "#414559", "#51576d", "#51576d", "#c6d0f5", "#a5adce", "#8caaee", "#232634", "#ca9ee6", "#f4b8e4", "#a6d189", "#ef9f76", "#e78284"],
        latte:      ["#dce0e8", "#e6e9ef", "#eff1f5", "#ccd0da", "#bcc0cc", "#bcc0cc", "#4c4f69", "#5c5f77", "#1e66f5", "#eff1f5", "#8839ef", "#d3479f", "#2f8420", "#c9540a", "#d20f39"],
        rosepine:   ["#13111c", "#191724", "#1f1d2e", "#26233a", "#403d52", "#403d52", "#e0def4", "#908caa", "#9ccfd8", "#191724", "#c4a7e7", "#ebbcba", "#8fc9a8", "#f6c177", "#eb6f92"],
        everforest: ["#232a2e", "#272e33", "#2d353b", "#343f44", "#475258", "#475258", "#d3c6aa", "#9da9a0", "#7fbbb3", "#232a2e", "#d699b6", "#e8a5b8", "#a7c080", "#e69875", "#e67e80"],
        gruvbox:    ["#1d2021", "#232627", "#282828", "#3c3836", "#504945", "#504945", "#ebdbb2", "#bdae93", "#83a598", "#1d2021", "#d3869b", "#fe8019", "#b8bb26", "#fabd2f", "#fb4934"],
        nord:       ["#1b2027", "#242933", "#2e3440", "#434c5e", "#4c566a", "#434c5e", "#eceff4", "#c0c8d8", "#88c0d0", "#1b2027", "#b48ead", "#81a1c1", "#a3be8c", "#ebcb8b", "#bf616a"],
        tokyo:      ["#101014", "#16161e", "#1a1b26", "#292e42", "#363b54", "#363b54", "#c0caf5", "#9aa5ce", "#7aa2f7", "#101014", "#bb9af7", "#ff9eca", "#9ece6a", "#ff9e64", "#f7768e"]
    })

    // what the pickers offer, in order
    readonly property var themes: [
        { key: "mocha", label: "Mocha" }, { key: "macchiato", label: "Macchiato" }, { key: "frappe", label: "Frappé" }, { key: "latte", label: "Latte" },
        { key: "rosepine", label: "Rosé Pine" }, { key: "everforest", label: "Everforest" }, { key: "gruvbox", label: "Gruvbox" }, { key: "nord", label: "Nord" },
        { key: "tokyo", label: "Tokyo Night" }, { key: "desktop", label: Lang.t("Masaüstü", "Desktop") }
    ]
    // the accent colours that can be chosen, as places in a palette
    readonly property var accents: ({ blue: 8, mauve: 10, pink: 11, green: 12, peach: 13, red: 14 })

    readonly property var desktopRoles: ["surface_container_lowest", "surface_container_low", "surface_container", "surface_container_high", "surface_container_highest", "outline_variant", "on_surface", "on_surface_variant", "primary", "on_primary", "tertiary", "secondary", "primary_fixed", "tertiary_fixed", "error"]

    // colour i of any theme, used by the pickers to draw previews
    function colorOf(key, i) {
        const base = palettes[key] ?? palettes.mocha
        if (key === "desktop")
            return DesktopColors.colors[desktopRoles[i]] ?? base[i]
        return base[i]
    }
    function pick(i) { return colorOf(palette, i) }

    readonly property color frame: pick(0)       // behind everything
    readonly property color window: pick(1)      // the body of a window
    readonly property color surface: pick(2)     // pages of our own, fields
    readonly property color raised: pick(3)      // buttons
    readonly property color title: pick(4)       // title bars
    readonly property color line: pick(5)
    readonly property color text: pick(6)
    readonly property color dim: pick(7)
    readonly property color accent: pick(accents[accentChoice] ?? 8)
    readonly property color onAccent: pick(9)
    readonly property color mauve: pick(10)
    readonly property color pink: pick(11)
    readonly property color green: pick(12)
    readonly property color peach: pick(13)
    readonly property color danger: pick(14)
    readonly property bool dark: surface.hslLightness < 0.5

    // The backgrounds of the window itself. Popups and menus stay solid, to be readable.
    // The layers lie on each other, so each one is thinner than the whole should look.
    readonly property color frameBack: glass ? Qt.alpha(frame, solidity * 0.6) : frame
    readonly property color paneBack: glass ? Qt.alpha(window, solidity * 0.65) : window
    readonly property color sheetBack: glass ? Qt.alpha(surface, solidity * 0.35) : surface
    readonly property var rainbow: [accent, mauve, pink, green, peach]

    property FontLoader pixelFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/VT323-Regular.ttf") }
    property FontLoader uiFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/GoogleSansFlex.woff") }
    readonly property string pixel: pixelFont.name      // has the Turkish letters
    readonly property string ui: uiFont.name

    readonly property int radius: 10       // buttons, fields, rows
    readonly property int corner: 16       // windows
    readonly property int gap: 8
    readonly property int sidebar: 280
    readonly property int strip: 60
    readonly property int quick: 120
    readonly property int smooth: 220
}
