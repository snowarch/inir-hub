import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "dock"
    name: "Dock"
    group: "Desktop"
    glyph: "dock_to_bottom"
    tint: "blue"
    lead: ["iris.dock.position", "iris.dock.shape"]
    sections: [
        { title: "Dock", rows: [
            {"path": "iris.dock.enable", "label": "Show dock", "kind": "switch", "def": true, "glyph": "dock_to_bottom"},
            {"path": "iris.dock.autoHide", "label": "Automatically hide", "kind": "switch", "def": true, "glyph": "visibility", "detail": "Rest the pointer at the screen edge to reveal it."},
            {"path": "iris.dock.revealOnEmpty", "label": "Stay visible on empty workspaces", "kind": "switch", "def": true, "glyph": "desktop_windows"}
        ] },
        { title: "Icons", rows: [
            {"path": "iris.dock.iconSize", "label": "Icon size", "kind": "range", "def": 40, "glyph": "apps", "min": 28, "max": 64, "unit": " px"},
            {"path": "iris.dock.magnification", "label": "Magnify on hover", "kind": "switch", "def": false, "glyph": "zoom_in"},
            {"path": "iris.dock.magnifySize", "label": "Magnification", "kind": "range", "def": 150, "glyph": "zoom_out_map", "detail": "How large the icon under the pointer grows; its neighbours follow.", "min": 110, "max": 200, "step": 5, "unit": " %", "when": "iris.dock.magnification"},
            {"path": "iris.dock.badges", "label": "Notification badges", "kind": "switch", "def": true, "glyph": "looks_one"},
            {"path": "iris.dock.launcher", "label": "Applications button", "kind": "switch", "def": true, "glyph": "grid_view", "detail": "Opens Spotlight from the start of the Dock."}
        ] },
        { title: "Order", rows: [
            {"path": "iris.dock.arrange", "label": "Open apps", "kind": "choice", "def": "pinned", "glyph": "reorder", "detail": "Where open apps sit in the dock.", "choices": [{"label": "Keep pinned place", "value": "pinned"}, {"label": "In opening order", "value": "opened"}]},
            {"path": "iris.dock.reorder", "label": "Drag to reorder", "kind": "switch", "def": true, "glyph": "drag_indicator", "detail": "Slide an icon along the Dock to move it."}
        ] },
        { title: "Shape", rows: [
            {"path": "iris.dock.position", "label": "Screen edge", "kind": "choice", "def": "auto", "glyph": "vertical_align_bottom", "detail": "Auto keeps the Dock on the edge opposite the Island.", "choices": [{"label": "Auto", "value": "auto"}, {"label": "Bottom", "value": "bottom"}, {"label": "Top", "value": "top"}, {"label": "Left", "value": "left"}, {"label": "Right", "value": "right"}]},
            {"path": "iris.dock.shape", "label": "Dock shape", "kind": "choice", "def": "auto", "glyph": "rounded_corner", "choices": [{"label": "Auto", "value": "auto"}, {"label": "Round", "value": "round"}, {"label": "Squircle", "value": "squircle"}, {"label": "Square", "value": "square"}]},
            {"path": "iris.dock.material", "label": "Material", "kind": "choice", "def": "inherit", "glyph": "layers", "detail": "What this surface is made of.", "choices": [{"label": "iRiS", "value": "inherit"}, {"label": "Solid", "value": "solid"}, {"label": "Glass", "value": "glass"}, {"label": "Blur (beta)", "value": "blur"}]},
            {"path": "iris.dock.notch", "label": "Dock notch", "kind": "switch", "def": true, "glyph": "crop_7_5", "detail": "The Dock melts into its screen edge like the Island's notch."}
        ] }
    ]
}
