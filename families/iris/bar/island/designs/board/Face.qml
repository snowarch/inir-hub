pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Board: a split-flap departures board. The time and one line of your day stand in real flaps; when something changes the
// letters rattle through the drum and stop on the new word, then nothing moves.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property int minute: Math.floor(root.now.getTime() / 60000)
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)

    readonly property real contentWidth: row.implicitWidth
    readonly property var parts: IrisFaceData.clockParts(DateTime.timeDisplay)
    readonly property string drum: " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.-°"
    readonly property int cells: 15
    readonly property var entry: IrisFaceData.nextEntry(root.minute * 60000, 180)
    readonly property var lines: {
        const now = new Date(root.minute * 60000)
        const night = Weather.isNightNow()
        const list = []
        if (root.entry.title.length > 0) {
            const when = root.entry.running ? root.entry.when : IrisFaceData.clockText(new Date(root.entry.start))
            list.push(root.entry.title.slice(0, root.cells - when.length - 1).padEnd(root.cells - when.length) + when)
        }
        if (Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--"))
            list.push(String(Weather.data?.temp ?? "").replace(/[^\d-]/g, "") + "° " + String(Weather.data?.description ?? ""))
        const sun = IrisFaceData.dayShare(night ? Weather.data?.sunrise : Weather.data?.sunset)
        if (sun >= 0) {
            const at = new Date(now)
            at.setHours(0, Math.round(sun * 1440), 0, 0)
            list.push((night ? Translation.tr("Sunrise") : Translation.tr("Sunset")) + " " + IrisFaceData.clockText(at))
        }
        list.push(Translation.locale.toString(now, "dddd d"))
        return list
    }
    readonly property string line: String(root.lines[Math.floor(root.minute / 3) % root.lines.length]).toUpperCase()

    // One half of the card; the board's flaps are two of these on a hinge.
    component Half: Item {
        id: half
        property Item flap: null
        property bool upper: true
        property string letter: " "
        property real shut: 1
        y: half.upper ? 0 : half.flap.hinge
        width: half.flap.width
        height: half.upper ? half.flap.hinge - 0.5 : half.flap.height - half.flap.hinge
        clip: true
        transform: Scale { origin.y: half.upper ? half.height : 0; yScale: half.shut }
        Rectangle {
            y: half.upper ? 0 : -half.flap.hinge
            width: half.flap.width
            height: half.flap.height
            radius: IrisStyle.radiusMicro
            color: IrisStyle.liftOver(IrisStyle.fillActive, IrisStyle.surfaceOpaque)
        }
        Text {
            y: (half.upper ? 0 : -half.flap.hinge) + Math.round((half.flap.height - height) / 2)
            width: half.flap.width
            horizontalAlignment: Text.AlignHCenter
            text: half.letter
            font.family: IrisStyle.fontMain
            font.pixelSize: half.flap.px
            font.weight: IrisStyle.weight(Font.Bold)
            font.features: ({ "tnum": 1 })
            color: IrisStyle.text
            renderType: Text.NativeRendering
        }
    }

    component Flap: Item {
        id: flap
        property string glyph: " "
        property real px: IrisStyle.typeLabel
        property int delay: 0
        property string shown: " "
        property string coming: " "
        property string target: " "
        property real fold: 1
        readonly property real hinge: Math.round(height / 2)

        function turnToward(): void {
            if (flap.shown === flap.target) return
            const pool = root.drum
            const here = pool.indexOf(flap.shown)
            const there = pool.indexOf(flap.target)
            const gap = here < 0 || there < 0 ? 1 : (there - here + pool.length) % pool.length
            flap.coming = gap <= 1 ? flap.target : pool[(here + Math.max(1, Math.ceil(gap / 3))) % pool.length]
            flip.restart()
        }
        onGlyphChanged: {
            flap.target = flap.glyph
            if (!IrisStyle.motionEnabled) { flap.shown = flap.glyph; return }
            start.interval = Math.max(1, flap.delay)
            start.restart()
        }
        Component.onCompleted: { flap.shown = flap.glyph; flap.target = flap.glyph }
        Timer { id: start; onTriggered: flap.turnToward() }
        SequentialAnimation {
            id: flip
            PropertyAction { target: flap; property: "fold"; value: 0 }
            NumberAnimation { target: flap; property: "fold"; to: 1; duration: 46 }
            ScriptAction { script: { flap.shown = flap.coming; flap.turnToward() } }
        }
        Half { flap: flap; upper: true; letter: flap.fold < 1 ? flap.coming : flap.shown }
        Half { flap: flap; upper: false; letter: flap.shown }
        Half { flap: flap; upper: true; letter: flap.shown; visible: flap.fold < 0.5; shut: Math.cos(flap.fold * Math.PI) }
        Half { flap: flap; upper: false; letter: flap.coming; visible: flap.fold >= 0.5 && flap.fold < 1; shut: -Math.cos(flap.fold * Math.PI) }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(2 * root.d))
            Repeater {
                model: 4
                Flap {
                    required property int index
                    width: Math.round(18 * root.d)
                    height: Math.round(root.h - 10 * root.d)
                    px: Math.round(23 * root.d)
                    delay: index * 22
                    glyph: (root.parts.hours.padStart(2, "0") + root.parts.minutes)[index] ?? " "
                }
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Repeater {
                model: root.cells
                Flap {
                    required property int index
                    width: Math.round(12 * root.d)
                    height: Math.round(root.h - 18 * root.d)
                    px: IrisStyle.typeLabel
                    delay: index * 26
                    glyph: root.line[index] ?? " "
                }
            }
        }
    }
}
