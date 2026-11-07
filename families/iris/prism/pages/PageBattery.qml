import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "battery"
    name: "Battery"
    group: "System"
    glyph: "battery_full"
    tint: "green"
    needs: "battery"
    lead: ["battery.low", "battery.critical"]
    sections: [
        { title: "Battery", rows: [
            {"path": "battery.low", "label": "Low battery", "kind": "range", "def": 20, "glyph": "battery_3_bar", "min": 5, "max": 50, "step": 5, "unit": " %"},
            {"path": "battery.critical", "label": "Critical battery", "kind": "range", "def": 5, "glyph": "battery_alert", "min": 1, "max": 20, "unit": " %"},
            {"path": "battery.automaticSuspend", "label": "Suspend when almost empty", "kind": "switch", "def": false, "glyph": "power_settings_new"}
        ] },
        { title: "Charging", rows: [
            {"path": "battery.chargeLimit.enable", "label": "Limit charging", "kind": "switch", "def": false, "glyph": "battery_charging_full", "detail": "Stops charging early so the battery ages slower."},
            {"path": "battery.chargeLimit.threshold", "label": "Stop at", "kind": "range", "def": 80, "glyph": "battery_5_bar", "min": 50, "max": 100, "step": 5, "unit": " %", "when": "battery.chargeLimit.enable"}
        ] }
    ]
}
