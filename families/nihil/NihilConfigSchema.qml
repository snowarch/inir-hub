import QtQuick
import Quickshell.Io

// NiHiL's part of the shell config (`nihil.*` in config.json): Config holds it in its `nihil` slot once this plugin is
// installed (plugin.json `configKey`).
JsonObject {
    property JsonObject settings: JsonObject {
        // Settings in Material's full window instead of NiHiL's own menu.
        property bool useMaterial: false
    }
    property JsonObject theme: JsonObject {
        // "signal": the red of a glyph light; "dynamic": the wallpaper's own colour at the same strength.
        property string accent: "signal"
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
