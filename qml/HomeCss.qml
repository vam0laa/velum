import QtQuick

// The style sheet you can write for the home page: a small part of CSS, read here.
// Only the names below exist; nothing in it can reach the network or run.
QtObject {
    readonly property var selectors: ["page", "headline", "pill", "chip", "search", "tile", "clock", "widget", "date", "calendar", "shield", "note", "tasks", "timer"]
    readonly property var properties: ["background", "background-color", "color", "border-color", "border-width", "border-radius", "opacity", "font-size", "font-weight", "font-family", "display"]
    readonly property var names: ["transparent", "black", "white", "red", "green", "blue", "yellow", "orange", "purple", "pink", "gray", "grey", "teal", "cyan", "magenta", "navy", "olive", "maroon", "lime", "silver", "gold", "crimson", "coral", "salmon", "violet", "indigo", "turquoise", "tomato", "orchid", "plum", "khaki", "beige", "ivory", "lavender", "skyblue", "steelblue", "hotpink", "darkblue", "darkred", "darkgreen", "lightgray", "lightblue", "lightgreen"]

    // "#rgb", "#rrggbb", "#rrggbbaa", "rgb(...)", "rgba(...)" or a known name, as Qt writes it; "" if not
    function color(text) {
        const v = String(text).trim().toLowerCase()
        if (names.includes(v))
            return v
        if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(v))
            return v
        if (/^#[0-9a-f]{8}$/.test(v))
            return "#" + v.slice(7) + v.slice(1, 7)        // Qt puts the transparency first
        const m = v.match(/^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*([01]?\.?\d+)\s*)?\)$/)
        if (!m || [m[1], m[2], m[3]].some(n => Number(n) > 255))
            return ""
        const hex = n => ("0" + Math.round(n).toString(16)).slice(-2)
        const alpha = m[4] === undefined ? 1 : Math.max(0, Math.min(1, Number(m[4])))
        return "#" + hex(alpha * 255) + hex(Number(m[1])) + hex(Number(m[2])) + hex(Number(m[3]))
    }

    // the value of one declaration, in the form the page uses; undefined if it makes no sense
    function value(property, text) {
        const v = String(text).trim()
        if (property === "color" || property === "border-color" || property === "background" || property === "background-color") {
            const c = color(v)
            return c === "" ? undefined : c
        }
        if (property === "display")
            return v === "none" || v === "block" ? v : undefined
        if (property === "font-family") {
            const family = v.replace(/^["']|["']$/g, "")
            return /^[\w \-]{1,60}$/.test(family) ? family : undefined
        }
        if (property === "font-weight") {
            const w = v === "bold" ? 700 : v === "normal" ? 400 : Number(v)
            return w >= 100 && w <= 900 ? w : undefined
        }
        if (property === "opacity") {
            const o = Number(v)
            return v !== "" && o >= 0 && o <= 1 ? o : undefined
        }
        const m = v.match(/^(\d{1,3}(?:\.\d+)?)(px)?$/)
        if (!m)
            return undefined
        const n = Number(m[1])
        const limits = { "font-size": [6, 320], "border-width": [0, 40], "border-radius": [0, 400] }[property]
        return limits && n >= limits[0] && n <= limits[1] ? n : undefined
    }

    // { sheet: { selector: { property: value } }, errors: [text] }
    function parse(source) {
        const sheet = {}, errors = []
        const text = String(source).slice(0, 20000).replace(/\/\*[\s\S]*?(\*\/|$)/g, "")
        const rule = /([^{}]+)\{([^{}]*)\}/g
        let m, end = 0
        while ((m = rule.exec(text)) !== null) {
            end = rule.lastIndex
            const found = []
            for (const raw of m[1].split(",")) {
                const name = raw.trim().replace(/^\./, "")
                if (selectors.includes(name))
                    found.push(name)
                else if (name !== "")
                    errors.push(Lang.t("Bilinmeyen seçici: ", "Unknown selector: ") + raw.trim().slice(0, 40))
            }
            for (const line of m[2].split(";")) {
                if (line.trim() === "")
                    continue
                const colon = line.indexOf(":")
                const property = line.slice(0, colon).trim().toLowerCase()
                if (colon < 0 || !properties.includes(property)) {
                    errors.push(Lang.t("Bilinmeyen özellik: ", "Unknown property: ") + (colon < 0 ? line : property).trim().slice(0, 40))
                    continue
                }
                const v = value(property, line.slice(colon + 1))
                if (v === undefined) {
                    errors.push(Lang.t("Anlaşılmayan değer: ", "Value not understood: ") + line.trim().slice(0, 60))
                    continue
                }
                const key = property === "background-color" ? "background" : property
                for (const name of found) {
                    sheet[name] = sheet[name] ?? {}
                    sheet[name][key] = v
                }
            }
        }
        if (text.slice(end).trim() !== "")
            errors.push(Lang.t("Kapanmamış ya da eksik kural: ", "A rule is not closed: ") + text.slice(end).trim().slice(0, 40))
        return { sheet: sheet, errors: errors.slice(0, 12) }
    }
}
