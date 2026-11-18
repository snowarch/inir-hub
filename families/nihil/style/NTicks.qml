import QtQuick

// A meter of upright strokes, lit from the start to `level`: a battery's charge, a day's hours, a volume.
Canvas {
    id: root

    property real level: 0
    property int count: 24
    property real fillShare: 0.5
    property color litColor: NihilStyle.ink
    property color offColor: Qt.alpha(root.litColor, 0.2)
    // A stroke that the level ends on, printed in the signal.
    property bool marked: false
    property color markColor: NihilStyle.accent

    renderStrategy: Canvas.Cooperative
    antialiasing: true
    onLevelChanged: requestPaint()
    onCountChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onOffColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const pitch = width / root.count
        const w = Math.max(1, pitch * root.fillShare)
        const lit = Math.round(Math.max(0, Math.min(1, root.level)) * root.count)
        for (let i = 0; i < root.count; ++i) {
            ctx.fillStyle = root.marked && i === lit - 1 ? root.markColor : i < lit ? root.litColor : root.offColor
            ctx.beginPath()
            ctx.roundedRect(i * pitch + (pitch - w) / 2, 0, w, height, w / 2, w / 2)
            ctx.fill()
        }
    }
}
