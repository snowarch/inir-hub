import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "sound"
    name: "Sound"
    group: "System"
    glyph: "volume_up"
    tint: "orange"
    lead: ["audio.protection.maxAllowed", "audio.protection.maxAllowedIncrease"]
    sections: [
        { title: "Ear protection", rows: [
            {"path": "audio.protection.enable", "label": "Ear protection", "kind": "switch", "def": true, "glyph": "hearing", "detail": "Holds back sudden jumps and keeps the volume under the limit."},
            {"path": "audio.protection.maxAllowed", "label": "Volume limit", "kind": "range", "def": 100, "glyph": "volume_up", "detail": "Above 100 % amplifies the sound and can distort it; 153 % is as far as the system mixer goes.", "min": 50, "max": 154, "step": 2, "unit": " %", "when": "audio.protection.enable"},
            {"path": "audio.protection.maxAllowedIncrease", "label": "Largest jump", "kind": "range", "def": 10, "glyph": "trending_up", "detail": "The most one change can raise the volume.", "min": 2, "max": 50, "step": 2, "unit": " %", "when": "audio.protection.enable"}
        ] }
    ]
}
