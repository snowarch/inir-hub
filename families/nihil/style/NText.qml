import QtQuick

// Text in NiHiL: Hanken Grotesk to read; `figures` for numbers that change (tabular, a touch heavier), `dots` for a
// heading or a name in Doto's round dots.
Text {
    property bool figures: false
    property bool dots: false
    font.family: dots ? NihilStyle.dots : NihilStyle.grotesk
    font.pixelSize: NihilStyle.textBody
    font.weight: dots ? Font.Normal : figures ? Font.Medium : Font.Normal
    font.features: figures ? { "tnum": 1 } : ({})
    color: NihilStyle.ink
    // The dot face is drawn by Qt itself: native hinting pulls its round dots out of line.
    renderType: dots ? Text.QtRendering : Text.NativeRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
