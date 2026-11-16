.pragma library

// The one reading of Niri's layout every face draws: the workspaces of one screen, top to bottom as Niri stacks them,
// each a lane of its columns left to right, each column as wide as it is on the screen and holding its windows top to
// bottom. Floating windows stand together at the lane's end. Umbriel answers on the same socket with the same shape.

// What decides the drawing: which windows sit where, how wide, which workspace is in use and which window each one
// remembers. A title is not in it, so a terminal that retitles itself every second never rebuilds the lanes.
function keyOf(windows, workspaces, output, hidden) {
    const parts = [output]
    for (const ws of workspaces ?? []) {
        if (output && ws.output !== output) continue
        parts.push(`w${ws.id}.${ws.idx}.${ws.is_active ? 1 : 0}.${ws.active_window_id ?? "-"}.${ws.name ?? ""}`)
    }
    for (const w of windows ?? []) {
        const pos = w.layout?.pos_in_scrolling_layout
        const size = w.layout?.tile_size
        parts.push(`${w.id}:${w.workspace_id}:${pos ? pos[0] + "." + pos[1] : "f"}:${size ? Math.round(size[0]) : "-"}`
            + `:${w.is_floating ? "f" : ""}${w.is_minimized || hidden.indexOf(w.id) >= 0 ? "m" : ""}${w.is_focused ? "*" : ""}:${w.app_id ?? ""}`)
    }
    return parts.join("|")
}

// A column's width as a share of the screen (Niri's "proportion 0.5" reads 0.5), held to what a drawing can show.
function share(width, screenWidth) {
    if (!(screenWidth > 0) || !(width > 0)) return 0.5
    return Math.max(0.12, Math.min(1.5, width / screenWidth))
}

// `hidden`: the ids iNiR keeps minimized (they wait on a workspace of their own, never shown as one).
function lanes(windows, workspaces, output, screenWidth, hidden) {
    const shown = (windows ?? []).filter(w => !w.is_minimized && hidden.indexOf(w.id) < 0)
    const stashed = id => (windows ?? []).some(w => w.workspace_id === id) && !shown.some(w => w.workspace_id === id)
    const mine = (workspaces ?? []).filter(ws => (!output || ws.output === output) && !stashed(ws.id))
        .slice().sort((a, b) => a.idx - b.idx)
    const out = mine.map(ws => {
        const own = shown.filter(w => w.workspace_id === ws.id)
        const byColumn = {}
        const floating = []
        for (const w of own) {
            const pos = w.layout?.pos_in_scrolling_layout
            if (w.is_floating || !pos || pos.length < 2) floating.push(w)
            else (byColumn[pos[0]] = byColumn[pos[0]] ?? []).push(w)
        }
        // Niri's own memory of the workspace's window; is_focused only stands in where it has none.
        const remembered = Number(ws.active_window_id ?? (own.find(w => w.is_focused)?.id ?? -1))
        const columns = Object.keys(byColumn).map(Number).sort((a, b) => a - b).map(index => {
            const tiles = byColumn[index].slice().sort((a, b) => a.layout.pos_in_scrolling_layout[1] - b.layout.pos_in_scrolling_layout[1])
            const width = Math.max(...tiles.map(w => Number(w.layout?.tile_size?.[0] ?? 0)))
            return { share: share(width, screenWidth), windows: tiles.map(w => windowOf(w, remembered)) }
        })
        if (floating.length > 0)
            columns.push({ share: 0.3, floating: true, windows: floating.map(w => windowOf(w, remembered)) })
        return {
            id: ws.id,
            idx: ws.idx,
            name: String(ws.name ?? ""),
            active: Boolean(ws.is_active),
            columns: columns,
            count: own.length
        }
    })
    // Niri always keeps one empty workspace at the bottom: it is drawn only while it is the one in use.
    while (out.length > 1 && out[out.length - 1].count === 0 && !out[out.length - 1].active) out.pop()
    return out
}

// `here`: the window the workspace comes back to (Niri's own focus while it is in use): one per workspace.
function windowOf(w, remembered) {
    return { id: w.id, app: String(w.app_id ?? ""), here: w.id === remembered }
}

// The lanes a face has room for: the one in use always, its neighbours around it, kept in Niri's order. An empty
// workspace is drawn thin, so it leaves room for one more.
function around(all, most) {
    const pick = n => {
        const at = Math.max(0, all.findIndex(lane => lane.active))
        const from = Math.max(0, Math.min(at - Math.floor((n - 1) / 2), all.length - n))
        return all.slice(from, from + n)
    }
    if (all.length <= most) return all
    const first = pick(most)
    return first.some(lane => lane.count === 0) ? pick(most + 1) : first
}

// How many screens wide the widest lane runs: every lane is drawn at one scale, so widths compare across lanes.
function span(shown) {
    let most = 1
    for (const lane of shown)
        most = Math.max(most, lane.columns.reduce((sum, column) => sum + column.share, 0))
    return most
}

function count(all) {
    return all.reduce((sum, lane) => sum + lane.count, 0)
}

function active(all) {
    return all.find(lane => lane.active) ?? null
}

// The window in focus on the workspace in use (null on an empty one): Prism passes its light whole only then.
function here(all) {
    const lane = active(all)
    if (!lane) return null
    for (const column of lane.columns)
        for (const w of column.windows) if (w.here) return w
    return null
}
