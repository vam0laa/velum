import QtQuick

// The arithmetic of the theme studio: from four colours to the fifteen a theme needs.
// Colours are "#rrggbb" texts.
QtObject {
    function rgb(hex) { const n = parseInt(String(hex).slice(-6), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255] }
    function hex(c) { return "#" + c.map(v => ("0" + Math.round(Math.max(0, Math.min(255, v))).toString(16)).slice(-2)).join("") }
    // `t` of the way from a to b
    function mix(a, b, t) { const x = rgb(a), y = rgb(b); return hex(x.map((v, i) => v + (y[i] - v) * t)) }

    function luminance(c) {
        const [r, g, b] = rgb(c).map(v => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4) })
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    // 1 (the same) to 21 (black on white); text reads comfortably from 4.5
    function contrast(a, b) {
        const x = luminance(a), y = luminance(b)
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
    }

    // hue 0..360, saturation and lightness 0..1
    function toHsl(c) {
        const [r, g, b] = rgb(c).map(v => v / 255)
        const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min, l = (max + min) / 2
        const s = d === 0 ? 0 : d / (1 - Math.abs(2 * l - 1))
        let h = d === 0 ? 0 : max === r ? ((g - b) / d) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4
        return [(h * 60 + 360) % 360, s, l]
    }
    function fromHsl(h, s, l) {
        const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2
        const [r, g, b] = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x]
        return hex([(r + m) * 255, (g + m) * 255, (b + m) * 255])
    }

    // the writing colour that reads best on `back`
    function inkOn(back) {
        const light = mix("#ffffff", back, 0.04), dark = mix("#000000", back, 0.14)
        return contrast(light, back) >= contrast(dark, back) ? light : dark
    }

    // The whole theme from the page, the bars, the writing and the accent, in the order
    // Theme keeps them.
    function derive(page, bars, ink, accent) {
        const dark = luminance(page) < 0.25
        const [h, s] = toHsl(accent)
        const soft = (turn, hue) => fromHsl(hue ?? (h + turn) % 360, Math.max(0.45, Math.min(0.8, s)), dark ? 0.76 : 0.38)
        return [mix(page, "#000000", dark ? 0.4 : 0.08), bars, page, mix(bars, ink, 0.09), mix(bars, ink, 0.16), mix(bars, ink, 0.2),
                ink, mix(ink, page, 0.3), accent, inkOn(accent), soft(60), soft(110), soft(0, 130), soft(0, 24), soft(0, 352)]
    }
}
