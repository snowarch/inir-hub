.pragma library

// What the widget draws: which subject a setting means. The drawing itself is the shell's GlyphArt.

// What kind of file a path is, by its name: the view needs an animated decoder for a GIF.
function animated(path) {
    return /\.(gif|apng)$/i.test(String(path || ""))
}

function fileUrl(path) {
    var value = String(path || "").trim()
    if (value.length === 0) return ""
    if (/^(file|https?):\/\//.test(value)) return value
    if (value.charAt(0) === "~") return ""   // the view expands ~ with the home it knows
    return "file://" + value
}

// Which subject a source setting means right now. `cover` is the playing track's art ("" when none), `wall` the
// wallpaper's still, `builtIn` whether the setting names one of GlyphArt's own subjects. Returns
// { kind: "picture"|"word"|"demo"|"none", url, why } where `why` names an empty state.
function resolve(source, cover, wall, file, word, home, builtIn) {
    var s = String(source || "auto")
    if (builtIn) return { kind: "demo", url: "", why: "" }
    if (s === "word") {
        var w = String(word || "").replace(/\|/g, "").trim()
        return w.length > 0 ? { kind: "word", url: "", why: "" } : { kind: "none", url: "", why: "word" }
    }
    if (s === "file") {
        var p = String(file || "").trim()
        if (p.charAt(0) === "~") p = String(home || "") + p.slice(1)
        var u = fileUrl(p)
        return u.length > 0 ? { kind: "picture", url: u, why: "" } : { kind: "none", url: "", why: "file" }
    }
    if (s === "music")
        return cover ? { kind: "picture", url: cover, why: "" } : { kind: "none", url: "", why: "music" }
    if (s === "wallpaper" || !cover)
        return wall ? { kind: "picture", url: wall, why: "" } : { kind: "none", url: "", why: "wallpaper" }
    return { kind: "picture", url: cover, why: "" }
}

// Width over height of the plate: a fixed shape, or the subject's own.
function aspect(shape, kind, pictureWidth, pictureHeight) {
    switch (String(shape || "auto")) {
    case "wide": return 1.6
    case "cinema": return 2.4
    case "square": return 1
    case "tall": return 0.75
    }
    if (kind === "word") return 2.4
    if (kind === "demo") return 1.25
    return pictureWidth > 0 && pictureHeight > 0 ? Math.max(0.6, Math.min(2.4, pictureWidth / pictureHeight)) : 1.6
}
