import QtQuick
import "DotGlyphs.js" as DotGlyphs

// A line drawn in NiHiL's dot face: each lit cell of DotGlyphs a round dot. `fuse` joins dots that touch along a row
// into one rounded bar (the clock's heavy cut); `dot` is a cell's diameter and `spacing` the gap after it.
Canvas {
    id: root

    property string text: ""
    property color color: NihilStyle.ink
    property real dot: 6
    property real spacing: dot * 0.35
    property int tracking: 1
    property bool fuse: false
    // A weather picture instead of text (DotGlyphs.icons): its name.
    property string icon: ""

    // The widest the line may be: past it the dots shrink to fit (a long name). 0: no limit.
    property real fitWidth: 0

    readonly property var shape: root.icon.length > 0 ? DotGlyphs.iconCells(root.icon) : DotGlyphs.layout(root.text, root.tracking)
    readonly property real _wanted: Math.max(0, root.shape.width * (root.dot + root.spacing) - root.spacing)
    readonly property real _fit: root.fitWidth > 0 && root._wanted > root.fitWidth ? root.fitWidth / root._wanted : 1
    readonly property real cellDot: root.dot * root._fit
    readonly property real cellSpacing: root.spacing * root._fit
    readonly property real pitch: root.cellDot + root.cellSpacing

    implicitWidth: Math.max(0, root.shape.width * root.pitch - root.cellSpacing)
    implicitHeight: root.shape.height * root.pitch - root.cellSpacing
    width: implicitWidth
    height: implicitHeight
    antialiasing: true
    renderStrategy: Canvas.Cooperative

    onTextChanged: requestPaint()
    onIconChanged: requestPaint()
    onColorChanged: requestPaint()
    onCellDotChanged: requestPaint()
    onSpacingChanged: requestPaint()
    onFuseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = root.color
        const r = root.cellDot / 2
        const cells = root.shape.cells
        if (!root.fuse) {
            ctx.beginPath()
            for (const cell of cells) {
                const cx = cell.x * root.pitch + r
                const cy = cell.y * root.pitch + r
                ctx.moveTo(cx + r, cy)
                ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
            }
            ctx.fill()
            return
        }
        // Runs along each row become one bar with round ends.
        const lit = {}
        for (const cell of cells) lit[cell.x + ":" + cell.y] = true
        const seen = {}
        for (const cell of cells) {
            const key = cell.x + ":" + cell.y
            if (seen[key]) continue
            let end = cell.x
            while (lit[(end + 1) + ":" + cell.y]) { end++; seen[end + ":" + cell.y] = true }
            seen[key] = true
            const x0 = cell.x * root.pitch
            const w = (end - cell.x) * root.pitch + root.cellDot
            ctx.beginPath()
            ctx.roundedRect(x0, cell.y * root.pitch, w, root.cellDot, r, r)
            ctx.fill()
        }
    }
}
