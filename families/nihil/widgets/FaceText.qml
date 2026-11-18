import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets

StyledText {
    id: root
    required property var face
    property real size: 13
    property int weight: Font.Medium

    // A credit (`.claude/ref/language`): a figure's name or a count, set small in mono caps, never in sentence case.
    property bool credit: false

    color: face.ink
    font.family: root.credit ? face.fontLabel : face.fontMain
    font.pixelSize: face.px(root.credit ? size * 0.84 : size)
    font.weight: weight
    font.capitalization: root.credit ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: root.credit ? face.px(size) * 0.06 : 0
    elide: Text.ElideRight
    maximumLineCount: 1
    // Whole-pixel size: a text's fractional natural size puts every neighbour after it off the pixel grid.
    width: Math.ceil(implicitWidth)
    height: root.wrapMode === Text.NoWrap ? Math.ceil(root.implicitHeight) : root.implicitHeight
    Layout.preferredWidth: Math.ceil(implicitWidth)
    Layout.preferredHeight: root.wrapMode === Text.NoWrap ? Math.ceil(root.implicitHeight) : -1
    transform: Translate { x: Math.round(root.x) - root.x; y: Math.round(root.y) - root.y }
}
