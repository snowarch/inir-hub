pragma ComponentBehavior: Bound

// Network on the desktop: what comes in and goes out of the connection in use, second by second, and its last minute
// as a horizon (in above the line, out below it, on one scale). The Material face holds the kind of link in the shape
// the person picks; Instrument (or the person's Instrument or Readout design) gives it the measured grammar. Under iRiS
// the family's widget designs draw it instead (IrisTraffic for iRiS, PrismTraffic for Prism, named by `iris.desktop`).
// This file owns the reading: every face reads `down`, `up`, the levels, the kind and the words from it.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.instrument
import "traffic.js" as Logic

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.net-traffic"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie9Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240, unit: "bytes" })
    needsColText: true
    resizeMinWidth: 150
    resizeMinHeight: 150
    resizeMaxWidth: 760
    resizeMaxHeight: 760

    // ── What it reads ────────────────────────────────────────
    // A second at a time, only while the card is on a desktop someone can see (a fullscreen game stops it).
    readonly property bool sampling: root.visible && root.powerActive
    readonly property int keep: 60
    property string iface: ""
    property bool routed: false
    // [{ down, up, got, sent }]: bytes per second and bytes in that second, newest last.
    property var samples: []
    property real _rx: -1
    property real _tx: -1
    property real _at: 0
    function forget(): void {
        root.samples = []
        root._rx = -1
        root._tx = -1
    }
    onSamplingChanged: if (!root.sampling) root.forget()
    onIfaceChanged: root.forget()

    FileView {
        id: routes
        path: "/proc/net/route"
        printErrors: false
        onLoaded: {
            root.iface = Logic.routeOf(routes.text())
            root.routed = true
        }
    }
    FileView {
        id: counters
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: {
            const now = Date.now()
            const read = Logic.countersOf(counters.text(), root.iface)
            if (!read) {
                root.forget()
                return
            }
            // A counter that went back (the link came up again) starts a new baseline, never a negative second.
            if (root._rx >= 0 && now > root._at && read.rx >= root._rx && read.tx >= root._tx) {
                const seconds = (now - root._at) / 1000
                const got = read.rx - root._rx
                const sent = read.tx - root._tx
                root.samples = Logic.pushed(root.samples, { down: got / seconds, up: sent / seconds, got: got, sent: sent }, root.keep)
            }
            root._rx = read.rx
            root._tx = read.tx
            root._at = now
        }
    }
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.sampling
        onTriggered: {
            routes.reload()
            counters.reload()
        }
    }

    readonly property bool online: root.iface.length > 0
    readonly property bool ready: root.samples.length > 0
    readonly property var latest: root.samples.length > 0 ? root.samples[root.samples.length - 1] : null
    readonly property real down: root.latest?.down ?? 0
    readonly property real up: root.latest?.up ?? 0
    readonly property var downs: root.samples.map(s => s.down)
    readonly property var ups: root.samples.map(s => s.up)
    readonly property real peak: root.downs.reduce((most, v) => Math.max(most, v), 0)
    readonly property real peakUp: root.ups.reduce((most, v) => Math.max(most, v), 0)
    readonly property real got: root.samples.reduce((sum, s) => sum + s.got, 0)
    readonly property real sent: root.samples.reduce((sum, s) => sum + s.sent, 0)
    readonly property real ceiling: Logic.ceilingOf(root.downs, root.ups)
    readonly property var downLevels: Logic.eased(Logic.levels(root.downs, root.ceiling))
    readonly property var upLevels: Logic.eased(Logic.levels(root.ups, root.ceiling))
    readonly property real filled: root.samples.length / root.keep
    readonly property bool drawable: root.samples.length >= 2

    // ── The words every face shares ──────────────────────────
    readonly property bool bits: String(root._readConfigKey("unit") ?? "bytes") === "bits"
    readonly property var downRate: Logic.rate(root.down, root.bits)
    readonly property var upRate: Logic.rate(root.up, root.bits)
    function rateText(bytesPerSecond: real): string { return Logic.rate(bytesPerSecond, root.bits).join(" ") }
    function amountText(bytes: real): string { return Logic.amount(bytes).join(" ") }
    readonly property string kind: Logic.kindOf(root.iface)
    readonly property string kindName: !root.online ? Translation.tr("Network")
        : root.kind === "wifi" ? Translation.tr("Wi-Fi")
        : root.kind === "ethernet" ? Translation.tr("Ethernet")
        : root.kind === "tunnel" ? Translation.tr("VPN")
        : root.kind === "mobile" ? Translation.tr("Mobile") : root.iface
    readonly property string kindGlyph: !root.online ? "public_off"
        : root.kind === "wifi" ? "wifi" : root.kind === "ethernet" ? "lan"
        : root.kind === "tunnel" ? "vpn_lock" : root.kind === "mobile" ? "cell_tower" : "router"
    // A state with nothing to draw says why, and what will show.
    readonly property string emptyText: root.routed && !root.online ? Translation.tr("No connection. Traffic shows here once you connect")
        : !root.ready ? Translation.tr("Measuring…") : ""
    readonly property bool shown: root.emptyText.length === 0

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie9Sided")
    readonly property real k: Math.max(0.4, Math.min(root.width / (root.isSmall ? 176 : 368), root.height / (root.isLarge ? 368 : 176)))
    function px(v: real): int { return Math.round(v * root.k) }
    readonly property int pad: root.px(root.isSmall ? 14 : 16)
    readonly property bool mediumSize: !root.isSmall && !root.isLarge
    readonly property color inTint: root.widgetAccentVisible
    readonly property color outTint: root.widgetSemanticForeground(root.widgetSecondaryRole)

    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && !root.familyFaced && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    component Horizon: TrafficHorizon {
        downs: root.downLevels
        ups: root.upLevels
        filled: root.filled
        stroke: Math.max(1.5, root.px(2))
        inTint: root.inTint
        outTint: root.outTint
        axis: ColorUtils.applyAlpha(root.widgetInk, 0.22)
    }
    component Empty: StyledText {
        text: root.emptyText
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: root.px(Appearance.font.pixelSize.small)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
    }
    // The kind of link in the picked shape (a quiet circle while there is none).
    component Seal: Item {
        id: seal
        property int size: root.px(64)
        implicitWidth: seal.size
        implicitHeight: seal.size
        MaterialShape {
            anchors.fill: parent
            implicitSize: seal.size
            shape: DesktopWidgetShapes.shapeForName(root.online ? root.shapeName : "Circle")
            color: root.online ? root.widgetSemanticContainer(root.widgetPrimaryRole) : ColorUtils.applyAlpha(root.widgetInk, 0.14)
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.kindGlyph
            fill: 1
            iconSize: Math.round(seal.size * 0.44)
            color: root.online ? root.widgetSemanticOnContainer(root.widgetPrimaryRole) : root.widgetInk
        }
    }
    component Eyebrow: StyledText {
        text: root.kindName
        elide: Text.ElideRight
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(Appearance.font.pixelSize.smaller * 0.72)
        font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
        font.weight: Font.DemiBold
        font.capitalization: root.widgetCapitalization
        font.letterSpacing: root.isSmall ? 0 : root.px(1)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
    }
    // A rate with its arrow: in leads, out follows smaller in its own colour.
    component Reading: Row {
        id: reading
        property bool outgoing: false
        property real size: root.px(Appearance.font.pixelSize.small)
        readonly property var value: reading.outgoing ? root.upRate : root.downRate
        spacing: Math.round(reading.size * 0.12)
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: reading.outgoing ? "arrow_upward" : "arrow_downward"
            iconSize: Math.round(reading.size * 0.62)
            color: reading.outgoing ? root.outTint : root.inTint
        }
        StyledText {
            id: figure
            text: reading.value[0]
            font.family: Appearance.font.family.numbers
            font.pixelSize: Math.round(reading.size)
            font.weight: reading.outgoing ? Font.DemiBold : Font.Bold
            font.features: ({ "tnum": 1 })
            color: root.widgetInk
        }
        StyledText {
            anchors.baseline: figure.baseline
            text: reading.value[1]
            font.pixelSize: Math.max(root.px(Appearance.font.pixelSize.smallest), Math.round(reading.size * 0.36))
            font.weight: Font.DemiBold
            color: ColorUtils.applyAlpha(root.widgetInk, 0.62)
        }
    }
    component Detail: StyledText {
        elide: Text.ElideRight
        font.pixelSize: root.px(Appearance.font.pixelSize.small)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.58)
    }

    // ── Shape look ───────────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.pad
        active: !root.instrument && !root.familyFaced
        sourceComponent: Item {
            id: face
            readonly property real head: root.isLarge ? root.px(72) : root.px(44)
            Seal {
                id: seal
                size: root.isLarge ? root.px(72) : root.isSmall ? root.px(44) : root.px(80)
                y: root.mediumSize ? Math.round((face.height - height) / 2) : 0
            }
            // Small and large: the name and what goes out beside the seal. Medium: over the readings.
            Column {
                x: seal.width + root.px(12)
                y: root.mediumSize ? 0 : Math.round((face.head - height) / 2)
                width: face.width - x
                spacing: root.px(2)
                Eyebrow { width: parent.width }
                Reading {
                    visible: root.shown && !root.mediumSize
                    outgoing: true
                    size: root.px(Appearance.font.pixelSize.small)
                }
            }
            // The rate coming in leads; medium puts what goes out at its right.
            Reading {
                id: lead
                visible: root.shown
                x: root.mediumSize ? seal.width + root.px(12) : 0
                y: root.mediumSize ? root.px(20) : face.head + root.px(root.isLarge ? 14 : 8)
                size: root.px(root.isLarge ? 54 : root.isSmall ? 32 : 36)
            }
            Reading {
                visible: root.shown && root.mediumSize
                x: face.width - width
                y: lead.y + lead.height - height - root.px(4)
                outgoing: true
                size: root.px(Appearance.font.pixelSize.normal)
            }
            Horizon {
                id: horizon
                visible: root.shown && root.drawable
                x: lead.x
                y: lead.y + lead.height + root.px(root.isLarge ? 12 : 6)
                width: face.width - x
                height: face.height - y - (foot.visible ? foot.height + root.px(10) : 0)
            }
            // Large: the minute's peak and what it moved.
            RowLayout {
                id: foot
                visible: root.shown && root.isLarge
                width: face.width
                y: face.height - height
                spacing: root.px(12)
                Detail {
                    Layout.fillWidth: true
                    text: Translation.tr("Peak %1").arg(root.rateText(root.peak))
                }
                Detail {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: Translation.tr("%1 in this minute").arg(root.amountText(root.got))
                }
            }
            Empty {
                visible: !root.shown
                x: root.mediumSize ? seal.width + root.px(12) : 0
                y: root.mediumSize ? root.px(24) : face.head + root.px(12)
                width: face.width - x
                height: face.height - y
            }
        }
    }

    // ── Instrument look ──────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.px(14)
        active: root.instrument && !root.familyFaced
        sourceComponent: ColumnLayout {
            spacing: root.px(8)
            InstrumentLabel {
                Layout.fillWidth: true
                text: Translation.tr("Network") + (root.online ? " / " + root.kindName : "")
                color: root.widgetAccentVisible
                scaleFactor: root.k
            }
            Horizon {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.shown
                inTint: root.widgetInk
                outTint: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                fade: 0.16
            }
            Empty {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.shown
            }
            GridLayout {
                Layout.fillWidth: true
                visible: root.shown
                columns: root.isSmall ? 2 : 4
                columnSpacing: root.px(12)
                rowSpacing: root.px(6)
                InstrumentField {
                    Layout.fillWidth: true
                    label: Translation.tr("In")
                    value: root.downRate.join(" ")
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
                InstrumentField {
                    Layout.fillWidth: true
                    label: Translation.tr("Out")
                    value: root.upRate.join(" ")
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
                InstrumentField {
                    Layout.fillWidth: true
                    visible: !root.isSmall
                    label: Translation.tr("Peak")
                    value: root.rateText(root.peak)
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
                InstrumentField {
                    Layout.fillWidth: true
                    visible: !root.isSmall
                    label: Translation.tr("This minute")
                    value: root.amountText(root.got)
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
            }
        }
    }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                visible: !root.familyFaced
                title: Translation.tr("Style")
                WidgetQuickChoices {
                    current: root.instrument ? "instrument" : "shape"
                    model: [
                        { label: Translation.tr("Shape"), icon: "interests", value: "shape" },
                        { label: Translation.tr("Instrument"), icon: "avg_pace", value: "instrument" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                visible: !root.instrument && !root.familyFaced
                title: Translation.tr("Shape of the link")
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
