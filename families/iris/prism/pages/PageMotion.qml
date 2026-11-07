import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "motion"
    name: "Motion"
    group: "Shell"
    glyph: "animation"
    tint: "pink"
    lead: ["iris.appearance.morph", "iris.appearance.theme.curve"]
    sections: [
        { title: "Movement", rows: [
            {"path": "iris.appearance.motion", "label": "Reduce motion", "kind": "switch", "def": true, "glyph": "motion_photos_off", "detail": "Surfaces appear in place.", "invert": true},
            {"path": "iris.appearance.morph", "label": "Movement", "kind": "choice", "def": "direct", "glyph": "gesture", "detail": "How every shape iRiS grows moves.", "choices": [{"label": "Direct", "value": "direct"}, {"label": "Liquid", "value": "liquid"}, {"label": "Glide", "value": "glide"}, {"label": "Snap", "value": "snap"}, {"label": "Elastic", "value": "elastic"}]},
            {"path": "iris.appearance.theme.curve", "label": "Curve", "kind": "choice", "def": "expressive", "glyph": "show_chart", "detail": "The path a Direct shape follows as it opens or adjusts.", "choices": [{"label": "Expressive", "value": "expressive"}, {"label": "Standard", "value": "standard"}, {"label": "Gentle", "value": "gentle"}, {"label": "Swift", "value": "swift"}, {"label": "Custom", "value": "custom"}]}
        ] },
        { title: "Timing", rows: [
            {"path": "iris.appearance.theme.openTime", "label": "Open and close", "kind": "range", "def": 100, "glyph": "open_in_full", "detail": "How long a shape takes to grow out of what opened it and fold back.", "min": 40, "max": 250, "step": 5, "unit": " %"},
            {"path": "iris.appearance.theme.moveTime", "label": "Adjusting", "kind": "range", "def": 100, "glyph": "tune", "detail": "How long an open shape takes to change size, like switching pages.", "min": 40, "max": 250, "step": 5, "unit": " %"},
            {"path": "iris.appearance.theme.contentTiming", "label": "Content arrives", "kind": "range", "def": 100, "glyph": "hourglass_top", "detail": "Lower shows what is inside while the shape is still growing; higher waits until it has formed.", "min": 30, "max": 170, "step": 5, "unit": " %"}
        ] },
        { title: "Feel", rows: [
            {"path": "iris.appearance.theme.bounce", "label": "Bounce", "kind": "range", "def": 100, "glyph": "sports_basketball", "detail": "How far arrivals and moves pass their place before settling, as a share of the style's own. 0 never bounces; leaving never does.", "min": 0, "max": 200, "step": 10, "unit": " %"},
            {"path": "iris.appearance.theme.press", "label": "Press depth", "kind": "range", "def": 100, "glyph": "touch_app", "detail": "How far buttons, bubbles and the Island dip under a press.", "min": 0, "max": 200, "step": 10, "unit": " %"},
            {"path": "iris.appearance.theme.melt", "label": "Fusion", "kind": "range", "def": 0, "glyph": "join", "detail": "How deeply shapes melt where they meet.", "min": 0, "max": 200, "step": 5, "unit": " %"}
        ] }
    ]
}
