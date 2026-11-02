pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Approach: your next three hours as a strip hung beside the time. An event is a block of its real length at its real
// distance, and it travels to the needle until it arrives; running, it burns down against it. You see how close things
// are before you read them.
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
    readonly property int span: 180
    readonly property real track: Math.round(226 * root.d)
    readonly property real perMinute: root.track / root.span
    readonly property int local: root.minute - root.now.getTimezoneOffset()
    readonly property var blocks: IrisFaceData.agenda(root.minute * 60000, root.span)
    readonly property var ticks: {
        const list = []
        const first = Math.ceil(root.local / 15) * 15
        for (let t = first; t - root.local <= root.span; t += 15)
            list.push({ away: t - root.local, rank: t % 60 === 0 ? 2 : t % 30 === 0 ? 1 : 0, hour: Math.floor(t / 60) % 24 })
        return list
    }
    readonly property real tickTop: Math.round(7 * root.d)
    readonly property real barH: Math.round(16 * root.d)
    readonly property real barY: root.h - root.barH - Math.round(6 * root.d)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(12 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Item {
            width: root.track
            height: root.h
            clip: true
            Canvas {
                id: ruler
                anchors.fill: parent
                readonly property var marks: root.ticks
                onMarksChanged: ruler.requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.font = `${IrisStyle.weight(Font.Medium)} ${IrisStyle.typeCaption}px "${IrisStyle.fontMain}"`
                    ctx.textBaseline = "top"
                    for (const tick of ruler.marks) {
                        const at = Math.round(tick.away * root.perMinute)
                        const tall = tick.rank === 2 ? 8 : tick.rank === 1 ? 5 : 3
                        ctx.fillStyle = tick.rank === 2 ? IrisStyle.textSecondary : IrisStyle.textTertiary
                        ctx.fillRect(at, root.tickTop, 1, Math.round(tall * root.d))
                        if (tick.rank === 2) ctx.fillText(String(tick.hour), at + Math.round(4 * root.d), root.tickTop - 2)
                    }
                }
            }
            Repeater {
                model: root.blocks
                Rectangle {
                    id: block
                    required property var modelData
                    required property int index
                    readonly property real away: (block.modelData.start - root.minute * 60000) / 60000
                    readonly property real last: (block.modelData.end - root.minute * 60000) / 60000
                    readonly property bool running: block.away <= 0
                    readonly property bool first: block.index === 0
                    readonly property var next: root.blocks[block.index + 1] ?? null
                    readonly property real room: (block.next ? (block.next.start - root.minute * 60000) / 60000 * root.perMinute : root.track)
                        - block.x - block.width - Math.round(6 * root.d)
                    x: Math.round(Math.max(0, block.away) * root.perMinute) + 2
                    // Each minute it comes a little closer, gliding, never a jump.
                    Behavior on x { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(420); velocity: -1 } }
                    y: root.barY
                    width: Math.max(Math.round(6 * root.d), Math.round((block.last - Math.max(0, block.away)) * root.perMinute) - 3)
                    height: root.barH
                    radius: IrisStyle.radiusMicro
                    color: block.running || block.first ? root.mark : IrisStyle.liftOver(IrisStyle.fillActive, IrisStyle.surfaceOpaque)
                    IrisText {
                        id: label
                        // A long block holds its name; a short one wears it beside, only with room before the next.
                        readonly property bool fits: block.width >= Math.round(44 * root.d)
                        visible: label.fits || block.room >= Math.round(28 * root.d)
                        x: label.fits ? Math.round(6 * root.d) : block.width + Math.round(5 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        // On a quiet block the same ink reads past its end; on a lit one the name stays inside.
                        width: Math.min(implicitWidth, !label.fits ? block.room
                            : block.running || block.first ? block.width - Math.round(12 * root.d) : block.width - Math.round(6 * root.d) + block.room)
                        text: block.modelData.title
                        elide: Text.ElideRight
                        font.pixelSize: IrisStyle.typeFootnote
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        color: label.fits && (block.running || block.first) ? IrisStyle.onTintFor(root.mark) : IrisStyle.text
                    }
                }
            }
            IrisText {
                visible: root.blocks.length === 0
                x: Math.round(6 * root.d)
                y: root.barY + Math.round((root.barH - height) / 2)
                text: Translation.tr("Nothing ahead")
                font.pixelSize: IrisStyle.typeFootnote
                font.weight: IrisStyle.weight(Font.Medium)
                color: IrisStyle.textTertiary
            }
            Rectangle {
                y: Math.round(5 * root.d)
                width: Math.max(2, Math.round(2 * root.d))
                height: root.h - Math.round(10 * root.d)
                radius: width / 2
                color: root.mark
            }
        }
    }
}
