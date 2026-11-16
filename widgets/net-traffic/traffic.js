.pragma library

// The one reading every face draws: the interface the default route uses (what carries the traffic now), its bytes in
// and out from /proc/net/dev turned into rates each second, and a minute of them, newest last.

// /proc/net/route: Iface Destination Gateway Flags RefCnt Use Metric ...; the default route with the lowest metric.
function routeOf(text) {
    let best = null
    for (const line of String(text ?? "").split("\n").slice(1)) {
        const f = line.trim().split(/\s+/)
        if (f.length < 7 || f[1] !== "00000000") continue
        if (!best || Number(f[6]) < Number(best[6])) best = f
    }
    return best ? best[0] : ""
}

// /proc/net/dev: "  wlan0: rx_bytes rx_packets ... (eight receive fields) tx_bytes ..."; null when it is not listed.
function countersOf(text, iface) {
    if (!iface) return null
    const line = String(text ?? "").split("\n").find(l => l.trim().startsWith(iface + ":"))
    if (!line) return null
    const f = line.slice(line.indexOf(":") + 1).trim().split(/\s+/)
    const rx = Number(f[0])
    const tx = Number(f[8])
    return isFinite(rx) && isFinite(tx) ? { rx: rx, tx: tx } : null
}

// What kind of link it is, from the kernel's name for it (systemd's predictable names and the usual tunnels).
function kindOf(iface) {
    const name = String(iface ?? "")
    if (/^(wl|ath|ra\d)/.test(name)) return "wifi"
    if (/^(en|eth|em\d)/.test(name)) return "ethernet"
    if (/^(wg|tun|tap|tailscale|ppp|nordlynx|proton|vpn)/.test(name)) return "tunnel"
    if (/^(ww|usb|rmnet)/.test(name)) return "mobile"
    return "other"
}

// The newest sample last, a minute kept.
function pushed(samples, sample, keep) {
    const next = samples.slice(-(keep - 1))
    next.push(sample)
    return next
}

// A rate in the person's unit, as [figure, unit]: bytes step by 1024 (KB/s, MB/s, as file managers and the Network
// overlay say), bits by 1000 (Mb/s, as an internet plan is sold). Three figures at most: 8.2, 45, 312.
function rate(bytesPerSecond, bits) {
    const units = bits ? ["b/s", "kb/s", "Mb/s", "Gb/s"] : ["B/s", "KB/s", "MB/s", "GB/s"]
    const step = bits ? 1000 : 1024
    let value = Math.max(0, Number(bytesPerSecond) || 0) * (bits ? 8 : 1)
    let unit = 0
    while (value >= 999.5 && unit < units.length - 1) {
        value /= step
        unit++
    }
    return [unit > 0 && value < 9.95 ? value.toFixed(1) : String(Math.round(value)), units[unit]]
}

// An amount of data, as [figure, unit] (bytes, 1024 each step).
function amount(bytes) {
    const units = ["B", "KB", "MB", "GB", "TB"]
    let value = Math.max(0, Number(bytes) || 0)
    let unit = 0
    while (value >= 999.5 && unit < units.length - 1) {
        value /= 1024
        unit++
    }
    return [unit > 0 && value < 9.95 ? value.toFixed(1) : String(Math.round(value)), units[unit]]
}

// Both directions on one scale, so in and out compare. Logarithmic from 16 KB/s, because a link hums near nothing and
// peaks a thousand times higher: a download and the upload beside it both read. The ceiling is the minute's highest,
// 256 KB/s at least, so the idle hum stays near the line.
function ceilingOf(downs, ups) {
    let most = 256 * 1024
    for (const v of downs) most = Math.max(most, v)
    for (const v of ups) most = Math.max(most, v)
    return most
}
function levels(values, ceiling) {
    const top = Math.log(1 + ceiling / 16384)
    return values.map(v => Math.max(0, Math.min(1, Math.log(1 + Math.max(0, v) / 16384) / top)))
}

// The height at t in 0..1 across the drawn samples, the Hermite curve the iRiS faces draw (IrisFaceData.smooth).
function smooth(values, t) {
    const n = values.length
    if (n === 0) return 0
    const x = t * n - 0.5
    if (x <= 0) return values[0]
    if (x >= n - 1) return values[n - 1]
    const i = Math.floor(x)
    const f = x - i
    const p0 = values[i]
    const p1 = values[i + 1]
    const m0 = (p1 - values[Math.max(0, i - 1)]) / (i > 0 ? 2 : 1)
    const m1 = (values[Math.min(n - 1, i + 2)] - p0) / (i + 2 < n ? 2 : 1)
    const f2 = f * f
    const f3 = f2 * f
    return Math.max(0, Math.min(1, (2 * f3 - 3 * f2 + 1) * p0 + (f3 - 2 * f2 + f) * m0 + (-2 * f3 + 3 * f2) * p1 + (f3 - f2) * m1))
}

// A light blur over the drawn seconds ([1 2 1] / 4): a link moves in bursts the eye reads as noise at one sample a
// second. Only the drawing: the figures stay the second's own.
function eased(values) {
    const last = values.length - 1
    return values.map((v, i) => (values[Math.max(0, i - 1)] + 2 * v + values[Math.min(last, i + 1)]) / 4)
}
