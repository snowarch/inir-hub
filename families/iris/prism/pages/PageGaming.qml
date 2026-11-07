import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "gaming"
    name: "Gaming"
    group: "System"
    glyph: "sports_esports"
    tint: "teal"
    lead: ["gameMode.autoDetect", "gameMode.disableAnimations"]
    sections: [
        { title: "Game mode", rows: [
            {"path": "gameMode.autoDetect", "label": "Turn on for fullscreen apps", "kind": "switch", "def": true, "glyph": "sports_esports", "detail": "Game mode starts by itself while a window is fullscreen and ends when it leaves."},
            {"path": "gameMode.disableAnimations", "label": "Stop shell animations", "kind": "switch", "def": false, "glyph": "animation", "detail": "iRiS shapes appear in place while you play."},
            {"path": "gameMode.disableEffects", "label": "Stop glass and blur", "kind": "switch", "def": false, "glyph": "blur_off"},
            {"path": "gameMode.suppressNotifications", "label": "Hold notifications", "kind": "switch", "def": true, "glyph": "notifications_paused", "detail": "Banners wait until you are done; they still collect in Today."},
            {"path": "gameMode.disableNiriAnimations", "label": "Stop Niri animations", "kind": "switch", "def": false, "glyph": "motion_photos_off"},
            {"path": "gameMode.disableVisualizers", "label": "Stop audio visualizers", "kind": "switch", "def": true, "glyph": "graphic_eq"}
        ] }
    ]
}
