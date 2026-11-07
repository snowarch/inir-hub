import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "display"
    name: "Display"
    group: "System"
    glyph: "desktop_windows"
    tint: "amber"
    lead: ["light.night.colorTemperature", "light.night.automatic"]
    sections: [
        { title: "Night Light", rows: [
            {"path": "light.night.automatic", "label": "On a schedule", "kind": "switch", "def": false, "glyph": "schedule", "detail": "Warmer colours in the evening, back to normal in the morning."},
            {"path": "light.night.enabled", "label": "Night Light now", "kind": "switch", "def": false, "glyph": "nightlight", "when": "!light.night.automatic"},
            {"path": "light.night.colorTemperature", "label": "Warmth", "kind": "range", "def": 6000, "glyph": "thermostat", "detail": "Lower is warmer.", "min": 2500, "max": 6500, "step": 100, "unit": " K"}
        ] },
        { title: "Comfort", rows: [
            {"path": "light.antiFlashbang.enable", "label": "Soften bright flashes", "kind": "switch", "def": false, "glyph": "flash_off", "detail": "Dims the screen when a mostly white window suddenly fills it."}
        ] }
    ]
}
