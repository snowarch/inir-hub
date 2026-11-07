import QtQuick
import qs.modules.iris.prism.core

// Prism's text: its face, its ink and a size from the ladder.
Text {
    property bool mono: false
    property bool figures: false
    color: PrismTheme.ink
    font.family: mono ? PrismTheme.fontMono : figures ? PrismTheme.fontNumbers : PrismTheme.fontMain
    font.pixelSize: PrismTheme.body
    font.features: figures ? { "tnum": 1 } : {}
    elide: Text.ElideRight
    maximumLineCount: 1
    verticalAlignment: Text.AlignVCenter
}
