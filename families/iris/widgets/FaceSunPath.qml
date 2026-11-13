import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions

// The sun's path through the day: altitude as a cosine around solar noon, crossing the horizon at sunrise and sunset.
// An Item around the Shape: a Shape sizes itself from its paths, and these paths come from its size. Shared by the
// Day's faces: `face` gives the day's shares (`sunrise`, `sunset`, `fraction`, 0..1 of the day) and the
// face's colours.
Item {
    id: path
    required property var face
    readonly property real pad: path.face.dp(6)
    readonly property real noon: (path.face.sunrise + path.face.sunset) / 2
    readonly property real c: Math.cos(Math.PI * (path.face.sunset - path.face.sunrise))
    readonly property real amp: (path.height - path.pad * 2) / 2
    readonly property real horizon: path.pad + path.amp * (1 - path.c)
    function yAt(t: real): real { return path.horizon - (Math.cos(2 * Math.PI * (t - path.noon)) - path.c) * path.amp }
    function trace(from: real, to: real): var {
        const steps = Math.max(2, Math.ceil((to - from) * 64))
        const points = []
        for (let i = 0; i <= steps; i++) {
            const t = from + (to - from) * i / steps
            points.push(Qt.point(t * path.width, path.yAt(t)))
        }
        return points
    }
    function svg(points: var, closed: bool): string {
        if (points.length === 0)
            return ""
        let d = "M " + points[0].x + " " + points[0].y
        for (let i = 1; i < points.length; i++)
            d += " L " + points[i].x + " " + points[i].y
        return closed ? d + " Z" : d
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: path.pad; x2: 0; y2: path.horizon
                GradientStop { position: 0; color: ColorUtils.applyAlpha(path.face.warm, 0.26) } // iris-literal: daylight fades from 26 % at noon to nothing at the horizon
                GradientStop { position: 1; color: ColorUtils.applyAlpha(path.face.warm, 0) }
            }
            PathSvg { path: path.width > 0 ? path.svg(path.trace(path.face.sunrise, path.face.sunset), true) : "" }
        }
        ShapePath {
            strokeColor: path.face.fillActive
            strokeWidth: path.face.dp(2)
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathSvg { path: path.width > 0 ? path.svg(path.trace(0, 1), false) : "" }
        }
        ShapePath {
            strokeColor: path.face.warm
            strokeWidth: path.face.dp(2)
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathSvg { path: path.width > 0 && path.face.fraction > 0.004 ? path.svg(path.trace(0, path.face.fraction), false) : "" }
        }
    }
    Rectangle {
        width: parent.width
        height: 1
        y: Math.round(path.horizon)
        color: path.face.hairline
    }
}
