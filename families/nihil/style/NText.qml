import QtQuick

// NiHiL's type. `figures` keeps numbers in even columns.
Text {
    property bool figures: false

    color: NihilStyle.text
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    font.family: NihilStyle.fontFamily
    font.pixelSize: NihilStyle.textBody
    font.weight: Font.Normal
    font.features: figures ? { "tnum": 1 } : ({})
}
