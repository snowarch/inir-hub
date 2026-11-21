.pragma library
// SPDX-License-Identifier: GPL-3.0-or-later
// Display Projection's rules, apart from any QML so they can be tested on their own: which displays there are, which
// mode is on, and the steps each mode takes. A display is always turned on before another one is turned off, so the
// person is never left without a screen.

var MODES = ["pcOnly", "duplicate", "extend", "secondOnly"]

// Built-in panels (a laptop's own screen) use these connectors.
function isInternal(name) {
    return /^(eDP|LVDS|DSI)/.test(String(name))
}

function _number(value) {
    var n = Number(value)
    return isFinite(n) && n > 0 ? Math.round(n) : 0
}

// What `niri msg -j outputs` prints, as a list: the built-in panel first, then the rest by connector name.
// Throws when the text is not that JSON object.
function parseOutputs(text) {
    var data = JSON.parse(text)
    if (!data || typeof data !== "object" || Array.isArray(data))
        throw new Error("not an object of outputs")
    var list = []
    var keys = Object.keys(data)
    for (var i = 0; i < keys.length; i++) {
        var o = data[keys[i]]
        if (!o || typeof o !== "object")
            continue
        var modes = Array.isArray(o.modes) ? o.modes : []
        var mode = (typeof o.current_mode === "number" ? modes[o.current_mode] : null)
            || modes.find(function (m) { return m && m.is_preferred })
            || modes[0]
            || null
        list.push({
            name: String(o.name || keys[i]),
            make: String(o.make || ""),
            model: String(o.model || ""),
            enabled: o.logical !== null && o.logical !== undefined,
            width: _number(mode && mode.width),
            height: _number(mode && mode.height)
        })
    }
    list.sort(function (a, b) {
        var ai = isInternal(a.name), bi = isInternal(b.name)
        if (ai !== bi)
            return ai ? -1 : 1
        return a.name < b.name ? -1 : a.name > b.name ? 1 : 0
    })
    return list
}

// The name people know a display by: its model when the display reports a real one, its connector otherwise.
function label(output) {
    var model = String((output && output.model) || "").trim()
    if (!model || model.indexOf("0x") === 0 || model === "Unknown")
        return String((output && output.name) || "")
    return model
}

// "2560×1440", or "" when the display reports no mode.
function size(output) {
    return output && output.width > 0 && output.height > 0 ? output.width + "×" + output.height : ""
}

// The main display: the first built-in panel, otherwise the first display.
function primary(outputs) {
    var list = outputs || []
    return list.find(function (o) { return isInternal(o.name) }) || list[0] || null
}

// Every display but the main one.
function externals(outputs) {
    var main = primary(outputs)
    return (outputs || []).filter(function (o) { return !main || o.name !== main.name })
}

// The second display to use: the one asked for when it is connected, else the first one.
function resolveTarget(outputs, requested) {
    var list = externals(outputs)
    return list.find(function (o) { return o.name === requested }) || list[0] || null
}

// Fullscreen mirrors among the lines `pgrep -a -x wl-mirror` prints ("<pid> wl-mirror <args…>"): the kind this
// component starts. A wl-mirror someone runs in a window of its own is left alone.
function parseMirrors(text) {
    var found = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].trim().split(/\s+/)
        if (parts.length < 2 || !/^[0-9]+$/.test(parts[0]))
            continue
        var args = parts.slice(2)
        var flag = args.indexOf("--fullscreen-output")
        if (flag < 0)
            flag = args.indexOf("-F")
        var fullscreen = flag >= 0 || args.indexOf("--fullscreen") >= 0 || args.indexOf("-f") >= 0
        if (!fullscreen)
            continue
        found.push({
            pid: parts[0],
            target: flag >= 0 && flag + 1 < args.length ? args[flag + 1] : "",
            source: args.length > 0 && args[args.length - 1].charAt(0) !== "-" ? args[args.length - 1] : ""
        })
    }
    return found
}

// The mode on now, from the displays and whether a mirror runs; "" when there is no display at all.
function detectMode(outputs, mirroring) {
    var main = primary(outputs)
    if (!main)
        return ""
    var externalOn = externals(outputs).some(function (o) { return o.enabled })
    if (!externalOn)
        return "pcOnly"
    if (!main.enabled)
        return "secondOnly"
    return mirroring ? "duplicate" : "extend"
}

// The steps that put `mode` on, in order: { steps: [...] } or { error: "noDisplays" | "noSecond" | "unknownMode" }.
// A step is { kind: "on" | "off", name }, { kind: "stop", pids }, { kind: "wait", name } (until that display is on)
// or { kind: "mirror", source, target }. Displays already as wanted are left alone.
function plan(mode, outputs, requested, mirrors) {
    if (MODES.indexOf(mode) < 0)
        return { error: "unknownMode" }
    var main = primary(outputs)
    if (!main)
        return { error: "noDisplays" }
    var steps = []
    var pids = (mirrors || []).map(function (m) { return m.pid })
    function on(o) { if (!o.enabled) steps.push({ kind: "on", name: o.name }) }
    function off(o) { if (o.enabled) steps.push({ kind: "off", name: o.name }) }
    function stop() { if (pids.length > 0) steps.push({ kind: "stop", pids: pids }) }

    if (mode === "pcOnly") {
        on(main)
        stop()
        externals(outputs).forEach(off)
        return { steps: steps }
    }
    var target = resolveTarget(outputs, requested)
    if (!target)
        return { error: "noSecond" }
    if (mode === "secondOnly") {
        on(target)
        stop()
        off(main)
        return { steps: steps }
    }
    on(main)
    on(target)
    stop()
    if (mode === "duplicate") {
        steps.push({ kind: "wait", name: target.name })
        steps.push({ kind: "mirror", source: main.name, target: target.name })
    }
    return { steps: steps }
}

// Whether the steps turn off the display called `name`.
function turnsOff(steps, name) {
    return (steps || []).some(function (s) { return s.kind === "off" && s.name === name })
}
