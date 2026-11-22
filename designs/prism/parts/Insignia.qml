import QtQuick
import QtQuick.Shapes
import qs.modules.iris.style

// The Prism insignia: one prism, its corners rounded, lit through with the spectrum from its lower left to its upper
// right (IrisStyle.prismStops, the shell's one). A single solid shape, nothing around it (his 11-21: the beam and fan
// round a stroked triangle read as a scribble in the Dock), so it reads the same at a Dock's size and at a page's. A
// host that asks for a colour other than the accent (a lit tile's ink) gets the prism in that colour.
Item {
    id: root
    property Item host: null
    property color ink: !root.host || Qt.colorEqual(root.host.color, IrisStyle.accent) ? IrisStyle.text : root.host.color
    readonly property bool mono: !!root.host && !Qt.colorEqual(root.host.color, IrisStyle.accent)
    readonly property var stops: IrisStyle.prismStops
    function tone(index: int): color { return root.mono ? root.ink : root.stops[index] }

    // An even triangle on a 100-unit grid, its point up, its corners round; the shape sits centred in the box.
    readonly property real side: 96
    readonly property real tall: root.side * Math.sqrt(3) / 2
    readonly property real corner: 13
    // How far each corner's curve starts from the point it rounds (the corner's radius over tan 30°).
    readonly property real cut: root.corner * Math.sqrt(3)
    // The rounded shape stands from the top curve's crest to the base: centre that span.
    readonly property real apex: 50 - (root.tall - root.corner) / 2 - root.corner
    readonly property point a: Qt.point(50, root.apex)
    readonly property point b: Qt.point(50 + root.side / 2, root.apex + root.tall)
    readonly property point c: Qt.point(50 - root.side / 2, root.apex + root.tall)
    function toward(from: point, to: point, by: real): point {
        const len = Math.hypot(to.x - from.x, to.y - from.y)
        return Qt.point(from.x + (to.x - from.x) * by / len, from.y + (to.y - from.y) * by / len)
    }
    readonly property point ab: root.toward(root.a, root.b, root.cut)
    readonly property point ba: root.toward(root.b, root.a, root.cut)
    readonly property point bc: root.toward(root.b, root.c, root.cut)
    readonly property point cb: root.toward(root.c, root.b, root.cut)
    readonly property point ca: root.toward(root.c, root.a, root.cut)
    readonly property point ac: root.toward(root.a, root.c, root.cut)

    Shape {
        width: 100
        height: 100
        anchors.centerIn: parent
        scale: Math.min(root.width, root.height) / 100
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: root.c.x; y1: root.c.y
                x2: root.b.x; y2: root.a.y
                GradientStop { position: 0; color: root.tone(0) }
                GradientStop { position: 1 / 6; color: root.tone(1) }
                GradientStop { position: 2 / 6; color: root.tone(2) }
                GradientStop { position: 3 / 6; color: root.tone(3) }
                GradientStop { position: 4 / 6; color: root.tone(4) }
                GradientStop { position: 5 / 6; color: root.tone(5) }
                GradientStop { position: 1; color: root.tone(6) }
            }
            startX: root.ab.x; startY: root.ab.y
            PathLine { x: root.ba.x; y: root.ba.y }
            PathArc { x: root.bc.x; y: root.bc.y; radiusX: root.corner; radiusY: root.corner }
            PathLine { x: root.cb.x; y: root.cb.y }
            PathArc { x: root.ca.x; y: root.ca.y; radiusX: root.corner; radiusY: root.corner }
            PathLine { x: root.ac.x; y: root.ac.y }
            PathArc { x: root.ab.x; y: root.ab.y; radiusX: root.corner; radiusY: root.corner }
        }
    }
}
