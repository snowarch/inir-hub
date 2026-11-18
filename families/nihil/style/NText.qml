import QtQuick

// Text in NiHiL: Space Grotesk to read, `mono` for figures and labels, `serif` for the one word that sets the tone.
Text {
    property bool mono: false
    property bool serif: false
    font.family: serif ? NihilStyle.serif : mono ? NihilStyle.mono : NihilStyle.grotesk
    font.pixelSize: NihilStyle.textBody
    color: NihilStyle.ink
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
