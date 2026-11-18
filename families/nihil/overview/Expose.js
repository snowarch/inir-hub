.pragma library

// Spreads windows over a box in rows, trying every row count and keeping the one that shows them largest.
// items: [{ id, w, h }]. Returns { id: { x, y, w, h } }.
function arrange(items, width, height, gap, maxScale) {
    var out = {}
    if (!items.length || width <= 0 || height <= 0) return out
    var best = null
    for (var count = 1; count <= items.length; ++count) {
        var rows = split(items, count)
        var scale = fit(rows, width, height, gap, maxScale)
        if (!best || scale > best.scale + 0.0001) best = { rows: rows, scale: scale }
    }
    var total = 0
    best.rows.forEach(function (row) { total += rowHeight(row) * best.scale })
    total += gap * (best.rows.length - 1)
    var y = (height - total) / 2
    best.rows.forEach(function (row) {
        var tall = rowHeight(row) * best.scale
        var wide = gap * (row.length - 1)
        row.forEach(function (item) { wide += item.w * best.scale })
        var x = (width - wide) / 2
        row.forEach(function (item) {
            var w = item.w * best.scale, h = item.h * best.scale
            out[item.id] = { x: x, y: y + (tall - h) / 2, w: w, h: h }
            x += w + gap
        })
        y += tall + gap
    })
    return out
}

function split(items, count) {
    var total = 0
    items.forEach(function (item) { total += item.w })
    var target = total / count, rows = [[]], run = 0
    items.forEach(function (item) {
        var row = rows[rows.length - 1]
        if (row.length > 0 && run + item.w / 2 > target && rows.length < count) {
            rows.push([])
            row = rows[rows.length - 1]
            run = 0
        }
        row.push(item)
        run += item.w
    })
    return rows
}

function rowHeight(row) {
    return row.reduce(function (most, item) { return Math.max(most, item.h) }, 0)
}

function fit(rows, width, height, gap, maxScale) {
    var tall = 0, scale = maxScale
    rows.forEach(function (row) {
        tall += rowHeight(row)
        var wide = row.reduce(function (sum, item) { return sum + item.w }, 0)
        scale = Math.min(scale, (width - gap * (row.length - 1)) / wide)
    })
    return Math.min(scale, (height - gap * (rows.length - 1)) / tall)
}

// Windows where they really stand: columns side by side, in niri's order, scaled to fit.
function inPlace(items, width, height, gap, maxScale) {
    var out = {}
    if (!items.length || width <= 0 || height <= 0) return out
    var columns = {}, order = []
    items.forEach(function (item) {
        var key = item.column
        if (!columns[key]) { columns[key] = []; order.push(key) }
        columns[key].push(item)
    })
    order.sort(function (a, b) { return a - b })
    var wide = gap * (order.length - 1), tall = 0
    order.forEach(function (key) {
        var column = columns[key]
        wide += column.reduce(function (most, item) { return Math.max(most, item.w) }, 0)
        tall = Math.max(tall, column.reduce(function (sum, item) { return sum + item.h }, 0) + gap * (column.length - 1))
    })
    var scale = Math.min(maxScale, width / wide, height / tall)
    var x = (width - wide * scale) / 2
    order.forEach(function (key) {
        var column = columns[key]
        var columnWide = column.reduce(function (most, item) { return Math.max(most, item.w) }, 0) * scale
        var columnTall = column.reduce(function (sum, item) { return sum + item.h * scale }, 0) + gap * (column.length - 1)
        var y = (height - columnTall) / 2
        column.forEach(function (item) {
            out[item.id] = { x: x, y: y, w: item.w * scale, h: item.h * scale }
            y += item.h * scale + gap
        })
        x += columnWide + gap
    })
    return out
}
