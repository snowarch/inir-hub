.pragma library

// Each page's object in its art (`.claude/ref/language/letter-holo.png`): the thing the page sets, drawn in lines of
// light, a part per group where the page has one. Units: y runs 0 to 1 down the object, x 0 to `aspect` across it, so a
// circle stays round. A part names its group (`g`); its pin sits at `pin`, else its middle. Kinds: box (x, y, w, h, r:
// 0 square to 1 round ends), circle (cx, cy, d), line (pts, closed), arc (cx, cy, d, from, to: degrees, 0 at the right,
// clockwise), curve (a cubic: 4 points). `two` draws a box as two rails, `fill` fills it quietly, `faint` steps it
// back, `lit` draws it in the accent. A part with no group of its own belongs to the one before it.

function B(x, y, w, h, r, g, o) { return Object.assign({ k: "box", x: x, y: y, w: w, h: h, r: r, g: g || "" }, o || {}) }
function C(cx, cy, d, g, o) { return Object.assign({ k: "circle", cx: cx, cy: cy, d: d, g: g || "" }, o || {}) }
function L(pts, g, o) { return Object.assign({ k: "line", pts: pts, g: g || "" }, o || {}) }
function A(cx, cy, d, from, to, g, o) { return Object.assign({ k: "arc", cx: cx, cy: cy, d: d, from: from, to: to, g: g || "" }, o || {}) }
function Q(pts, g, o) { return Object.assign({ k: "curve", pts: pts, g: g || "" }, o || {}) }

function wave(x0, x1, y, amp, n) {
    const pts = []
    for (let i = 0; i <= n; i++) pts.push([x0 + (x1 - x0) * i / n, y + amp * Math.sin(i / n * Math.PI * 4)])
    return pts
}
function corners(x, y, w, h, s) {
    return [L([[x, y + s], [x, y], [x + s, y]]), L([[x + w - s, y], [x + w, y], [x + w, y + s]]),
        L([[x + w, y + h - s], [x + w, y + h], [x + w - s, y + h]]), L([[x + s, y + h], [x, y + h], [x, y + h - s]])]
}

const objects = {
    // The machine: a laptop, its screen the shell, the time, the apps, the Settings window on it.
    general: { aspect: 1.6, parts: [
        B(0.36, 0.1, 0.88, 0.58, 0.08, "Shell", { two: true }),
        L([[0.24, 0.72], [1.36, 0.72], [1.46, 0.82], [0.14, 0.82]], "Every day", { closed: true, pin: [0.8, 0.77] }),
        C(0.6, 0.38, 0.22, "Language & time"), L([[0.6, 0.38], [0.6, 0.31], [0.65, 0.38]]),
        B(0.82, 0.2, 0.08, 0.08, 0.4, "Apps & login"), B(0.82, 0.31, 0.08, 0.08, 0.4), B(0.82, 0.42, 0.08, 0.08, 0.4),
        B(0.97, 0.2, 0.2, 0.38, 0.14, "Settings window"), L([[1.0, 0.27], [1.14, 0.27]]), L([[1.0, 0.33], [1.1, 0.33]])
    ] },
    // Style: the presets stacked at the left, a window as the Design draws it, the knob that customizes it.
    appearance: { aspect: 1.6, parts: [
        B(0.12, 0.16, 0.34, 0.2, 0.22, "Presets", { fill: true }), B(0.12, 0.4, 0.34, 0.2, 0.22), B(0.12, 0.64, 0.34, 0.2, 0.22, "", { faint: true }),
        B(0.56, 0.1, 0.92, 0.8, 0.1, "Design", { two: true, pin: [1.02, 0.5] }),
        C(0.65, 0.19, 0.03), C(0.7, 0.19, 0.03), C(0.75, 0.19, 0.03), L([[0.56, 0.27], [1.48, 0.27]]),
        L([[0.66, 0.4], [1.1, 0.4]]), L([[0.66, 0.48], [1.0, 0.48]]), L([[0.66, 0.56], [1.06, 0.56]]),
        L([[0.66, 0.76], [1.38, 0.76]], "Customize", { pin: [1.16, 0.76] }), C(1.16, 0.76, 0.06, "", { fill: true })
    ] },
    // Colour: the scheme's half moon, the accent, the theme's swatches, the wallpaper's tint, the dark, light and ink looks.
    colour: { aspect: 1.6, parts: [
        C(0.42, 0.36, 0.36, "Scheme", { two: true }), A(0.42, 0.36, 0.36, 270, 450, "", { lit: true }), L([[0.42, 0.18], [0.42, 0.54]]),
        C(0.86, 0.3, 0.2, "Accent", { fill: true }),
        B(1.06, 0.2, 0.12, 0.2, 0.3, "Colour theme", { fill: true }), B(1.2, 0.2, 0.12, 0.2, 0.3), B(1.34, 0.2, 0.12, 0.2, 0.3),
        B(0.72, 0.5, 0.42, 0.34, 0.12, "Wallpaper tint"), L([[0.76, 0.78], [0.86, 0.66], [0.94, 0.74], [1.02, 0.62], [1.1, 0.78]]),
        B(1.22, 0.54, 0.1, 0.1, 0.3, "Dark look", { fill: true }), B(1.22, 0.67, 0.1, 0.1, 0.3, "Light look"), B(1.36, 0.6, 0.1, 0.1, 0.3, "Ink look"),
        L([[0.24, 0.72], [0.6, 0.72]]), L([[0.24, 0.8], [0.5, 0.8]])
    ] },
    // Surfaces: sheets of the material stacked, the glass and its light, its edge, its grain, its corner, the frame, a menu.
    surfaces: { aspect: 1.6, parts: [
        B(0.08, 0.05, 1.44, 0.9, 0.08, "Frame", { faint: true, pin: [0.14, 0.88] }),
        B(0.3, 0.26, 0.6, 0.5, 0.14, "", { faint: true }), B(0.4, 0.18, 0.6, 0.5, 0.14, "Material", { pin: [0.5, 0.6] }),
        B(0.5, 0.1, 0.6, 0.5, 0.14, "Glass", { two: true, pin: [0.9, 0.4] }),
        A(0.66, 0.26, 0.24, 200, 280, "Light", { lit: true, pin: [0.6, 0.16] }),
        L([[0.55, 0.52], [0.7, 0.52]], "Texture"), L([[0.55, 0.47], [0.62, 0.47]]),
        A(1.02, 0.18, 0.16, 270, 360, "Shape", { pin: [1.08, 0.12] }),
        L([[0.5, 0.36], [0.5, 0.24]], "Edges", { pin: [0.5, 0.3] }),
        B(1.2, 0.52, 0.26, 0.32, 0.14, "Menus", { fill: true }), L([[1.25, 0.6], [1.4, 0.6]]), L([[1.25, 0.68], [1.36, 0.68]]), L([[1.25, 0.76], [1.38, 0.76]])
    ] },
    // Type and icons: a letter drawn as a face, the lines of text, the icons in their grid.
    typeIcons: { aspect: 1.6, parts: [
        L([[0.2, 0.78], [0.42, 0.18], [0.64, 0.78]], "Faces", { pin: [0.42, 0.5] }), L([[0.29, 0.56], [0.55, 0.56]]),
        Q([[0.8, 0.78], [0.66, 0.78], [0.66, 0.5], [0.8, 0.5]]), L([[0.8, 0.46], [0.8, 0.78]]),
        L([[0.98, 0.3], [1.42, 0.3]], "Text"), L([[0.98, 0.38], [1.34, 0.38]]), L([[0.98, 0.46], [1.4, 0.46]]),
        B(0.98, 0.6, 0.12, 0.12, 0.35, "Icons", { fill: true }), B(1.14, 0.6, 0.12, 0.12, 0.35), B(1.3, 0.6, 0.12, 0.12, 0.35),
        B(0.98, 0.76, 0.12, 0.12, 0.35), B(1.14, 0.76, 0.12, 0.12, 0.35), B(1.3, 0.76, 0.12, 0.12, 0.35)
    ] },
    // App colours: a window wearing the colour, a terminal, the apps that take it.
    appColours: { aspect: 1.6, parts: [
        B(0.14, 0.12, 0.66, 0.5, 0.1, "What your apps take", { two: true }), B(0.14, 0.12, 0.66, 0.1, 0.4, "", { fill: true }),
        L([[0.24, 0.34], [0.6, 0.34]]), L([[0.24, 0.42], [0.52, 0.42]]),
        B(0.58, 0.48, 0.6, 0.4, 0.1, "Toolkits and terminals"), L([[0.66, 0.6], [0.7, 0.64], [0.66, 0.68]]), L([[0.74, 0.68], [0.84, 0.68]]),
        B(1.28, 0.16, 0.12, 0.12, 0.35, "Apps", { fill: true }), B(1.28, 0.32, 0.12, 0.12, 0.35), B(1.28, 0.48, 0.12, 0.12, 0.35),
        B(1.28, 0.64, 0.12, 0.12, 0.35)
    ] },
    // Windows: the one in focus with its title bar, corners and tabs, the rules an app gets beside it.
    windows: { aspect: 1.6, parts: [
        B(0.1, 0.2, 0.26, 0.62, 0.08, "", { faint: true }), B(1.24, 0.2, 0.26, 0.62, 0.08, "", { faint: true }),
        B(0.42, 0.2, 0.62, 0.62, 0.08, "Shape", { two: true, pin: [1.0, 0.24] }),
        L([[0.42, 0.3], [1.04, 0.3]], "Title bars", { pin: [0.56, 0.25] }), C(0.96, 0.25, 0.025), C(0.92, 0.25, 0.025),
        B(0.44, 0.11, 0.16, 0.06, 0.5, "Tabs", { fill: true }), B(0.62, 0.11, 0.16, 0.06, 0.5),
        B(1.1, 0.5, 0.36, 0.36, 0.12, "App rules", { fill: true }), C(1.16, 0.6, 0.025, "", { fill: true }), L([[1.2, 0.6], [1.38, 0.6]]),
        C(1.16, 0.68, 0.025), L([[1.2, 0.68], [1.34, 0.68]]), C(1.16, 0.76, 0.025), L([[1.2, 0.76], [1.36, 0.76]])
    ] },
    // Layout: Niri's strip of columns, the gaps between them, the room kept for iRiS along the top.
    layout: { aspect: 1.6, parts: [
        B(0.08, 0.06, 1.44, 0.1, 0.5, "Room for iRiS", { faint: true, pin: [0.8, 0.11] }),
        B(0.08, 0.24, 0.36, 0.64, 0.08, "", { faint: true }), B(0.5, 0.24, 0.6, 0.64, 0.08, "Layout", { two: true }),
        B(1.16, 0.24, 0.2, 0.3, 0.08), B(1.16, 0.58, 0.2, 0.3, 0.08), B(1.42, 0.24, 0.3, 0.64, 0.08, "", { faint: true }),
        L([[0.46, 0.92], [0.46, 0.96]]), L([[1.13, 0.92], [1.13, 0.96]])
    ] },
    // Glass: a window seen through, the desktop's colour behind it, its shadow.
    glass: { aspect: 1.6, parts: [
        C(0.5, 0.42, 0.36, "", { fill: true, faint: true }), C(1.06, 0.6, 0.28, "", { fill: true, faint: true }),
        B(0.36, 0.16, 0.86, 0.62, 0.1, "Glass behind apps", { two: true, pin: [0.6, 0.3] }),
        L([[0.46, 0.66], [0.66, 0.26]]), L([[0.56, 0.68], [0.74, 0.32]]),
        B(0.42, 0.24, 0.86, 0.62, 0.1, "Effects", { faint: true, pin: [1.22, 0.84] })
    ] },
    // Movement: a window carried, its trail, where it lands.
    movement: { aspect: 1.6, parts: [
        B(0.16, 0.34, 0.3, 0.3, 0.12, "", { faint: true }), B(0.42, 0.3, 0.3, 0.3, 0.12, "", { faint: true }),
        B(0.76, 0.24, 0.36, 0.36, 0.12, "Movement", { two: true }),
        Q([[0.3, 0.8], [0.6, 0.84], [0.94, 0.8], [1.3, 0.62]]), L([[1.24, 0.6], [1.3, 0.62], [1.27, 0.68]])
    ] },
    // Pointing: a mouse, a trackpad, the pointer, a hot corner, a pen, a touch.
    pointer: { aspect: 1.6, parts: [
        B(0.18, 0.2, 0.24, 0.4, 1, "Mouse", { two: true }), L([[0.3, 0.2], [0.3, 0.34]]),
        B(0.54, 0.26, 0.5, 0.34, 0.14, "Trackpad"), L([[0.54, 0.5], [1.04, 0.5]], "", { faint: true }),
        L([[1.18, 0.22], [1.18, 0.44], [1.24, 0.38], [1.29, 0.48], [1.32, 0.46], [1.27, 0.37], [1.35, 0.37]], "Pointer", { closed: true }),
        A(1.52, 0.04, 0.24, 90, 180, "Hot corners", { pin: [1.45, 0.11] }),
        L([[0.26, 0.86], [0.54, 0.7]], "Tablet"), L([[0.24, 0.88], [0.26, 0.86]]),
        B(0.74, 0.68, 0.36, 0.22, 0.12, "Touch screen"), C(0.92, 0.79, 0.07, "", { fill: true })
    ] },
    // An easing curve on its axes, the window it moves and the time it takes.
    motion: { aspect: 1.6, parts: [
        L([[0.24, 0.1], [0.24, 0.84], [1.4, 0.84]], "", { faint: true }),
        Q([[0.24, 0.84], [0.66, 0.84], [0.72, 0.14], [1.4, 0.14]], "Curve", { pin: [0.82, 0.48] }),
        C(1.4, 0.14, 0.04, "", { fill: true }),
        L([[0.4, 0.84], [0.4, 0.88]], "Timing", { pin: [0.82, 0.92] }), L([[0.56, 0.84], [0.56, 0.88]]), L([[0.72, 0.84], [0.72, 0.88]]),
        L([[0.88, 0.84], [0.88, 0.88]]), L([[1.04, 0.84], [1.04, 0.88]]), L([[1.2, 0.84], [1.2, 0.88]]),
        B(0.32, 0.16, 0.18, 0.13, 0.25, "", { faint: true }), B(0.44, 0.3, 0.18, 0.13, 0.25, "Motion")
    ] },
    // The Island at rest under the screen's edge, opened round a live activity, its pages and its shelf.
    bar: { aspect: 1.6, parts: [
        L([[0.1, 0.1], [1.5, 0.1]], "Visibility", { faint: true, pin: [0.22, 0.1] }),
        B(0.6, 0.14, 0.4, 0.1, 1, "At rest", { fill: true }),
        B(0.38, 0.33, 0.84, 0.36, 0.42, "Live activities", { two: true, pin: [1.1, 0.42] }),
        B(0.47, 0.41, 0.17, 0.2, 0.3), L([[0.7, 0.45], [1.0, 0.45]]), L([[0.7, 0.52], [0.92, 0.52]]),
        L([[0.7, 0.6], [1.12, 0.6]]), C(0.84, 0.6, 0.03, "", { fill: true }),
        C(0.74, 0.77, 0.025, "Pages", { pin: [0.8, 0.77] }), C(0.8, 0.77, 0.025, "", { fill: true }), C(0.86, 0.77, 0.025),
        B(0.62, 0.84, 0.36, 0.08, 1, "Shelf")
    ] },
    // The bubbles on the screen's contour: the activity one, the trailing one, the utility one, a card under one.
    bubbles: { aspect: 1.6, parts: [
        B(0.1, 0.08, 1.4, 0.84, 0.1, "On the contour", { faint: true, pin: [0.8, 0.92] }),
        C(0.25, 0.2, 0.12, "Activity bubble", { fill: true }), A(0.25, 0.2, 0.19, 200, 340, "Size", { pin: [0.25, 0.1] }),
        C(0.39, 0.2, 0.07, "Joining"), L([[0.31, 0.2], [0.355, 0.2]]),
        C(1.35, 0.2, 0.12, "Trailing bubble"), B(1.0, 0.3, 0.42, 0.3, 0.2, "Cards", { two: true }),
        L([[1.06, 0.4], [1.3, 0.4]]), L([[1.06, 0.47], [1.24, 0.47]]),
        C(1.35, 0.8, 0.1, "Utility bubble"), C(0.75, 0.56, 0.08, "Floating")
    ] },
    // The Dock at the screen's foot, its icons, the one pointed at grown, the open apps marked.
    dock: { aspect: 1.6, parts: [
        L([[0.1, 0.86], [1.5, 0.86]], "Visibility", { faint: true, pin: [0.2, 0.86] }),
        B(0.28, 0.58, 1.04, 0.2, 0.5, "Look", { two: true, pin: [1.22, 0.68] }),
        B(0.36, 0.625, 0.11, 0.11, 0.38, "Apps"), B(0.5, 0.625, 0.11, 0.11, 0.38), B(0.64, 0.59, 0.16, 0.16, 0.38, "Icons", { fill: true }),
        B(0.83, 0.625, 0.11, 0.11, 0.38), B(0.97, 0.625, 0.11, 0.11, 0.38),
        C(0.415, 0.765, 0.018, "", { fill: true }), C(0.72, 0.765, 0.018, "", { fill: true })
    ] },
    // The desktop: its widgets inside their margins, the colour they wear, the menu a right click opens.
    desktop: { aspect: 1.6, parts: [
        B(0.1, 0.08, 1.4, 0.84, 0.06, "", { faint: true }),
        B(0.18, 0.16, 1.24, 0.68, 0.04, "Edges", { faint: true, pin: [1.42, 0.5] }),
        B(0.26, 0.22, 0.3, 0.3, 0.2, "Widgets", { two: true }), B(0.26, 0.57, 0.3, 0.14, 0.4, "Design"),
        C(1.22, 0.3, 0.14, "Colour", { fill: true }),
        B(0.9, 0.46, 0.3, 0.32, 0.12, "Desktop menu"), L([[0.95, 0.55], [1.14, 0.55]]), L([[0.95, 0.62], [1.1, 0.62]]),
        L([[0.95, 0.69], [1.12, 0.69]]), L([[0.84, 0.4], [0.84, 0.47], [0.86, 0.45], [0.88, 0.49]])
    ] },
    // Widgets by their own forms: the clock's lens, the weather's sky, the month, the player, a reading.
    widgets: { aspect: 1.6, parts: [
        C(0.36, 0.3, 0.3, "Clock", { two: true }), L([[0.36, 0.3], [0.36, 0.2]]), L([[0.36, 0.3], [0.43, 0.33]]),
        B(0.6, 0.15, 0.58, 0.3, 0.2, "Weather"), A(0.82, 0.38, 0.26, 180, 360), C(1.04, 0.24, 0.06),
        B(1.25, 0.15, 0.3, 0.3, 0.2, "Month Calendar"), C(1.33, 0.25, 0.025), C(1.4, 0.25, 0.025), C(1.47, 0.25, 0.025),
        C(1.33, 0.33, 0.025), C(1.4, 0.33, 0.025, "", { fill: true }), C(1.47, 0.33, 0.025),
        B(0.21, 0.55, 0.58, 0.3, 0.2, "Media Controls"), B(0.27, 0.61, 0.17, 0.17, 0.3), L([[0.5, 0.66], [0.72, 0.66]]),
        L([[0.5, 0.76], [0.72, 0.76]]),
        B(0.86, 0.55, 0.32, 0.3, 0.2, "System Monitor"), L(wave(0.9, 1.14, 0.72, 0.05, 12)),
        B(1.25, 0.55, 0.3, 0.3, 0.2, "Weather", { faint: true }), C(1.4, 0.7, 0.12, "Battery")
    ] },
    // The Control Center: its round keys, its levels, the corner that opens it.
    controlCenter: { aspect: 1.6, parts: [
        B(0.4, 0.08, 0.8, 0.84, 0.12, "Panel look", { two: true, pin: [1.14, 0.88] }),
        C(0.53, 0.24, 0.11, "Controls", { fill: true }), C(0.68, 0.24, 0.11), C(0.83, 0.24, 0.11), C(0.98, 0.24, 0.11),
        C(0.53, 0.41, 0.11), C(0.68, 0.41, 0.11, "", { fill: true }), C(0.83, 0.41, 0.11), C(0.98, 0.41, 0.11),
        B(0.48, 0.56, 0.64, 0.08, 1, "Control Center"), C(0.86, 0.6, 0.06, "", { fill: true }),
        B(0.48, 0.7, 0.64, 0.08, 1), C(0.66, 0.74, 0.06, "", { fill: true }),
        A(1.5, 0.08, 0.2, 90, 180, "Hotspot", { pin: [1.43, 0.15] }),
        L([[1.36, 0.62], [1.44, 0.65], [1.44, 0.74], [1.36, 0.8], [1.28, 0.74], [1.28, 0.65]], "VPN", { closed: true })
    ] },
    // The side panel at the screen's right: today, the focus timer, its glass.
    sidebars: { aspect: 1.6, parts: [
        B(0.12, 0.1, 0.8, 0.8, 0.05, "", { faint: true }), L([[1.5, 0.06], [1.5, 0.94]], "", { faint: true }),
        B(1.0, 0.1, 0.42, 0.8, 0.1, "Panel look", { two: true, pin: [1.38, 0.86] }),
        L([[1.07, 0.22], [1.35, 0.22]], "Today"), L([[1.07, 0.29], [1.28, 0.29]]), L([[1.07, 0.36], [1.32, 0.36]]),
        C(1.21, 0.62, 0.2, "Focus"), A(1.21, 0.62, 0.2, 270, 470, "", { lit: true })
    ] },
    // The Island with the quiet hours' moon, a banner out of it with its app's mark and its chime, Today's stack under.
    notifications: { aspect: 1.6, parts: [
        B(0.56, 0.1, 0.48, 0.11, 1, ""), C(0.97, 0.155, 0.055, "Do Not Disturb", { fill: true }),
        B(0.42, 0.3, 0.76, 0.2, 0.3, "Banners", { two: true }), L([[0.6, 0.37], [0.96, 0.37]]), L([[0.6, 0.43], [0.86, 0.43]]),
        C(0.51, 0.4, 0.1, "Apps", { fill: true }),
        A(1.2, 0.4, 0.12, 300, 420, "Sound", { pin: [1.3, 0.3] }), A(1.2, 0.4, 0.24, 300, 420),
        B(0.48, 0.56, 0.64, 0.14, 0.3, "", { faint: true }), B(0.54, 0.75, 0.52, 0.11, 0.3, "", { faint: true })
    ] },
    // A speaker, a microphone, a fader, the apps that play, the bell and the click.
    sound: { aspect: 1.6, parts: [
        B(0.24, 0.08, 0.5, 0.84, 0.12, "Output", { two: true, pin: [0.49, 0.38] }),
        C(0.49, 0.22, 0.14), C(0.49, 0.62, 0.38), C(0.49, 0.62, 0.14, "", { fill: true }),
        B(0.88, 0.12, 0.12, 0.3, 1, "Input"), A(0.94, 0.36, 0.22, 0, 180), L([[0.94, 0.47], [0.94, 0.54]]),
        B(1.12, 0.12, 0.035, 0.7, 1, "Volume", { pin: [1.1375, 0.48] }), B(1.095, 0.45, 0.09, 0.06, 0.4, "", { fill: true }),
        L([[1.26, 0.18], [1.48, 0.18]], "Apps playing"), L([[1.26, 0.25], [1.42, 0.25]]), L([[1.26, 0.32], [1.46, 0.32]]),
        Q([[1.3, 0.72], [1.3, 0.56], [1.44, 0.56], [1.44, 0.72]], "Alert sounds", { pin: [1.37, 0.66] }), L([[1.27, 0.72], [1.47, 0.72]]),
        L(wave(0.84, 1.06, 0.84, 0.03, 16), "Feedback")
    ] },
    // A search field with its prefix and the results under it.
    spotlight: { aspect: 1.6, parts: [
        B(0.3, 0.16, 1.0, 0.14, 1, "Spotlight", { two: true }), C(0.4, 0.225, 0.06), L([[0.42, 0.25], [0.45, 0.27]]),
        B(1.1, 0.185, 0.14, 0.08, 1, "Prefixes", { fill: true }),
        B(0.3, 0.36, 1.0, 0.48, 0.12, "Panel look", { pin: [1.24, 0.78] }),
        B(0.38, 0.43, 0.07, 0.07, 0.35, "", { fill: true }), L([[0.5, 0.465], [0.9, 0.465]]),
        B(0.38, 0.55, 0.07, 0.07, 0.35), L([[0.5, 0.585], [0.84, 0.585]]),
        B(0.38, 0.67, 0.07, 0.07, 0.35), L([[0.5, 0.705], [0.88, 0.705]])
    ] },
    // Orbit: apps on a ring round the pointer, the hot corner that opens it, its shelf.
    orbit: { aspect: 1.6, parts: [
        A(0.1, 0.08, 0.24, 0, 90, "Hot corner", { pin: [0.16, 0.14] }),
        C(0.8, 0.48, 0.66, "Orbit", { pin: [0.8, 0.15] }), A(0.8, 0.48, 0.8, 200, 340, "Size", { pin: [0.8, 0.08] }),
        C(0.8, 0.48, 0.14, "Look", { fill: true }),
        C(1.13, 0.48, 0.08), C(1.033, 0.247, 0.08), C(0.8, 0.15, 0.08), C(0.567, 0.247, 0.08), C(0.47, 0.48, 0.08),
        C(0.567, 0.713, 0.08), C(0.8, 0.81, 0.08, "", { fill: true }), C(1.033, 0.713, 0.08),
        B(0.6, 0.88, 0.4, 0.07, 1, "Shelf")
    ] },
    // A cut drawn on the screen, the recording dot, a word looked up.
    capture: { aspect: 1.6, parts: [
        B(0.36, 0.2, 0.88, 0.6, 0.02, "Snip", { faint: true, pin: [0.8, 0.5] })
    ].concat(corners(0.36, 0.2, 0.88, 0.6, 0.06)).concat([
        C(1.38, 0.2, 0.08, "Recording", { fill: true }), C(1.38, 0.2, 0.15),
        B(0.12, 0.62, 0.17, 0.2, 0.2, "Japanese lookup"), L([[0.16, 0.69], [0.25, 0.69]]), L([[0.16, 0.75], [0.23, 0.75]])
    ]) },
    // The player: the cover and its disc, the song, its bars, the wave along the screen's edge.
    player: { aspect: 1.6, parts: [
        B(0.06, 0.04, 1.48, 0.92, 0.06, "Frame music", { faint: true, pin: [1.48, 0.1] }),
        B(0.2, 0.12, 0.54, 0.54, 0.1, "Player", { two: true }), C(0.47, 0.39, 0.36), C(0.47, 0.39, 0.06, "", { fill: true }),
        L([[0.86, 0.2], [1.3, 0.2]]), L([[0.86, 0.27], [1.14, 0.27]]),
        L([[0.86, 0.58], [1.4, 0.58]]), C(1.04, 0.58, 0.035, "", { fill: true }),
        L([[0.88, 0.5], [0.88, 0.42]], "Visualizer", { pin: [1.0, 0.44] }), L([[0.94, 0.5], [0.94, 0.36]]), L([[1.0, 0.5], [1.0, 0.4]]),
        L([[1.06, 0.5], [1.06, 0.33]]), L([[1.12, 0.5], [1.12, 0.43]]), L([[1.18, 0.5], [1.18, 0.38]]),
        L(wave(0.12, 1.48, 0.85, 0.025, 28), "Edge wave", { pin: [0.4, 0.85] })
    ] },
    // A poster of what airs, the one being watched with how far, the colour laid over them.
    anime: { aspect: 1.6, parts: [
        B(0.24, 0.1, 0.42, 0.8, 0.1, "Airing", { two: true }), L([[0.3, 0.74], [0.56, 0.74]]), L([[0.3, 0.8], [0.5, 0.8]]),
        B(0.76, 0.2, 0.36, 0.6, 0.1, "Continue"), L([[0.8, 0.72], [1.08, 0.72]]), L([[0.8, 0.72], [0.98, 0.72]], "", { lit: true }),
        C(1.32, 0.3, 0.16, "Colour layer", { fill: true })
    ] },
    // A battery: its charge, the limit it stops at, the warnings on the way down, sleep.
    battery: { aspect: 1.6, parts: [
        B(0.3, 0.26, 0.9, 0.48, 0.28, "Warnings", { two: true, pin: [0.45, 0.5] }), B(1.22, 0.42, 0.05, 0.16, 0.6),
        B(0.35, 0.32, 0.56, 0.36, 0.28, "", { fill: true }),
        L([[1.03, 0.18], [1.03, 0.82]], "Charge limit", { pin: [1.03, 0.18] }),
        C(1.4, 0.16, 0.14, "Suspend"), A(1.43, 0.13, 0.12, 120, 320, "", { faint: true })
    ] },
    // A controller, the corners of a fullscreen game, the floating tools beside it.
    gaming: { aspect: 1.6, parts: [
        B(0.36, 0.3, 0.88, 0.42, 0.7, "Game mode", { two: true, pin: [0.8, 0.62] }),
        L([[0.5, 0.51], [0.62, 0.51]]), L([[0.56, 0.45], [0.56, 0.57]]),
        C(1.02, 0.45, 0.06, "", { fill: true }), C(1.1, 0.53, 0.06),
        B(1.22, 0.74, 0.24, 0.16, 0.2, "Floating tools"), L([[1.26, 0.8], [1.42, 0.8]])
    ].concat(corners(0.1, 0.08, 1.4, 0.84, 0.08).map((part, i) => Object.assign(part, i === 0 ? { g: "Fullscreen" } : {}))) },
    // The lock screen: the scene, the time leading, the day at a glance, the player, the field to sign in.
    lock: { aspect: 1.6, parts: [
        B(0.3, 0.06, 1.0, 0.88, 0.08, "Scene", { two: true, pin: [0.38, 0.86] }),
        C(0.4, 0.13, 0.05, "When idle"), C(1.16, 0.13, 0.03, "Status", { fill: true }), C(1.22, 0.13, 0.03),
        B(0.55, 0.2, 0.5, 0.18, 0.3, "Clock", { fill: true }), L([[0.64, 0.44], [0.96, 0.44]], "At a glance"),
        B(0.42, 0.53, 0.76, 0.1, 0.5, "Now playing"), B(0.6, 0.72, 0.4, 0.08, 1, "Sign in")
    ] },
    login: { aspect: 1.6, parts: [
        B(0.3, 0.06, 1.0, 0.88, 0.08, "", { faint: true }),
        C(0.8, 0.38, 0.24, "Login Screen", { two: true }), B(0.6, 0.62, 0.4, 0.09, 1)
    ] },
    // Where the shell reads from: the sky, the calendar, updates, the machine's readings, the network.
    sources: { aspect: 1.6, parts: [
        C(0.4, 0.46, 0.44, "Weather"), A(0.4, 0.46, 0.44, 0, 180, "", { faint: true }), L([[0.18, 0.46], [0.62, 0.46]]),
        B(0.78, 0.22, 0.28, 0.28, 0.15, "Calendar"), C(0.86, 0.33, 0.025), C(0.92, 0.33, 0.025, "", { fill: true }), C(0.98, 0.33, 0.025),
        C(0.86, 0.41, 0.025), C(0.92, 0.41, 0.025), C(0.98, 0.41, 0.025),
        A(1.32, 0.34, 0.2, 30, 330, "Updates"), L([[1.39, 0.25], [1.42, 0.3], [1.36, 0.3]]),
        A(0.92, 0.8, 0.26, 180, 360, "System readings", { pin: [0.92, 0.7] }), L([[0.92, 0.8], [0.99, 0.7]]),
        A(1.32, 0.82, 0.12, 225, 315, "Network", { pin: [1.32, 0.8] }), A(1.32, 0.82, 0.24, 225, 315), C(1.32, 0.82, 0.025, "", { fill: true })
    ] }
}
// Displays: the screen on its stand, the room it shows inside it, a second screen beside it.
const screen = { aspect: 1.6, parts: [
    B(0.12, 0.05, 1.12, 0.66, 0.05, "Screen", { two: true, pin: [0.68, 0.05] }),
    L([[0.68, 0.71], [0.68, 0.85]]), Q([[0.46, 0.9], [0.56, 0.85], [0.8, 0.85], [0.9, 0.9]]),
    B(0.24, 0.16, 0.2, 0.36, 0.1, "Workspaces"), B(0.48, 0.16, 0.3, 0.36, 0.1, "", { faint: true }),
    B(0.82, 0.16, 0.1, 0.36, 0.1, "", { faint: true }),
    C(1.08, 0.24, 0.12, "Night Light"), A(1.11, 0.21, 0.1, 120, 320, "", { faint: true }),
    B(0.24, 0.58, 0.68, 0.035, 1, "Colour", { fill: true }),
    L(wave(0.98, 1.16, 0.6, 0.018, 10), "Comfort"),
    B(1.32, 0.26, 0.22, 0.34, 0.06, "Screens", { two: true }), L([[1.43, 0.6], [1.43, 0.7]]), L([[1.37, 0.7], [1.49, 0.7]])
] }

function of(page) { return page === "display" ? screen : (objects[page] ?? null) }
