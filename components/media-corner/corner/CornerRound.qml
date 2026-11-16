import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// A round key: `solid` is the one that matters (play), the rest sit quietly on their card.
IrisButton {
    id: root
    property string glyph: ""
    property bool solid: false
    property real size: Math.round(36 * IrisStyle.density)
    readonly property color ink: root.solid ? CornerSkin.inkOnSolid : IrisStyle.text
    foreground: root.ink
    colBackground: root.solid ? CornerSkin.solid : "transparent"
    colBackgroundHover: root.solid ? Qt.tint(CornerSkin.solid, IrisStyle.fillQuiet) : IrisStyle.fillHover
    buttonRadius: root.size / 2
    buttonRadiusPressed: root.size / 2
    implicitWidth: root.size
    implicitHeight: root.size
    MaterialSymbol {
        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        iconSize: Math.round(root.size * 0.52)
        color: root.ink
    }
}
