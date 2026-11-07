import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "bar"
    name: "Island"
    group: "Desktop"
    glyph: "smart_button"
    tint: "indigo"
    lead: ["iris.bar.design", "iris.bar.position"]
    sections: [
        { title: "Island", rows: [
            {"path": "iris.bar.position", "label": "Screen edge", "kind": "choice", "def": "top", "glyph": "vertical_align_top", "choices": [{"label": "Top", "value": "top"}, {"label": "Bottom", "value": "bottom"}, {"label": "Left", "value": "left"}, {"label": "Right", "value": "right"}]},
            {"path": "iris.bar.composition", "label": "Composition", "kind": "choice", "def": "cluster", "glyph": "view_week", "detail": "How the Island holds media and controls.", "choices": [{"label": "Unified", "value": "unified"}, {"label": "Cluster", "value": "cluster"}]},
            {"path": "iris.bar.design", "label": "Island design", "kind": "choice", "def": "halo", "glyph": "design_services", "detail": "How the resting Island shows the time.", "choices": [{"label": "Halo", "value": "halo"}, {"label": "Ledger", "value": "ledger"}, {"label": "Tiles", "value": "tiles"}, {"label": "Dial", "value": "dial"}, {"label": "Marquee", "value": "marquee"}, {"label": "Duo", "value": "duo"}, {"label": "Headline", "value": "headline"}, {"label": "Rings", "value": "rings"}, {"label": "Aura", "value": "aura"}, {"label": "Status", "value": "status"}, {"label": "Forecast", "value": "forecast"}, {"label": "World", "value": "world"}, {"label": "Comet", "value": "comet"}, {"label": "Lumen", "value": "lumen"}]},
            {"path": "iris.bar.notch", "label": "Notch", "kind": "switch", "def": true, "glyph": "crop_7_5", "detail": "The Island melts into the screen edge, like the notch it grows from."}
        ] },
        { title: "Clock", rows: [
            {"path": "iris.bar.clockStyle", "label": "Clock", "kind": "choice", "def": "dateTime", "glyph": "schedule", "detail": "What the resting Island shows beside the time.", "choices": [{"label": "Time", "value": "time"}, {"label": "Date", "value": "dateTime"}, {"label": "Weather", "value": "weather"}]},
            {"path": "iris.bar.clockScale", "label": "Clock size", "kind": "range", "def": 100, "glyph": "text_fields", "detail": "The time and date on the resting Island.", "min": 80, "max": 150, "step": 5, "unit": " %"},
            {"path": "iris.bar.clockAccent", "label": "Clock accent", "kind": "choice", "def": "highlight", "glyph": "format_color_fill", "detail": "The colour of the time's separator and the day number on the resting Island.", "choices": [{"label": "Highlight", "value": "highlight"}, {"label": "Accent", "value": "accent"}, {"label": "Plain", "value": "plain"}]}
        ] },
        { title: "Size", rows: [
            {"path": "iris.bar.padding", "label": "Breathing room", "kind": "range", "def": 100, "glyph": "padding", "detail": "Space around what the resting Island shows.", "min": 50, "max": 250, "step": 10, "unit": " %"},
            {"path": "iris.bar.height", "label": "Height", "kind": "range", "def": 42, "glyph": "height", "detail": "The resting Island, and how deep its notch melts into the edge.", "min": 32, "max": 64, "unit": " px"}
        ] },
        { title: "Behaviour", rows: [
            {"path": "iris.bar.hoverExpand", "label": "Expand on hover", "kind": "switch", "def": true, "glyph": "unfold_more", "detail": "The pointer has to rest on the Island; passing over it does nothing. A full-width Island always opens on a click instead."},
            {"path": "iris.bar.hoverDelay", "label": "Hover delay", "kind": "range", "def": 300, "glyph": "timer", "min": 120, "max": 800, "step": 20, "unit": " ms", "when": "iris.bar.hoverExpand"},
            {"path": "iris.bar.scrollAction", "label": "Scroll on the Island", "kind": "choice", "def": "volume", "glyph": "swipe_vertical", "detail": "On the resting Island: Shift swaps volume and brightness; Ctrl adjusts the microphone.", "choices": [{"label": "Volume", "value": "volume"}, {"label": "Brightness", "value": "brightness"}, {"label": "Off", "value": "none"}]},
            {"path": "iris.bar.autoHide", "label": "Automatically hide", "kind": "switch", "def": false, "glyph": "visibility", "detail": "The Island tucks into its edge and comes back when you rest the pointer there."},
            {"path": "iris.bar.reserveSpace", "label": "Reserve space for windows", "kind": "switch", "def": true, "glyph": "space_bar", "detail": "Bubbles on the same edge reserve their own room."}
        ] },
        { title: "Events", rows: [
            {"path": "iris.bar.events", "label": "System events", "kind": "switch", "def": true, "glyph": "campaign", "detail": "The Island says by itself what just happened, for a moment: a connection, a timer, a screenshot, Do Not Disturb."},
            {"path": "iris.bar.notices.seconds", "label": "Stays for", "kind": "range", "def": 2.5, "glyph": "hourglass_bottom", "detail": "How long a notice holds the Island.", "min": 1.5, "max": 8, "step": 0.5, "unit": " s", "when": "iris.bar.events"}
        ] },
        { title: "Bubbles", rows: [
            {"path": "iris.bar.trailing", "label": "Trailing bubble", "kind": "choice", "def": "controls", "glyph": "radio_button_checked", "detail": "The bubble beside a Cluster Island.", "choices": [{"label": "Controls", "value": "controls"}, {"label": "Notifications", "value": "notifications"}, {"label": "Weather", "value": "weather"}, {"label": "Sound", "value": "sound"}, {"label": "Microphone", "value": "mic"}, {"label": "None", "value": "none"}]},
            {"path": "iris.bar.auxiliary", "label": "Utility island", "kind": "choice", "def": "tray", "glyph": "apps", "detail": "Emerges beside the Island; the tray hides when no apps are present.", "choices": [{"label": "Tray", "value": "tray"}, {"label": "Timers", "value": "tools"}, {"label": "Sound", "value": "sound"}, {"label": "Microphone", "value": "mic"}, {"label": "None", "value": "none"}]},
            {"path": "iris.bar.sunLight", "label": "Sunlight", "kind": "switch", "def": true, "glyph": "wb_sunny", "detail": "By day, the Island's foot glows where the sun stands."}
        ] }
    ]
}
