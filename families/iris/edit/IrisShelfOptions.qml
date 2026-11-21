pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One area's options on the shelf, as the lines of Prism's chart the widget's quick controls draw (his 11-07: the Look
// page showed three tiles and a "More"): every row the area has in Settings, refinements too. Each group takes columns of
// its own, kept whole, and the page shows as many as the shelf is wide; the shelf's head lists the groups to jump to
// (`chapters`, `onShow`, `open`), those the page names first (`order`) leading. Nothing slides sideways to be found
// (11-20: the lines had to be dragged to reach a setting): the page turns a step at a time, by the arrows at its end or
// the wheel. A folded choice lays its chips across the page, with the way back, since there is no room under a line
// here. The card above shows each change as it lands.
Item {
    id: root

    required property string section
    // The groups that lead, in this order; with `only`, the page holds just these (Look = the widget groups of Desktop).
    property var order: []
    property bool only: false

    readonly property real lineHeight: PrismTheme.dp(46)
    readonly property int perColumn: Math.max(1, Math.floor(root.height / root.lineHeight))
    readonly property real columnGap: PrismTheme.dp(36)
    readonly property real narrowest: PrismTheme.dp(320)
    readonly property real pagerWidth: PrismTheme.dp(48)
    readonly property var drawn: ["switch", "choice", "range", "text", "action"]
    readonly property var specs: {
        Config.revision
        const order = Array.from(root.order ?? [])
        const rank = spec => { const at = order.indexOf(String(spec.group ?? "")); return at < 0 ? order.length : at }
        return IrisOptions.settings.filter(spec => spec.section === root.section && (!root.only || order.includes(String(spec.group ?? "")))
            && !spec.mirror && spec.shelf !== false && root.drawn.includes(spec.kind) && IrisOptions.shown(spec))
            .map((spec, at) => ({ spec: spec, at: at })).sort((a, b) => rank(a.spec) - rank(b.spec) || a.at - b.at).map(item => item.spec)
    }
    // The groups in the page's order, each with its lines; a group set apart in Settings still reads as one.
    readonly property var groups: {
        const out = []
        for (const spec of root.specs) {
            const name = String(spec.group ?? "")
            const group = out.find(item => item.name === name)
            if (group) group.specs.push(spec)
            else out.push({ name: name, specs: [spec] })
        }
        return out
    }
    // The groups to jump to; an area of one group has none.
    readonly property var chapters: root.groups.length > 1 ? root.groups.map(group => group.name) : []

    // Each group in columns of as many lines as the page holds, numbered down the area, a group always opening a column.
    readonly property var lanes: {
        const out = []
        let number = 1
        for (const group of root.groups) {
            for (let at = 0; at < group.specs.length; at += root.perColumn)
                out.push({ key: group.name + "/" + at, group: group.name, inGroup: at / root.perColumn, first: number + at,
                    specs: group.specs.slice(at, at + root.perColumn) })
            number += group.specs.length
        }
        return out
    }
    // As many columns as fit; the arrows take their room only when the area is longer than the page.
    function fitIn(room: real): int { return Math.max(1, Math.floor((room + root.columnGap) / (root.narrowest + root.columnGap))) }
    readonly property var grid: {
        const plain = root.fitIn(root.width)
        const paged = root.lanes.length > plain
        const room = Math.max(0, root.width - (paged ? root.pagerWidth : 0))
        const fit = paged ? root.fitIn(room) : plain
        return { fit: fit, columnWidth: Math.max(0, (room - (fit - 1) * root.columnGap) / fit) }
    }
    // The steps the page turns through: a group that does not fit beside the ones before opens the next step, and only a
    // group longer than a whole step goes on over several.
    readonly property var steps: {
        const fit = root.grid.fit
        const out = []
        let step = []
        let at = 0
        while (at < root.lanes.length) {
            let end = at
            while (end < root.lanes.length && root.lanes[end].group === root.lanes[at].group) end++
            if (step.length > 0 && step.length + end - at > fit) { out.push(step); step = [] }
            for (; at < end; at++) {
                if (step.length === fit) { out.push(step); step = [] }
                step.push(root.lanes[at])
            }
        }
        if (step.length > 0) out.push(step)
        return out
    }
    readonly property int parts: Math.max(1, root.steps.length)

    // The step on show, held by its first column: a line that comes or goes as a value changes repacks the steps, and
    // the page stays on the groups it showed.
    property string anchorGroup: ""
    property int anchorLane: 0
    readonly property int partShown: {
        let found = root.steps.findIndex(step => step.some(lane => lane.group === root.anchorGroup && lane.inGroup === root.anchorLane))
        if (found < 0) found = root.steps.findIndex(step => step.some(lane => lane.group === root.anchorGroup))
        return Math.max(0, found)
    }
    readonly property var columns: root.steps[root.partShown] ?? []
    // The groups on show, for the head to light.
    readonly property var onShow: {
        const out = []
        for (const lane of root.columns) if (!out.includes(lane.group)) out.push(lane.group)
        return out
    }

    // Where the new lines come from: a later step from the right, an earlier one from the left.
    property int from: 1
    function show(next: int): void {
        const lane = root.steps[next]?.[0]
        root.unfolded = null
        if (!lane || next === root.partShown) return
        root.from = next > root.partShown ? 1 : -1
        root.anchorGroup = lane.group
        root.anchorLane = lane.inGroup
        arrive.restart()
    }
    function open(group: string): void { root.show(root.steps.findIndex(step => step.some(lane => lane.group === group))) }
    function turn(by: int): void { root.show(Math.max(0, Math.min(root.parts - 1, root.partShown + by))) }

    // The folded choice laid open across the page, or none.
    property var unfolded: null
    readonly property var unfoldedNow: { Config.revision; return root.unfolded ? IrisOptions.currentValue(root.unfolded) : undefined }
    onSectionChanged: { root.unfolded = null; root.anchorGroup = ""; root.anchorLane = 0 }

    ParallelAnimation {
        id: arrive
        NumberAnimation { target: board; property: "opacity"; from: 0; to: 1; duration: PrismTheme.ms(180); easing.type: Easing.OutCubic }
        NumberAnimation { target: board; property: "shift"; from: root.from * PrismTheme.dp(14); to: 0; duration: PrismTheme.ms(220); easing.type: Easing.OutCubic }
    }

    Item {
        id: page
        anchors.fill: parent
        opacity: root.unfolded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }

        // The wheel turns a step per notch.
        WheelHandler {
            enabled: root.parts > 1
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            property real gathered: 0
            onWheel: event => {
                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y
                gathered += delta
                if (Math.abs(gathered) < 120) return
                root.turn(gathered > 0 ? -1 : 1)
                gathered = 0
            }
        }

        Row {
            id: board
            property real shift: 0
            x: board.shift
            height: page.height
            spacing: root.columnGap
            Repeater {
                model: ScriptModel { values: root.columns; objectProp: "key" }
                delegate: Item {
                    id: lane
                    required property var modelData
                    width: root.grid.columnWidth
                    height: board.height
                    IrisSheetRows {
                        x: PrismTheme.dp(8)
                        width: lane.width - PrismTheme.dp(16)
                        specs: lane.modelData.specs
                        firstNumber: lane.modelData.first
                        fold: spec => root.unfolded = spec
                    }
                }
            }
        }

        // The way through the steps, at the page's end: back above, on below.
        Column {
            visible: root.parts > 1
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(6)
            PrismRound {
                glyph: "chevron_left"
                smoked: true
                enabled_: root.partShown > 0
                opacity: root.partShown > 0 ? 1 : 0.35
                Accessible.name: Translation.tr("Back")
                onClicked: root.turn(-1)
            }
            PrismRound {
                glyph: "chevron_right"
                smoked: true
                enabled_: root.partShown < root.parts - 1
                opacity: root.partShown < root.parts - 1 ? 1 : 0.35
                Accessible.name: Translation.tr("More")
                onClicked: root.turn(1)
            }
        }
    }

    // A folded choice, open: its name and the way back, every option a chip under it.
    Item {
        anchors.fill: parent
        opacity: root.unfolded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        Row {
            id: unfoldedHead
            x: PrismTheme.dp(8)
            y: PrismTheme.dp(6)
            spacing: PrismTheme.dp(8)
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "arrow_back"
                Accessible.name: Translation.tr("Back")
                onClicked: root.unfolded = null
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.unfolded ? Translation.tr(String(root.unfolded.label ?? "")) : ""
                color: PrismTheme.ink
                font.pixelSize: PrismTheme.body
                font.weight: Font.DemiBold
            }
        }
        PrismChips {
            x: PrismTheme.dp(8)
            anchors.top: unfoldedHead.bottom
            anchors.topMargin: PrismTheme.dp(10)
            width: parent.width - PrismTheme.dp(16)
            choices: root.unfolded ? IrisOptions.choicesOf(root.unfolded) : []
            current: root.unfoldedNow
            onPicked: value => {
                IrisOptions.commit(root.unfolded, value)
                root.unfolded = null
            }
        }
    }
}
