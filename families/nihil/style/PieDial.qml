import QtQuick

// A pie: the share `value` lit as a wedge from twelve o'clock, the rest the unlit tone (storage, RAM).
Canvas {
    id: root

    property real value: 0
    property color litColor: NihilStyle.accent
    property color offColor: NihilStyle.dotOff

    renderStrategy: Canvas.Cooperative
    antialiasing: true
    onValueChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onOffColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const r = Math.min(width, height) / 2
        const cx = width / 2, cy = height / 2
        ctx.fillStyle = root.offColor
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
        const v = Math.max(0, Math.min(1, root.value))
        if (v <= 0) return
        ctx.fillStyle = root.litColor
        ctx.beginPath(); ctx.moveTo(cx, cy)
        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + v * Math.PI * 2, false)
        ctx.closePath(); ctx.fill()
    }
}
