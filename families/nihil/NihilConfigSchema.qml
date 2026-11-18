import QtQuick
import Quickshell.Io

// NiHiL's part of the shell config (`nihil.*` in config.json): Config holds it in its `nihil` slot once this plugin is
// installed (plugin.json `configKey`).
JsonObject {
    property JsonObject settings: JsonObject {
        // The wallpaper, dimmed, behind the Settings window's pieces.
        property bool backdrop: true
    }
    property JsonObject theme: JsonObject {
        // "signal": the red of a glyph light; "dynamic" and "tertiary": the wallpaper's first and second colours;
        // "custom": the hue below; "ink": no colour, what is on inverts.
        property string accent: "signal"
        property real hue: 0
        // 0.4 to 1: how strong the signal is.
        property real vividness: 1
        // "quiet": only what is on; "balanced": levels and meters too; "vivid": titles too.
        property string reach: "balanced"
        // 0 to 0.35: the wallpaper's hue in the grey pieces.
        property real tint: 0
        // 0.55 to 1: how solid the outer pieces are.
        property real opacity: 1
        // 0.35 to 1.25: how round every piece is.
        property real corners: 1
        // "tile" (square-cornered blocks) or "round" (pills and circles).
        property string keys: "tile"
        // "round" or "square".
        property string dotShape: "round"
        // "grotesk" or "mono".
        property string font: "grotesk"
        // "full", "calm" or "off".
        property string motion: "full"
        property real scale: 1
    }
    property JsonObject widgets: JsonObject {
        // "nihil" faces, or "material" (each widget's own style), "instrument" or "readout".
        property string design: "nihil"
    }
    property JsonObject bar: JsonObject {
        property bool bottom: true
        // Hide the bar until the pointer reaches its edge.
        property bool autoHide: false
        property list<string> screenList: []
        // App icons drawn in ink, one glyph language with the rest of the bar.
        property bool monochromeIcons: true
        property bool showSearch: true
        property bool showApps: true
    }
    property JsonObject clock: JsonObject {
        // "dots": a dot each; "fused": dots run together along each row.
        property string style: "dots"
        // Hours in the signal colour, minutes in ink.
        property bool twoTone: true
    }
    property JsonObject power: JsonObject {
        // The greeting over the power menu; empty uses the account's name.
        property string greeting: ""
    }
    property JsonObject lock: JsonObject {
        property bool blur: true
    }
}
