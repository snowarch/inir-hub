import QtQuick
import QtQuick.Effects

// What leads a surface: the condensed face, tight, in capitals, with the soft bloom of type printed on light.
Item {
    id: root

    property alias text: word.text
    property real size: NihilStyle.textHero
    property color color: NihilStyle.ink
    property real bloom: 0.5
    property bool capitals: true
    property alias horizontalAlignment: word.horizontalAlignment
    property alias elide: word.elide
    readonly property alias paintedWidth: word.paintedWidth
    readonly property alias contentWidth: word.contentWidth

    implicitWidth: word.implicitWidth
    implicitHeight: word.implicitHeight

    Text {
        id: word
        anchors.fill: parent
        color: root.color
        verticalAlignment: Text.AlignVCenter
        font.family: NihilStyle.display
        font.pixelSize: root.size
        font.weight: NihilStyle.displayCondensed ? Font.Normal : Font.Black
        font.capitalization: root.capitals ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: NihilStyle.displayCondensed ? root.size * 0.005 : -root.size * 0.03
        font.features: { "tnum": 1 }
        lineHeight: 0.86
        visible: root.bloom <= 0
    }
    MultiEffect {
        anchors.fill: word
        visible: root.bloom > 0
        source: word
        shadowEnabled: true
        shadowColor: Qt.alpha(root.color, 0.55 * root.bloom)
        shadowBlur: 1.0
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowScale: 1.02
    }
}
