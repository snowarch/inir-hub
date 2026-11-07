import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "general"
    name: "Home"
    group: "Shell"
    glyph: "home"
    tint: "blue"
    lead: ["panelFamily", "time.format"]
    sections: [
        { title: "Shell", rows: [
            {"path": "panelFamily", "label": "Family", "kind": "choice", "def": "ii", "glyph": "style", "detail": "The whole shell's look.", "choices": [{"label": "iRiS", "value": "iris"}, {"label": "Material", "value": "ii"}, {"label": "Windows 11", "value": "waffle"}]},
            {"path": "familyTransitionAnimation", "label": "Animated switch", "kind": "switch", "def": true, "glyph": "swap_horiz", "detail": "A short transition while the families swap, instead of a cut."},
            {"path": "performance.lowPower", "label": "Low power", "kind": "switch", "def": false, "glyph": "energy_savings_leaf", "detail": "Turns glass, blur and heavy wallpaper effects off everywhere."}
        ] },
        { title: "Clock", rows: [
            {"path": "time.format", "label": "Clock", "kind": "choice", "def": "hh:mm", "glyph": "schedule", "detail": "The Island, the lock screen and every clock in iRiS.", "choices": [{"label": "24-hour", "value": "hh:mm"}, {"label": "12-hour", "value": "h:mm ap"}, {"label": "12-hour AM/PM", "value": "h:mm AP"}]},
            {"path": "time.secondPrecision", "label": "Exact seconds", "kind": "switch", "def": false, "glyph": "timer", "detail": "Clocks that show seconds tick on the second."}
        ] },
        { title: "Settings window", rows: [
            {"path": "settingsDesign", "label": "Layout", "kind": "designs", "def": "prism", "glyph": "settings_applications", "detail": "How Settings lays out its areas.", "choices": [{"label": "Prism", "value": "prism"}, {"label": "Classic", "value": "classic"}, {"label": "Folio", "value": "folio"}, {"label": "Pocket", "value": "pocket"}, {"label": "Drawer", "value": "drawer"}, {"label": "v2.33", "value": "original"}]}
        ] },
        { title: "Apps", rows: [
            {"path": "apps.terminal", "label": "Terminal", "kind": "text", "def": "kitty", "glyph": "terminal", "detail": "Where Spotlight's commands, package installs and anime playback open."}
        ] }
    ]
}
