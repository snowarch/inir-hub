import QtQuick

// The small line over a figure: capitals, spaced, in the block's ink.
NText {
    font.pixelSize: NihilStyle.textMicro
    font.weight: Font.Bold
    font.letterSpacing: NihilStyle.s(1) * 0.7
    font.capitalization: Font.AllUppercase
}
