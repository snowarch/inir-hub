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
import qs.modules.iris.state
import qs.modules.iris.preview.parts
import "../bar/island/NoticeSamples.js" as NoticeSamples

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
    function reachOf(body: var, edge: string, pad: real): rect {
        switch (edge) {
        case "bottom": return Qt.rect(body.x - pad, body.y - pad, body.width + 2 * pad, root.screenH - body.y + pad)
        case "left": return Qt.rect(0, body.y - pad, body.x + body.width + pad, body.height + 2 * pad)
        case "right": return Qt.rect(body.x - pad, body.y - pad, root.screenW - body.x + pad, body.height + 2 * pad)
        default: return Qt.rect(body.x - pad, 0, body.width + 2 * pad, body.y + body.height + pad)
        }
    }
    readonly property rect islandReach: {
        const g = root.island
        let x0 = g.x, y0 = g.y, x1 = g.x + g.width, y1 = g.y + g.height
        // A full bar spans its edge: look at the middle of it, where the heart rests, not at all of it.
        if (g.fullWidth) {
            if (g.vertical) { const span = root.screenH * 0.4; y0 = (root.screenH - span) / 2; y1 = y0 + span }
            else { const span = root.screenW * 0.4; x0 = (root.screenW - span) / 2; x1 = x0 + span }
        }
        for (const sat of root.satellites) {
            x0 = Math.min(x0, sat.x); y0 = Math.min(y0, sat.y)
            x1 = Math.max(x1, sat.x + sat.width); y1 = Math.max(y1, sat.y + sat.height)
        }
        return root.reachOf({ x: x0, y: y0, width: x1 - x0, height: y1 - y0 }, root.islandEdge, Math.round(28 * root.d))
    }

    readonly property rect dockReach: root.dock ? root.reachOf(root.dock, IrisFrame.dockEdge, Math.round(36 * root.d))
        : Qt.rect(0, 0, root.screenW, root.screenH)

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
    readonly property string clockStyle: String(IrisStyle.structuralValue("bar.clockStyle", "dateTime"))
    // The face the Island wears (a Design's, else the design's own); Halo is the engine's clock below. A stand-in clock
    // kept Halo's time under every design, so a Face option changed nothing here (11-06).
    readonly property string faceUrl: {
        const own = IrisDesign.skin("islandFace")
        if (own.length > 0) return own
        const design = String(root.bar?.design ?? "halo")
        return (IrisStyle.islandDesignParts[design] ?? []).includes("Face.qml") ? Qt.resolvedUrl("../bar/island/designs/" + design + "/Face.qml") : ""
    }

    readonly property string layout: String(root.bar?.layout ?? "island")
    readonly property var island: {
        const g = IrisState.islandGeometry?.[root.screenName] ?? null
        if (g && g.width > 0 && g.height > 0) {
            const edge = String(g.edge ?? (g.bottomEdge ? "bottom" : "top"))
            return Object.assign({}, g, { edge: edge, vertical: edge === "left" || edge === "right" })
        }
        const edge = IrisFrame.islandEdge
        const vertical = edge === "left" || edge === "right"
        const thick = IrisFrame.islandBand
        const span = vertical ? root.screenH : root.screenW
        const full = root.layout === "full" || root.layout === "menubar" || root.layout === "pods"
        const length = full ? span - 2 * (IrisFrame.band + IrisFrame.islandMargin) : Math.round(thick * 4.2)
        const margin = IrisFrame.band + Math.round(16 * root.d)
        const along = full ? IrisFrame.band + IrisFrame.islandMargin : root.layout === "left" ? margin
            : root.layout === "right" ? span - margin - length : Math.round((span - length) / 2)
        const inset = IrisFrame.band + IrisFrame.islandMargin
        const across = edge === "bottom" ? root.screenH - inset - thick : edge === "right" ? root.screenW - inset - thick : inset
        return { x: vertical ? across : along, y: vertical ? along : across,
            width: vertical ? thick : length, height: vertical ? length : thick,
            bubble: thick - Math.round(6 * root.d), gap: Math.round(6 * root.d), edge: edge, vertical: vertical,
            bottomEdge: edge === "bottom", auxiliarySlot: 2, fullWidth: full }
    }
    readonly property string islandEdge: String(root.island.edge ?? "top")

    // A notice Settings asks to see plays here too, at its size and for its time: the live Island sits under
    // Settings' window. Only a scene that asks listens, and the card exists only while one plays.
    property bool notices: false
    readonly property var noticeOptions: root.bar?.notices ?? ({})
    property var noticeEvent: null
    property bool noticeUp: false
    Connections {
        target: root.notices ? IrisState : null
        function onNoticeSampleChanged(): void {
            const kind = String(IrisState.noticeSample?.kind ?? "")
            if (kind.length === 0 || root.island.vertical) return
            root.noticeEvent = NoticeSamples.of(kind, Translation, IrisStyle, IrisStyle.nothingAt("island"), canvasWallpaper.stillUrl)
            root.noticeUp = true
            noticeHold.restart()
        }
    }
    Timer {
        id: noticeHold
        interval: Math.round(1000 * Math.max(1.5, Math.min(8, Number(root.noticeOptions?.seconds ?? 2.5))))
        onTriggered: root.noticeUp = false
    }
    IrisSpring { id: noticeSpring; surface: "island"; intent: "move"; to: root.noticeUp ? 1 : 0; minimum: 0; epsilon: 0.002 }
    readonly property real noticeOpen: noticeLoader.item ? noticeSpring.value : 0
    // A bar hangs the notice under its strip; the floating Island grows into it.
    readonly property bool noticeHung: Boolean(root.island.fullWidth) || root.menubar
    readonly property var noticeBody: {
        const c = noticeLoader.item
        if (!c || root.noticeOpen <= 0.002) return null
        const g = root.island, p = root.noticeOpen, bottom = root.islandEdge === "bottom"
        const w = c.cardWidth, h = c.cardHeight, cx = g.x + g.width / 2
        if (root.noticeHung) {
            const gap = Math.round(6 * root.d), seed = Math.round(40 * root.d)
            const lw = seed + (w - seed) * p, lh = Math.max(1, h * p)
            return { x: Math.round(cx - lw / 2), y: bottom ? g.y - gap - lh : g.y + g.height + gap,
                width: lw, height: lh, radius: Math.min(lh / 2, seed / 2 + (c.cardRadius - seed / 2) * p), card: c }
        }
        const rest = IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, root.notch), Math.min(g.width, g.height))
        const lw = g.width + (w - g.width) * p, lh = g.height + (h - g.height) * p
        return { x: Math.round(cx - lw / 2), y: bottom ? g.y + g.height - lh : g.y,
            width: lw, height: lh, radius: rest + (c.cardRadius - rest) * p, card: c }
    }
    readonly property var kinds: IrisState.bubbleKinds?.[root.screenName] ?? ({})

    function satelliteRect(slot: string): var {
        const g = root.island
        const size = Number(g.bubble ?? Math.min(g.width, g.height))
        const gap = Number(g.gap ?? 6)
        const step = size + gap
        const start = g.vertical ? g.y : g.x
        const end = g.vertical ? g.y + g.height : g.x + g.width
        const along = slot === "left" ? start - gap - size / 2
            : slot === "utility" ? end + (Number(g.auxiliarySlot ?? 2) - 1) * step + gap + size / 2
            : end + gap + size / 2
        const across = g.vertical ? g.x + g.width / 2
            : g.bottomEdge ? g.y + g.height - size / 2 : g.y + size / 2
        return g.vertical ? { x: across - size / 2, y: along - size / 2, width: size, height: size }
            : { x: along - size / 2, y: across - size / 2, width: size, height: size }
    }
    readonly property var satellites: ["left", "right", "utility"]
        .filter(slot => String(root.kinds?.[slot] ?? "").length > 0
            && String(root.bubbles?.[slot]?.place ?? "island") === "island")
        .map(slot => Object.assign(root.satelliteRect(slot), { slot: slot, kind: String(root.kinds[slot]) }))

    readonly property var dock: {
        if (!(root.dockOptions?.enable ?? true)) return null
        const published = IrisState.dockBody?.[root.screenName]
        const body = Array.isArray(published) ? published.find(shape => shape.id === "dock") : null
        if (body && body.width > 0)
            return { x: body.x, y: body.y, width: body.width, height: body.height, radius: body.radius }
        const icon = IrisFrame.dockIcon
        const count = Math.max(4, Math.min(10, root.apps.length))
        const thick = Math.round(icon + 18 * root.d)
        const length = Math.round(count * (icon + 10 * root.d) + 16 * root.d)
        const dockNotch = Boolean(root.dockOptions?.notch ?? false)
        const inset = IrisFrame.band + (dockNotch ? 0 : Math.round(10 * root.d))
        const edge = IrisFrame.dockEdge
        const vertical = edge === "left" || edge === "right"
        const across = edge === "bottom" ? root.screenH - inset - thick : edge === "right" ? root.screenW - inset - thick : inset
        const along = Math.round(((vertical ? root.screenH : root.screenW) - length) / 2)
        return { x: vertical ? across : along, y: vertical ? along : across,
            width: vertical ? thick : length, height: vertical ? length : thick,
            radius: IrisStyle.dockShape !== "auto" ? IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.dockShape, dockNotch), thick)
                : dockNotch ? Math.round(16 * root.d) : Math.round(thick / 2) }
    }
    readonly property bool dockVertical: IrisFrame.dockEdge === "left" || IrisFrame.dockEdge === "right"
    function edgeBody(edge: string, id: string): var {
        const deep = Math.max(8, IrisStyle.fuseDeep * 2)
        const wide = root.screenW + 4 * IrisStyle.fuseDeep
        const tall = root.screenH + 4 * IrisStyle.fuseDeep
        switch (edge) {
        case "bottom": return { x: -2 * IrisStyle.fuseDeep, y: root.screenH + 1, width: wide, height: deep, radius: 0, fuse: IrisStyle.fuseDeep, id: id }
        case "left": return { x: -deep - 1, y: -2 * IrisStyle.fuseDeep, width: deep, height: tall, radius: 0, fuse: IrisStyle.fuseDeep, id: id }
        case "right": return { x: root.screenW + 1, y: -2 * IrisStyle.fuseDeep, width: deep, height: tall, radius: 0, fuse: IrisStyle.fuseDeep, id: id }
        default: return { x: -2 * IrisStyle.fuseDeep, y: -deep - 1, width: wide, height: deep, radius: 0, fuse: IrisStyle.fuseDeep, id: id }
        }
    }
    readonly property bool menubar: root.layout === "menubar" && !root.island.vertical
    readonly property var zoneLists: root.island.fullWidth && (root.layout === "full" || root.layout === "menubar")
        ? [IrisStyle.structuralValue("bar.fullStart", ["workspaces", "window"]), IrisStyle.structuralValue("bar.fullEnd", ["tray", "notifications", "sound", "controls"])]
        : [[], []]
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

        IrisWallpaperView {
            id: canvasWallpaper
            live: false
            anchors.fill: parent
            screen: root.screen
            decodeSize: Qt.size(Math.round(Math.max(1, canvas.width) * 1.5), 0)
            opacity: ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing } }
        }
        PreviewGlass {
            id: screenGlass
            anchors.fill: parent
            source: IrisStyle.glassy ? canvasWallpaper.textureItem : null
            k: root.s
        }

        Field.IrisField {
            anchors.fill: parent
            backdropOverride: IrisStyle.glassy ? screenGlass : null
            framed: root.framed
            band: IrisFrame.band * root.s
            cornerRadius: IrisFrame.cornerRadius * root.s
            smoothing: IrisStyle.fuse * root.s
            rimWidth: 1
            shapes: {
                const out = []
                const g = root.island
                if (root.notch && !root.framed) out.push(root.edgeBody(root.islandEdge, "edge"))
                if (root.menubar) {
                    const strip = IrisFrame.islandBand
                    const notchW = Math.round(g.height * 4.2)
                    const inset = root.framed ? IrisFrame.band : 0
                    const clear = String(root.bar?.strip ?? "clear") === "clear"
                    if (clear && !root.notch && !root.framed) out.push(root.edgeBody(root.islandEdge, "edge"))
                    if (!clear) out.push({ x: inset, y: g.edge === "bottom" ? g.y + g.height - strip : g.y,
                        width: root.screenW - 2 * inset, height: strip, radius: 0,
                        fuse: Math.round(16 * root.d), id: "island",
                        joins: !root.notch ? "" : root.framed ? "frame" : "edge" })
                    out.push({ x: g.x + (g.width - notchW) / 2, y: g.y, width: notchW, height: g.height, radius: IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, true), g.height),
                        fuse: clear ? IrisStyle.fuseEdge : Math.round(32 * root.d), id: "islandnotch",
                        joins: !clear ? "island" : root.framed ? "frame" : "edge" })
                } else out.push({ x: g.fullWidth && !g.vertical ? (root.framed ? IrisFrame.band : 0) : g.x,
                    y: g.y, width: g.fullWidth && !g.vertical ? root.screenW - (root.framed ? 2 * IrisFrame.band : 0) : g.width,
                    height: g.height, radius: g.fullWidth && !g.vertical ? 0
                        : IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, root.notch), Math.min(g.width, g.height)),
                    fuse: g.fullWidth && !g.vertical ? Math.round(16 * root.d) : root.notch ? IrisStyle.fuseEdge : IrisStyle.fuse, id: "island",
                    joins: !root.notch ? "" : root.framed ? "frame" : "edge" })
                // Shelf: the Island rising out of its middle, as IrisIsland draws it.
                const rise = Math.round(({ none: 0, low: 10, deep: 20 })[String(root.bar?.rise ?? "deep")] ?? 20) * root.d
                if (root.layout === "full" && !g.vertical && rise > 0) {
                    const heartW = Math.round(g.height * 4.2), tall = g.height + rise
                    out.push({ x: Math.round((root.screenW - heartW) / 2), y: g.edge === "bottom" ? g.y - rise : g.y,
                        width: heartW, height: tall, radius: Math.round(tall * 0.4),
                        fuse: Math.round(rise * 1.1 + 6 * root.d), id: "islandheart", joins: "island" })
                }
                for (const sat of root.satellites)
                    out.push({ x: sat.x, y: sat.y, width: sat.width, height: sat.height,
                        radius: IrisStyle.pieceRadius(sat.width), fuse: IrisStyle.fuse, id: "satellite:" + sat.slot, joins: "island" })
                const dk = root.dock
                if (dk) {
                    if (root.dockNotch && !root.framed) out.push(root.edgeBody(IrisFrame.dockEdge, "dockEdge"))
                    out.push({ x: dk.x, y: dk.y, width: dk.width, height: dk.height, radius: dk.radius,
                        fuse: root.dockNotch ? IrisStyle.fuseEdge : IrisStyle.fuse, id: "dock",
                        joins: !root.dockNotch ? "" : root.framed ? "frame" : "dockEdge" })
                }
                const nb = root.noticeBody
                if (nb && root.noticeHung)
                    out.push({ x: nb.x, y: nb.y, width: nb.width, height: nb.height, radius: nb.radius,
                        fuse: IrisStyle.fuse, id: "notice", joins: "island" })
                else if (nb) {
                    const body = out.find(shape => shape.id === "island")
                    if (body) Object.assign(body, { x: nb.x, y: nb.y, width: nb.width, height: nb.height, radius: nb.radius })
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
            layer.enabled: canvas.width > 0 && root.s < 0.999
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(Math.max(1, Math.ceil(canvas.width * 2)), Math.max(1, Math.ceil(canvas.height * 2)))

            Item {
                id: islandBox
                x: root.island.x
                y: root.island.y
                width: root.island.width
                height: root.island.height
                opacity: root.noticeHung ? 1 : 1 - IrisStyle.contentAt(root.noticeOpen)

                IslandStackedClock {
                    visible: root.island.vertical
                    anchors.centerIn: parent
                    pixelSize: IrisStyle.typeHeadline * root.clockScale
                    accent: root.clockAccent
                    showDay: root.clockStyle === "dateTime"
                }

                Repeater {
                    model: [0, 1]
                    Grid {
                        id: zone
                        required property int modelData
                        readonly property var kinds: Array.from(root.zoneLists[zone.modelData] ?? []).filter(kind => kind !== "island")
                        readonly property real size: Math.round(Math.min(root.island.width, root.island.height) * 0.56)
                        readonly property real inset: Math.round((Math.min(root.island.width, root.island.height) - zone.size) / 2)
                        visible: zone.kinds.length > 0
                        columns: zone.vertical ? 1 : zone.kinds.length
                        spacing: Math.round(6 * root.d)
                        readonly property bool vertical: root?.island?.vertical ?? false
                        x: zone.vertical ? zone.inset : zone.modelData === 0 ? zone.inset * 2 : islandBox.width - width - zone.inset * 2
                        y: !zone.vertical ? zone.inset : zone.modelData === 0 ? zone.inset * 2 : islandBox.height - height - zone.inset * 2
                        Repeater {
                            model: zone.kinds
                            Rectangle {
                                required property string modelData
                                readonly property bool wide: modelData === "workspaces" || modelData === "window"
                                width: root.island.vertical || !wide ? zone.size : zone.size * 2.4
                                height: root.island.vertical && wide ? zone.size * 2.4 : zone.size
                                radius: Math.min(width, height) / 2
                                color: IrisStyle.fill
                            }
                        }
                    }
                }

                // What a face reads of the Island, at the Island's own size here.
                QtObject {
                    id: faceSample
                    readonly property real compactHeight: root.island.height
                    readonly property color clockAccent: root.clockAccent
                    readonly property real figureSize: IrisStyle.typeHeadline * root.clockScale
                    readonly property bool nothingLook: IrisStyle.nothingAt("island")
                    readonly property bool zoned: false
                    readonly property bool vertical: false
                }
                Loader {
                    id: wornFace
                    active: !root.island.vertical && root.faceUrl.length > 0
                    asynchronous: true
                    source: wornFace.active ? root.faceUrl : ""
                    anchors.centerIn: parent
                    width: Math.min(islandBox.width, Number(wornFace.item?.contentWidth ?? 0))
                    height: islandBox.height
                    onLoaded: if (item && item.island !== undefined) item.island = faceSample
                }

                RowLayout {
                    visible: !root.island.vertical && !(wornFace.status === Loader.Ready)
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.d)
                    DateMark {
                        visible: root.clockStyle === "dateTime"
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: IrisStyle.typeMeta * root.clockScale
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
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.Medium)
                    }
                    IrisClock {
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: IrisStyle.typeHeadline * root.clockScale
                        separatorColor: root.clockAccent
                    }
                }
            }

            Item {
                visible: root.noticeBody !== null
                x: root.noticeBody?.x ?? 0
                y: root.noticeBody?.y ?? 0
                width: root.noticeBody?.width ?? 0
                height: root.noticeBody?.height ?? 0
                clip: true
                Loader {
                    id: noticeLoader
                    active: root.notices && root.noticeEvent !== null && (root.noticeUp || noticeSpring.value > 0.002)
                    anchors.centerIn: parent
                    width: item?.cardWidth ?? 0
                    height: item?.cardHeight ?? 0
                    sourceComponent: IslandNoticeCard {
                        event: root.noticeEvent
                        reveal: root.noticeOpen
                        live: root.noticeUp
                        compact: String(root.noticeOptions?.style ?? "compact") !== "large"
                        band: IrisFrame.islandBand
                        notch: root.notch
                        maxWidth: root.screenW - 2 * (IrisFrame.band + IrisFrame.islandMargin)
                        nothingLook: IrisStyle.nothingAt("island")
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

            Grid {
                visible: root.dock !== null
                readonly property real icon: IrisFrame.dockIcon
                readonly property real length: root.dock ? (root.dockVertical ? root.dock.height : root.dock.width) : 0
                readonly property int fits: root.dock ? Math.max(0, Math.floor((length - 16 * root.d) / (icon + 10 * root.d))) : 0
                columns: root.dockVertical ? 1 : Math.max(1, fits)
                x: root.dock ? root.dock.x + (root.dock.width - width) / 2 : 0
                y: root.dock ? root.dock.y + (root.dock.height - height) / 2 : 0
                spacing: Math.round(10 * root.d)
                // Ids, not the apps: an app entry holds its windows' toplevels, and a delegate built from one copied a
                // toplevel that closed meanwhile (closing the Settings window crashed the shell, 2026-10-21).
                Repeater {
                    model: root.apps.slice(0, parent.fits).map(app => String(app.appId))
                    SmartAppIcon {
                        required property string modelData
                        icon: IrisPieces.appIcon(modelData)
                        fallback: "application-x-executable"
                        iconSize: Math.round(IrisFrame.dockIcon)
                    }
                }
            }
        }
    }

    // A scene inside Settings' own framed stage leaves the outline to the stage.
    property bool outlined: true
    Rectangle {
        anchors.fill: parent
        visible: root.outlined
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: IrisStyle.border
    }
}
