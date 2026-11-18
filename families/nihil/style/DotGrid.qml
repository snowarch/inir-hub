import QtQuick

// A field of dots, `lit` of `count` in the signal colour (RAM, battery): filled left to right, row by row, or column
// by column with `columnFirst`. A dot cut by the level shows its lit part as a half.
Canvas {
    id: root

    property int columns: 7
    property int rows: 4
    property real level: 0
    property bool columnFirst: true
    property color litColor: NihilStyle.litLevel
    property color offColor: NihilStyle.dotOff
    readonly property int count: root.columns * root.rows
    readonly property real cell: Math.min(width / root.columns, height / root.rows)
    readonly property real dot: root.cell * 0.72

    renderStrategy: Canvas.Cooperative
    antialiasing: true
    readonly property bool squareDots: NihilStyle.squareDots
    onSquareDotsChanged: requestPaint()
    onLevelChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onOffColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const lit = Math.max(0, Math.min(1, root.level)) * root.count
        const r = root.dot / 2
        const offX = (width - root.cell * root.columns) / 2
        const offY = (height - root.cell * root.rows) / 2
        for (let i = 0; i < root.count; ++i) {
            const col = root.columnFirst ? Math.floor(i / root.rows) : i % root.columns
            const row = root.columnFirst ? i % root.rows : Math.floor(i / root.columns)
            const cx = offX + col * root.cell + root.cell / 2
            const cy = offY + row * root.cell + root.cell / 2
            const part = Math.max(0, Math.min(1, lit - i))
            ctx.fillStyle = root.offColor
            ctx.beginPath()
            if (root.squareDots) ctx.rect(cx - r, cy - r, root.dot, root.dot)
            else ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fill()
            if (part <= 0) continue
            ctx.fillStyle = root.litColor
            ctx.beginPath()
            if (root.squareDots) ctx.rect(cx - r, cy - r, root.dot * Math.min(1, part), root.dot)
            else if (part >= 1) ctx.arc(cx, cy, r, 0, Math.PI * 2)
            else { ctx.save(); ctx.rect(cx - r, cy - r, root.dot * part, root.dot); ctx.clip(); ctx.arc(cx, cy, r, 0, Math.PI * 2) }
            ctx.fill()
            if (part < 1 && !root.squareDots) ctx.restore()
        }
    }
}
