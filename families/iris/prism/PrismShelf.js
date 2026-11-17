.pragma library

// The shelf's packing (PrismPanel): each group goes under the columns it spans where they are lowest together, so no
// group is stretched to its neighbour's height. An item is { span, height }, or null when it is not shown.

function place(tops, span) {
    let c = 0, top = Infinity
    for (let k = 0; k + span <= tops.length; ++k) {
        const y = Math.max(...tops.slice(k, k + span))
        if (y < top - 1) { c = k; top = y }
    }
    return { c: c, top: top }
}

// Each item's column and top ({ c, top } or null), and where each column ends.
function pack(items, columns, gap) {
    const tops = Array(columns).fill(0)
    const at = items.map(item => {
        if (!item) return null
        const span = Math.min(columns, item.span)
        const spot = place(tops, span)
        for (let k = spot.c; k < spot.c + span; ++k) tops[k] = spot.top + item.height + gap
        return spot
    })
    return { at: at, tops: tops }
}

// The last item widened over the run of columns still free at its top, on both sides of where it would stand, so the
// shelf's last line ends at its edge. Read from the items before it only: its own height follows its width.
function grown(items, columns, gap) {
    const none = { index: -1, span: 0 }
    let last = -1
    items.forEach((item, i) => { if (item) last = i })
    if (last < 0) return none
    const tops = pack(items.slice(0, last), columns, gap).tops
    const own = Math.min(columns, items[last].span)
    const at = place(tops, own)
    let a = at.c, b = at.c + own
    while (a > 0 && tops[a - 1] <= at.top + 1) --a
    while (b < columns && tops[b] <= at.top + 1) ++b
    return b - a > own ? { index: last, span: b - a } : none
}
