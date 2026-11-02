pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Marquee · Bulbs: the time, then a theatre sign whose edge is lined with bulbs and whose bill is what is on now: the
// song and who sings it, or the day when nothing plays. The bulbs chase round the sign only while music plays.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property var player: MprisController.activePlayer
    readonly property string title: String(root.player?.trackTitle ?? "")
    readonly property bool playing: MprisController.isPlaying && root.title.length > 0
    readonly property string lead: root.playing ? root.title : Translation.locale.toString(root.now, "dddd")
    readonly property string rest: root.playing ? String(root.player?.trackArtist ?? "") : Translation.locale.toString(root.now, "d MMMM")
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    property int phase: 0
    Timer {
        interval: 170
        repeat: true
        running: root.playing && root.visible && IrisStyle.motionEnabled
        onTriggered: root.phase = (root.phase + 1) % 3
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(9 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: Math.round((root.island?.figureSize ?? IrisStyle.typeHeadline) * 0.88)
            family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
            separatorColor: root.mark
        }
        Rectangle {
            id: sign
            anchors.verticalCenter: parent.verticalCenter
            readonly property real pitch: Math.round(6 * root.d)
            readonly property real bulb: Math.max(2, Math.round(2.5 * root.d))
            readonly property real inset: Math.round(4 * root.d)
            height: Math.round(root.h - 10 * root.d)
            width: Math.min(Math.round(236 * root.d), bill.implicitWidth + 2 * Math.round(13 * root.d))
            radius: IrisStyle.radiusRow
            color: IrisStyle.fillQuiet
            // Bulbs on a rounded track inside the edge, evenly spaced, numbered round the sign so a chase runs round it.
            readonly property var bulbs: {
                const w = sign.width - 2 * sign.inset, hh = sign.height - 2 * sign.inset
                const across = Math.max(2, Math.floor(w / sign.pitch)), down = Math.max(1, Math.floor(hh / sign.pitch))
                const out = []
                for (let i = 0; i <= across; i++) out.push({ x: sign.inset + w * i / across, y: sign.inset })
                for (let i = 1; i < down; i++) out.push({ x: sign.inset + w, y: sign.inset + hh * i / down })
                for (let i = across; i >= 0; i--) out.push({ x: sign.inset + w * i / across, y: sign.inset + hh })
                for (let i = down - 1; i > 0; i--) out.push({ x: sign.inset, y: sign.inset + hh * i / down })
                return out
            }
            Repeater {
                model: sign.bulbs
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool lit: !root.playing || (index + root.phase) % 3 === 0
                    x: Math.round(modelData.x - width / 2)
                    y: Math.round(modelData.y - height / 2)
                    width: sign.bulb
                    height: sign.bulb
                    radius: width / 2
                    color: lit ? root.mark : IrisStyle.hairlineStrong
                    opacity: lit ? (root.playing ? 1 : 0.7) : 1
                }
            }
            IrisText {
                id: bill
                anchors.centerIn: parent
                width: Math.min(implicitWidth, sign.width - 2 * Math.round(13 * root.d))
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: "<b>" + root.lead.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</b>"
                    + (root.rest.length > 0 ? "  <font color=\"" + IrisStyle.textSecondary + "\">" + root.rest.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</font>" : "")
                font.pixelSize: IrisStyle.typeLabel
                color: IrisStyle.text
            }
        }
    }
}
