import QtQuick

// NiHiL's type. `figures` keeps numbers in even columns.
Text {
    property bool figures: false

    color: NihilStyle.ink
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    font.family: NihilStyle.grotesk
    font.pixelSize: NihilStyle.textBody
    font.weight: Font.Normal
    font.features: figures ? { "tnum": 1 } : ({})
}
