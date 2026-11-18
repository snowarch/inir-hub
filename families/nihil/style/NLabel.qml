import QtQuick

// A label in small tracked capitals: what names a part, never what it says.
Text {
    property bool strong: false

    color: strong ? NihilStyle.ink : NihilStyle.inkSoft
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    font.family: NihilStyle.grotesk
    font.pixelSize: NihilStyle.textLabel
    font.weight: Font.DemiBold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: NihilStyle.labelTracking
    font.features: { "tnum": 1 }
}
