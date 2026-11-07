import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "lock"
    name: "Lock"
    group: "System"
    glyph: "lock"
    tint: "indigo"
    show: ({"label": "Lock now", "target": "lock", "fn": "activate"})
    lead: ["iris.lock.material", "iris.lock.type.clockFont"]
    sections: [
        { title: "Scene", rows: [
            {"path": "iris.lock.material", "label": "Plates", "kind": "choice", "def": "glass", "glyph": "layers", "detail": "What the player, the field and the chips sit on.", "choices": [{"label": "Glass", "value": "glass"}, {"label": "Tint", "value": "tint"}, {"label": "Nothing", "value": "none"}]},
            {"path": "iris.lock.scene.source", "label": "Behind everything", "kind": "choice", "def": "desktop", "glyph": "wallpaper", "detail": "The desktop wallpaper, a picture of its own, or nothing but the material.", "choices": [{"label": "Wallpaper", "value": "desktop"}, {"label": "Its own", "value": "custom"}, {"label": "Material", "value": "colour"}]},
            {"path": "iris.lock.scene.blur", "label": "Blur", "kind": "range", "def": 100, "glyph": "lens_blur", "detail": "0 leaves the picture sharp.", "min": 0, "max": 100, "step": 5, "unit": " %"},
            {"path": "iris.lock.scene.dim", "label": "Dim", "kind": "range", "def": 0, "glyph": "brightness_4", "min": 0, "max": 80, "step": 5, "unit": " %"},
            {"path": "iris.lock.scene.scrim", "label": "Legibility wash", "kind": "choice", "def": "gradient", "glyph": "gradient", "detail": "What keeps white text readable over a bright picture.", "choices": [{"label": "Top and bottom", "value": "gradient"}, {"label": "Even", "value": "flat"}, {"label": "None", "value": "none"}]},
            {"path": "iris.lock.scene.motion", "label": "Slow drift", "kind": "choice", "def": "none", "glyph": "motion_photos_on", "detail": "The picture creeps and breathes instead of standing still.", "choices": [{"label": "Still", "value": "none"}, {"label": "Drift", "value": "drift"}]}
        ] },
        { title: "Clock", rows: [
            {"path": "iris.lock.type.clockFont", "label": "Clock face", "kind": "choice", "def": "numbers", "glyph": "font_download", "detail": "The typeface the hour is set in.", "choices": [{"label": "Numbers", "value": "numbers"}, {"label": "Interface", "value": "main"}, {"label": "Display", "value": "title"}]},
            {"path": "iris.lock.type.clockFormat", "label": "Clock format", "kind": "choice", "def": "auto", "glyph": "schedule", "choices": [{"label": "Follow the system", "value": "auto"}, {"label": "24 hour", "value": "24h"}, {"label": "12 hour", "value": "12h"}]},
            {"path": "iris.lock.type.seconds", "label": "Seconds", "kind": "switch", "def": false, "glyph": "timer", "detail": "Ticks every second while the screen is locked."},
            {"path": "iris.lock.type.accent", "label": "Clock colour", "kind": "choice", "def": "plain", "glyph": "format_color_fill", "choices": [{"label": "White", "value": "plain"}, {"label": "Accent", "value": "accent"}, {"label": "Highlight", "value": "highlight"}]}
        ] },
        { title: "Idle", rows: [
            {"path": "idle.screenOffTimeout", "label": "Turn the screen off after", "kind": "choice", "def": 300, "glyph": "monitor", "choices": [{"label": "Never", "value": 0}, {"label": "1 min", "value": 60}, {"label": "2 min", "value": 120}, {"label": "5 min", "value": 300}, {"label": "10 min", "value": 600}, {"label": "15 min", "value": 900}, {"label": "30 min", "value": 1800}, {"label": "1 hour", "value": 3600}]},
            {"path": "idle.lockTimeout", "label": "Lock after", "kind": "choice", "def": 600, "glyph": "lock_clock", "choices": [{"label": "Never", "value": 0}, {"label": "1 min", "value": 60}, {"label": "2 min", "value": 120}, {"label": "5 min", "value": 300}, {"label": "10 min", "value": 600}, {"label": "15 min", "value": 900}, {"label": "30 min", "value": 1800}, {"label": "1 hour", "value": 3600}]},
            {"path": "idle.suspendTimeout", "label": "Suspend after", "kind": "choice", "def": 0, "glyph": "bedtime", "choices": [{"label": "Never", "value": 0}, {"label": "1 min", "value": 60}, {"label": "2 min", "value": 120}, {"label": "5 min", "value": 300}, {"label": "10 min", "value": 600}, {"label": "15 min", "value": 900}, {"label": "30 min", "value": 1800}, {"label": "1 hour", "value": 3600}]},
            {"path": "idle.lockBeforeSleep", "label": "Lock before sleeping", "kind": "switch", "def": true, "glyph": "lock"}
        ] }
    ]
}
