.pragma library

// NiHiL's own glyphs, drawn on a 24 grid out of lines, circles and dots. Segments are split by "|": "M..." a stroked
// path, "*M..." a filled one, "o x y r" a ring, "O x y r" a disc. A name with "_off" or "_disabled" is its glyph struck.
var set = {
    search: "o 10.5 10.5 6.5|M15.5 15.5 20.5 20.5",
    close: "M6 6 18 18|M18 6 6 18",
    check: "M4.5 12.5 10 18 19.5 7",
    add: "M12 5v14|M5 12h14",
    remove: "M5 12h14",
    chevron_right: "M9.5 5.5 16 12l-6.5 6.5",
    chevron_left: "M14.5 5.5 8 12l6.5 6.5",
    expand_less: "M5.5 15 12 8.5l6.5 6.5",
    expand_more: "M5.5 9 12 15.5 18.5 9",
    arrow_back: "M20 12H4.5|M10.5 6l-6 6 6 6",
    arrow_forward: "M4 12h15.5|M13.5 6l6 6-6 6",
    more: "O 5 12 1.9|O 12 12 1.9|O 19 12 1.9",
    apps: "O 5.5 5.5 2|O 12 5.5 2|O 18.5 5.5 2|O 5.5 12 2|O 12 12 2|O 18.5 12 2|O 5.5 18.5 2|O 12 18.5 2|O 18.5 18.5 2",
    widgets: "o 7.5 7.5 3.6|o 16.5 7.5 3.6|o 7.5 16.5 3.6|O 16.5 16.5 3.6",
    home: "M4 11.5 12 4.5l8 7|M6.5 10v9.5h11V10",
    tune: "M4 8h9|M19 8h1|o 16 8 2.6|M4 16h1|M11 16h9|o 8 16 2.6",
    power: "M12 3.5v8|M7 6.2a8 8 0 1 0 10 0",
    restart: "M5 12a7 7 0 1 0 2.4-5.3L4.5 9.5|M4.5 4.5v5h5",
    logout: "M10 4.5H5v15h5|M14 8l4 4-4 4|M18 12H9.5",
    lock: "M6 11h12v9H6z|M8.5 11V8a3.5 3.5 0 0 1 7 0v3|O 12 15.5 1.4",
    moon: "*M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z",
    sun: "O 12 12 4|M12 2.5v2|M12 19.5v2|M2.5 12h2|M19.5 12h2|M5.3 5.3l1.4 1.4|M17.3 17.3l1.4 1.4|M5.3 18.7l1.4-1.4|M17.3 6.7l1.4-1.4",
    wifi: "M3 9.5a13 13 0 0 1 18 0|M6.5 13.2a8 8 0 0 1 11 0|M10 16.8a3 3 0 0 1 4 0|O 12 19.8 1.3",
    lan: "M9 3.5h6v5H9z|M12 8.5v4|M5.5 12.5h13|M5.5 12.5v3|M18.5 12.5v3|M3 15.5h5v5H3z|M16 15.5h5v5h-5z",
    bluetooth: "M7 7.5l10 9-5 4.5V3l5 4.5-10 9",
    flight: "M12 3v7l8 5v2l-8-2.5V19l2.5 2h-5L12 19v-4.5L4 17v-2l8-5z",
    volume_up: "*M4 9.5h3.5L12 5.5v13l-4.5-4H4z|M15.5 9a4 4 0 0 1 0 6|M18 6.5a8 8 0 0 1 0 11",
    volume_down: "*M4 9.5h3.5L12 5.5v13l-4.5-4H4z|M15.5 9a4 4 0 0 1 0 6",
    volume_mute: "*M4 9.5h3.5L12 5.5v13l-4.5-4H4z|M16 9.5l5 5|M21 9.5l-5 5",
    mic: "M9 5.5a3 3 0 0 1 6 0v6a3 3 0 0 1-6 0z|M5.5 11.5a6.5 6.5 0 0 0 13 0|M12 18v3",
    bell: "M6 17v-6a6 6 0 0 1 12 0v6l1.5 1.5h-15z|M10 21h4",
    music: "M9 17.5v-12l10-2v12|o 6.5 17.5 2.5|o 16.5 15.5 2.5",
    play: "*M7 4.5 19.5 12 7 19.5z",
    pause: "*M7 5h3.5v14H7z|*M13.5 5H17v14h-3.5z",
    next: "*M5.5 5 15 12l-9.5 7z|M18.5 5v14",
    previous: "*M18.5 5 9 12l9.5 7z|M5.5 5v14",
    shuffle: "M3.5 7h3c5 0 5 10 10 10h4|M3.5 17h3c1.7 0 2.9-1 4-2.5|M13.5 9.5C14.6 8 15.5 7 17 7h3.5|M18 4.5 20.5 7 18 9.5|M18 14.5l2.5 2.5-2.5 2.5",
    image: "M4 5h16v14H4z|O 8.5 9.5 1.6|M4 16l5-4.5 3.5 3 3-2.5 4.5 3.5",
    image_add: "M13 5H4v14h16v-8|O 8.5 9.5 1.6|M4 16l5-4.5 3.5 3 3-2.5 4.5 3.5|M19 2.5v6|M16 5.5h6",
    palette: "o 12 12 8.5|O 8 10 1.3|O 12 7.5 1.3|O 16 10 1.3|O 14.5 15 1.7",
    memory: "M6.5 6.5h11v11h-11z|M9.5 3v3.5|M14.5 3v3.5|M9.5 17.5V21|M14.5 17.5V21|M3 9.5h3.5|M3 14.5h3.5|M17.5 9.5H21|M17.5 14.5H21",
    storage: "M4 5h16v6H4z|M4 13h16v6H4z|O 8 8 1.1|O 8 16 1.1",
    keyboard: "M3 6.5h18v11H3z|O 7 10.2 1|O 12 10.2 1|O 17 10.2 1|M8 14.3h8",
    globe: "o 12 12 8.5|M3.5 12h17|M12 3.5c3.2 3 3.2 14 0 17|M12 3.5c-3.2 3-3.2 14 0 17",
    region: "M4 9V4h5|M15 4h5v5|M20 15v5h-5|M9 20H4v-5|O 12 12 1.8",
    toggle: "M2.5 12a6 6 0 0 1 6-6h7a6 6 0 0 1 0 12h-7a6 6 0 0 1-6-6z|O 15.5 12 3",
    page: "M6 3.5h8.5l4 4v13H6z|M14 4v4h4|M9 12.5h6|M9 16.5h6",
    download: "M12 4v11|M7.5 11l4.5 4.5 4.5-4.5|M5 20h14",
    trash: "M5 7h14|M9.5 7V4.5h5V7|M7 7l1 13h8l1-13",
    undo: "M8.5 5 4 9.5 8.5 14|M4 9.5h10a5.5 5.5 0 0 1 0 11H9",
    favorite: "*M12 19.5 5 13a4.2 4.2 0 0 1 7-4.6 4.2 4.2 0 0 1 7 4.6z",
    redo: "M15.5 5 20 9.5 15.5 14|M20 9.5H10a5.5 5.5 0 0 0 0 11h5",
    grid: "M4.5 4.5h15v15h-15z|M9.5 4.5v15|M14.5 4.5v15|M4.5 9.5h15|M4.5 14.5h15",
    lock_open: "M6 11h12v9H6z|M8.5 11V8a3.5 3.5 0 0 1 6.8-1.2|O 12 15.5 1.4",
    heart: "M12 19.5 5 13a4.2 4.2 0 0 1 7-4.6 4.2 4.2 0 0 1 7 4.6z",
    pin: "M9 3.5h6l-.8 6 3.3 3.5v2h-11v-2l3.3-3.5z|M12 15v6",
    desktop: "M3.5 5h17v11h-17z|M12 16v4|M8 20h8",
    bar: "M3.5 5h17v14h-17z|M3.5 15h17",
    ring: "O 12 4.5 1.5|O 17.3 6.7 1.5|O 19.5 12 1.5|O 17.3 17.3 1.5|O 12 19.5 1.5|O 6.7 17.3 1.5|O 4.5 12 1.5|O 6.7 6.7 1.5|O 12 12 2.6",
    bolt: "*M13.5 2.5 5.5 13.5h5l-1 8 9-12H13z",
    leaf: "M6 18c-1-8 4-13 14-13 0 10-5 15-13 14|M4 21c2-5 5-8 10-10",
    password: "O 6 11 1.9|O 12 11 1.9|O 18 11 1.9|M4 18h16",
    eye: "M2.5 12s3.5-6.5 9.5-6.5 9.5 6.5 9.5 6.5-3.5 6.5-9.5 6.5-9.5-6.5-9.5-6.5z|O 12 12 2.6",
    contrast: "o 12 12 8.5|*M12 3.5a8.5 8.5 0 0 1 0 17z",
    video: "M3.5 7h12v10h-12z|M15.5 11l5-3v8l-5-3z",
    timer: "o 12 13.5 7.5|M12 9v4.5l2.5 2|M9.5 2.5h5",
    calendar: "M4 6h16v14H4z|M4 10.5h16|M8.5 3.5v4|M15.5 3.5v4",
    clipboard: "M7 5H5v15.5h14V5h-2|M8.5 3.5h7v4h-7z",
    person: "o 12 8 4|M4.5 20.5a7.5 7.5 0 0 1 15 0",
    speaker: "M7 3.5h10v17H7z|o 12 15 3|O 12 7.5 1.1",
    headphones: "M4 14v-2a8 8 0 0 1 16 0v2|M4 14h3v6H4z|M17 14h3v6h-3z",
    edit: "M4 20h4L19.5 8.5l-4-4L4 16z",
    info: "o 12 12 8.5|M12 11v5.5|O 12 7.8 1.2",
    warning: "M12 3.5 21.5 20h-19z|M12 10v4.5|O 12 17.3 1.1",
    folder: "M3.5 6h6l2 2.5h9v11h-17z",
    copy: "M8.5 8.5h11v12h-11z|M15.5 8.5v-5h-11v12h4",
    open: "M10 5H5v14h14v-5|M14 4h6v6|M20 4l-9 9",
    layers: "M12 4.5 20 9l-8 4.5L4 9z|M4 13l8 4.5 8-4.5",
    maximize: "M5.5 5.5h13v13h-13z",
    restore: "M8.5 8.5h10v10h-10z|M5.5 15.5v-10h10",
    star: "M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7L12 17l-5.1 2.7 1-5.7-4.1-4 5.7-.8z",
    battery: "M3.5 8h15v8h-15z|M21 10.5v3",
    windows: "M3.5 5h7.5v14H3.5z|M14 5h6.5v6H14z|M14 14h6.5v5H14z",
    dot: "O 12 12 3.5"
}

// The shell's service glyph names, said in NiHiL's words.
var alias = {
    settings: "tune", settings_applications: "tune", page_info: "tune",
    power_settings_new: "power", restart_alt: "restart", refresh: "restart", autorenew: "restart", sync: "restart",
    bedtime: "moon", dark_mode: "moon", nightlight: "moon", nightlight_round: "moon", mode_night: "moon",
    light_mode: "sun", brightness_empty: "sun", brightness_high: "sun", brightness_medium: "sun", brightness_low: "sun",
    keyboard_arrow_up: "expand_less", keyboard_arrow_down: "expand_more", keyboard_arrow_right: "chevron_right",
    keyboard_arrow_left: "chevron_left", more_horiz: "more", more_vert: "more", menu: "apps", grid_view: "apps",
    dashboard_customize: "widgets", dashboard: "widgets", notifications: "bell", notifications_active: "bell",
    notifications_paused: "bell_off", do_not_disturb_on: "bell_off", music_note: "music", play_arrow: "play",
    skip_next: "next", skip_previous: "previous", wallpaper: "image", photo: "image", add_photo_alternate: "image_add",
    hide_image: "image_off", language: "globe", travel_explore: "globe", public: "globe", screenshot_region: "region",
    screenshot: "region", toggle_on: "toggle", description: "page", menu_book: "page", article: "page",
    delete_sweep: "trash", delete: "trash", push_pin: "pin", keep: "pin", desktop_windows: "desktop", monitor: "desktop",
    dock_to_bottom: "bar", toolbar: "bar", blur_circular: "ring", energy_savings_leaf: "leaf", eco: "leaf",
    battery_saver: "leaf", speed: "bolt", coffee: "eye", local_cafe: "eye", visibility: "eye", videocam: "video",
    schedule: "timer", calendar_month: "calendar", event: "calendar", today: "calendar", content_paste: "clipboard",
    account_circle: "person", edit_note: "edit", error: "warning", content_copy: "copy", open_in_new: "open",
    settings_ethernet: "lan", cable: "lan", volume_mute: "volume_mute", volume_off: "volume_mute",
    speaker_group: "speaker", graphic_eq: "music", airplanemode_active: "flight", airplanemode_inactive: "flight_off",
    bluetooth_connected: "bluetooth", bluetooth_searching: "bluetooth", search_off: "search_off"
}

function resolve(name) {
    var key = String(name)
    if (key.indexOf("signal_wifi_off") === 0 || key === "signal_wifi_0_bar" || key === "wifi_off") return { glyph: "wifi", struck: true }
    if (key.indexOf("wifi") === 0 || key.indexOf("signal_wifi") === 0 || key.indexOf("network_wifi") === 0) return { glyph: "wifi", struck: false }
    if (key.indexOf("battery") === 0 && key !== "battery_saver") return { glyph: "battery", struck: false }
    key = alias[key] || key
    if (set[key]) return { glyph: key, struck: false }
    var struck = key.replace(/_(off|disabled)$/, "")
    if (struck !== key) {
        struck = alias[struck] || struck
        if (set[struck]) return { glyph: struck, struck: true }
    }
    return { glyph: "dot", struck: false }
}

function _segment(part, ink) {
    var head = part.charAt(0)
    if (head === "o" || head === "O") {
        var c = part.slice(2).split(" ")
        return '<circle cx="' + c[0] + '" cy="' + c[1] + '" r="' + c[2] + '"' + (head === "O" ? ' fill="' + ink + '" stroke="none"' : "") + "/>"
    }
    if (head === "*") return '<path d="' + part.slice(1) + '" fill="' + ink + '" stroke="none"/>'
    return '<path d="' + part + '"/>'
}

// The glyph as an SVG address an Image can load, in one ink.
function url(name, ink, weight) {
    var found = resolve(name)
    var body = set[found.glyph].split("|").map(function (part) { return _segment(part, ink) }).join("")
    if (found.struck) body += '<path d="M4 4l16 16"/>'
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + ink + '" stroke-width="' + weight
        + '" stroke-linecap="round" stroke-linejoin="round">' + body + "</svg>"
    return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
}
