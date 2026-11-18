import QtQuick

// What leads a surface: Geist set large and tight, in the sentence's own case.
Text {
    property real size: NihilStyle.textHero
    property bool capitals: false

    color: NihilStyle.ink
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    font.family: NihilStyle.display
    font.pixelSize: size
    font.weight: size >= NihilStyle.s(40) ? Font.Medium : Font.DemiBold
    font.capitalization: capitals ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: -size * (size >= NihilStyle.s(40) ? 0.035 : 0.018)
    font.features: { "tnum": 1, "ss01": 1 }
    lineHeight: 0.95
}
