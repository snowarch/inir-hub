import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "bubbles"
    name: "Bubbles"
    group: "Desktop"
    glyph: "bubble_chart"
    tint: "pink"
    lead: ["iris.bubbles.design", "iris.bubbles.join"]
    sections: [
        { title: "Bubbles", rows: [
            {"path": "iris.bubbles.design", "label": "Bubble design", "kind": "choice", "def": "glass", "glyph": "bubble_chart", "detail": "How each bubble beside the Island is drawn.", "choices": [{"label": "Glass", "value": "glass"}, {"label": "Tinted", "value": "tint"}, {"label": "Outline", "value": "outline"}]},
            {"path": "iris.bubbles.scale", "label": "Bubble size", "kind": "range", "def": 100, "glyph": "zoom_in", "detail": "Bubbles off the Island, as a share of the Island's height.", "min": 60, "max": 140, "step": 5, "unit": " %"},
            {"path": "iris.bubbles.edgeGap", "label": "Space from the screen edges", "kind": "range", "def": 20, "glyph": "border_outer", "detail": "How far floating bubbles rest from the edges when they are not on the frame.", "min": 0, "max": 64, "unit": " px"}
        ] },
        { title: "Placement", rows: [
            {"path": "iris.bubbles.snap", "label": "Snap to corners and edges", "kind": "switch", "def": true, "glyph": "grid_on", "detail": "Dropped near one, a bubble settles there; off, it stays where you let go."},
            {"path": "iris.bubbles.cluster", "label": "Group into a bar", "kind": "switch", "def": true, "glyph": "view_week", "detail": "Bubbles resting in the same place share one plate and read as a small bar; off, each one floats as its own disc."},
            {"path": "iris.bubbles.attach", "label": "Keep them on the frame", "kind": "switch", "def": true, "glyph": "link", "detail": "Bubbles in a corner or on an edge sit on the shell's own edge, where they read as a swelling of it, instead of floating over your windows."},
            {"path": "iris.bubbles.join", "label": "Meet the edge", "kind": "choice", "def": "notch", "glyph": "join", "detail": "Notch: they melt into the edge with the Island's curved shoulders.", "choices": [{"label": "Notch", "value": "notch"}, {"label": "Weld", "value": "weld"}, {"label": "Gap", "value": "gap"}]}
        ] },
        { title: "Shape", rows: [
            {"path": "iris.appearance.theme.pieceShape", "label": "All shapes", "kind": "choice", "def": "circle", "glyph": "category", "choices": [{"label": "Circle", "value": "circle"}, {"label": "Squircle", "value": "squircle"}, {"label": "Square", "value": "square"}]},
            {"path": "iris.appearance.theme.linkShapes", "label": "One shape for all", "kind": "switch", "def": false, "glyph": "link", "detail": "The Island, the Dock and the bubbles share the bubbles' shape."}
        ] }
    ]
}
