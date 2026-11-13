import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// A compact ring meter for a container tile. The arc is drawn by Canvas and the
// label sits inside it.

Item {
    id: root

    property real value: 0
    property color accent: "white"
    property color track: "transparent"
    property color ink: "white"
    property string label: ""
    property string detail: ""
    property string numbersFamily: ""
    property real scaleFactor: 1

    implicitWidth: Math.round(76 * root.scaleFactor)
    implicitHeight: implicitWidth

    Canvas {
        id: canvas
        anchors.fill: parent
        property real progress: Math.max(0, Math.min(100, root.value))
        property color arcColor: root.accent
        property color trackColor: root.track
        onProgressChanged: requestPaint()
        onArcColorChanged: requestPaint()
        onTrackColorChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const line = Math.max(4, Math.round(6 * root.scaleFactor))
            const radius = Math.min(w, h) / 2 - line / 2 - 1
            const cx = w / 2
            const cy = h / 2
            const start = -Math.PI / 2
            const end = start + Math.PI * 2 * (progress / 100)
            ctx.clearRect(0, 0, w, h)
            ctx.lineWidth = line
            ctx.lineCap = "round"
            ctx.strokeStyle = trackColor
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
            ctx.stroke()
            if (progress <= 0) return
            ctx.strokeStyle = arcColor
            ctx.beginPath()
            ctx.arc(cx, cy, radius, start, end, false)
            ctx.stroke()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.detail
            font.family: root.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            font.weight: Font.DemiBold
            color: root.ink
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.ink, 0.5)
        }
    }
}
