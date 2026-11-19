.pragma library

// Everything a profile holds: the desktop's structure, never its look.
var keys = [
    "panel.position", "panel.visibility", "panel.overviewStyle",
    "overview.mode", "overview.background", "overview.hotCorner", "overview.hotCornerAction", "overview.superKey",
    "overview.superKeyDouble", "overview.backgroundBrightness",
    "dash.position", "dash.adjust", "dash.iconSize", "dash.showApps", "dash.isolateWorkspace", "dash.click", "dash.scroll",
    "thumbnails.position", "thumbnails.adjust", "thumbnails.scale", "thumbnails.labels", "thumbnails.closeButton",
    "stage.scale", "stage.radius", "stage.spacing", "stage.adjacent",
    "windows.iconSize", "windows.titlePosition", "windows.closeButton", "windows.middleClick", "windows.rightClick",
    "search.showEntry", "search.center", "switcher.popup", "switcher.horizontal", "switcher.vertical"
]

// Four whole desktop layouts to start from.
var list = [
    {
        id: "vertical",
        name: "Vertical",
        description: "Dash on the left, workspaces stacked on the right",
        values: {
            "dash.position": "left", "thumbnails.position": "right", "panel.position": "top",
            "panel.visibility": "always", "overview.hotCorner": "topLeft", "overview.mode": "default",
            "search.showEntry": true, "switcher.vertical": 0.95, "switcher.horizontal": 0.5
        }
    },
    {
        id: "horizontal",
        name: "Horizontal",
        description: "Dash along the bottom, workspaces in a row on top",
        values: {
            "dash.position": "bottom", "thumbnails.position": "top", "panel.position": "top",
            "panel.visibility": "always", "overview.hotCorner": "bottomEdge", "overview.mode": "default",
            "search.showEntry": true, "switcher.vertical": 0.5, "switcher.horizontal": 0.5
        }
    },
    {
        id: "corner",
        name: "Hot corner",
        description: "No panel: the top-left corner opens everything",
        values: {
            "dash.position": "left", "thumbnails.position": "right", "panel.position": "top",
            "panel.visibility": "overview", "overview.hotCorner": "topLeft", "overview.mode": "default",
            "search.showEntry": false, "switcher.vertical": 0.95, "switcher.horizontal": 0.5
        }
    },
    {
        id: "dock",
        name: "Dock",
        description: "Windows stay in place, the dash stays at the bottom",
        values: {
            "dash.position": "bottom", "thumbnails.position": "right", "panel.position": "top",
            "panel.visibility": "always", "overview.hotCorner": "none", "overview.mode": "static",
            "search.showEntry": true, "switcher.vertical": 0.95, "switcher.horizontal": 0.5
        }
    }
]
