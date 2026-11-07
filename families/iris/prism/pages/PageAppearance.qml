import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "appearance"
    name: "Style"
    group: "Shell"
    glyph: "palette"
    tint: "violet"
    show: ({"label": "Change wallpaper", "target": "wallpaperSelector", "fn": "open"})
    lead: ["iris.appearance.look", "iris.appearance.scheme"]
    sections: [
        { title: "Colour", rows: [
            {"path": "iris.appearance.scheme", "label": "Scheme", "kind": "choice", "def": "auto", "glyph": "contrast", "detail": "Ink sits between dark and light: paper and ink, easier on the eyes.", "choices": [{"label": "Auto", "value": "auto"}, {"label": "Dark mode", "value": "dark"}, {"label": "Ink", "value": "ink"}, {"label": "Light mode", "value": "light"}]},
            {"path": "iris.appearance.accent", "label": "System accent", "kind": "swatch", "def": "blue", "glyph": "colors", "detail": "What your apps wear, and what iRiS marks as chosen under the Apple look.", "choices": [{"label": "Blue", "value": "blue"}, {"label": "Mint", "value": "mint"}, {"label": "Rose", "value": "rose"}, {"label": "Lilac", "value": "lilac"}, {"label": "Theme", "value": "theme"}, {"label": "Wallpaper", "value": "wallpaper"}]},
            {"path": "iris.appearance.highlight", "label": "Highlight", "kind": "swatch", "def": "orange", "glyph": "highlight", "detail": "The glanced detail: clock separator, day number, timers.", "choices": [{"label": "Orange", "value": "orange"}, {"label": "Yellow", "value": "yellow"}, {"label": "Red", "value": "red"}, {"label": "Pink", "value": "pink"}, {"label": "Green", "value": "green"}, {"label": "Accent", "value": "accent"}, {"label": "Theme", "value": "theme"}, {"label": "Wallpaper", "value": "wallpaper"}]},
            {"path": "iris.appearance.look", "label": "Look", "kind": "choice", "def": "apple", "glyph": "auto_awesome", "detail": "The dialect iRiS speaks: how controls are made, what marks the chosen thing, the voice of labels. Each place below can wear its own.", "choices": [{"label": "Apple", "value": "apple"}, {"label": "Nothing OS", "value": "nothing"}, {"label": "Synth", "value": "synth"}, {"label": "Gel", "value": "gel"}]},
            {"path": "iris.appearance.theme.surface", "label": "Material", "kind": "choice", "def": "black", "glyph": "layers", "detail": "What every surface is made of.", "choices": [{"label": "Black", "value": "black"}, {"label": "Graphite", "value": "graphite"}, {"label": "Midnight", "value": "midnight"}, {"label": "Wallpaper", "value": "wallpaper"}, {"label": "Theme", "value": "theme"}]}
        ] },
        { title: "Glass", rows: [
            {"path": "iris.appearance.glass.mode", "label": "Glass", "kind": "choice", "def": "wallpaper", "glyph": "blur_on", "detail": "Glass blurs the wallpaper.", "choices": [{"label": "Off", "value": "off"}, {"label": "Glass", "value": "wallpaper"}, {"label": "Blur (beta)", "value": "compositor"}]},
            {"path": "iris.appearance.glass.tint", "label": "Tint", "kind": "range", "def": 58, "glyph": "opacity", "detail": "How much material covers the glass.", "min": 12, "max": 96, "step": 2, "unit": " %", "when": "iris.appearance.glass.mode!=off"},
            {"path": "iris.appearance.glass.blur", "label": "Frost", "kind": "range", "def": 100, "glyph": "lens_blur", "detail": "How blurred the wallpaper is behind the glass, on iRiS and on glass widgets.", "min": 20, "max": 100, "step": 5, "unit": " %", "when": "iris.appearance.glass.mode!=off"}
        ] },
        { title: "Text", rows: [
            {"path": "iris.appearance.theme.text", "label": "Size", "kind": "range", "def": 100, "glyph": "format_size", "detail": "Text across iRiS, on top of the system scale.", "min": 85, "max": 125, "step": 5, "unit": " %"},
            {"path": "iris.appearance.theme.weight", "label": "Weight", "kind": "choice", "def": "regular", "glyph": "format_bold", "detail": "Every weight in iRiS one step lighter or firmer.", "choices": [{"label": "Light", "value": "light"}, {"label": "Regular", "value": "regular"}, {"label": "Bold", "value": "bold"}]},
            {"path": "iris.appearance.theme.contrast", "label": "Contrast", "kind": "range", "def": 100, "glyph": "tonality", "detail": "Secondary and quiet text.", "min": 60, "max": 150, "step": 5, "unit": " %"},
            {"path": "iris.appearance.figureWeight", "label": "Figure weight", "kind": "choice", "def": "bold", "glyph": "pin", "choices": [{"label": "Light", "value": "light"}, {"label": "Regular", "value": "regular"}, {"label": "Bold", "value": "bold"}]}
        ] },
        { title: "Shape", rows: [
            {"path": "iris.appearance.theme.shape", "label": "Corners", "kind": "range", "def": 100, "glyph": "rounded_corner", "detail": "Every radius in the family; nested corners keep stepping down.", "min": 30, "max": 160, "step": 5, "unit": " %"},
            {"path": "iris.appearance.density", "label": "Spacing", "kind": "range", "def": 1, "glyph": "density_medium", "detail": "Padding, gaps and control sizes.", "min": 0.8, "max": 1.35, "step": 0.05, "unit": "×"}
        ] },
        { title: "Light", rows: [
            {"path": "iris.appearance.theme.shadow", "label": "Shadows", "kind": "range", "def": 100, "glyph": "shadow", "detail": "Under bodies floating over windows.", "min": 0, "max": 160, "step": 5, "unit": " %"},
            {"path": "iris.appearance.theme.glow", "label": "Glow", "kind": "range", "def": 0, "glyph": "flare", "detail": "Floating surfaces cast an accent halo instead of a dark shadow.", "min": 0, "max": 100, "step": 5, "unit": " %"},
            {"path": "iris.appearance.aura", "label": "Light", "kind": "choice", "def": "subtle", "glyph": "light_mode", "detail": "What lights an open card: its own colour or the wallpaper's.", "choices": [{"label": "Off", "value": "off"}, {"label": "Subtle", "value": "subtle"}, {"label": "Vivid", "value": "vivid"}]},
            {"path": "iris.appearance.adaptive", "label": "Adapt to the wallpaper", "kind": "range", "def": 0, "glyph": "wallpaper", "detail": "iRiS takes its shape from the wallpaper: calm images round, busy ones sharpen. 0 is off.", "min": 0, "max": 100, "step": 5, "unit": " %"}
        ] }
    ]
}
