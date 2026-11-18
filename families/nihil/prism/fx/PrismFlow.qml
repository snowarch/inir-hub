import QtQuick
import qs.modules.nihil.prism.core
import qs.modules.nihil.style
import qs.modules.nihil.components

// Prism's art, printed: paper under a sparse screen of ink dots, so words set on it still read.
Item {
    id: root
    property string tint: "blue"
    property real seed: 0
    property point centre: Qt.point(0.62, 0.5)
    property real thickness: 0.42
    property real radius: 0
    property real topLeftRadius: root.radius
    property real topRightRadius: root.radius
    property real bottomRightRadius: root.radius
    property real bottomLeftRadius: root.radius
    property bool dark: !PrismTheme.light
    property bool bare: false
    property real fade: 1
    property real side: 0
    property vector4d cut: Qt.vector4d(0, 0, 0, 0)
    property real strength: 1
    property real mute: 0
    property color frostColour: "transparent"
    property int turn: 0

    Rectangle { anchors.fill: parent; color: PrismTheme.card }
    IrisDither { anchors.fill: parent; ink: IrisStyle.text; level: 0.14 }
}
