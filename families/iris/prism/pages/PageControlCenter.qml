import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "controlCenter"
    name: "Control Center"
    group: "Desktop"
    glyph: "toggle_on"
    tint: "green"
    show: ({"label": "Open", "target": "controlCenter", "fn": "open"})
    lead: ["iris.controlCenter.opens", "iris.controlCenter.controls"]
    sections: [
        { title: "Control Center", rows: [
            {"path": "iris.controlCenter.opens", "label": "Opens as", "kind": "choice", "def": "island", "glyph": "open_in_new", "detail": "The Island itself becomes the Control Center, or a panel hangs from it.", "choices": [{"label": "The Island", "value": "island"}, {"label": "A panel", "value": "panel"}]},
            {"path": "iris.controlCenter.controls", "label": "Control shape", "kind": "choice", "def": "tiles", "glyph": "toggle_on", "detail": "Round draws each switch as a disc with its name under it; Tiles are rounded squares.", "choices": [{"label": "Tiles", "value": "tiles"}, {"label": "Round", "value": "round"}]},
            {"path": "iris.controlCenter.columns", "label": "Columns", "kind": "range", "def": 4, "glyph": "view_column", "detail": "How many controls fit across.", "min": 3, "max": 6},
            {"path": "iris.controlCenter.labels", "label": "Names under the controls", "kind": "switch", "def": true, "glyph": "label", "detail": "Off shows a name in the header while you point at it."}
        ] },
        { title: "Colour", rows: [
            {"path": "iris.controlCenter.accent", "label": "Accent", "kind": "choice", "def": "system", "glyph": "colors", "detail": "What a switch lights up with.", "choices": [{"label": "Accent", "value": "system"}, {"label": "Colourful", "value": "colourful"}, {"label": "Mono", "value": "mono"}]},
            {"path": "iris.controlCenter.sliders", "label": "Slider fill", "kind": "choice", "def": "neutral", "glyph": "tune", "choices": [{"label": "Neutral", "value": "neutral"}, {"label": "Accent", "value": "accent"}]},
            {"path": "iris.controlCenter.width", "label": "Width", "kind": "range", "def": 360, "glyph": "width", "min": 320, "max": 540, "step": 10, "unit": " px"}
        ] }
    ]
}
