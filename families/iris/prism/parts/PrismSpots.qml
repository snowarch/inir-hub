pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The page's parts on its scene, numbered like its legend (Logitech Options+, `.claude/ref/iris-prism/pin-options-plus-parts.jpg`):
// each part a number on the drawing; pointed at (the number or the part itself) it turns white, names its group and
// what it holds now beside it, and the rest of the scene steps back round the part; a press opens the group's rows
// beside the scene. Lies over the scene at its size and corners; draws nothing where the scene names no part.
ClippingRectangle {
    id: root
    // The scene's spots in this frame (IrisGroupPreview.spots) and the page's legend entries ({ title, rows, changed }).
    property var spots: []
    property var groups: []
    // What is pointed at from anywhere (here or the legend) and the group open beside the scene: entry titles.
    property string pointed: ""
    property string picked: ""
    // What an entry holds now, in a few words (the legend's glance).
    property var sayOf: null
    signal point(string title)
    signal pick(string title)

    color: "transparent"

    // Each spot whose group the page shows, with its legend number: one number an entry, its first spot.
    readonly property var marks: {
        const out = []
        for (const spot of root.spots) {
            const i = root.groups.findIndex(entry => entry.title === spot.group
                || Array.from(entry.rows ?? []).some(row => row.section === spot.group))
            if (i < 0 || out.some(mark => mark.number === i + 1)) continue
            out.push(Object.assign({}, spot, { entry: String(root.groups[i].title), number: i + 1, changed: Boolean(root.groups[i].changed) }))
        }
        return out
    }
    readonly property string here: hover.hovered ? root.under : ""
    property string under: ""
    onHereChanged: root.point(root.here)

    // What the pointer is on: a number first, then the smallest part under it.
    function hit(x: real, y: real): string {
        const reach = PrismTheme.dp(18)
        for (const mark of root.marks)
            if (Math.hypot(x - mark.x, y - mark.y) <= reach) return mark.entry
        let best = "", area = Infinity
        for (const mark of root.marks) {
            const r = mark.part
            if (!r || x < r.x || y < r.y || x > r.x + r.width || y > r.y + r.height) continue
            if (r.width * r.height < area) { area = r.width * r.height; best = mark.entry }
        }
        return best
    }
    HoverHandler {
        id: hover
        cursorShape: root.under.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPointChanged: root.under = root.hit(hover.point.position.x, hover.point.position.y)
    }
    TapHandler {
        onTapped: (point) => {
            const title = root.hit(point.position.x, point.position.y)
            root.pick(title === root.picked ? "" : title)
        }
    }

    // ── The part pointed at stays lit, the rest of the scene steps back: a scrim with a hole the part's shape. Moving to
    // another part the hole glides there (from where it stands to the new part); the same part moving with the scene's
    // size is followed as it is, frame by frame.
    readonly property string lit: root.pointed.length > 0 ? root.pointed : root.picked
    readonly property var litMark: root.marks.find(mark => mark.entry === root.lit && mark.part) ?? null
    Rectangle {
        id: scrim
        readonly property real big: Math.max(root.width, root.height) * 2
        readonly property real pad: 0 // the part as drawn: a padded hole would read as a ring round it
        property string entry: ""
        property rect from: Qt.rect(0, 0, 0, 0)
        property rect to: Qt.rect(0, 0, 0, 0)
        property real fromRadius: 0
        property real toRadius: 0
        property real glide: 1
        readonly property real hx: scrim.from.x + (scrim.to.x - scrim.from.x) * scrim.glide
        readonly property real hy: scrim.from.y + (scrim.to.y - scrim.from.y) * scrim.glide
        readonly property real hw: scrim.from.width + (scrim.to.width - scrim.from.width) * scrim.glide
        readonly property real hh: scrim.from.height + (scrim.to.height - scrim.from.height) * scrim.glide
        readonly property real hr: scrim.fromRadius + (scrim.toRadius - scrim.fromRadius) * scrim.glide
        x: scrim.hx - scrim.pad - scrim.big
        y: scrim.hy - scrim.pad - scrim.big
        width: scrim.hw + 2 * (scrim.pad + scrim.big)
        height: scrim.hh + 2 * (scrim.pad + scrim.big)
        radius: Math.max(PrismTheme.dp(6), scrim.hr) + scrim.pad + scrim.big
        color: "transparent"
        border.width: scrim.big
        border.color: PrismTheme.spotScrim
        opacity: root.litMark ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
        NumberAnimation { id: glider; target: scrim; property: "glide"; from: 0; to: 1; duration: PrismTheme.ms(240); easing.type: Easing.OutCubic }
        Connections {
            target: root
            function onLitMarkChanged(): void {
                const mark = root.litMark
                if (!mark) return
                const radius = Number(mark.radius ?? 0)
                // Another part, while the scrim shows: glide from where the hole stands now.
                if (mark.entry !== scrim.entry && scrim.opacity > 0.02 && PrismTheme.ms(1) > 0) {
                    scrim.from = Qt.rect(scrim.hx, scrim.hy, scrim.hw, scrim.hh)
                    scrim.fromRadius = scrim.hr
                    scrim.to = mark.part
                    scrim.toRadius = radius
                    scrim.entry = mark.entry
                    glider.restart()
                    return
                }
                scrim.entry = mark.entry
                scrim.to = mark.part
                scrim.toRadius = radius
                if (!glider.running) { scrim.from = mark.part; scrim.fromRadius = radius; scrim.glide = 1 }
            }
        }
    }

    // ── The numbers. Counted, not listed: the marks move with the scene's size (a new list each frame of a resize)
    // and a list model would build every number again for each.
    Repeater {
        model: root.marks.length
        delegate: Item {
            id: disc
            required property int index
            readonly property var mark: root.marks[disc.index] ?? null
            readonly property string entry: String(disc.mark?.entry ?? "")
            readonly property bool lit: disc.entry.length > 0 && (root.pointed === disc.entry || root.picked === disc.entry)
            width: PrismTheme.dp(22)
            height: width
            x: Math.round(Number(disc.mark?.x ?? 0) - width / 2)
            y: Math.round(Number(disc.mark?.y ?? 0) - height / 2)
            scale: disc.lit ? 1.18 : 1
            opacity: root.picked.length > 0 && !disc.lit ? 0.5 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
            RectangularShadow {
                anchors.fill: face
                radius: face.radius
                blur: PrismTheme.dp(10)
                offset.y: PrismTheme.dp(1)
                color: PrismTheme.spotShadow
            }
            Rectangle {
                id: face
                anchors.fill: parent
                radius: width / 2
                color: disc.lit ? PrismTheme.paper : PrismTheme.spot
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            }
            PrismText {
                anchors.centerIn: parent
                mono: true
                text: String(Number(disc.mark?.number ?? 0)).padStart(2, "0")
                color: disc.lit ? PrismTheme.night : PrismTheme.paper
                font.pixelSize: PrismTheme.caption
                font.weight: Font.DemiBold
            }
            // Changed from iNiR's: the legend's accent dot, on the number's shoulder.
            Rectangle {
                visible: Boolean(disc.mark?.changed)
                x: parent.width - width * 0.75
                y: -height * 0.25
                width: PrismTheme.dp(7)
                height: width
                radius: width / 2
                color: PrismTheme.accent
            }
        }
    }

    // ── What the pointed number is: its group and what it holds now, beside it on the side with room.
    readonly property var named: root.pointed.length > 0 && root.pointed !== root.picked
        ? (root.marks.find(mark => mark.entry === root.pointed) ?? null) : null
    Rectangle {
        id: chip
        property var mark: null
        // Away from its part when the number stands beside it (right of the part, the name goes right), never over
        // what it names; a number on its part takes the side with room.
        readonly property real markX: Number(chip.mark?.x ?? 0)
        readonly property var markPart: chip.mark?.part ?? null
        readonly property bool rightward: chip.markPart && chip.markX >= chip.markPart.x + chip.markPart.width ? true
            : chip.markPart && chip.markX <= chip.markPart.x ? false
            : chip.markX < root.width * 0.62
        readonly property string say: chip.mark && typeof root.sayOf === "function" ? String(root.sayOf(String(chip.mark.entry)) ?? "") : ""
        readonly property real gap: PrismTheme.dp(18)
        // Measured from both words, never from the row: the value's own visibility hangs on the room left.
        // The name whole always; the value only where the scene leaves room for it (chipSay).
        width: Math.min(Math.max(root.width - PrismTheme.dp(12), chipName.implicitWidth + PrismTheme.dp(24)),
            chipName.implicitWidth + (chip.say.length > 0 ? chipRow.spacing + chipSay.implicitWidth : 0) + PrismTheme.dp(24))
        height: PrismTheme.dp(30)
        radius: height / 2
        color: PrismTheme.spot
        x: Math.round(Math.max(PrismTheme.dp(6), Math.min(root.width - width - PrismTheme.dp(6),
            chip.rightward ? Number(chip.mark?.x ?? 0) + chip.gap : Number(chip.mark?.x ?? 0) - chip.gap - width)))
        y: Math.round(Math.max(PrismTheme.dp(6), Math.min(root.height - height - PrismTheme.dp(6), Number(chip.mark?.y ?? 0) - height / 2)))
        opacity: root.named ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        Connections {
            target: root
            function onNamedChanged(): void { if (root.named) chip.mark = root.named }
        }
        Row {
            id: chipRow
            x: PrismTheme.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            width: chip.width - 2 * x
            spacing: PrismTheme.dp(8)
            PrismText {
                id: chipName
                text: Translation.tr(String(chip.mark?.entry ?? ""))
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
            }
            // The value goes whole or not at all, as in the legend.
            PrismText {
                id: chipSay
                visible: chip.say.length > 0 && implicitWidth <= chipRow.width - chipName.width - chipRow.spacing
                text: chip.say
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.small
            }
        }
    }
}
