import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "orbit"
    name: "Orbit"
    group: "Desktop"
    glyph: "grid_view"
    tint: "violet"
    show: ({"label": "Open", "target": "orbit", "fn": "open"})
    lead: ["iris.orbit.opens", "iris.orbit.titles"]
    sections: [
        { title: "Orbit", rows: [
            {"path": "iris.orbit.enable", "label": "Orbit", "kind": "switch", "def": false, "glyph": "grid_view", "detail": "Every workspace with its windows where they are, and a search that finds any of them."},
            {"path": "iris.orbit.opens", "label": "Opens as", "kind": "choice", "def": "island", "glyph": "open_in_new", "detail": "The Island grows into it, or a sheet opens under the Island.", "choices": [{"label": "The Island", "value": "island"}, {"label": "A sheet", "value": "floating"}]},
            {"path": "iris.orbit.hotCorner", "label": "Hot corner", "kind": "switch", "def": true, "glyph": "north_west", "detail": "Rest the pointer in a corner of the screen and Orbit opens."},
            {"path": "iris.orbit.hotCornerDelay", "label": "Wait before opening", "kind": "range", "def": 150, "glyph": "timer", "detail": "How long the pointer rests in the corner.", "min": 0, "max": 600, "step": 10, "unit": " ms", "when": "iris.orbit.hotCorner"},
            {"path": "iris.orbit.closeOnGo", "label": "Close after going", "kind": "switch", "def": true, "glyph": "close", "detail": "Off keeps Orbit open after you pick a window."},
            {"path": "iris.orbit.keys", "label": "Arrow keys", "kind": "choice", "def": "niri", "glyph": "keyboard", "detail": "Niri: up and down change workspace, left and right change window.", "choices": [{"label": "Niri", "value": "niri"}, {"label": "Swapped", "value": "swapped"}]}
        ] },
        { title: "Workspaces", rows: [
            {"path": "iris.orbit.previews", "label": "Window pictures", "kind": "switch", "def": true, "glyph": "image", "detail": "What each window looks like, from Niri's own screenshot of it. Off shows app icons and takes no screenshots."},
            {"path": "iris.orbit.wallpaper", "label": "Wallpaper on the workspaces", "kind": "switch", "def": true, "glyph": "wallpaper"},
            {"path": "iris.orbit.titles", "label": "Window titles", "kind": "choice", "def": "hover", "glyph": "title", "detail": "On the window under the cursor, on every window, or never.", "choices": [{"label": "Under the cursor", "value": "hover"}, {"label": "Always", "value": "always"}, {"label": "Never", "value": "off"}]},
            {"path": "iris.orbit.labels", "label": "Workspace names", "kind": "choice", "def": "full", "glyph": "label", "choices": [{"label": "Number and name", "value": "full"}, {"label": "Number only", "value": "number"}]},
            {"path": "iris.orbit.peek", "label": "Neighbours", "kind": "range", "def": 56, "glyph": "view_carousel", "detail": "How much of the workspaces above and below shows.", "min": 0, "max": 140, "step": 4, "unit": " px"}
        ] }
    ]
}
