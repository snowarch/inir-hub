.pragma library

// Each page's graph (Technical Minimalism, his 11-17): what the page changes, drawn as a plate of a technical
// drawing in thin lines, with its subject in the person's accent, a dimension or two and mono callouts. It explains;
// it is never a control. Units: x and y from 0 to 1 across a 16:10 plate; a circle's radius in plate widths.
// Styles: "line" (the drawing), "faint" (what is around it), "mark" (the subject), "fill" (a quiet face),
// "markfill" (the subject's face), "dash" (a place, not a thing).

// The desktop on a screen: the monitor, its glass, and the parts of the shell, each lit when named in `lit`.
function desk(lit, opts) {
    const on = part => lit.indexOf(part) >= 0
    const o = opts || {}
    const out = [
        ["rect", 0.14, 0.04, 0.72, 0.68, 9, "line"],
        ["rect", 0.155, 0.065, 0.69, 0.63, 5, "faint"],
        ["line", 0.475, 0.72, 0.46, 0.84, "line"],
        ["line", 0.525, 0.72, 0.54, 0.84, "line"],
        ["rect", 0.38, 0.84, 0.24, 0.035, 4, "line"]
    ]
    const part = (name, item) => { item[item.length - 1] = on(name) ? "markfill" : (o.hide && o.hide.indexOf(name) >= 0 ? null : "faint"); if (item[item.length - 1]) out.push(item) }
    part("island", ["rect", 0.44, 0.095, 0.12, 0.045, 99, ""])
    part("dock", ["rect", 0.38, 0.6, 0.24, 0.055, 99, ""])
    part("widgets", ["rect", 0.19, 0.17, 0.11, 0.15, 5, ""])
    part("widgets2", ["rect", 0.19, 0.35, 0.11, 0.09, 5, ""])
    part("panel", ["rect", 0.69, 0.11, 0.13, 0.46, 6, ""])
    part("leftPanel", ["rect", 0.18, 0.11, 0.13, 0.46, 6, ""])
    part("control", ["rect", 0.64, 0.11, 0.18, 0.24, 6, ""])
    part("bubble", ["circle", 0.8, 0.5, 0.022, ""])
    part("bubble2", ["circle", 0.75, 0.56, 0.014, ""])
    part("search", ["rect", 0.33, 0.24, 0.34, 0.06, 99, ""])
    return out.map(fit)
}

// The desktop alone, no monitor round it (his 11-17: the monitor is Display's own): one quiet frame, the parts lit.
function screen(lit, opts) {
    return desk(lit, opts).slice(5).concat([fit(["rect", 0.12, 0.04, 0.76, 0.78, 10, "faint"])])
}

// The desk is drawn a size smaller so callouts have room round it: a point of it, and every item of it, moved there.
const K = 0.72
function dx(x) { return 0.5 + (x - 0.5) * K }
function dy(y) { return 0.04 + y * K }
function fit(it) {
    const o = it.slice()
    if (o[0] === "rect") { o[1] = dx(o[1]); o[2] = dy(o[2]); o[3] *= K; o[4] *= K }
    else if (o[0] === "line") { o[1] = dx(o[1]); o[2] = dy(o[2]); o[3] = dx(o[3]); o[4] = dy(o[4]) }
    else if (o[0] === "circle") { o[1] = dx(o[1]); o[2] = dy(o[2]); o[3] *= K }
    return o
}

function axes() {
    return [
        ["line", 0.12, 0.84, 0.88, 0.84, "line"],
        ["line", 0.12, 0.84, 0.12, 0.1, "line"],
        ["ticks", 0.12, 0.84, 0.88, 10, "faint"],
        ["line", 0.12, 0.2, 0.88, 0.2, "dash"]
    ]
}

const figures = {
    general: v => ({
        code: v.family || "IRIS",
        note: "YOUR DESKTOP",
        items: screen(["island", "dock", "widgets", "bubble"], {}).concat([
            ["call", dx(0.56), dy(0.117), 0.8, 0.06, "ISLAND"],
            ["call", dx(0.8), dy(0.5), 0.8, 0.34, "BUBBLES"],
            ["call", dx(0.62), dy(0.627), 0.8, 0.6, "DOCK"],
            ["call", dx(0.19), dy(0.245), 0.2, 0.34, "WIDGETS"]
        ])
    }),
    appearance: v => ({
        code: "LOOK",
        note: "TYPE · COLOUR · SHAPE",
        items: [
            ["big", 0.12, 0.62, "Aa", "left"],
            ["line", 0.12, 0.64, 0.5, 0.64, "faint"],
            ["line", 0.12, 0.3, 0.5, 0.3, "dash"],
            ["dim", 0.54, 0.3, 0.54, 0.64, "CAP"],
            ["circle", 0.66, 0.36, 0.035, "markfill"],
            ["circle", 0.75, 0.36, 0.035, "line"],
            ["circle", 0.84, 0.36, 0.035, "faint"],
            ["rect", 0.62, 0.52, 0.26, 0.09, 99, "line"],
            ["rect", 0.625, 0.535, 0.1, 0.06, 99, "markfill"],
            ["text", 0.62, 0.74, "ACCENT · KEY · RADIUS", "left", "faint"]
        ]
    }),
    colour: v => {
        const items = []
        for (let i = 0; i < 12; ++i) {
            const a0 = i * 30 + 2, a1 = i * 30 + 28
            items.push(["arc", 0.36, 0.46, 0.17, a0, a1, i === 0 ? "mark" : "line"])
            items.push(["arc", 0.36, 0.46, 0.13, a0, a1, "faint"])
        }
        items.push(["dot", 0.36, 0.46, "line"])
        items.push(["call", 0.53, 0.46, 0.66, 0.3, "ACCENT"])
        items.push(["line", 0.66, 0.5, 0.9, 0.5, "faint"])
        items.push(["rect", 0.66, 0.56, 0.06, 0.1, 3, "markfill"])
        items.push(["rect", 0.74, 0.56, 0.06, 0.1, 3, "line"])
        items.push(["rect", 0.82, 0.56, 0.06, 0.1, 3, "faint"])
        return { code: "OKLCH", note: "HUE · CHROMA · LIGHT", items: items }
    },
    surfaces: v => ({
        code: "LAYERS",
        note: "CANVAS · PANEL · CARD",
        items: [
            ["rect", 0.16, 0.12, 0.46, 0.56, 10, "faint"],
            ["rect", 0.26, 0.22, 0.46, 0.56, 10, "line"],
            ["rect", 0.36, 0.32, 0.46, 0.5, 10, "markfill"],
            ["call", 0.18, 0.14, 0.08, 0.06, "CANVAS"],
            ["call", 0.72, 0.4, 0.9, 0.3, "PANEL"],
            ["call", 0.6, 0.82, 0.9, 0.9, "CARD"]
        ]
    }),
    typeIcons: v => ({
        code: "TYPE",
        note: "SIZE · WEIGHT · ICONS",
        items: [
            ["big", 0.1, 0.62, "Ag", "left"],
            ["line", 0.08, 0.62, 0.52, 0.62, "line"],
            ["line", 0.08, 0.4, 0.52, 0.4, "dash"],
            ["line", 0.08, 0.26, 0.52, 0.26, "dash"],
            ["dim", 0.54, 0.4, 0.54, 0.62, "X"],
            ["dim", 0.6, 0.26, 0.6, 0.62, "CAP"],
            ["rect", 0.7, 0.26, 0.08, 0.13, 3, "markfill"],
            ["rect", 0.8, 0.26, 0.08, 0.13, 3, "line"],
            ["rect", 0.7, 0.44, 0.08, 0.13, 3, "line"],
            ["rect", 0.8, 0.44, 0.08, 0.13, 3, "faint"],
            ["text", 0.7, 0.72, "ICON GRID", "left", "faint"]
        ]
    }),
    appColours: v => ({
        code: "GTK · QT",
        note: "APPS WEAR THE THEME",
        items: [
            ["rect", 0.14, 0.12, 0.5, 0.62, 8, "line"],
            ["line", 0.14, 0.22, 0.64, 0.22, "line"],
            ["circle", 0.17, 0.17, 0.008, "faint"],
            ["circle", 0.195, 0.17, 0.008, "faint"],
            ["rect", 0.18, 0.28, 0.14, 0.4, 4, "faint"],
            ["rect", 0.36, 0.28, 0.24, 0.06, 3, "markfill"],
            ["line", 0.36, 0.42, 0.58, 0.42, "faint"],
            ["line", 0.36, 0.48, 0.54, 0.48, "faint"],
            ["line", 0.36, 0.54, 0.56, 0.54, "faint"],
            ["rect", 0.72, 0.2, 0.06, 0.1, 3, "markfill"],
            ["rect", 0.72, 0.34, 0.06, 0.1, 3, "line"],
            ["rect", 0.72, 0.48, 0.06, 0.1, 3, "faint"],
            ["call", 0.78, 0.25, 0.9, 0.18, "ACCENT"]
        ]
    }),
    wallpaper: v => ({
        code: "16:9",
        note: "THE PICTURE BEHIND IT ALL",
        items: [
            ["crop", 0.14, 0.1, 0.72, 0.66, "line"],
            ["rect", 0.17, 0.14, 0.66, 0.58, 6, "faint"],
            ["poly", [[0.17, 0.6], [0.32, 0.4], [0.42, 0.52], [0.56, 0.32], [0.83, 0.62]], "line", false],
            ["circle", 0.7, 0.28, 0.035, "markfill"],
            ["dim", 0.17, 0.82, 0.83, 0.82, "WIDTH"],
            ["call", 0.7, 0.28, 0.9, 0.16, "LIGHT"]
        ]
    }),
    motion: v => ({
        code: "EASE",
        note: "TIME → DISTANCE",
        items: axes().concat([
            ["curve", 0.12, 0.84, 0.36, 0.84, 0.44, 0.2, 0.88, 0.2, "mark"],
            ["dot", 0.12, 0.84, "mark"],
            ["dot", 0.88, 0.2, "mark"],
            ["text", 0.88, 0.92, "T", "right", "faint"],
            ["text", 0.08, 0.12, "X", "left", "faint"],
            ["call", 0.4, 0.5, 0.56, 0.58, "SPRING"]
        ])
    }),
    movement: v => ({
        code: "NIRI",
        note: "HOW WINDOWS TRAVEL",
        items: axes().concat([
            ["curve", 0.12, 0.84, 0.3, 0.2, 0.5, 0.12, 0.88, 0.2, "mark"],
            ["line", 0.5, 0.84, 0.5, 0.16, "dash"],
            ["text", 0.5, 0.92, "OVERSHOOT", "center", "faint"],
            ["dot", 0.88, 0.2, "mark"],
            ["text", 0.88, 0.92, "T", "right", "faint"]
        ])
    }),
    bar: v => ({
        code: v.island || "ISLAND",
        note: "TOP CENTRE OF EVERY SCREEN",
        items: [
            ["rect", 0.06, 0.18, 0.88, 0.62, 10, "faint"],
            ["line", 0.06, 0.3, 0.94, 0.3, "dash"],
            ["rect", 0.34, 0.24, 0.32, 0.13, 99, "markfill"],
            ["circle", 0.4, 0.305, 0.018, "line"],
            ["line", 0.45, 0.305, 0.58, 0.305, "line"],
            ["dim", 0.34, 0.47, 0.66, 0.47, "WIDTH"],
            ["dim", 0.7, 0.24, 0.7, 0.37, "H"],
            ["call", 0.66, 0.27, 0.82, 0.14, "ISLAND"]
        ]
    }),
    dock: v => ({
        code: "DOCK",
        note: "PINNED AND OPEN APPS",
        items: [
            ["rect", 0.06, 0.08, 0.88, 0.7, 10, "faint"],
            ["rect", 0.22, 0.56, 0.56, 0.14, 99, "markfill"],
            ["rect", 0.26, 0.59, 0.07, 0.08, 4, "line"],
            ["rect", 0.35, 0.59, 0.07, 0.08, 4, "line"],
            ["rect", 0.44, 0.59, 0.07, 0.08, 4, "line"],
            ["rect", 0.53, 0.59, 0.07, 0.08, 4, "line"],
            ["line", 0.62, 0.59, 0.62, 0.67, "faint"],
            ["rect", 0.65, 0.59, 0.07, 0.08, 4, "faint"],
            ["dot", 0.295, 0.69, "mark"],
            ["dot", 0.385, 0.69, "mark"],
            ["dim", 0.22, 0.84, 0.78, 0.84, "LENGTH"],
            ["call", 0.62, 0.59, 0.8, 0.4, "DIVIDER"]
        ]
    }),
    // The Island seen close, its bubbles beside it, one opening its card.
    bubbles: v => ({
        code: "BUBBLES",
        note: "BESIDE THE ISLAND",
        items: [
            ["line", 0.04, 0.14, 0.96, 0.14, "dash"],
            ["rect", 0.36, 0.2, 0.28, 0.12, 99, "line"],
            ["circle", 0.42, 0.26, 0.014, "faint"],
            ["line", 0.46, 0.26, 0.58, 0.26, "faint"],
            ["circle", 0.29, 0.26, 0.038, "line"],
            ["circle", 0.71, 0.26, 0.038, "markfill"],
            ["circle", 0.8, 0.26, 0.026, "line"],
            ["rect", 0.55, 0.42, 0.32, 0.34, 8, "dash"],
            ["line", 0.71, 0.32, 0.71, 0.42, "faint"],
            ["dim", 0.64, 0.4, 0.67, 0.4, ""],
            ["call", 0.29, 0.26, 0.14, 0.44, "ACTIVITY"],
            ["call", 0.71, 0.22, 0.62, 0.07, "TRAILING"],
            ["call", 0.8, 0.235, 0.84, 0.07, "UTILITY"],
            ["text", 0.71, 0.84, "CARD", "center", "faint"]
        ]
    }),
    // What sits on the wallpaper: a clock face, a card of lines, the grid they snap to.
    desktop: v => ({
        code: "DESKTOP",
        note: "WHAT SITS ON THE WALLPAPER",
        items: [
            ["poly", [[0.06, 0.78], [0.24, 0.56], [0.36, 0.66], [0.54, 0.44], [0.72, 0.6], [0.94, 0.4]], "faint", false],
            ["rect", 0.1, 0.12, 0.17, 0.17, 6, "dash"],
            ["rect", 0.3, 0.12, 0.17, 0.17, 6, "dash"],
            ["rect", 0.1, 0.32, 0.17, 0.17, 6, "dash"],
            ["circle", 0.185, 0.205, 0.06, "markfill"],
            ["line", 0.185, 0.205, 0.185, 0.15, "line"],
            ["line", 0.185, 0.205, 0.22, 0.225, "line"],
            ["rect", 0.3, 0.32, 0.36, 0.17, 6, "line"],
            ["line", 0.33, 0.37, 0.52, 0.37, "faint"],
            ["line", 0.33, 0.42, 0.6, 0.42, "faint"],
            ["dim", 0.3, 0.06, 0.47, 0.06, ""],
            ["call", 0.245, 0.17, 0.62, 0.14, "WIDGET"],
            ["call", 0.27, 0.4, 0.14, 0.62, "SNAP"]
        ]
    }),
    widgets: v => ({
        code: "GRID",
        note: "S · M · L",
        items: [
            ["rect", 0.12, 0.12, 0.22, 0.3, 8, "markfill"],
            ["rect", 0.37, 0.12, 0.22, 0.3, 8, "line"],
            ["rect", 0.62, 0.12, 0.26, 0.3, 8, "line"],
            ["rect", 0.12, 0.46, 0.47, 0.3, 8, "line"],
            ["rect", 0.62, 0.46, 0.26, 0.3, 8, "dash"],
            ["line", 0.73, 0.61, 0.77, 0.61, "faint"],
            ["line", 0.75, 0.59, 0.75, 0.63, "faint"],
            ["text", 0.12, 0.86, "S", "left", "faint"],
            ["text", 0.37, 0.86, "M", "left", "faint"],
            ["text", 0.62, 0.86, "L", "left", "faint"]
        ]
    }),
    display: v => ({
        code: v.output || "SCREEN",
        note: v.mode || "THE PICTURE",
        items: desk([], { hide: ["widgets2", "panel", "leftPanel", "control", "bubble", "bubble2", "search"] }).concat([
            fit(["rect", 0.155, 0.065, 0.69, 0.63, 5, "mark"]),
            ["dim", dx(0.14), 0.8, dx(0.86), 0.8, v.width || "W"],
            ["dim", dx(0.92), dy(0.04), dx(0.92), dy(0.72), v.height || "H"]
        ])
    }),
    layout: v => ({
        code: "COLUMNS",
        note: "A STRIP THAT SCROLLS",
        items: [
            ["rect", 0.04, 0.16, 0.18, 0.56, 6, "faint"],
            ["rect", 0.26, 0.16, 0.24, 0.56, 6, "markfill"],
            ["rect", 0.54, 0.16, 0.2, 0.26, 6, "line"],
            ["rect", 0.54, 0.46, 0.2, 0.26, 6, "line"],
            ["rect", 0.78, 0.16, 0.2, 0.56, 6, "faint"],
            ["line", 0.22, 0.04, 0.78, 0.04, "dash"],
            ["dim", 0.5, 0.82, 0.54, 0.82, "GAP"],
            ["call", 0.38, 0.72, 0.3, 0.9, "FOCUS"]
        ]
    }),
    windows: v => ({
        code: "WINDOWS",
        note: "BORDERS · SHADOWS · CORNERS",
        items: [
            ["rect", 0.12, 0.14, 0.44, 0.48, 8, "faint"],
            ["line", 0.12, 0.22, 0.56, 0.22, "faint"],
            ["rect", 0.34, 0.3, 0.5, 0.5, 8, "markfill"],
            ["line", 0.34, 0.38, 0.84, 0.38, "line"],
            ["circle", 0.37, 0.34, 0.008, "line"],
            ["circle", 0.395, 0.34, 0.008, "line"],
            ["arc", 0.84, 0.8, 0.04, 0, 90, "line"],
            ["call", 0.84, 0.76, 0.94, 0.9, "RADIUS"],
            ["call", 0.34, 0.6, 0.18, 0.76, "FOCUSED"]
        ]
    }),
    glass: v => ({
        code: "BLUR",
        note: "WHAT SHOWS THROUGH",
        items: [
            ["poly", [[0.1, 0.7], [0.3, 0.4], [0.45, 0.55], [0.62, 0.3], [0.9, 0.7]], "faint", false],
            ["rect", 0.2, 0.18, 0.5, 0.5, 10, "line"],
            ["rect", 0.3, 0.26, 0.5, 0.5, 10, "markfill"],
            ["dim", 0.3, 0.84, 0.8, 0.84, "RADIUS"],
            ["call", 0.8, 0.4, 0.94, 0.26, "GLASS"]
        ]
    }),
    pointer: v => ({
        code: "POINTER",
        note: "SPEED · ACCELERATION",
        items: [
            ["dot", 0.16, 0.7, "faint"],
            ["dot", 0.24, 0.63, "faint"],
            ["dot", 0.33, 0.56, "line"],
            ["dot", 0.43, 0.48, "line"],
            ["poly", [[0.55, 0.22], [0.55, 0.6], [0.63, 0.52], [0.69, 0.65], [0.73, 0.63], [0.67, 0.5], [0.78, 0.5]], "markfill", true],
            ["dim", 0.16, 0.84, 0.55, 0.84, "SPEED"],
            ["call", 0.55, 0.22, 0.4, 0.14, "HOTSPOT"]
        ]
    }),
    // A panel hugging each edge, the right one open, its width and its sections.
    sidebars: v => ({
        code: "PANELS",
        note: "LEFT AND RIGHT",
        items: [
            ["line", 0.04, 0.08, 0.04, 0.84, "dash"],
            ["line", 0.96, 0.08, 0.96, 0.84, "dash"],
            ["rect", 0.07, 0.12, 0.2, 0.64, 8, "line"],
            ["rect", 0.62, 0.12, 0.31, 0.64, 8, "markfill"],
            ["rect", 0.65, 0.16, 0.25, 0.14, 5, "line"],
            ["rect", 0.65, 0.34, 0.25, 0.2, 5, "line"],
            ["line", 0.67, 0.6, 0.86, 0.6, "faint"],
            ["line", 0.67, 0.66, 0.8, 0.66, "faint"],
            ["line", 0.1, 0.2, 0.22, 0.2, "faint"],
            ["line", 0.1, 0.26, 0.19, 0.26, "faint"],
            ["dim", 0.62, 0.84, 0.93, 0.84, "WIDTH"],
            ["call", 0.27, 0.44, 0.42, 0.3, "LEFT"],
            ["call", 0.62, 0.44, 0.48, 0.58, "RIGHT"]
        ]
    }),
    controlCenter: v => ({
        code: "CONTROLS",
        note: "THE QUICK TOGGLES",
        items: [
            ["rect", 0.22, 0.08, 0.56, 0.76, 12, "line"],
            ["rect", 0.27, 0.14, 0.21, 0.13, 99, "markfill"],
            ["rect", 0.52, 0.14, 0.21, 0.13, 99, "line"],
            ["rect", 0.27, 0.31, 0.21, 0.13, 99, "line"],
            ["rect", 0.52, 0.31, 0.21, 0.13, 99, "faint"],
            ["rect", 0.27, 0.5, 0.46, 0.07, 99, "line"],
            ["rect", 0.27, 0.5, 0.28, 0.07, 99, "fill"],
            ["rect", 0.27, 0.62, 0.46, 0.07, 99, "line"],
            ["call", 0.48, 0.2, 0.88, 0.14, "TOGGLE"],
            ["call", 0.73, 0.535, 0.88, 0.6, "LEVEL"]
        ]
    }),
    spotlight: v => ({
        code: "SEARCH",
        note: "TYPE TO FIND ANYTHING",
        items: [
            ["rect", 0.16, 0.14, 0.68, 0.11, 99, "markfill"],
            ["circle", 0.21, 0.195, 0.014, "line"],
            ["line", 0.24, 0.195, 0.4, 0.195, "line"],
            ["rect", 0.16, 0.3, 0.68, 0.44, 10, "line"],
            ["line", 0.2, 0.4, 0.6, 0.4, "faint"],
            ["line", 0.2, 0.5, 0.7, 0.5, "faint"],
            ["line", 0.2, 0.6, 0.5, 0.6, "faint"],
            ["call", 0.84, 0.19, 0.94, 0.08, "QUERY"]
        ]
    }),
    orbit: v => {
        const items = [["circle", 0.5, 0.46, 0.17, "line"], ["circle", 0.5, 0.46, 0.035, "markfill"]]
        for (let i = 0; i < 8; ++i) {
            const a = i * Math.PI / 4
            items.push(["circle", 0.5 + Math.cos(a) * 0.17, 0.46 + Math.sin(a) * 0.272, 0.022, i === 0 ? "markfill" : "line"])
        }
        items.push(["call", 0.67, 0.46, 0.88, 0.3, "APP"])
        return { code: "ORBIT", note: "APPS ROUND A CENTRE", items: items }
    },
    capture: v => ({
        code: "REC",
        note: "A REGION, A SHOT, A FILM",
        items: [
            ["rect", 0.06, 0.06, 0.88, 0.76, 10, "faint"],
            ["crop", 0.24, 0.2, 0.46, 0.44, "mark"],
            ["rect", 0.24, 0.2, 0.46, 0.44, 0, "dash"],
            ["circle", 0.82, 0.16, 0.02, "markfill"],
            ["dim", 0.24, 0.72, 0.7, 0.72, "REGION"],
            ["call", 0.7, 0.2, 0.86, 0.3, "CROP"]
        ]
    }),
    player: v => {
        const items = [["circle", 0.28, 0.46, 0.15, "line"], ["circle", 0.28, 0.46, 0.04, "line"], ["arc", 0.28, 0.46, 0.18, -90, 60, "mark"]]
        const bars = [0.3, 0.55, 0.42, 0.8, 0.62, 0.36, 0.7, 0.5, 0.88, 0.4, 0.6, 0.3, 0.5]
        bars.forEach((h, i) => items.push(["line", 0.54 + i * 0.03, 0.62, 0.54 + i * 0.03, 0.62 - h * 0.3, i < 5 ? "mark" : "line"]))
        items.push(["line", 0.54, 0.7, 0.9, 0.7, "faint"])
        items.push(["dot", 0.66, 0.7, "mark"])
        return { code: "NOW PLAYING", note: "COVER · LEVELS · TIME", items: items }
    },
    anime: v => ({
        code: "ANIME",
        note: "WHAT YOU WATCH",
        items: [
            ["rect", 0.1, 0.12, 0.5, 0.56, 8, "line"],
            ["poly", [[0.31, 0.3], [0.31, 0.5], [0.42, 0.4]], "markfill", true],
            ["line", 0.1, 0.76, 0.6, 0.76, "faint"],
            ["line", 0.1, 0.76, 0.32, 0.76, "mark"],
            ["rect", 0.66, 0.12, 0.24, 0.16, 6, "line"],
            ["rect", 0.66, 0.32, 0.24, 0.16, 6, "faint"],
            ["rect", 0.66, 0.52, 0.24, 0.16, 6, "faint"],
            ["text", 0.66, 0.78, "NEXT EPISODE", "left", "faint"]
        ]
    }),
    // Banners dropping out of the Island, the newest in front, the older ones stacked behind it, and its time.
    notifications: v => ({
        code: "NOTIFY",
        note: "OUT OF THE ISLAND",
        items: [
            ["line", 0.04, 0.12, 0.96, 0.12, "dash"],
            ["rect", 0.4, 0.16, 0.2, 0.09, 99, "line"],
            ["rect", 0.32, 0.56, 0.36, 0.12, 8, "faint"],
            ["rect", 0.29, 0.45, 0.42, 0.13, 9, "line"],
            ["rect", 0.26, 0.31, 0.48, 0.16, 10, "markfill"],
            ["circle", 0.31, 0.39, 0.02, "line"],
            ["line", 0.35, 0.36, 0.6, 0.36, "line"],
            ["line", 0.35, 0.42, 0.52, 0.42, "faint"],
            ["arc", 0.8, 0.39, 0.05, -90, 150, "mark"],
            ["arc", 0.8, 0.39, 0.05, 150, 270, "faint"],
            ["line", 0.5, 0.25, 0.5, 0.31, "faint"],
            ["call", 0.74, 0.33, 0.9, 0.18, "NEWEST"],
            ["text", 0.8, 0.56, "TIME", "center", "faint"]
        ]
    }),
    sound: v => {
        const items = [["poly", [[0.12, 0.38], [0.18, 0.38], [0.27, 0.28], [0.27, 0.64], [0.18, 0.54], [0.12, 0.54]], "line", true],
            ["arc", 0.27, 0.46, 0.06, -45, 45, "mark"], ["arc", 0.27, 0.46, 0.1, -45, 45, "line"], ["arc", 0.27, 0.46, 0.14, -45, 45, "faint"]]
        const pts = []
        for (let i = 0; i <= 40; ++i) pts.push([0.5 + i * 0.0105, 0.46 + Math.sin(i * 0.9) * 0.16 * Math.exp(-Math.abs(i - 20) / 14)])
        items.push(["poly", pts, "mark", false])
        items.push(["line", 0.5, 0.2, 0.92, 0.2, "dash"])
        items.push(["text", 0.92, 0.16, "MAX", "right", "faint"])
        return { code: "AUDIO", note: "LEVEL · LIMIT · DEVICE", items: items }
    },
    battery: v => ({
        code: v.battery || "POWER",
        note: "CHARGE AND ITS LIMITS",
        items: [
            ["rect", 0.18, 0.28, 0.58, 0.34, 8, "line"],
            ["rect", 0.77, 0.38, 0.04, 0.14, 2, "line"],
            ["rect", 0.2, 0.31, 0.38, 0.28, 5, "markfill"],
            ["line", 0.3, 0.24, 0.3, 0.66, "dash"],
            ["text", 0.3, 0.76, "LOW", "center", "faint"],
            ["line", 0.24, 0.24, 0.24, 0.66, "dash"],
            ["dim", 0.18, 0.84, 0.76, 0.84, "100%"]
        ]
    }),
    gaming: v => ({
        code: "GAME",
        note: "FULL SCREEN, NOTHING IN THE WAY",
        items: [
            ["arc", 0.5, 0.62, 0.28, 180, 360, "line"],
            ["arc", 0.5, 0.62, 0.28, 180, 290, "mark"],
            ["ticks", 0.22, 0.62, 0.78, 8, "faint"],
            ["line", 0.5, 0.62, 0.62, 0.3, "mark"],
            ["dot", 0.5, 0.62, "mark"],
            ["text", 0.5, 0.8, "FRAMES", "center", "faint"]
        ]
    }),
    lock: v => ({
        code: "LOCK",
        note: "WHAT THE LOCKED SCREEN SHOWS",
        items: [
            ["rect", 0.14, 0.06, 0.72, 0.76, 10, "faint"],
            ["big", 0.5, 0.42, v.time || "12:00", "center"],
            ["rect", 0.42, 0.56, 0.16, 0.12, 4, "line"],
            ["arc", 0.5, 0.56, 0.05, 180, 360, "mark"],
            ["call", 0.55, 0.5, 0.74, 0.62, "SHACKLE"]
        ]
    }),
    login: v => ({
        code: "LOGIN",
        note: "BEFORE THE SESSION",
        items: [
            ["circle", 0.5, 0.3, 0.06, "line"],
            ["rect", 0.32, 0.5, 0.36, 0.09, 99, "markfill"],
            ["circle", 0.62, 0.545, 0.012, "line"],
            ["line", 0.34, 0.68, 0.66, 0.68, "faint"],
            ["call", 0.32, 0.545, 0.14, 0.7, "PASSWORD"]
        ]
    }),
    sources: v => ({
        code: "SYNC",
        note: "WEATHER · CALENDAR · ACCOUNTS",
        items: [
            ["circle", 0.26, 0.44, 0.08, "line"],
            ["circle", 0.74, 0.44, 0.08, "markfill"],
            ["curve", 0.34, 0.36, 0.44, 0.24, 0.56, 0.24, 0.66, 0.36, "line"],
            ["curve", 0.66, 0.52, 0.56, 0.64, 0.44, 0.64, 0.34, 0.52, "faint"],
            ["text", 0.26, 0.74, "SOURCE", "center", "faint"],
            ["text", 0.74, 0.74, "IRIS", "center", "faint"]
        ]
    }),
    fallback: v => ({
        code: "IRIS",
        note: "",
        items: screen(["island"], {})
    })
}

// { items, code (top right), note (bottom left) } for a page; v carries a few live values the page knows.
function of(id, v) {
    const key = String(id || "").split(/[:.\-]/)[0]
    const f = figures[key] || figures.fallback
    return f(v || {})
}
