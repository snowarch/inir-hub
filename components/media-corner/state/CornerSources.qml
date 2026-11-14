pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "streams.js" as Streams
import "sources.js" as Sources

// The sources the person added. The Corner ships none: a Stremio add-on is added by its manifest's address, a web source
// by a URL with %s where the title goes. They are kept as JSON text in the Corner's options file.
Singleton {
    id: root

    // { type: "stremio", name, url, on, types, prefixes } | { type: "web", name, template, on }
    readonly property var data: Sources.migrate(CornerState.options.sources || "[]")
    readonly property var list: root.data.sources
    readonly property int invalid: root.data.invalid
    readonly property var addons: root.list.filter(s => s.type === "stremio" && s.on && s.hasStreams !== false)
    readonly property var subtitles: root.list.filter(s => s.type === "stremio" && s.on && s.hasSubtitles !== false)
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
    property var refreshErrors: ({})
    function refreshAddon(url: string, callback: var): void {
        CornerState.ask(url, "", manifest => manifest, (manifest, error) => {
            if (error) { callback(Translation.tr("It doesn't answer")); return }
            const info = Streams.manifestInfo(manifest)
            if (info === null) { callback(Translation.tr("It lists no streams")); return }
            root._save(root.list.map(s => s.type === "stremio" && s.url === url ? Object.assign({}, s, {
                types: info.types, prefixes: info.prefixes, streamTypes: info.streamTypes, streamPrefixes: info.streamPrefixes,
                subtitleTypes: info.subtitleTypes, subtitlePrefixes: info.subtitlePrefixes,
                hasStreams: info.hasStreams, hasSubtitles: info.hasSubtitles
            }) : s))
            callback("")
        }, true)
    }
    function addWeb(name: string, template: string): string {
        if (!root.data.recognized || root.migrationPending) return Translation.tr("Sources are not ready; try again")
        const label = name.trim(), address = template.trim()
        if (label.length === 0) return Translation.tr("Give it a name")
        if (!Sources.webUrl(address, "test")) return Translation.tr("It starts with https:// and has %s where the title goes")
        root._save(root.list.concat([{ type: "web", name: label.slice(0, 40), template: address, on: true }]))
        return ""
    }
    // callback(error): empty when it was added.
    function addAddon(address: string, callback: var): void {
        if (!root.data.recognized || root.migrationPending) { callback(Translation.tr("Sources are not ready; try again")); return }
        const base = Streams.baseOf(address)
        if (base.length === 0) { callback(Translation.tr("Not an add-on address: it starts with https:// and ends in /manifest.json")); return }
        const url = base + "/manifest.json"
        if (root.list.some(s => s.url === url)) { callback(Translation.tr("It is already here")); return }
        CornerState.ask(url, "", manifest => manifest, (manifest, error) => {
            if (error) { callback(Translation.tr("It doesn't answer")); return }
            const info = Streams.manifestInfo(manifest)
            if (info === null) { callback(Translation.tr("It lists no streams")); return }
            root._save(root.list.concat([{ type: "stremio", name: info.name || Streams.hostOf(url), url, on: true, types: info.types, prefixes: info.prefixes, streamTypes: info.streamTypes, streamPrefixes: info.streamPrefixes, subtitleTypes: info.subtitleTypes, subtitlePrefixes: info.subtitlePrefixes, hasStreams: info.hasStreams, hasSubtitles: info.hasSubtitles }]))
            callback("")
        })
    }
}
