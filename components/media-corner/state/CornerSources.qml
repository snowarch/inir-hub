pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "streams.js" as Streams
import "sources.js" as Sources
import "http.js" as Http

// The sources the person added. The Corner ships none: a Stremio add-on is added by its manifest's address, a web source
// by a URL with %s where the title goes. They are kept as JSON text in the Corner's options file.
Singleton {
    id: root

    // { type: "stremio", name, url, on, types, prefixes } | { type: "web", name, template, on }
    readonly property var data: Sources.migrate(CornerState.options.sources || "[]")
    readonly property var list: root.data.sources
    readonly property int invalid: root.data.invalid
    readonly property var addons: root.list.filter(s => s.type === "stremio" && s.on && s.hasStreams !== false && s.streamsEnabled !== false)
    readonly property var subtitles: root.list.filter(s => s.type === "stremio" && s.on && s.hasSubtitles !== false && s.subtitlesEnabled !== false)
    readonly property var webs: root.list.filter(s => s.type === "web" && s.on)

    function _save(next: var): void {
        if (!root.data.recognized || root.migrationPending) return
        CornerState.set("sources", JSON.stringify({ schemaVersion: 1, sources: next }))
    }
    readonly property bool migrationPending: String(CornerState.options.sources).trim().startsWith("[")
    function remove(index: int): void { root._save(root.list.filter((s, i) => i !== index)) }
    function toggle(index: int): void {
        root._save(root.list.map((s, i) => i === index ? Object.assign({}, s, { on: !s.on }) : s))
    }
    // Source order is the person's priority. A blank alias restores the manifest name.
    function move(index: int, delta: int): void {
        const destination = index + delta
        if (index < 0 || index >= root.list.length || destination < 0 || destination >= root.list.length || Math.abs(delta) !== 1) return
        const next = root.list.slice()
        const source = next[index]
        next[index] = next[destination]
        next[destination] = source
        root._save(next)
    }
    function setAlias(index: int, alias: string): void {
        root._save(root.list.map((s, i) => i === index ? Object.assign({}, s, { alias: alias.trim().slice(0, 80) }) : s))
    }
    function setCapability(index: int, capability: string, enabled: bool): void {
        if (capability !== "streams" && capability !== "subtitles") return
        const key = capability === "streams" ? "streamsEnabled" : "subtitlesEnabled"
        root._save(root.list.map((s, i) => i === index && s.type === "stremio" ? Object.assign({}, s, { [key]: enabled }) : s))
    }
    function displayName(source: var): string { return String(source?.alias || source?.name || "") }
    property var refreshErrors: ({})
    property var previewCallback: null
    function cancelPreview(): void {
        CornerState.cancelAsk(root.previewCallback)
        root.previewCallback = null
    }
    function previewAddon(address: string, refreshing: bool, callback: var): void {
        root.cancelPreview()
        if (!root.data.recognized || root.migrationPending) { callback(null, Translation.tr("Sources are not ready; try again")); return }
        const base = Streams.baseOf(address)
        if (!base) { callback(null, Translation.tr("Not an add-on address: it starts with https:// and ends in /manifest.json")); return }
        const url = base + "/manifest.json"
        if (!refreshing && root.list.some(s => s.url === url)) { callback(null, Translation.tr("It is already here")); return }
        const received = (manifest, error, retryAfter) => {
            root.previewCallback = null
            if (error) {
                const reason = error === "busy" ? Translation.tr("The provider limited requests; try again later") + (retryAfter ? " · " + Translation.tr("Retry-After: %1").arg(Http.retryDisplay(retryAfter)) : "") : Translation.tr("It doesn't answer")
                callback(null, reason); return
            }
            let info = Streams.manifestInfo(manifest)
            // A refreshed manifest may withdraw both capabilities; show that change before applying it.
            if (!info && refreshing && Array.isArray(manifest?.resources)) info = {
                name: String(manifest.name ?? "").slice(0, 40), types: [], prefixes: [], streamTypes: [], streamPrefixes: [],
                subtitleTypes: [], subtitlePrefixes: [], hasStreams: false, hasSubtitles: false
            }
            if (info === null) { callback(null, Translation.tr("It lists no streams")); return }
            callback({ url, info, checkedAt: Date.now(), refreshing }, "")
        }
        root.previewCallback = received
        CornerState.ask(url, "", manifest => manifest, received, refreshing)
    }
    function applyPreview(preview: var): bool {
        if (!preview || !root.data.recognized || root.migrationPending) return false
        const info = preview.info, url = preview.url
        const old = root.list.find(s => s.type === "stremio" && s.url === url)
        if (preview.refreshing ? !old : Boolean(old)) return false
        const updated = Sources.applyManifest(old, info, url, preview.checkedAt, Streams.hostOf(url))
        if (old) root._save(root.list.map(s => s === old ? updated : s))
        else root._save(root.list.concat([updated]))
        return true
    }
    function addWeb(name: string, template: string): string {
        if (!root.data.recognized || root.migrationPending) return Translation.tr("Sources are not ready; try again")
        const label = name.trim(), address = template.trim()
        if (label.length === 0) return Translation.tr("Give it a name")
        if (!Sources.webUrl(address, "test")) return Translation.tr("It starts with https:// and has %s where the title goes")
        root._save(root.list.concat([{ type: "web", name: label.slice(0, 40), template: address, on: true }]))
        return ""
    }
}
