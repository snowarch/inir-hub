import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "spotlight"
    name: "Spotlight"
    group: "Desktop"
    glyph: "search"
    tint: "orange"
    show: ({"label": "Open", "target": "search", "fn": "open"})
    lead: ["iris.palette.opens", "iris.palette.maxResults"]
    sections: [
        { title: "Spotlight", rows: [
            {"path": "iris.palette.opens", "label": "Opens as", "kind": "choice", "def": "floating", "glyph": "open_in_new", "detail": "Floating opens a sheet of its own; Island turns the Island into Spotlight.", "choices": [{"label": "Floating", "value": "floating"}, {"label": "The Island", "value": "island"}]},
            {"path": "iris.palette.width", "label": "Width", "kind": "range", "def": 640, "glyph": "width", "min": 420, "max": 900, "step": 10, "unit": " px"},
            {"path": "iris.palette.maxResults", "label": "Maximum results", "kind": "range", "def": 8, "glyph": "format_list_numbered", "min": 3, "max": 14},
            {"path": "iris.palette.clipboardResults", "label": "Entries shown", "kind": "range", "def": 8, "glyph": "content_paste", "detail": "How many recent copies Spotlight lists first; scroll or keep pressing Down to go through the whole history. Type ; to open it.", "min": 3, "max": 20},
            {"path": "iris.palette.showHints", "label": "Search mode shortcuts", "kind": "switch", "def": true, "glyph": "keyboard", "detail": "Clipboard, calculator, actions and more under the suggestions."}
        ] }
    ]
}
