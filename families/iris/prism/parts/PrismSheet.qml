import QtQuick
import QtQuick.Shapes
import qs.modules.iris.prism.core

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

    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: root.fill
        fillItem: root.art
        strokeColor: "transparent"
        strokeWidth: -1
        PathSvg {
            readonly property real w: root.width
            readonly property real h: Math.max(root.height, root.rise + root.radius * 2)
            readonly property real r: root.radius
            readonly property real rr: Math.min(root.radius, root.rise + 2)
            readonly property real k: root.rise
            readonly property real s: root.slope
            readonly property real t: root.onRight ? root.width - root.tab : root.tab
            path: !root.onRight
                ? `M 0 ${rr} Q 0 0 ${rr} 0 L ${t - s * 0.15} 0 C ${t + s * 0.35} 0 ${t + s * 0.45} ${k} ${t + s} ${k} `
                    + `L ${w - r} ${k} Q ${w} ${k} ${w} ${k + r} L ${w} ${h - r} Q ${w} ${h} ${w - r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h - r} Z`
                : `M 0 ${k + r} Q 0 ${k} ${r} ${k} L ${t - s} ${k} C ${t - s * 0.45} ${k} ${t - s * 0.35} 0 ${t + s * 0.15} 0 `
                    + `L ${w - rr} 0 Q ${w} 0 ${w} ${rr} L ${w} ${h - r} Q ${w} ${h} ${w - r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h - r} Z`
        }
    }
}
