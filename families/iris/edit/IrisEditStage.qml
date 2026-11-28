pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.modules.common.functions
import qs.modules.iris.style
import qs
import qs.services
import qs.modules.iris.components
import qs.modules.iris.frame

// Arranging widgets stage: instant-ready backdrop that softly fades in the blurred wallpaper
// behind the shrunk live desktop card without ever holding frame 0, crisp card hairline edge
// over it, and accent rims on bodies a carried widget snaps to.
Item {
    id: root

    property string side: "under"
    property string output: ""
    property var room: null
    property var card: ({ x: 0, y: 0, s: 1, p: 0 })
    property bool waiting: false
    property string still: ""
    // Never block the entrance zoom on slow decodes; the blurred stage fades in smoothly once decoded.
    readonly property bool ready: true

    readonly property real d: IrisStyle.density
    readonly property real p: Math.max(0, Math.min(1, root.card.p))
    readonly property real cardX: root.card.x
    readonly property real cardY: root.card.y
    readonly property real cardW: root.width * root.card.s
    readonly property real cardH: root.height * root.card.s
    readonly property real cornerSize: Math.round(IrisStyle.radiusPanel * root.p)
    readonly property color paper: IrisStyle.paper

    // Immediate tinted scrim so frame 0 is smooth, layered under the async blurred wallpaper.
    Rectangle {
        anchors.fill: parent
        visible: root.side === "under" && root.p > 0.001
        color: ColorUtils.applyAlpha(root.paper, (IrisStyle.light ? 0.56 : 0.72) * root.p)
    }

    Loader {
        id: under
        anchors.fill: parent
        active: root.side === "under" && root.p > 0.001
        asynchronous: true
        sourceComponent: Item {
            id: stage
            anchors.fill: parent
            opacity: Math.min(1, root.p * 1.6)

            // Two stills: a new wallpaper (a pick in the strip) decodes in the hidden one and fades in over the one on
            // show. Set on the shown one, it emptied while it decoded and the stage flashed its bare scrim at every pick.
            property int current: 0
            readonly property Image shown: stage.current === 0 ? stillA : stillB
            readonly property Image next: stage.current === 0 ? stillB : stillA
            readonly property bool picture: stage.shown.status === Image.Ready
            function load(): void {
                if (arrive.running) {
                    // A pick during a fade: the one fading in takes the place at once and the new one fades over it.
                    arrive.stop()
                    stage.next.opacity = 1
                    stage.current = stage.current === 0 ? 1 : 0
                }
                if (String(stage.shown.source) === root.still) {
                    stage.next.source = ""
                    return
                }
                stage.next.opacity = 0
                stage.next.z = 1
                stage.shown.z = 0
                stage.next.source = root.still
                if (stage.next.status === Image.Ready) arrive.restart()
            }
            function arrived(still: Image): void {
                if (still === stage.next && still.status === Image.Ready && String(still.source).length > 0) arrive.restart()
            }
            Connections {
                target: root
                function onStillChanged(): void { stage.load() }
            }
            Component.onCompleted: stillA.source = root.still
            NumberAnimation {
                id: arrive
                target: stage.next
                property: "opacity"
                from: 0
                to: 1
                duration: IrisStyle.duration(320)
                easing.type: Easing.OutCubic
                onFinished: stage.current = stage.current === 0 ? 1 : 0
            }
            component Still: Image {
                anchors.fill: parent
                sourceSize: Qt.size(Math.max(160, Math.round(root.width / 4)), Math.max(90, Math.round(root.height / 4)))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
            // Blurred as one picture: the blur runs again only while a new still fades in.
            Item {
                id: stills
                anchors.fill: parent
                visible: false
                Still {
                    id: stillA
                    onStatusChanged: stage.arrived(stillA)
                }
                Still {
                    id: stillB
                    opacity: 0
                    onStatusChanged: stage.arrived(stillB)
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: stills
                visible: stage.picture
                blurEnabled: true
                blur: 1
                blurMax: 36
                saturation: -0.15
                autoPaddingEnabled: false
            }
            Rectangle {
                anchors.fill: parent
                visible: stage.picture
                color: ColorUtils.applyAlpha(root.paper, IrisStyle.light ? 0.32 : 0.46) // iris-literal: the stage still's paper wash, set by eye over the blurred wallpaper
            }
            IrisBodyShadow {
                x: root.cardX
                y: root.cardY + 10 * root.d * root.p
                width: root.cardW
                height: root.cardH
                radius: root.cornerSize
                blur: 42 * root.d
                spread: -8 * root.d
                color: ColorUtils.applyAlpha(IrisStyle.shadow, IrisStyle.shadow.a * root.p)
            }
        }
    }

    // The card's shape at the desktop's own size (cut by CardPicture.frag).
    readonly property Item cardMask: root.side === "over" ? mask : null
    readonly property real cardCorner: root.cornerSize / Math.max(0.2, root.card.s)
    Item {
        id: mask
        width: root.width
        height: root.height
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: root.cardCorner
            color: "#ffffff" // iris-literal: an opacity mask, only its alpha counts
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
        border.width: 1
        border.color: ColorUtils.applyAlpha(IrisStyle.text, (IrisStyle.light ? 0.14 : 0.16) * root.p)
    }

    readonly property var obstacles: root.side === "lit" && root.output.length > 0
        ? (DesktopArrange.obstacles?.[root.output] ?? []) : []
    readonly property var lit: {
        const out = ({})
        if (root.side !== "lit" || DesktopArrange.dragOutput !== root.output) return out
        for (const id in DesktopArrange.matched) out[id] = true
        return out
    }
    function outline(x: real, y: real, w: real, h: real, r: real): string {
        const half = Math.min(w, h) / 2
        if (r >= half - 0.5) {
            const c = Math.max(0, half)
            return `M ${x + c} ${y} L ${x + w - c} ${y} A ${c} ${c} 0 0 1 ${x + w} ${y + c}`
                + ` L ${x + w} ${y + h - c} A ${c} ${c} 0 0 1 ${x + w - c} ${y + h}`
                + ` L ${x + c} ${y + h} A ${c} ${c} 0 0 1 ${x} ${y + h - c}`
                + ` L ${x} ${y + c} A ${c} ${c} 0 0 1 ${x + c} ${y} Z`
        }
        const q = Math.min(r * 1.8409, half)
        const s = q * 0.55228475
        return `M ${x + q} ${y} L ${x + w - q} ${y}`
            + ` C ${x + w - q + s} ${y} ${x + w} ${y + q - s} ${x + w} ${y + q}`
            + ` L ${x + w} ${y + h - q}`
            + ` C ${x + w} ${y + h - q + s} ${x + w - q + s} ${y + h} ${x + w - q} ${y + h}`
            + ` L ${x + q} ${y + h}`
            + ` C ${x + q - s} ${y + h} ${x} ${y + h - q + s} ${x} ${y + h - q}`
            + ` L ${x} ${y + q}`
            + ` C ${x} ${y + q - s} ${x + q - s} ${y} ${x + q} ${y} Z`
    }
    readonly property real hair: 1 / Math.max(1, root.Screen?.devicePixelRatio ?? 1)
    Repeater {
        model: root.obstacles
        delegate: Item {
            id: rim
            required property var modelData
            readonly property bool on: Boolean(root.lit[rim.modelData.id])
            x: root.cardX + rim.modelData.x * root.card.s
            y: root.cardY + rim.modelData.y * root.card.s
            width: rim.modelData.width * root.card.s
            height: rim.modelData.height * root.card.s
            visible: rim.width > 0 && rim.height > 0 && (rim.on || rimShape.opacity > 0.005)
            Shape {
                id: rimShape
                anchors.fill: parent
                opacity: rim.on ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 110; easing.type: IrisStyle.feedbackEasing } }
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: IrisStyle.tintFill(IrisStyle.accent)
                    strokeColor: IrisStyle.accent
                    strokeWidth: 2 * root.hair
                    PathSvg { path: root.outline(0, 0, rim.width, rim.height, rim.modelData.radius ?? 0) }
                }
            }
        }
    }
}
