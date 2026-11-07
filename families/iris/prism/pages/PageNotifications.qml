import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "notifications"
    name: "Notifications"
    group: "System"
    glyph: "notifications"
    tint: "red"
    show: ({"label": "Send a test", "target": "notifications", "fn": "test"})
    lead: ["iris.osd.style", "iris.notifications.duration"]
    sections: [
        { title: "Notifications", rows: [
            {"path": "notifications.silent", "label": "Do Not Disturb", "kind": "switch", "def": false, "glyph": "do_not_disturb_on", "detail": "Banners stay away; notifications still collect in Today."},
            {"path": "notifications.quietHours.enable", "label": "Quiet hours", "kind": "switch", "def": false, "glyph": "bedtime", "detail": "Do Not Disturb turns itself on every day between these times."},
            {"path": "iris.notifications.fullscreen", "label": "Notification banners", "kind": "switch", "def": true, "glyph": "fullscreen", "detail": "Over a fullscreen video or game."}
        ] },
        { title: "Banners", rows: [
            {"path": "iris.notifications.duration", "label": "Banner duration", "kind": "range", "def": 4000, "glyph": "timer", "detail": "How long a notification stays when the app does not choose.", "min": 2000, "max": 12000, "step": 500, "unit": " s", "scale": 0.001},
            {"path": "iris.notifications.width", "label": "Width", "kind": "range", "def": 380, "glyph": "width", "min": 340, "max": 560, "step": 10, "unit": " px"}
        ] },
        { title: "Levels", rows: [
            {"path": "iris.osd.levels", "label": "Volume, brightness and mic", "kind": "choice", "def": "yours", "glyph": "volume_up", "detail": "When the Island shows a change of volume, brightness or mic.", "choices": [{"label": "Yours", "value": "yours"}, {"label": "Every change", "value": "every"}, {"label": "Never", "value": "off"}]},
            {"path": "iris.osd.media", "label": "Song changes", "kind": "choice", "def": "yours", "glyph": "music_note", "detail": "When the Island shows the song.", "choices": [{"label": "Yours", "value": "yours"}, {"label": "Every change", "value": "every"}, {"label": "Never", "value": "off"}]},
            {"path": "iris.osd.style", "label": "Level style", "kind": "choice", "def": "capsule", "glyph": "linear_scale", "detail": "How a level shows in its pill.", "choices": [{"label": "Capsule", "value": "capsule"}, {"label": "Bar", "value": "bar"}, {"label": "Minimal", "value": "minimal"}]},
            {"path": "iris.osd.position", "label": "OSD position", "kind": "choice", "def": "bottom", "glyph": "vertical_align_bottom", "detail": "Where the level pill shows when the Island is not there to answer, like over a fullscreen game.", "choices": [{"label": "Bottom", "value": "bottom"}, {"label": "Top", "value": "top"}]},
            {"path": "iris.osd.keyboard", "label": "Keyboard layout and locks", "kind": "switch", "def": true, "glyph": "keyboard"},
            {"path": "iris.osd.figure", "label": "Show the percentage", "kind": "switch", "def": true, "glyph": "percent"}
        ] }
    ]
}
