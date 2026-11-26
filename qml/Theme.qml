pragma Singleton
import QtCore
import QtQuick

// One place for every colour, font and size. The look is webcore: square windows with
// blue title bars, pixel lettering and a sky behind the start page.
QtObject {
    id: theme
    property string palette: "auto"        // a key of "palettes", "desktop", or "auto"
    // "auto" is the bright blue by day and the night blue from the evening on
    property int hour: new Date().getHours()
    readonly property string shown: palette !== "auto" ? palette : hour >= 7 && hour < 19 ? "cybercore" : "night"
    readonly property bool night: shown === "night"
    property Timer clock: Timer { interval: 30000; running: true; repeat: true; onTriggered: theme.hour = new Date().getHours() }
    property string accentChoice: ""       // "" keeps the palette's own accent
    property bool glass: false             // see-through windows; the desktop blurs behind them
    property real solidity: 0.72           // how opaque the glass is: 0.55, 0.72 or 0.88
    property bool motion: true             // false: nothing slides or grows

    property Settings saved: Settings {
        category: "look"
        property alias scheme: theme.palette
        property alias accent: theme.accentChoice
        property alias glass: theme.glass
        property alias solidity: theme.solidity
        property alias motion: theme.motion
    }

    // frame, window, card, raised, title, line, text, dim, accent, accentInk, mauve, pink, green, peach, danger
    readonly property var palettes: ({
        night:      ["#0d1124", "#171c33", "#171c33", "#10142a", "#26306a", "#3a478c", "#c3cdee", "#8590ba", "#6473d6", "#f0f3ff", "#a58be0", "#d27cc4", "#5fbf9c", "#d9a066", "#e0708c"],
        cybercore:  ["#050a5c", "#c9d8ff", "#eef3ff", "#ffffff", "#b4c6ff", "#1a2cff", "#0b17a8", "#46549c", "#1a2cff", "#ffffff", "#6a22d6", "#c2188a", "#08765a", "#a84e00", "#c8102e"],
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
        { key: "auto", label: Lang.t("Saate göre", "By the clock") }, { key: "night", label: Lang.t("Cybercore gece", "Cybercore night") }, { key: "cybercore", label: Lang.t("Cybercore gündüz", "Cybercore day") }, { key: "mocha", label: "Mocha" }, { key: "macchiato", label: "Macchiato" }, { key: "frappe", label: "Frappé" }, { key: "latte", label: "Latte" },
        { key: "rosepine", label: "Rosé Pine" }, { key: "everforest", label: "Everforest" }, { key: "gruvbox", label: "Gruvbox" }, { key: "nord", label: "Nord" },
        { key: "tokyo", label: "Tokyo Night" }, { key: "desktop", label: Lang.t("Masaüstü", "Desktop") }
    ]
    // the accent colours that can be chosen, as places in a palette
    readonly property var accents: ({ blue: 8, mauve: 10, pink: 11, green: 12, peach: 13, red: 14 })

    readonly property var desktopRoles: ["surface_container_lowest", "surface_container_low", "surface_container", "surface_container_high", "surface_container_highest", "outline_variant", "on_surface", "on_surface_variant", "primary", "on_primary", "tertiary", "secondary", "primary_fixed", "tertiary_fixed", "error"]

    // colour i of any theme, used by the pickers to draw previews
    function colorOf(key, i) {
        if (key === "auto")
            key = shown
        const base = palettes[key] ?? palettes.cybercore
        if (key === "desktop")
            return DesktopColors.colors[desktopRoles[i]] ?? base[i]
        return base[i]
    }
    function pick(i) { return colorOf(shown, i) }

    readonly property color frame: pick(0)       // behind everything
    readonly property color window: pick(1)      // the body of a window
    readonly property color surface: pick(2)     // pages of our own, fields
    readonly property color raised: pick(3)      // buttons
    readonly property color title: pick(4)       // title bars
    readonly property color line: pick(5)
    readonly property color text: pick(6)
    readonly property color dim: pick(7)
    readonly property color accent: pick(accents[accentChoice] ?? 8)
    readonly property color accentInk: pick(9)
    readonly property color mauve: pick(10)
    readonly property color pink: pick(11)
    readonly property color green: pick(12)
    readonly property color peach: pick(13)
    readonly property color danger: pick(14)
    readonly property bool dark: surface.hslLightness < 0.5
    // title bars, the tab strip and the few white lines drawn on them
    readonly property color bar: night ? "#2c3a9e" : accent
    readonly property color barInk: accentInk
    readonly property color barDeep: night ? "#11162b" : Qt.darker(accent, 1.45)
    readonly property color stripTop: night ? "#0d1124" : bar
    readonly property color stripBottom: night ? "#0d1124" : barDeep
    readonly property color edge: dark ? line : "#ffffff"       // the bright outer line of a window
    readonly property color hardShadow: Qt.rgba(0, 0.015, 0.2, 0.45)

    // The backgrounds of the window itself. Popups and menus stay solid, to be readable.
    // The layers lie on each other, so each one is thinner than the whole should look.
    readonly property color frameBack: glass ? Qt.alpha(frame, solidity * 0.6) : frame
    readonly property color paneBack: glass ? Qt.alpha(window, solidity * 0.65) : window
    readonly property color sheetBack: glass ? Qt.alpha(surface, solidity * 0.35) : surface
    readonly property var rainbow: [accent, mauve, pink, green, peach]

    property FontLoader pixelFont: FontLoader { source: Qt.resolvedUrl("../data/fonts/VT323-Regular.ttf") }
    readonly property string pixel: pixelFont.name      // has the Turkish letters
    readonly property string ui: pixelFont.name         // pixel letters everywhere

    readonly property int radius: 0        // everything is square
    readonly property int corner: 0
    readonly property int gap: 8
    readonly property int sidebar: 280
    readonly property int strip: 60
    readonly property int quick: motion ? 120 : 0
    readonly property int smooth: motion ? 220 : 0
}
