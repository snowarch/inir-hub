import QtQuick
import QtQuick.Shapes
import qs.modules.nihil.prism.core

// A folder's sheet (the B · Carpeta study, his 11-17 pick): a round card whose top edge carries a tab on one side and a
// soft step down to the rest. The page card's sheet, a folder's back and its front are all this one shape. No outline:
// its fill alone sets it off.
Shape {
    id: root
    // The tab's width, how far the rest of the edge sits below it, the step's run and the card's round.
    property real tab: PrismTheme.dp(214)
    property real rise: PrismTheme.dp(58)
    property real slope: PrismTheme.dp(78)
    property real radius: PrismTheme.dp(30)
    // The tab at the right instead (a folder's back sheet).
    property bool onRight: false
    property color fill: PrismTheme.card
    // A picture the sheet is cut from instead of its fill (a folder's back sheet is its art): a texture provider laid
    // from the sheet's top left.
    property Item art: null

    preferredRendererType: Shape.GeometryRenderer
    ShapePath {
        fillColor: root.fill
        fillItem: root.art
        strokeColor: PrismTheme.ink
        strokeWidth: 2
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.SquareCap
        PathSvg {
            readonly property real e: 1
            readonly property real w: root.width - e
            readonly property real h: Math.max(root.height, root.rise) - e
            readonly property real k: root.rise + e
            readonly property real t: root.onRight ? root.width - root.tab : root.tab
            path: !root.onRight
                ? `M ${e} ${e} L ${t} ${e} L ${t} ${k} L ${w} ${k} L ${w} ${h} L ${e} ${h} Z`
                : `M ${e} ${k} L ${t} ${k} L ${t} ${e} L ${w} ${e} L ${w} ${h} L ${e} ${h} Z`
        }
    }
}
