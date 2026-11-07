pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// Vitals in Prism: the reading that leads names the tab, the next one sits on the flap, the lead's figure and its trend
// fill the pane, the other readings stand on the foot. Past 85 % the widget's colour turns to danger.
PrismFolder {
    id: root

    readonly property var resources: Array.from(root.widget._resourceModel ?? [])
    readonly property var loads: root.resources.filter(entry => ["cpu", "mem", "gpu"].includes(entry.key))
    readonly property var heats: root.resources.filter(entry => ["temp", "gpuTemp"].includes(entry.key))
    readonly property string leadKey: String(root.widget.familyOption("lead", "auto"))
    readonly property var leadEntry: root.resources.find(entry => entry.key === root.leadKey)
        ?? root.loads[0] ?? root.heats[0] ?? root.resources[0] ?? null
    readonly property var rest: root.resources.filter(entry => entry !== root.leadEntry)
    readonly property var second: root.rest[0] ?? null
    readonly property var footing: root.rest.slice(root.small ? 0 : 1, root.small ? 2 : 4)
    readonly property string lead: root.leadEntry?.key ?? ""

    function level(key: string): real {
        return Math.max(0, Math.min(1, Number(root.widget._getValue(key)) || 0))
    }
    function tint(key: string): color { return root.level(key) >= 0.85 ? root.danger : root.nothing ? root.ink : root.accent }
    function name(entry: var): string {
        return entry.key === "temp" ? Translation.tr("CPU heat")
            : entry.key === "gpuTemp" ? Translation.tr("GPU heat")
            : entry.key === "mem" ? Translation.tr("Memory")
            : entry.key === "cpu" ? Translation.tr("Processor")
            : entry.key === "gpu" ? Translation.tr("Graphics") : entry.label
    }
    function short(entry: var): string {
        return entry.key === "cpu" ? Translation.tr("CPU") : entry.key === "mem" ? Translation.tr("RAM")
            : entry.key === "gpu" ? Translation.tr("GPU") : root.name(entry)
    }
    function glyph(key: string): string {
        return key === "mem" ? "memory_alt" : key === "gpu" ? "developer_board" : key === "temp" || key === "gpuTemp" ? "thermostat"
            : key === "disk" ? "hard_drive" : "memory"
    }
    function figure(key: string): string { return String(root.widget._getDisplayText(key)).replace(/[%°C]/g, "") }
    function unit(key: string): string { return key === "temp" || key === "gpuTemp" ? "°C" : "%" }
    function history(key: string): var {
        const values = key === "cpu" ? ResourceUsage.cpuUsageHistory
            : key === "mem" ? ResourceUsage.memoryUsageHistory
            : key === "gpu" ? ResourceUsage.gpuUsageHistory
            : key === "temp" ? ResourceUsage.cpuTempHistory
            : key === "gpuTemp" ? ResourceUsage.gpuTempHistory : []
        return Array.from(values ?? []).slice(-40).map(value => Math.max(0, Math.min(1, Number(value) || 0)))
    }
    // The trend scaled to its own span, as the iRiS face draws it: a calm line still reads its moves.
    readonly property var samples: root.history(root.lead)
    function spread(samples: var): var {
        if (samples.length < 2)
            return []
        const low = Math.min(...samples)
        const high = Math.max(...samples)
        const span = Math.max(0.1, high - low)
        const base = (low + high) / 2 - span / 2
        return samples.map(value => 0.1 + 0.8 * (value - base) / span)
    }
    readonly property var levels: root.spread(root.samples)

    tabGlyph: root.leadEntry ? root.glyph(root.lead) : "monitor_heart"
    tabText: root.leadEntry ? root.name(root.leadEntry) : Translation.tr("Machine")
    flapText: root.second ? (root.small ? "" : root.short(root.second) + " ") + root.figure(root.second.key) + root.unit(root.second.key) : ""
    flapGlyph: root.second && root.small ? root.glyph(root.second.key) : ""
    shelf: root.leadEntry ? root.tint(root.lead) : root.accent

    // ── the pane: the lead's figure, and its trend beside it ──
    Row {
        id: reading
        visible: root.leadEntry !== null
        x: root.inset
        // Centred by the figure's caps, not its line: Nothing's figure face has a taller line and sank onto the foot.
        y: Math.round(root.paneMiddle - number.baselineOffset + number.font.pixelSize * 0.36)
        spacing: root.dp(2)
        FaceFigure {
            id: number
            face: root
            text: root.leadEntry ? root.figure(root.lead) : ""
            size: root.type(42, 52, 80)
            tone: root.level(root.lead) >= 0.85 ? root.danger : root.ink
        }
        FaceText {
            face: root
            anchors.baseline: number.baseline
            text: root.leadEntry ? root.unit(root.lead) : ""
            size: root.type(15, 18, 26)
            weight: Font.DemiBold
            color: root.inkSecondary
        }
    }
    FaceArea {
        visible: !root.small && root.levels.length >= 2
        face: root
        x: reading.x + reading.width + root.pick(0, 22, 28)
        width: root.width - root.inset - x
        y: root.paneTop + root.pick(10, 10, 16)
        height: root.paneBottom - root.pick(10, 10, 16) - y
        curve: t => IrisFaceData.smooth(root.levels, t)
        tint: root.shelf
        guide: false
        // A slab colours the load by its height: calm blue at the foot, through green and yellow, red at the top.
        layer.enabled: !root.folded
        layer.smooth: true
        layer.effect: PrismSpectrum { mono: root.nothing; angle: -90; from: 0.3; to: 1 }
    }
    FaceText {
        visible: root.leadEntry === null
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        horizontalAlignment: Text.AlignHCenter
        text: Translation.tr("Choose what to watch")
        color: root.inkSecondary
        size: root.type(12, 13, 15)
    }

    // ── the foot: the other readings, each its name, figure and level ──
    Row {
        id: others
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2) + root.pick(-2, -2, -10)
        spacing: root.pick(14, 18, 22)
        Repeater {
            model: root.footing
            Column {
                id: other
                required property var modelData
                width: (others.width - (Math.max(1, root.footing.length) - 1) * others.spacing) / Math.max(1, root.footing.length)
                spacing: root.dp(3)
                FaceText {
                    face: root
                    width: Math.min(implicitWidth, other.width)
                    text: root.short(other.modelData)
                    color: root.inkTertiary
                    size: root.type(11, 11.5, 13)
                    weight: Font.DemiBold
                }
                Row {
                    spacing: root.dp(1)
                    FaceFigure {
                        id: otherFigure
                        face: root
                        text: root.figure(other.modelData.key)
                        size: root.type(17, 18, 28)
                        tone: root.level(other.modelData.key) >= 0.85 ? root.danger : root.ink
                    }
                    FaceText {
                        face: root
                        anchors.baseline: otherFigure.baseline
                        text: root.unit(other.modelData.key)
                        size: root.type(10, 10.5, 13)
                        weight: Font.DemiBold
                        color: root.inkSecondary
                    }
                }
                // Its own last minutes, scaled to its own span: the shape of the reading, not a fill.
                FaceArea {
                    id: trend
                    readonly property var levels: root.spread(root.history(other.modelData.key))
                    visible: trend.levels.length >= 2
                    face: root
                    width: other.width
                    height: root.pick(16, 16, 30)
                    curve: t => IrisFaceData.smooth(trend.levels, t)
                    tint: root.tint(other.modelData.key)
                    guide: false
                }
            }
        }
    }
}
