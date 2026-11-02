import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// A die (型抜き): the closed set of shapes AIRISU rules, built from straight lines and compass arcs on the module. `kind`
// "rect" · "round" (the shell's one form, IrisStyle.outline) · "tab" (an index tab standing on the top edge: `tabX`, `tabWidth`, `tabHeight`) · "ticket" (half moons punched in both sides at
// `notchY`). A stroke is laid inside the die so a 1 px rule lands on a whole pixel; `dashed` draws an inactive die.
// `texture` fills the die with a texture provider of the die's own size (a frosted piece of the scene) instead of `fill`.
Item {
    id: root
    property string kind: "rect"
    property color fill: "transparent"
    property color stroke: "transparent"
    property real strokeWidth: 0
    property bool dashed: false
    property real radius: IrisStyle.formOf(Math.min(root.width, root.height))
    property real tabX: 0
    property real tabWidth: 3 * Airisu.m
    property real tabHeight: Airisu.m
    property real notchY: root.height / 2
    property real notchRadius: Airisu.m
    property Item texture: null

    readonly property real s: root.strokeWidth > 0 ? root.strokeWidth / 2 : 0
    readonly property real rise: root.kind === "tab" ? root.tabHeight : 0
    readonly property real l: root.s
    readonly property real t: root.rise + root.s
    readonly property real r: root.width - root.s
    readonly property real b: root.height - root.s
    readonly property real n: root.kind === "ticket" ? Math.min(root.notchRadius, (root.b - root.t) / 3) : 0

    Shape {
        anchors.fill: parent
        visible: root.kind === "round"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.fill
            fillItem: root.texture
            strokeColor: root.strokeWidth > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeWidth
            strokeStyle: root.dashed ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [2, 2]
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.FlatCap
            PathPolyline { path: root.kind === "round" ? IrisStyle.outline(root.width, root.height, root.radius, root.s) : [] }
        }
    }
    Shape {
        anchors.fill: parent
        visible: root.kind !== "round"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.fill
            fillItem: root.texture
            strokeColor: root.strokeWidth > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeWidth
            strokeStyle: root.dashed ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [2, 2]
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap
            startX: root.l; startY: root.t
            // The tab rises from the top edge, square, before the edge runs on.
            PathLine { x: root.kind === "tab" ? root.l + root.tabX : root.l; y: root.t }
            PathLine { x: root.kind === "tab" ? root.l + root.tabX : root.l; y: root.kind === "tab" ? root.s : root.t }
            PathLine { x: root.kind === "tab" ? root.l + root.tabX + root.tabWidth : root.l; y: root.kind === "tab" ? root.s : root.t }
            PathLine { x: root.kind === "tab" ? root.l + root.tabX + root.tabWidth : root.l; y: root.t }
            PathLine { x: root.r; y: root.t }
            // The ticket's half moon on the right side, punched inward.
            PathLine { x: root.r; y: root.kind === "ticket" ? root.notchY - root.n : root.t }
            PathArc {
                x: root.r; y: root.kind === "ticket" ? root.notchY + root.n : root.t
                radiusX: root.n; radiusY: root.n
                direction: PathArc.Counterclockwise
            }
            PathLine { x: root.r; y: root.b }
            PathLine { x: root.l; y: root.b }
            PathLine { x: root.l; y: root.kind === "ticket" ? root.notchY + root.n : root.b }
            PathArc {
                x: root.l; y: root.kind === "ticket" ? root.notchY - root.n : root.b
                radiusX: root.n; radiusY: root.n
                direction: PathArc.Counterclockwise
            }
            PathLine { x: root.l; y: root.t }
        }
    }
}
