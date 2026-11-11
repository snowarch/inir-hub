.pragma library

// What the widget draws: which picture a setting means. The drawing itself is the shell's GlyphArt.

// What kind of file a path is, by its name: the view needs an animated decoder for a GIF.
function animated(path) {
    return /\.(gif|apng)$/i.test(String(path || ""))
}

function fileUrl(path) {
    var value = String(path || "").trim()
    if (value.length === 0) return ""
    if (/^(file|https?):\/\//.test(value)) return value
    if (value.charAt(0) === "~") return ""   // the faces expand ~ with the home they know
    return "file://" + value
}

// Which picture a source setting means right now. `cover` is the playing track's art ("" when none), `wall` the
// wallpaper's still. Returns { kind: "picture"|"word"|"none", url, why } where `why` names an empty state.
function resolve(source, cover, wall, file, word, home) {
    var s = String(source || "auto")
    if (s === "word") {
        var w = String(word || "").trim()
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
