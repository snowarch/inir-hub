pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions
import qs.modules.iris.style
import qs
import qs.services
import qs.modules.iris.frame

// Arranging widgets stage: instant-ready frosted scrim behind the shrunk live desktop card,
// crisp card hairline edge over it, and accent rims on bodies a carried widget snaps to.
Item {
    id: root

    property string side: "under"
    property string output: ""
    property var room: null
    property var card: ({ x: 0, y: 0, s: 1, p: 0 })
    property bool waiting: false
    property string still: ""
    readonly property bool ready: true

    readonly property real d: IrisStyle.density
    readonly property real p: Math.max(0, Math.min(1, root.card.p))
    readonly property real cardX: root.card.x
    readonly property real cardY: root.card.y
    readonly property real cardW: root.width * root.card.s
    readonly property real cardH: root.height * root.card.s
    readonly property real cornerSize: Math.round(22 * root.d) * root.p
    readonly property color paper: IrisStyle.paper

    // Lightweight instant backdrop behind the live desktop card — zero blocking MultiEffect FBOs.
    Rectangle {
        anchors.fill: parent
        visible: root.side === "under" && root.p > 0.001
        color: ColorUtils.applyAlpha(root.paper, (IrisStyle.light ? 0.56 : 0.72) * root.p)
    }

    // Subtle elevation halo behind the card (pure rectangle, zero GPU blur cost).
    Rectangle {
        visible: root.side === "under" && root.p > 0.01
        x: root.cardX - 1
        y: root.cardY + Math.round(6 * root.d * root.p)
        width: root.cardW + 2
        height: root.cardH + 2
        radius: root.cornerSize + 1
        color: ColorUtils.applyAlpha("#000000", (IrisStyle.light ? 0.14 : 0.32) * root.p)
    }

    // The card's shape at the desktop's own size (cut by CardPicture.frag).
    readonly property Item cardMask: root.side === "over" ? mask : null
    readonly property real cardCorner: root.cornerSize / Math.max(0.2, root.card.s)
    Item {
        id: mask
        visible: false
        width: root.width
        height: root.height
        readonly property real r: root.cornerSize / Math.max(0.2, root.card.s)
        Rectangle {
            anchors.fill: parent
            radius: mask.r
            antialiasing: true
        }
    }

    Rectangle {
        visible: root.side === "over" && root.p > 0.005
        x: root.cardX
        y: root.cardY
        width: root.cardW
        height: root.cardH
        radius: root.cornerSize
        color: "transparent"
        border.width: IrisStyle.devicePx
        border.color: ColorUtils.applyAlpha(IrisStyle.hairline, IrisStyle.hairline.a * root.p)
        antialiasing: true
    }

    // ── lit: the bodies a carried widget meets, their rims over the shrunk chassis ──
    readonly property real hair: 1 / Math.max(0.2, root.card.s)
    readonly property var bodies: root.side === "lit" ? DesktopArrange.bodiesOf(root.output) : []
    readonly property var lit: {
        const out = {}
        if (root.side !== "lit" || DesktopArrange.dragOutput !== root.output || DesktopArrange.phase === "idle")
            return out
        for (const line of DesktopArrange.slots)
            for (const id of (line?.ids ?? [])) out[id] = true
        for (const id in DesktopArrange.matched) out[id] = true
        return out
    }
    function outline(x: real, y: real, w: real, h: real, r: real): string {
        const half = Math.min(w, h) / 2
        if (r >= half - 0.5) {
            const k = half
            return w >= h
                ? `M ${x + k} ${y} L ${x + w - k} ${y} A ${k} ${k} 0 0 1 ${x + w - k} ${y + h} L ${x + k} ${y + h} A ${k} ${k} 0 0 1 ${x + k} ${y} Z`
                : `M ${x} ${y + k} A ${k} ${k} 0 0 1 ${x + w} ${y + k} L ${x + w} ${y + h - k} A ${k} ${k} 0 0 1 ${x} ${y + h - k} Z`
        }
        const R = Math.min(r * 1.8409, half)
        if (R <= 0.5)
            return `M ${x} ${y} L ${x + w} ${y} L ${x + w} ${y + h} L ${x} ${y + h} Z`
        const pts = []
        const corner = (cx, cy, from) => {
            for (let i = 0; i <= 8; i++) {
                const t = from + i / 8 * Math.PI / 2
                const c = Math.cos(t), sn = Math.sin(t)
                pts.push((cx + R * Math.sign(c) * Math.sqrt(Math.abs(c))).toFixed(2) + " " + (cy + R * Math.sign(sn) * Math.sqrt(Math.abs(sn))).toFixed(2))
            }
        }
        corner(x + w - R, y + R, -Math.PI / 2)
        corner(x + w - R, y + h - R, 0)
        corner(x + R, y + h - R, Math.PI / 2)
        corner(x + R, y + R, Math.PI)
        return "M " + pts.join(" L ") + " Z"
    }
    Item {
        visible: root.side === "lit"
        width: root.width
        height: root.height
        transform: [
            Scale { xScale: root.card.s; yScale: root.card.s },
            Translate { x: root.card.x; y: root.card.y }
        ]
        Repeater {
            model: root.bodies
            delegate: Shape {
                id: rim
                required property var modelData
                readonly property bool hot: Boolean(root.lit[rim.modelData.id])
                x: rim.modelData.x
                y: rim.modelData.y
                width: rim.modelData.w
                height: rim.modelData.h
                opacity: rim.hot ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 110; easing.type: IrisStyle.feedbackEasing } }
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: ColorUtils.applyAlpha(IrisStyle.accent, 0.12)
                    strokeColor: IrisStyle.accent
                    strokeWidth: 2 * root.hair
                    PathSvg { path: root.outline(0, 0, rim.width, rim.height, rim.modelData.radius ?? 0) }
                }
            }
        }
    }
}
