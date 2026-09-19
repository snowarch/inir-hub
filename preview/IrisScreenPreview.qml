pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.pieces
import qs.modules.iris.bar.island
import qs.modules.iris.field as Field

ClippingRectangle {
    id: root

    property var screen: GlobalStates.focusedScreen
    readonly property string screenName: root.screen?.name ?? ""
    readonly property real screenW: Math.max(1, root.screen?.width ?? 1920)
    readonly property real screenH: Math.max(1, root.screen?.height ?? 1080)
    property var focusRect: null
    property real maxScale: 1
    readonly property rect view: {
        const f = root.focusRect
        if (!f || root.width <= 0 || root.height <= 0) return Qt.rect(0, 0, root.screenW, root.screenH)
        const k = Math.min(root.maxScale, root.width / Math.max(1, f.width), root.height / Math.max(1, f.height))
        const w = Math.min(root.screenW, root.width / k)
        const h = Math.min(root.screenH, root.height / k)
        const x = Math.round(Math.max(0, Math.min(root.screenW - w, f.x + f.width / 2 - w / 2)))
        const y = Math.round(Math.max(0, Math.min(root.screenH - h, f.y + f.height / 2 - h / 2)))
        return Qt.rect(x, y, w, h)
    }
    readonly property real s: root.width / Math.max(1, root.view.width)
    readonly property real d: IrisStyle.density
    readonly property rect islandReach: {
        const g = root.island
        let left = g.x
        let right = g.x + g.width
        for (const sat of root.satellites) {
            left = Math.min(left, sat.x)
            right = Math.max(right, sat.x + sat.width)
        }
        const pad = Math.round(28 * root.d)
        return Qt.rect(left - pad, g.bottomEdge ? g.y - pad : 0, right - left + 2 * pad,
            g.bottomEdge ? root.screenH - g.y + pad : g.y + g.height + pad)
    }

    readonly property rect dockReach: {
        const dk = root.dock
        if (!dk) return Qt.rect(0, 0, root.screenW, root.screenH)
        const pad = Math.round(36 * root.d)
        const bottom = IrisFrame.dockEdge === "bottom"
        return Qt.rect(dk.x - pad, bottom ? dk.y - pad : 0, dk.width + 2 * pad,
            bottom ? root.screenH - dk.y + pad : dk.y + dk.height + pad)
    }

    implicitHeight: Math.round(root.width * root.screenH / root.screenW)
    radius: IrisStyle.radiusTile
    color: IrisStyle.surfaceHigh

    readonly property var bar: Config.options?.iris?.bar ?? ({})
    readonly property var bubbles: Config.options?.iris?.bubbles ?? ({})
    readonly property var dockOptions: Config.options?.iris?.dock ?? ({})
    readonly property bool notch: IrisFrame.notch
    readonly property bool framed: IrisFrame.framed
    readonly property real clockScale: Math.max(0.8, Math.min(1.5, Number(root.bar?.clockScale ?? 100) / 100))
    readonly property color clockAccent: String(root.bar?.clockAccent ?? "highlight") === "accent" ? IrisStyle.accent
        : String(root.bar?.clockAccent ?? "highlight") === "plain" ? IrisStyle.text : IrisStyle.secondaryAccent
    readonly property string clockStyle: String(IrisStyle.structuralValue("iris.bar.clockStyle", "dateTime"))

    readonly property var island: {
        const g = GlobalStates.irisIslandGeometry?.[root.screenName] ?? null
        if (g && g.width > 0 && g.height > 0) return g
        const h = IrisFrame.islandBand
        const w = Math.round(h * 4.2)
        const bottom = IrisFrame.islandEdge === "bottom"
        const inset = IrisFrame.band + IrisFrame.islandMargin
        return { x: Math.round((root.screenW - w) / 2), y: bottom ? root.screenH - inset - h : inset,
            width: w, height: h, bubble: h - Math.round(6 * root.d), gap: Math.round(6 * root.d),
            bottomEdge: bottom, auxiliarySlot: 2, fullWidth: false }
    }
    readonly property var kinds: GlobalStates.irisBubbleKinds?.[root.screenName] ?? ({})

    function satelliteRect(slot: string): var {
        const g = root.island
        const size = Number(g.bubble ?? g.height)
        const gap = Number(g.gap ?? 6)
        const cy = g.bottomEdge ? g.y + g.height - size / 2 : g.y + size / 2
        const step = size + gap
        const cx = slot === "left" ? g.x - gap - size / 2
            : slot === "utility" ? g.x + g.width + (Number(g.auxiliarySlot ?? 2) - 1) * step + gap + size / 2
            : g.x + g.width + gap + size / 2
        return { x: cx - size / 2, y: cy - size / 2, width: size, height: size }
    }
    readonly property var satellites: ["left", "right", "utility"]
        .filter(slot => String(root.kinds?.[slot] ?? "").length > 0
            && String(root.bubbles?.[slot]?.place ?? "island") === "island")
        .map(slot => Object.assign(root.satelliteRect(slot), { slot: slot, kind: String(root.kinds[slot]) }))

    readonly property var dock: {
        if (!(root.dockOptions?.enable ?? true)) return null
        const published = GlobalStates.irisDockBody?.[root.screenName]
        const body = Array.isArray(published) ? published.find(shape => shape.id === "dock") : null
        if (body && body.width > 0)
            return { x: body.x, y: body.y, width: body.width, height: body.height, radius: body.radius }
        const icon = IrisFrame.dockIcon
        const count = Math.max(4, Math.min(10, root.apps.length))
        const h = Math.round(icon + 18 * root.d)
        const w = Math.round(count * (icon + 10 * root.d) + 16 * root.d)
        const dockNotch = Boolean(root.dockOptions?.notch ?? false)
        const inset = IrisFrame.band + (dockNotch ? 0 : Math.round(10 * root.d))
        const bottom = IrisFrame.dockEdge === "bottom"
        return { x: Math.round((root.screenW - w) / 2), y: bottom ? root.screenH - inset - h : inset,
            width: w, height: h, radius: dockNotch ? Math.round(16 * root.d) : Math.round(h / 2) }
    }
    readonly property bool dockNotch: Boolean(root.dockOptions?.notch ?? false)
    readonly property var apps: (TaskbarApps.apps ?? []).filter(app => app && !app.separator && String(app.appId ?? "").length > 0 && app.appId !== "SEPARATOR")

    function scaled(shape: var): var {
        const out = Object.assign({}, shape)
        out.x = shape.x * root.s
        out.y = shape.y * root.s
        out.width = shape.width * root.s
        out.height = shape.height * root.s
        out.radius = Number(shape.radius ?? 0) * root.s
        out.fuse = Number(shape.fuse ?? IrisStyle.fuse) * root.s
        out.paints = true
        return out
    }

    Item {
        id: canvas
        x: -root.view.x * root.s
        y: -root.view.y * root.s
        width: root.screenW * root.s
        height: root.screenH * root.s

        Image {
            anchors.fill: parent
            source: WallpaperListener.wallpaperUrlForScreen(root.screen)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: Math.round(Math.max(1, canvas.width) * 1.5)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing } }
        }

        Field.IrisField {
            anchors.fill: parent
            framed: root.framed
            band: IrisFrame.band * root.s
            cornerRadius: IrisFrame.cornerRadius * root.s
            smoothing: IrisStyle.fuse * root.s
            rimWidth: 1
            shapes: {
                const out = []
                const g = root.island
                const wide = root.screenW + 4 * IrisStyle.fuseDeep
                const deep = Math.max(8, IrisStyle.fuseDeep * 2)
                if (root.notch && !root.framed)
                    out.push({ x: -2 * IrisStyle.fuseDeep, y: g.bottomEdge ? root.screenH + 1 : -deep - 1,
                        width: wide, height: deep, radius: 0, fuse: IrisStyle.fuseDeep, id: "edge" })
                out.push({ x: g.x, y: g.y, width: g.width, height: g.height, radius: g.height / 2,
                    fuse: root.notch ? IrisStyle.fuseEdge : IrisStyle.fuse, id: "island",
                    joins: !root.notch ? "" : root.framed ? "frame" : "edge" })
                for (const sat of root.satellites)
                    out.push({ x: sat.x, y: sat.y, width: sat.width, height: sat.height,
                        radius: IrisStyle.pieceRadius(sat.width), fuse: IrisStyle.fuse, id: "satellite:" + sat.slot, joins: "island" })
                const dk = root.dock
                if (dk) {
                    const bottom = IrisFrame.dockEdge === "bottom"
                    if (root.dockNotch && !root.framed)
                        out.push({ x: -2 * IrisStyle.fuseDeep, y: bottom ? root.screenH + 1 : -deep - 1,
                            width: wide, height: deep, radius: 0, fuse: IrisStyle.fuseDeep, id: "dockEdge" })
                    out.push({ x: dk.x, y: dk.y, width: dk.width, height: dk.height, radius: dk.radius,
                        fuse: root.dockNotch ? IrisStyle.fuseEdge : IrisStyle.fuse, id: "dock",
                        joins: !root.dockNotch ? "" : root.framed ? "frame" : "dockEdge" })
                }
                return out.map(shape => root.scaled(shape))
            }
        }

        Item {
            id: world
            width: root.screenW
            height: root.screenH
            scale: root.s
            transformOrigin: Item.TopLeft
            layer.enabled: canvas.width > 0 && root.s < 0.75
            layer.smooth: true
            layer.textureSize: Qt.size(Math.max(1, Math.ceil(canvas.width * 2)), Math.max(1, Math.ceil(canvas.height * 2)))

            Item {
                x: root.island.x
                y: root.island.y
                width: root.island.width
                height: root.island.height

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.d)
                    DateMark {
                        visible: root.clockStyle === "dateTime"
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: 12 * IrisStyle.typeScale * root.clockScale
                        dayColor: root.clockAccent
                    }
                    Glyph {
                        visible: root.clockStyle === "weather"
                        text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                        iconSize: Math.round(16 * root.d)
                        color: IrisStyle.subtext
                    }
                    Tabular {
                        visible: root.clockStyle === "weather"
                        text: String(Weather.data?.temp ?? "").replace(/[CF]$/, "")
                        color: IrisStyle.subtext
                        font.pixelSize: 12 * IrisStyle.typeScale
                        font.weight: Font.Medium
                    }
                    IrisClock {
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: 15 * IrisStyle.typeScale * root.clockScale
                        separatorColor: root.clockAccent
                    }
                }
            }

            Repeater {
                model: root.satellites
                IrisBubbleFace {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    bodyless: true
                    screenName: root.screenName
                    kind: modelData.kind
                }
            }

            Row {
                visible: root.dock !== null
                readonly property real icon: IrisFrame.dockIcon
                readonly property int fits: root.dock ? Math.max(0, Math.floor((root.dock.width - 16 * root.d) / (icon + 10 * root.d))) : 0
                x: root.dock ? root.dock.x + (root.dock.width - width) / 2 : 0
                y: root.dock ? root.dock.y + (root.dock.height - icon) / 2 : 0
                spacing: Math.round(10 * root.d)
                Repeater {
                    model: root.apps.slice(0, parent.fits)
                    SmartAppIcon {
                        required property var modelData
                        icon: IrisPieces.appIcon(modelData.appId)
                        fallback: "application-x-executable"
                        iconSize: Math.round(IrisFrame.dockIcon)
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: IrisStyle.border
    }
}
