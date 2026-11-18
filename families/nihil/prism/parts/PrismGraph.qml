import QtQuick
import qs.services
import qs.modules.nihil.prism.core
import qs.modules.nihil.prism.controls
import "PrismFigures.js" as Figures

// A page's graph (Technical Minimalism, his 11-17 pick): what the page changes drawn as a plate of a technical drawing,
// in thin lines on the inset card, its subject in the person's accent, with a dimension or two and mono callouts, and
// the plate's own marks round it: its number and name, a code, a note. It explains; it is never a control. Drawn once
// per size, page or colour change; nothing runs while it stands still.
Item {
    id: root
    property string pageId: ""
    property string pageName: ""
    property int number: 1
    // Live values a figure may say (the screen's name and size, the island's face).
    property var values: ({})
    property bool chrome: true

    readonly property var figure: Figures.of(root.pageId, root.values)
    readonly property real m: PrismTheme.dp(16)
    readonly property real labelSize: PrismTheme.dp(9.5)
    readonly property color line: PrismTheme.light ? Qt.rgba(0, 0, 0, 0.62) : Qt.rgba(1, 1, 1, 0.58) // iris-literal: the drawing's line on the inset card
    readonly property color faint: PrismTheme.light ? Qt.rgba(0, 0, 0, 0.26) : Qt.rgba(1, 1, 1, 0.26) // iris-literal: what is round the subject, a step quieter
    readonly property color mark: PrismTheme.mark

    // The plate: 16:10 inside the card, between the marks.
    readonly property real padTop: root.chrome ? PrismTheme.dp(34) : PrismTheme.dp(6)
    readonly property real padBottom: root.chrome ? PrismTheme.dp(30) : PrismTheme.dp(6)
    readonly property real pw: Math.max(10, Math.min(root.width - 2 * root.m, (root.height - root.padTop - root.padBottom) * 1.6))
    readonly property real ph: root.pw / 1.6
    readonly property real px: Math.round((root.width - root.pw) / 2)
    readonly property real py: Math.round(root.padTop + (root.height - root.padTop - root.padBottom - root.ph) / 2)

    function caption(text: string): string { return String(text ?? "").toUpperCase() }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            const X = v => root.px + v * root.pw
            const Y = v => root.py + v * root.ph
            const W = v => v * root.pw
            const H = v => v * root.ph
            const ink = { line: root.line, faint: root.faint, mark: root.mark, dash: root.faint, fill: root.faint, markfill: root.mark }
            const fillOf = style => style === "markfill" ? Qt.rgba(root.mark.r, root.mark.g, root.mark.b, 0.16)
                : style === "fill" ? Qt.rgba(root.line.r, root.line.g, root.line.b, 0.1) : null
            const mono = size => `500 ${Math.round(size)}px "${PrismTheme.fontMono}"`
            const stroke = (style, closedFill) => {
                ctx.lineWidth = style === "mark" || style === "markfill" ? 1.5 : 1.1
                ctx.strokeStyle = ink[style] ?? root.line
                ctx.setLineDash(style === "dash" ? [3, 4] : [])
                const f = fillOf(style)
                if (f && closedFill !== false) { ctx.fillStyle = f; ctx.fill() }
                ctx.stroke()
                ctx.setLineDash([])
            }
            const rrect = (x, y, w, h, r) => {
                const k = Math.min(r, w / 2, h / 2)
                ctx.beginPath()
                ctx.moveTo(x + k, y)
                ctx.arcTo(x + w, y, x + w, y + h, k)
                ctx.arcTo(x + w, y + h, x, y + h, k)
                ctx.arcTo(x, y + h, x, y, k)
                ctx.arcTo(x, y, x + w, y, k)
                ctx.closePath()
            }
            const label = (text, x, y, align, color, size) => {
                ctx.font = mono(size ?? root.labelSize)
                ctx.fillStyle = color ?? root.line
                ctx.textAlign = align ?? "left"
                ctx.textBaseline = "middle"
                ctx.fillText(String(text), x, y)
            }
            const tick = (x, y, dx, dy) => { ctx.beginPath(); ctx.moveTo(x - dx, y - dy); ctx.lineTo(x + dx, y + dy); ctx.stroke() }

            for (const it of root.figure.items) {
                const kind = it[0]
                if (kind === "rect") {
                    rrect(X(it[1]), Y(it[2]), W(it[3]), H(it[4]), PrismTheme.dp(it[5]))
                    stroke(it[6])
                } else if (kind === "line") {
                    ctx.beginPath(); ctx.moveTo(X(it[1]), Y(it[2])); ctx.lineTo(X(it[3]), Y(it[4]))
                    stroke(it[5], false)
                } else if (kind === "circle") {
                    ctx.beginPath(); ctx.arc(X(it[1]), Y(it[2]), W(it[3]), 0, Math.PI * 2)
                    stroke(it[4])
                } else if (kind === "arc") {
                    ctx.beginPath(); ctx.arc(X(it[1]), Y(it[2]), W(it[3]), it[4] * Math.PI / 180, it[5] * Math.PI / 180)
                    stroke(it[6], false)
                } else if (kind === "dot") {
                    ctx.beginPath(); ctx.arc(X(it[1]), Y(it[2]), 2.2, 0, Math.PI * 2)
                    ctx.fillStyle = ink[it[3]] ?? root.line; ctx.fill()
                } else if (kind === "poly") {
                    const pts = it[1]
                    ctx.beginPath(); ctx.moveTo(X(pts[0][0]), Y(pts[0][1]))
                    for (let i = 1; i < pts.length; ++i) ctx.lineTo(X(pts[i][0]), Y(pts[i][1]))
                    if (it[3]) ctx.closePath()
                    stroke(it[2], it[3])
                } else if (kind === "curve") {
                    ctx.beginPath(); ctx.moveTo(X(it[1]), Y(it[2]))
                    ctx.bezierCurveTo(X(it[3]), Y(it[4]), X(it[5]), Y(it[6]), X(it[7]), Y(it[8]))
                    stroke(it[9], false)
                } else if (kind === "ticks") {
                    ctx.lineWidth = 1; ctx.strokeStyle = ink[it[5]] ?? root.faint
                    for (let i = 0; i <= it[4]; ++i) {
                        const x = X(it[1] + (it[3] - it[1]) * i / it[4])
                        ctx.beginPath(); ctx.moveTo(x, Y(it[2])); ctx.lineTo(x, Y(it[2]) + 4); ctx.stroke()
                    }
                } else if (kind === "crop") {
                    const x = X(it[1]), y = Y(it[2]), w = W(it[3]), h = H(it[4]), k = Math.min(w, h) * 0.12
                    ctx.beginPath()
                    ctx.moveTo(x, y + k); ctx.lineTo(x, y); ctx.lineTo(x + k, y)
                    ctx.moveTo(x + w - k, y); ctx.lineTo(x + w, y); ctx.lineTo(x + w, y + k)
                    ctx.moveTo(x + w, y + h - k); ctx.lineTo(x + w, y + h); ctx.lineTo(x + w - k, y + h)
                    ctx.moveTo(x + k, y + h); ctx.lineTo(x, y + h); ctx.lineTo(x, y + h - k)
                    stroke(it[5], false)
                } else if (kind === "text") {
                    label(it[3], X(it[1]), Y(it[2]), it[4], ink[it[5]] ?? root.faint)
                } else if (kind === "big") {
                    ctx.font = `600 ${Math.round(root.ph * 0.36)}px "${PrismTheme.fontMain}"`
                    ctx.fillStyle = root.line
                    ctx.textAlign = it[4] ?? "left"
                    ctx.textBaseline = "alphabetic"
                    ctx.fillText(String(it[3]), X(it[1]), Y(it[2]))
                } else if (kind === "dim") {
                    // A dimension: the measured span, a tick at each end and its size said in its middle on a gap.
                    const x1 = X(it[1]), y1 = Y(it[2]), x2 = X(it[3]), y2 = Y(it[4])
                    const len = Math.hypot(x2 - x1, y2 - y1) || 1
                    const ux = (x2 - x1) / len, uy = (y2 - y1) / len
                    const text = String(it[5] ?? "")
                    ctx.font = mono(root.labelSize)
                    const gap = text.length > 0 ? (uy === 0 ? ctx.measureText(text).width : root.labelSize) / 2 + 6 : 0
                    const mx = (x1 + x2) / 2, my = (y1 + y2) / 2
                    ctx.lineWidth = 1; ctx.strokeStyle = root.faint; ctx.setLineDash([])
                    ctx.beginPath()
                    ctx.moveTo(x1, y1); ctx.lineTo(mx - ux * gap, my - uy * gap)
                    ctx.moveTo(mx + ux * gap, my + uy * gap); ctx.lineTo(x2, y2)
                    ctx.stroke()
                    ctx.strokeStyle = root.line
                    tick(x1, y1, -uy * 4 + ux * 0, ux * 4)
                    tick(x2, y2, -uy * 4, ux * 4)
                    if (uy === 0) label(text, mx, my, "center", root.line)
                    else {
                        ctx.save(); ctx.translate(mx, my); ctx.rotate(-Math.PI / 2)
                        label(text, 0, 0, "center", root.line); ctx.restore()
                    }
                } else if (kind === "call") {
                    // A callout: a dot on the part, a leader to a short shelf, the part's name on it.
                    const ax = X(it[1]), ay = Y(it[2]), lx = X(it[3]), ly = Y(it[4])
                    const right = lx >= ax
                    const text = String(it[5] ?? "")
                    ctx.font = mono(root.labelSize)
                    const tw = ctx.measureText(text).width
                    ctx.lineWidth = 1; ctx.strokeStyle = root.line; ctx.setLineDash([])
                    ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(lx, ly); ctx.lineTo(lx + (right ? 1 : -1) * (tw + 10), ly); ctx.stroke()
                    ctx.beginPath(); ctx.arc(ax, ay, 2.4, 0, Math.PI * 2); ctx.fillStyle = root.line; ctx.fill()
                    label(text, lx + (right ? 5 : -5), ly - root.labelSize * 0.75, right ? "left" : "right", root.line)
                }
            }
        }
    }

    // Repaint only when what it shows changes.
    onFigureChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onLineChanged: canvas.requestPaint()
    onMarkChanged: canvas.requestPaint()

    // The plate's marks: its number and page, a code, a note and its scale.
    component Mark: PrismText {
        mono: true
        color: PrismTheme.ink3
        font.pixelSize: root.labelSize
        font.letterSpacing: root.labelSize * 0.1
    }
    Mark {
        visible: root.chrome
        x: root.m
        y: PrismTheme.dp(12)
        text: "FIG. " + String(root.number).padStart(2, "0") + "  ·  " + root.caption(Translation.tr(root.pageName))
    }
    Mark {
        visible: root.chrome
        anchors.right: parent.right
        anchors.rightMargin: root.m
        y: PrismTheme.dp(12)
        text: root.caption(root.figure.code)
    }
    Mark {
        visible: root.chrome && text.length > 0
        x: root.m
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(10)
        width: parent.width * 0.62
        text: root.caption(root.figure.note)
    }
    Mark {
        visible: root.chrome
        anchors.right: parent.right
        anchors.rightMargin: root.m
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(10)
        text: "NTS"
    }
}
