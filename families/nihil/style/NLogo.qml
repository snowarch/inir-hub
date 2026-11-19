import QtQuick

// NiHiL's mark: a dark disc and the light caught along its lower limb, the sheet's horizon in small.
Canvas {
    id: root

    property real size: NihilStyle.s(20)
    // Kept for callers that paint the mark over a surface of their own.
    property color body: "transparent"

    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size
    readonly property var colors: [NihilStyle.highlight, NihilStyle.highlightTint, NihilStyle.outline]
    onColorsChanged: root.requestPaint()
    onPaint: {
        const ctx = root.getContext("2d")
        const c = root.width / 2, r = root.width * 0.36
        ctx.reset()
        ctx.lineCap = "round"
        ctx.lineWidth = Math.max(1, root.width * 0.075)
        ctx.strokeStyle = String(NihilStyle.outline)
        ctx.beginPath()
        ctx.arc(c, c, r, 0, Math.PI * 2)
        ctx.stroke()
        const highlighted = ctx.createLinearGradient(c - r, 0, c + r, 0)
        highlighted.addColorStop(0, String(NihilStyle.highlight))
        highlighted.addColorStop(1, String(NihilStyle.highlightTint))
        ctx.lineWidth = Math.max(1.4, root.width * 0.11)
        ctx.strokeStyle = highlighted
        ctx.beginPath()
        ctx.arc(c, c, r, Math.PI * 0.14, Math.PI * 0.86)
        ctx.stroke()
    }
}
