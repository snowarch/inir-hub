.pragma library

// Key bindings as Settings shows them, for the list of shortcuts and the drawn keyboard alike: each category's mark
// and tint (Niri's categories from inir-accel, Umbriel's from the headings of its files), and which key of the
// drawing a bind names.

const _glyphs = {
    "System": "settings_power", "ii Shell": "auto_awesome", "iNiR Shell": "auto_awesome", "iNiR shell": "auto_awesome",
    "Window Switcher": "swap_horiz", "Screenshots": "screenshot_region", "Applications": "apps", "Apps": "apps",
    "Window Management": "web_asset", "Windows": "web_asset", "Focus": "center_focus_strong", "Move Windows": "open_with",
    "Move": "open_with", "Workspaces": "grid_view", "Media": "volume_up", "Media and hardware keys": "volume_up",
    "Brightness": "light_mode", "Layout": "dashboard_customize", "Resize": "photo_size_select_large", "Monitors": "monitor",
    "Region Tools": "screenshot_region", "Scratchpad (Umbriel)": "inventory_2", "Other": "more_horiz"
}
const _tints = {
    "System": "gray", "ii Shell": "purple", "iNiR Shell": "purple", "iNiR shell": "purple", "Window Switcher": "indigo",
    "Screenshots": "orange", "Region Tools": "orange", "Applications": "blue", "Apps": "blue", "Window Management": "sky",
    "Windows": "sky", "Focus": "teal", "Move Windows": "green", "Move": "green", "Workspaces": "indigo", "Media": "pink",
    "Media and hardware keys": "pink", "Brightness": "yellow", "Layout": "lavender", "Resize": "red", "Monitors": "blue",
    "Scratchpad (Umbriel)": "lavender", "Other": "gray"
}
// An action as written, to tell two apart: spacing and Niri's closing semicolon say nothing.
function actionKey(raw) { return String(raw ?? "").trim().replace(/;$/, "").replace(/\s+/g, " ") }
function glyphOf(category) { return _glyphs[category] ?? "keyboard" }
function tintOf(category) { return _tints[category] ?? "gray" }

// The keysym a drawn key sends, by its XKB code. Typed keys name what the layout puts on them (Niri and Umbriel match
// a bind on the layout's own letter when it is Latin); a key whose letter is not Latin falls back to the US one, as
// both compositors do.
const _fixed = {
    ESC: "Escape", PRSC: "Print", INS: "Insert", HOME: "Home", PGUP: "Page_Up", DELE: "Delete", END: "End",
    PGDN: "Page_Down", UP: "Up", LEFT: "Left", DOWN: "Down", RGHT: "Right", TAB: "Tab", RTRN: "Return", SPCE: "Space",
    BKSP: "BackSpace", CAPS: "Caps_Lock", MENU: "Menu"
}
const _us = {
    TLDE: "`", AE01: "1", AE02: "2", AE03: "3", AE04: "4", AE05: "5", AE06: "6", AE07: "7", AE08: "8", AE09: "9", AE10: "0",
    AE11: "-", AE12: "=", AD01: "q", AD02: "w", AD03: "e", AD04: "r", AD05: "t", AD06: "y", AD07: "u", AD08: "i", AD09: "o",
    AD10: "p", AD11: "[", AD12: "]", BKSL: "\\", AC01: "a", AC02: "s", AC03: "d", AC04: "f", AC05: "g", AC06: "h", AC07: "j",
    AC08: "k", AC09: "l", AC10: ";", AC11: "'", AB01: "z", AB02: "x", AB03: "c", AB04: "v", AB05: "b", AB06: "n", AB07: "m",
    AB08: ",", AB09: ".", AB10: "/", LSGT: "<"
}
// Spelled as both compositors' shipped configs write them (keysym names are matched without case).
const _signs = {
    "`": "grave", "-": "Minus", "=": "Equal", "[": "BracketLeft", "]": "BracketRight", "\\": "Backslash", ";": "Semicolon",
    "'": "Apostrophe", ",": "Comma", ".": "Period", "/": "Slash", "<": "Less"
}
function symOf(code, typed) {
    if (_fixed[code]) return _fixed[code]
    if (/^FK\d\d$/.test(code)) return "F" + Number(code.slice(2))
    const own = String(typed ?? "")
    const sign = own.length === 1 && own.charCodeAt(0) < 128 && own.charCodeAt(0) > 32 ? own : String(_us[code] ?? "")
    if (sign.length === 0) return ""
    return _signs[sign] ?? sign.toLowerCase()
}

// A combo as a set: its modifiers in one order, its key in lower case ("Mod+Shift+Slash" → "Mod+Shift|slash").
// `mod` is the compositor's Mod key: a bind naming that key by its own name is a Mod bind.
function _modOf(part, mod) {
    const name = part === "Control" ? "Ctrl" : part === "Win" || part === "Logo" ? "Super" : part
    if (name === "Mod" || name === mod) return "Mod"
    return name
}
const _order = ["Mod", "Super", "Ctrl", "Alt", "Shift"]
function comboKey(combo, mod) {
    const parts = String(combo ?? "").split("+").filter(part => part.length > 0)
    const key = String(parts.pop() ?? "").toLowerCase()
    const mods = parts.map(part => _modOf(part, mod)).filter((name, i, all) => all.indexOf(name) === i)
    mods.sort((a, b) => _order.indexOf(a) - _order.indexOf(b))
    return mods.join("+") + "|" + key
}
function heldKey(held, sym) {
    const mods = Array.from(held ?? []).slice().sort((a, b) => _order.indexOf(a) - _order.indexOf(b))
    return mods.join("+") + "|" + String(sym ?? "").toLowerCase()
}
// The combo written for held modifiers and a key: Mod stays Mod, so it follows the person's Mod key.
function comboOf(held, sym) {
    const mods = Array.from(held ?? []).slice().sort((a, b) => _order.indexOf(a) - _order.indexOf(b))
    return mods.concat([sym.length === 1 ? sym.toUpperCase() : sym]).join("+")
}
