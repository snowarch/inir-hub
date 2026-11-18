import QtQuick

// A quiet caption: what names a part, set small and soft.
Text {
    property bool strong: false

    color: strong ? NihilStyle.ink : NihilStyle.inkSoft
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    font.family: NihilStyle.grotesk
    font.pixelSize: NihilStyle.textSmall
    font.weight: strong ? Font.DemiBold : Font.Medium
    font.features: { "tnum": 1 }
}
