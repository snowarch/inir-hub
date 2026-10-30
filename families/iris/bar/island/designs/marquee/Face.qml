pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Marquee: long and low. The time, then one line that shows one thing at a time (the song, then the date) sliding up
// to the next every few seconds only while there is more than one, then your link, Bluetooth and sound as dots.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property var player: MprisController.activePlayer
    readonly property var lines: {
        const out = []
        const title = String(root.player?.trackTitle ?? "")
        if (MprisController.isPlaying && title.length > 0)
            out.push({ lead: title, rest: String(root.player?.trackArtist ?? "") })
        out.push({ lead: Translation.locale.toString(root.now, "dddd"), rest: Translation.locale.toString(root.now, "d MMMM") })
        return out
    }
    property int shown: 0
    readonly property var line: root.lines[Math.min(root.shown, root.lines.length - 1)] ?? ({ lead: "", rest: "" })
    Timer {
        interval: 6000
        repeat: true
        running: root.lines.length > 1 && root.visible
        onTriggered: root.shown = (root.shown + 1) % root.lines.length
    }
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property var marks: [Network.ethernet || Network.wifiEnabled, BluetoothStatus.connected, !root.muted]

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(12 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: Math.round((root.island?.figureSize ?? IrisStyle.typeHeadline) * 0.86)
            family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
            separatorColor: root.island?.clockAccent ?? IrisStyle.accent
        }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(1, IrisStyle.devicePx); height: Math.round(14 * root.d); color: IrisStyle.hairlineStrong }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(220 * root.d)
            height: Math.round(18 * root.d)
            clip: true
            IrisText {
                id: lineText
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: "<b>" + String(root.line.lead).replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</b>"
                    + (String(root.line.rest).length > 0 ? "  <font color=\"" + IrisStyle.textSecondary + "\">" + String(root.line.rest).replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</font>" : "")
                font.pixelSize: IrisStyle.typeLabel
                color: IrisStyle.text
                property real lift: 0
                anchors.verticalCenterOffset: lift
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(4 * root.d)
            Repeater {
                model: root.marks
                delegate: Rectangle {
                    required property var modelData
                    width: Math.round(5 * root.d); height: width; radius: width / 2
                    color: modelData ? IrisStyle.textSecondary : IrisStyle.hairlineStrong
                }
            }
        }
    }
}
