import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "wallpaper"
    name: "Wallpaper"
    group: "Shell"
    glyph: "wallpaper"
    tint: "teal"
    show: ({"label": "Change wallpaper", "target": "wallpaperSelector", "fn": "open"})
    lead: ["iris.wallpaper.layout", "iris.wallpaper.sort"]
    sections: [
        { title: "Library", rows: [
            {"path": "iris.wallpaper.layout", "label": "Layout", "kind": "choice", "def": "reel", "glyph": "view_carousel", "detail": "How the picker lays out what you browse.", "choices": [{"label": "Reel", "value": "reel"}, {"label": "Mosaic", "value": "mosaic"}, {"label": "Browser", "value": "browser"}]},
            {"path": "iris.wallpaper.motion", "label": "Play previews", "kind": "switch", "def": true, "glyph": "play_circle", "detail": "Live wallpapers play a muted preview while chosen or hovered in the gallery."},
            {"path": "iris.wallpaper.liveQuality", "label": "Live wallpaper downloads", "kind": "choice", "def": "best", "glyph": "high_quality", "detail": "Which file a live wallpaper downloads.", "choices": [{"label": "Best", "value": "best"}, {"label": "Light", "value": "light"}]},
            {"path": "iris.wallpaper.sort", "label": "Library order", "kind": "choice", "def": "newest", "glyph": "sort", "detail": "How your folders line up in the gallery.", "choices": [{"label": "Newest", "value": "newest"}, {"label": "Oldest", "value": "oldest"}, {"label": "Name", "value": "name"}]},
            {"path": "iris.wallpaper.ratio", "label": "Shape", "kind": "choice", "def": "screen", "glyph": "aspect_ratio", "detail": "What the web is asked for.", "choices": [{"label": "Your screen", "value": "screen"}, {"label": "Wide", "value": "wide"}, {"label": "Portrait", "value": "portrait"}, {"label": "Any", "value": "any"}]},
            {"path": "iris.wallpaper.suggestive", "label": "Suggestive art", "kind": "switch", "def": false, "glyph": "visibility_off", "detail": "Off keeps swimsuits, lingerie and fan service out of online results."}
        ] },
        { title: "Change", rows: [
            {"path": "background.transition.enable", "label": "Animate the change", "kind": "switch", "def": true, "glyph": "transition_fade", "detail": "The next wallpaper arrives with a movement instead of a cut."},
            {"path": "background.transition.duration", "label": "Duration", "kind": "range", "def": 800, "glyph": "timelapse", "min": 200, "max": 3000, "step": 100, "unit": " ms", "when": "background.transition.enable"},
            {"path": "background.parallax.enable", "label": "Parallax", "kind": "switch", "def": false, "glyph": "3d_rotation", "detail": "The wallpaper drifts a little as you move between workspaces and columns."}
        ] },
        { title: "Effects", rows: [
            {"path": "background.effects.enableBlur", "label": "Blur the wallpaper", "kind": "switch", "def": true, "glyph": "blur_on", "detail": "While windows are open on the workspace; it comes back sharp when they leave."},
            {"path": "background.effects.blurRadius", "label": "Blur", "kind": "range", "def": 22, "glyph": "lens_blur", "min": 4, "max": 80, "step": 2, "unit": " px", "when": "background.effects.enableBlur"},
            {"path": "background.effects.dim", "label": "Always dim", "kind": "range", "def": 30, "glyph": "brightness_4", "min": 0, "max": 60, "step": 5, "unit": " %"}
        ] },
        { title: "Shuffle", rows: [
            {"path": "background.autoWallpaper.enable", "label": "Shuffle wallpapers", "kind": "switch", "def": false, "glyph": "shuffle", "detail": "A new wallpaper from your folder every few minutes."},
            {"path": "background.autoWallpaper.intervalMinutes", "label": "Every", "kind": "range", "def": 30, "glyph": "update", "min": 1, "max": 240, "step": 1, "unit": " min", "when": "background.autoWallpaper.enable"}
        ] }
    ]
}
