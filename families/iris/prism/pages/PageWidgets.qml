import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "widgets"
    name: "Widgets"
    group: "Desktop"
    glyph: "widgets"
    tint: "amber"
    show: ({"label": "Edit widgets", "target": "background", "fn": "toggleEditMode"})
    lead: ["iris.widgets.design", "iris.widgets.material"]
    sections: [
        { title: "Look", rows: [
            {"path": "iris.widgets.design", "label": "Design", "kind": "choice", "def": "iris", "glyph": "widgets", "detail": "One look on every widget.", "choices": [{"label": "iRiS", "value": "iris"}, {"label": "Prism", "value": "prism"}, {"label": "Material", "value": "material"}, {"label": "iNstrument", "value": "instrument"}, {"label": "Readout", "value": "readout"}]},
            {"path": "iris.widgets.material", "label": "Material", "kind": "choice", "def": "glass", "glyph": "layers", "detail": "What sits behind each widget.", "choices": [{"label": "Glass", "value": "glass"}, {"label": "Transparent", "value": "clear"}, {"label": "Solid", "value": "solid"}, {"label": "Tinted", "value": "tinted"}]},
            {"path": "iris.widgets.tint", "label": "Accents", "kind": "choice", "def": "wallpaper", "glyph": "colors", "detail": "The three colours every widget draws its rings, bars and figures with.", "choices": [{"label": "Wallpaper", "value": "wallpaper"}, {"label": "iRiS", "value": "system"}, {"label": "Spectrum", "value": "spectrum"}, {"label": "Mono", "value": "mono"}]},
            {"path": "iris.widgets.vibrance", "label": "Accent strength", "kind": "range", "def": 85, "glyph": "palette", "detail": "Low keeps soft pastels; high makes accents saturated and bright.", "min": 0, "max": 100, "step": 5, "unit": " %"}
        ] },
        { title: "Surface", rows: [
            {"path": "iris.widgets.radius", "label": "Widget corners", "kind": "range", "def": 22, "glyph": "rounded_corner", "detail": "Individual widget overrides take priority.", "min": 0, "max": 40, "unit": " px"},
            {"path": "iris.widgets.opacity", "label": "Surface opacity", "kind": "range", "def": 100, "glyph": "opacity", "detail": "How much material a widget carries.", "min": 20, "max": 100, "step": 5, "unit": " %"},
            {"path": "iris.widgets.weight", "label": "Titles and figures", "kind": "choice", "def": "regular", "glyph": "format_bold", "choices": [{"label": "Light", "value": "light"}, {"label": "Regular", "value": "regular"}, {"label": "Bold", "value": "bold"}]},
            {"path": "iris.widgets.legibleAlways", "label": "Lume on every widget", "kind": "switch", "def": false, "glyph": "contrast", "detail": "Every widget reads as if the wallpaper under it were bright and busy: a deeper veil on glass and a stronger text shadow on widgets without a background."}
        ] }
    ]
}
