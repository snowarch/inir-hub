.pragma library

// How a command's answer is drawn, decided by its shape. Kept apart from the faces so the desktop
// card and the iRiS line never disagree.
//   { kind: "percent", figure: "62%", unit: "", fraction: 0.62 }   first line starts with a percentage
//   { kind: "number",  figure: "14",  unit: "updates" }             first line is a number and a short word
//   { kind: "text",    lines: [...] }                                anything else, up to `max` lines
//   { kind: "empty" }                                                nothing printed
function read(answer, max) {
    const text = String(answer || "").trim()
    if (text.length === 0)
        return { kind: "empty", figure: "", unit: "", fraction: 0, lines: [] }
    const all = text.split("\n").map(line => line.replace(/\s+$/, ""))
    const first = all[0].trim()
    const percent = /^(-?\d+(?:[.,]\d+)?)\s*%\s*(.{0,24})$/.exec(first)
    if (percent && all.length === 1) {
        const value = Number(percent[1].replace(",", "."))
        return { kind: "percent", figure: `${percent[1]}%`, unit: percent[2].trim(), fraction: Math.max(0, Math.min(1, value / 100)), lines: [] }
    }
    const number = /^(-?\d+(?:[.,]\d+)?)(?:\s*(\S.{0,18}))?$/.exec(first)
    if (number && all.length === 1)
        return { kind: "number", figure: number[1], unit: (number[2] || "").trim(), fraction: 0, lines: [] }
    return { kind: "text", figure: "", unit: "", fraction: 0, lines: all.slice(0, Math.max(1, max)) }
}

// "Every" in the instrument footer: 45 s, 5 min, 2 h.
function every(seconds) {
    if (seconds < 60)
        return `${seconds} s`
    if (seconds < 3600)
        return `${Math.round(seconds / 60)} min`
    return `${Math.round(seconds / 360) / 10} h`
}
