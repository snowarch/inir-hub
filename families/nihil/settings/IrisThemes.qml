pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.shared.background.widgets

Singleton {
    id: root

    readonly property string folder: FileUtils.trimFileProtocol(`${Directories.shellConfig}/iris/themes`)
    readonly property var excludedPaths: ["nihil.bar.position", "nihil.dock.launcher", "nihil.appearance.surfaces.cards.header",
        "nihil.appearance.surfaces.cards.devices", "nihil.appearance.surfaces.cards.mixer",
        "nihil.dock.magnifySize",
        "nihil.bubbles.extras.anime.enable", "nihil.anime.shows"]
    readonly property var extraPaths: [
        { path: "nihil.appearance.preset", fallback: "nihil" },
        // A theme that names no Design draws with NiHiL's own anatomy (DESIGNS.md).
        { path: "nihil.appearance.design", fallback: "nihil" },
        { path: "nihil.bar.composition", fallback: "cluster" },
        { path: "nihil.appearance.motionDuration", fallback: 220 },
        { path: "nihil.lock.material", fallback: "glass" },
        { path: "nihil.lock.type.clockWeight", fallback: 700 },
        { path: "nihil.lock.type.clockTracking", fallback: -2 },
        { path: "nihil.lock.type.accent", fallback: "plain" }
    ]
    readonly property var paths: {
        const seen = new Set()
        const out = []
        for (const entry of root.extraPaths) { seen.add(entry.path); out.push(entry) }
        for (const spec of IrisOptions.studio) {
            const path = String(spec.path ?? "")
            if (!path.startsWith("nihil.") || spec.kind === "pieces" || spec.fallback === undefined) continue
            if (seen.has(path) || root.excludedPaths.includes(path)) continue
            seen.add(path)
            out.push({ path: path, fallback: spec.fallback })
        }
        return out
    }
    readonly property var pathSet: new Set(root.paths.map(entry => entry.path))
    function owns(path: string): bool { return root.pathSet.has(path) }

    function resolved(values: var): var {
        const out = {}
        for (const entry of root.paths)
            out[entry.path] = Object.prototype.hasOwnProperty.call(values ?? {}, entry.path) ? values[entry.path] : entry.fallback
        return out
    }
    function current(): var {
        const out = {}
        for (const entry of root.paths) out[entry.path] = IrisOptions.plain(Config.getNestedValue(entry.path, entry.fallback))
        return out
    }
    function differences(values: var): var {
        const out = {}
        for (const entry of root.paths)
            if (!IrisOptions.same(values[entry.path], entry.fallback)) out[entry.path] = values[entry.path]
        return out
    }
    function apply(theme: var): void {
        if (!theme) return
        const updates = root.resolved(theme.values)
        // The widget design goes through its owner so every widget follows the theme and the looks
        // it replaces can be undone.
        const design = String(updates["nihil.widgets.design"] ?? "nihil")
        delete updates["nihil.widgets.design"]
        updates["nihil.appearance.themeId"] = String(theme.id ?? "")
        Config.setNestedValues(updates)
        DesktopWidgetDesign.apply(design)
    }
    // A theme's palette alone: what it colours, never how anything is shaped, laid out or moves.
    readonly property var colourPaths: ["nihil.appearance.accent", "nihil.appearance.highlight", "nihil.appearance.theme.accentHue",
        "nihil.appearance.theme.highlightHue", "nihil.appearance.theme.surface", "nihil.appearance.theme.badge", "nihil.appearance.aura",
        "nihil.appearance.theme.lightReach", "nihil.appearance.theme.glow", "nihil.appearance.tint", "nihil.appearance.theme.rimTint",
        "nihil.appearance.glass.edgeColour", "nihil.bar.clockAccent", "nihil.controlCenter.accent", "nihil.controlCenter.sliders",
        "nihil.lock.type.accent", "nihil.appearance.anime.enabled", "nihil.appearance.anime.palette", "nihil.appearance.anime.strength",
        "nihil.appearance.anime.highlight", "nihil.widgets.tint"]
    function applyColours(theme: var): void {
        if (!theme) return
        const all = root.resolved(theme.values)
        const updates = {}
        for (const path of root.colourPaths) if (Object.prototype.hasOwnProperty.call(all, path)) updates[path] = all[path]
        Config.setNestedValues(updates)
    }
    readonly property bool coloursOnly: Boolean(Config.options?.nihil?.appearance?.themeColoursOnly ?? false)
    // What choosing a theme does, as the person set it: the whole theme, or its colours.
    function choose(theme: var): void {
        if (root.coloursOnly) root.applyColours(theme)
        else root.apply(theme)
    }
    function find(id: string): var {
        return root.all.find(theme => theme.id === id) ?? null
    }
    readonly property string activeId: String(Config.options?.nihil?.appearance?.themeId ?? "nihil")
    readonly property var active: root.find(root.activeId)
    readonly property bool modified: {
        void Config.revision
        if (!root.active) return true
        const wanted = root.resolved(root.active.values)
        for (const entry of root.paths)
            if (!IrisOptions.same(Config.getNestedValue(entry.path, entry.fallback), wanted[entry.path])) return true
        return false
    }

    function slug(name: string): string {
        const base = String(name).toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        return base.length > 0 ? base.slice(0, 48) : "theme"
    }
    function document(theme: var): var {
        return { iris: "theme", version: 1, id: theme.id, name: theme.name, author: theme.author ?? "",
            description: theme.description ?? "", values: root.differences(root.resolved(theme.values)) }
    }
    function exportText(theme: var): string { return JSON.stringify(root.document(theme), null, 2) }
    function parse(text: string, fallbackId: string): var {
        let data = null
        try { data = JSON.parse(String(text).trim()) } catch (error) { return null }
        if (!data || (data.iris !== "theme" && data.iris !== "look") || typeof data.values !== "object") return null
        const values = {}
        for (const path of Object.keys(data.values)) if (root.owns(path)) values[path] = data.values[path]
        const name = String(data.name ?? "").trim() || Translation.tr("Imported theme")
        return { id: fallbackId.length > 0 ? fallbackId : root.slug(String(data.id ?? name)), name: name,
            author: String(data.author ?? ""), description: String(data.description ?? ""), values: values, user: true }
    }
    function uniqueId(base: string): string {
        let id = base
        let n = 2
        while (root.curated.some(theme => theme.id === id) || root.user.some(theme => theme.id === id && theme.id !== base)) id = `${base}-${n++}`
        return root.curated.some(theme => theme.id === id) ? `${base}-mine` : id
    }
    function save(name: string, description: string): string {
        const clean = String(name).trim() || Translation.tr("My theme %1").arg(root.user.length + 1)
        const id = root.uniqueId(root.slug(clean))
        const theme = { id: id, name: clean, author: Quickshell.env("USER") ?? "", description: String(description ?? "").trim(),
            values: root.differences(root.current()) }
        root.write(theme)
        Config.setNestedValue("nihil.appearance.themeId", id)
        return id
    }
    function importText(text: string): var {
        const theme = root.parse(text, "")
        if (!theme) return null
        theme.id = root.uniqueId(theme.id)
        root.write(theme)
        return theme
    }
    function importFile(path: string): void {
        importer.command = ["cat", FileUtils.trimFileProtocol(path)]
        importer.running = true
    }
    function remove(id: string): void {
        if (!root.user.some(theme => theme.id === id)) return
        writer.exec(["rm", "-f", `${root.folder}/${id}.json`])
    }
    function reveal(): void {
        Quickshell.execDetached(["bash", "-c", 'mkdir -p "$1" && xdg-open "$1"', "reveal", root.folder])
    }
    function write(theme: var): void { root.writeAll([theme]) }
    function writeAll(themes: var): void {
        const args = []
        for (const theme of themes) args.push(theme.id, root.exportText(theme))
        writer.exec(["python3", "-c", "import os,sys\nd=sys.argv[1]\nos.makedirs(d,exist_ok=True)\na=sys.argv[2:]\nfor i in range(0,len(a),2): open(os.path.join(d,a[i]+'.json'),'w',encoding='utf-8').write(a[i+1]+'\\n')",
            root.folder].concat(args))
    }
    signal imported(var theme)
    Process {
        id: importer
        stdout: StdioCollector {
            id: importedText
            onStreamFinished: {
                const theme = root.importText(importedText.text)
                root.imported(theme)
            }
        }
    }
    Process {
        id: writer
        onExited: root.reload()
    }

    // A theme installed or removed from the community hub is one more user theme.
    Connections {
        target: Hub
        function onChanged(kind: string, id: string): void {
            if (kind === "iris-theme")
                root.reload()
        }
    }

    property var user: []
    function reload(): void {
        loader.running = false
        loader.running = true
    }
    Process {
        id: loader
        command: ["python3", "-c", "import os,sys,json\nd=sys.argv[1]\nout=[]\nfor f in sorted(os.listdir(d)) if os.path.isdir(d) else []:\n  if f.endswith('.json'):\n    try: out.append([f[:-5], open(os.path.join(d,f),encoding='utf-8').read()])\n    except Exception: pass\nprint(json.dumps(out))",
            root.folder]
        stdout: StdioCollector {
            id: listing
            onStreamFinished: {
                let rows = []
                try { rows = JSON.parse(listing.text) } catch (error) { rows = [] }
                root.user = rows.map(row => root.parse(row[1], row[0])).filter(theme => theme !== null)
            }
        }
    }
    FolderListModel {
        id: watcher
        folder: `file://${root.folder}`
        nameFilters: ["*.json"]
        showDirs: false
        onCountChanged: root.reload()
    }
    Component.onCompleted: {
        root.reload()
        root.migrateSaved()
    }
    function migrateSaved(): void {
        const saved = Array.from(Config.options?.nihil?.appearance?.saved ?? [])
        if (saved.length === 0) return
        const themes = []
        for (const entry of saved) {
            const theme = root.parse(JSON.stringify({ iris: "look", name: entry?.name, values: entry?.values ?? {} }), "")
            if (!theme) continue
            theme.id = root.uniqueId(theme.id)
            if (!themes.some(other => other.id === theme.id)) themes.push(theme)
        }
        if (themes.length > 0) root.writeAll(themes)
        Config.setNestedValue("nihil.appearance.saved", [])
    }

    // A look worn over a Design (its values name one) is offered while that Design is installed.
    readonly property var all: root.curated.concat(root.user)
        .filter(theme => IrisDesign.known.includes(String(theme?.values?.["nihil.appearance.design"] ?? "nihil")))

    function swatch(theme: var): var {
        const v = root.resolved(theme?.values ?? {})
        // the accent the shell will wear: vivid, like IrisStyle.baseAccent, or the swatch shows a pastel nothing uses
        const baseAccent = IrisStyle.vivid(IrisStyle.accentFrom(String(v["nihil.appearance.accent"] ?? "blue"), v["nihil.appearance.theme.accentHue"]), false)
        const animeOn = Boolean(v["nihil.appearance.anime.enabled"] ?? false)
        const animePalette = String(v["nihil.appearance.anime.palette"] ?? "sakura")
        const animeStrength = Number(v["nihil.appearance.anime.strength"] ?? 0) / 100
        const accent = animeOn ? IrisStyle.animeAccent(baseAccent, animePalette, animeStrength) : baseAccent
        const baseHighlight = IrisStyle.highlightFrom(String(v["nihil.appearance.highlight"] ?? "orange"), v["nihil.appearance.theme.highlightHue"], baseAccent)
        const highlight = animeOn && Boolean(v["nihil.appearance.anime.highlight"] ?? false)
            ? IrisStyle.animeHighlight(baseHighlight, animePalette, animeStrength) : baseHighlight
        const preset = IrisStyle.presets[v["nihil.appearance.preset"]] ?? IrisStyle.presets.iris
        return {
            surface: IrisStyle.materialSwatch(String(v["nihil.appearance.theme.surface"])),
            accent: accent,
            highlight: highlight,
            glass: v["nihil.appearance.glass.mode"] !== "off",
            tint: Number(v["nihil.appearance.glass.tint"]) / 100,
            shape: preset.shape * Number(v["nihil.appearance.theme.shape"]) / 100,
            pieceShape: String(v["nihil.appearance.theme.pieceShape"]),
            lines: Number(v["nihil.appearance.theme.lines"]) / 100,
            rim: Boolean(v["nihil.appearance.theme.rim"]),
            titleFont: IrisStyle.face("nihil.appearance.titleFontFamily", v["nihil.appearance.titleFontFamily"]),
            numbersFont: IrisStyle.face("nihil.appearance.numbersFontFamily", v["nihil.appearance.numbersFontFamily"]),
            figureWeight: ({ light: Font.Light, regular: Font.Normal })[v["nihil.appearance.figureWeight"]] ?? Font.Bold,
            framed: Boolean(v["nihil.surround.enable"]),
            notch: Boolean(v["nihil.bar.notch"]),
            dockNotch: Boolean(v["nihil.dock.notch"]),
            dockPosition: String(v["nihil.dock.position"] ?? "auto"),
            layout: String(v["nihil.bar.layout"]),
            clearStrip: String(v["nihil.bar.strip"] ?? "clear") === "clear",
            clockAccent: String(v["nihil.bar.clockAccent"])
        }
    }

    readonly property string a: "nihil.appearance."
    readonly property string t: "nihil.appearance.theme."
    function values(pairs: var): var {
        const out = {}
        for (const key of Object.keys(pairs)) {
            const path = key.startsWith("nihil.") ? key : key.startsWith("theme.") ? root.a + key : key.startsWith("glass.") || key.startsWith("surfaces.") ? root.a + key : key
            out[path] = pairs[key]
        }
        return out
    }
    readonly property var curated: [
        { id: "nihil", name: "NiHiL", author: "iNiR", tags: ["dark", "direct"],
            values: ({}) },
        { id: "liquid-glass", name: "Liquid Glass", author: "iNiR", tags: ["glass", "round", "springy"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "plain", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "neutral", "glass.mode": "wallpaper", "glass.tint": 42, "glass.blur": 100, "theme.rim": false, "nihil.appearance.preset": "round",
                "theme.shape": 115, "theme.melt": 55, "theme.lines": 0, "theme.shadow": 110, "theme.glow": 20, "nihil.appearance.aura": "vivid",
                "theme.lightReach": 170, "nihil.appearance.accent": "wallpaper", "nihil.appearance.highlight": "wallpaper",
                "nihil.appearance.fontFamily": "Roboto Flex", "nihil.appearance.numbersFontFamily": "Roboto Flex", "nihil.appearance.figureWeight": "light",
                "nihil.appearance.morph": "liquid", "theme.bounce": 120, "nihil.bar.notch": true, "nihil.bar.height": 44, "nihil.bar.satelliteGap": 8,
                "nihil.bubbles.scale": 108, "nihil.surround.thickness": 8, "nihil.surround.radius": 30, "nihil.palette.opens": "island",
                "nihil.controlCenter.controls": "round", "nihil.widgets.material": "glass", "nihil.widgets.radius": 30, "nihil.widgets.weight": "light",
                "nihil.dock.material": "inherit", "nihil.dock.magnification": false, "nihil.dock.iconSize": 44 }) },
        { id: "frost", name: "Frost", author: "iNiR", tags: ["glass", "bar", "calm"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "glass.mode": "wallpaper", "glass.tint": 56, "glass.blur": 100, "theme.surface": "graphite", "theme.rim": false,
                "nihil.appearance.preset": "soft", "theme.lines": 35, "theme.shadow": 80, "theme.melt": 15, "nihil.appearance.accent": "custom",
                "theme.accentHue": 196, "nihil.appearance.highlight": "custom", "theme.highlightHue": 188, "nihil.appearance.aura": "subtle",
                "nihil.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 115, "nihil.appearance.figureWeight": "light",
                "nihil.appearance.fontFamily": "Roboto Flex", "nihil.appearance.numbersFontFamily": "Roboto Flex", "nihil.appearance.titleFontFamily": "Roboto Flex",
                "nihil.bar.layout": "full", "nihil.bar.notch": true, "nihil.bar.height": 38, "nihil.bar.composition": "unified", "nihil.bar.clockStyle": "time",
                "nihil.bar.clockAccent": "accent", "nihil.surround.enable": false, "nihil.widgets.material": "glass", "nihil.widgets.radius": 18,
                "nihil.widgets.weight": "light", "nihil.dock.notch": false, "nihil.dock.iconSize": 38, "nihil.dock.magnification": false,
                "nihil.controlCenter.controls": "round" }) },
        { id: "obsidian", name: "Obsidian", author: "iNiR", tags: ["sharp", "technical"],
            values: root.values({ "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 600, "nihil.lock.type.clockTracking": -4, "nihil.lock.type.accent": "plain", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "neutral", "nihil.appearance.preset": "angular", "theme.shape": 70, "theme.pieceShape": "squircle", "theme.surface": "black",
                "theme.lines": 130, "theme.rim": false, "theme.shadow": 150, "theme.fill": 115, "nihil.dock.notch": false,
                "nihil.appearance.aura": "off", "nihil.appearance.accent": "lilac", "nihil.appearance.highlight": "accent",
                "theme.badge": "accent", "nihil.appearance.morph": "snap", "theme.curve": "swift", "theme.openTime": 80, "theme.press": 60,
                "nihil.appearance.fontFamily": "Space Grotesk", "nihil.appearance.titleFontFamily": "Space Grotesk", "nihil.appearance.numbersFontFamily": "Space Grotesk",
                "nihil.appearance.figureWeight": "regular", "nihil.surround.thickness": 14, "nihil.surround.radius": 8, "nihil.bar.layout": "left",
                "nihil.bar.margin": 12, "nihil.bar.notchCurve": 55, "nihil.bar.clockAccent": "plain", "nihil.bar.clockStyle": "time", "nihil.bar.blockStyle": "grouped",
                "nihil.controlCenter.controls": "tiles", "nihil.widgets.material": "solid", "nihil.widgets.radius": 6, "nihil.widgets.weight": "regular",
                "nihil.dock.material": "solid", "nihil.dock.iconSize": 40 , "nihil.appearance.expandedRadius": 16}) },
        { id: "aurora", name: "Aurora", author: "iNiR", tags: ["wallpaper", "vivid", "soft"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 200, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "colourful", "nihil.controlCenter.sliders": "accent", "theme.surface": "wallpaper", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 44, "nihil.appearance.tint": 60,
                "nihil.appearance.aura": "vivid", "theme.lightReach": 260, "theme.glow": 20, "nihil.appearance.accent": "wallpaper",
                "nihil.appearance.highlight": "wallpaper", "nihil.appearance.preset": "soft", "theme.shape": 125, "theme.melt": 60, "theme.lines": 0,
                "nihil.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 130, "nihil.appearance.titleFontFamily": "Gabarito",
                "nihil.appearance.figureWeight": "light", "nihil.bar.clockScale": 118, "nihil.bar.height": 46, "nihil.bar.desktopBanner": "wallpaper",
                "nihil.surround.thickness": 12, "nihil.surround.radius": 34, "nihil.widgets.material": "clear", "nihil.widgets.weight": "light",
                "nihil.widgets.radius": 34, "nihil.dock.magnification": false, "nihil.palette.opens": "island" }) },
        { id: "terminal", name: "Terminal", author: "iNiR", tags: ["mono", "brutalist", "bar"],
            values: root.values({ "nihil.lock.material": "none", "nihil.lock.type.clockWeight": 400, "nihil.lock.type.clockTracking": 0, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "nihil.appearance.fontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.titleFontFamily": "JetBrainsMono Nerd Font",
                "nihil.appearance.numbersFontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.figureWeight": "regular",
                "nihil.appearance.preset": "angular", "theme.shape": 35, "theme.pieceShape": "square", "theme.lines": 200,
                "theme.fill": 70, "theme.shadow": 0, "theme.rim": false, "nihil.bubbles.join": "weld", "nihil.appearance.aura": "off",
                "nihil.appearance.accent": "custom", "theme.accentHue": 135, "nihil.appearance.highlight": "green", "theme.badge": "highlight",
                "nihil.appearance.morph": "snap", "theme.bounce": 0, "theme.curve": "standard", "theme.openTime": 65,
                "theme.moveTime": 70, "theme.press": 30, "theme.text": 95, "theme.contrast": 125,
                "nihil.bar.layout": "full", "nihil.bar.notch": false, "nihil.bar.composition": "unified", "nihil.bar.clockStyle": "time",
                "nihil.bar.clockAccent": "accent", "nihil.bar.height": 34, "nihil.surround.thickness": 4, "nihil.surround.radius": 0,
                "nihil.widgets.material": "solid", "nihil.widgets.weight": "regular", "nihil.widgets.radius": 0, "nihil.dock.material": "solid",
                "nihil.dock.notch": false, "nihil.dock.iconSize": 34, "nihil.controlCenter.controls": "tiles", "nihil.palette.opens": "floating",
                "nihil.wallpaper.layout": "wall" , "nihil.appearance.expandedRadius": 16}) },
        { id: "neo-tokyo", name: "Neo Tokyo", author: "iNiR", tags: ["anime", "neon", "glass", "sci-fi"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 600, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "colourful", "nihil.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 58, "nihil.appearance.preset": "crisp",
                "theme.shape": 90, "theme.pieceShape": "squircle", "theme.lines": 120, "theme.shadow": 160, "theme.glow": 55,
                "nihil.appearance.accent": "custom", "theme.accentHue": 186, "nihil.appearance.highlight": "custom", "theme.highlightHue": 312,
                "nihil.appearance.aura": "vivid", "theme.lightReach": 210, "theme.badge": "highlight", "nihil.appearance.titleFontFamily": "Oxanium",
                "nihil.appearance.numbersFontFamily": "Oxanium", "nihil.appearance.morph": "elastic", "theme.bounce": 80, "nihil.bar.clockScale": 110,
                "nihil.appearance.glass.edgeColour": "accent", "nihil.appearance.glass.edgeLight": 70, "nihil.appearance.glass.edgeLine": 22, "nihil.surround.thickness": 12, "nihil.surround.radius": 16,
                "nihil.widgets.material": "tinted", "nihil.widgets.radius": 14, "nihil.widgets.weight": "bold", "theme.rim": false,
                "nihil.dock.notch": false, "nihil.dock.material": "glass", "nihil.dock.magnification": false }) },
        { id: "afterglow", name: "Afterglow", author: "iNiR", tags: ["retro", "amber", "chrome", "bloom", "crt"],
            values: root.values({ "nihil.appearance.texture": "afterglow", "nihil.appearance.afterglow.grade": "dusk", "nihil.appearance.afterglow.atmosphere": 75,
                "nihil.appearance.afterglow.chrome": 70, "nihil.appearance.afterglow.bloom": 60, "nihil.appearance.afterglow.signal": 40, "nihil.appearance.afterglow.wallpaper": true,
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 700, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "accent",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "nihil.appearance.preset": "crisp", "theme.shape": 85, "theme.pieceShape": "squircle", "theme.lines": 60, "theme.glow": 40, "theme.shadow": 120,
                "nihil.appearance.accent": "custom", "theme.accentHue": 32, "nihil.appearance.highlight": "custom", "theme.highlightHue": 170, "theme.badge": "highlight",
                "nihil.appearance.aura": "vivid", "theme.lightReach": 190, "nihil.appearance.titleFontFamily": "Oxanium", "nihil.appearance.numbersFontFamily": "Oxanium",
                "nihil.appearance.figureWeight": "bold", "nihil.appearance.morph": "snap", "theme.openTime": 90, "nihil.bar.clockAccent": "accent", "nihil.bar.clockScale": 110,
                "nihil.surround.thickness": 10, "nihil.surround.radius": 18, "nihil.widgets.material": "tinted", "nihil.widgets.radius": 14, "nihil.widgets.weight": "bold",
                "nihil.dock.material": "inherit", "nihil.dock.magnification": false, "nihil.controlCenter.controls": "tiles" }) },
        { id: "y2k", name: "Y2K", author: "iNiR", tags: ["retro", "ice", "lime", "chrome", "glass"],
            values: root.values({ "nihil.appearance.texture": "afterglow", "nihil.appearance.afterglow.grade": "cyber", "nihil.appearance.afterglow.atmosphere": 65,
                "nihil.appearance.afterglow.chrome": 90, "nihil.appearance.afterglow.bloom": 55, "nihil.appearance.afterglow.signal": 25, "nihil.appearance.afterglow.wallpaper": true,
                "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 600, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "highlight",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 64,
                "nihil.appearance.preset": "round", "theme.shape": 120, "theme.pieceShape": "circle", "theme.lines": 40, "theme.glow": 50,
                "nihil.appearance.accent": "custom", "theme.accentHue": 198, "nihil.appearance.highlight": "custom", "theme.highlightHue": 86, "theme.badge": "highlight",
                "nihil.appearance.aura": "subtle", "theme.lightReach": 160, "nihil.appearance.titleFontFamily": "Oxanium", "nihil.appearance.numbersFontFamily": "Oxanium",
                "nihil.appearance.figureWeight": "regular", "nihil.appearance.morph": "liquid", "theme.bounce": 90, "nihil.bar.clockAccent": "highlight",
                "nihil.surround.thickness": 10, "nihil.surround.radius": 30, "nihil.widgets.material": "glass", "nihil.widgets.radius": 26, "nihil.widgets.weight": "regular",
                "nihil.dock.material": "inherit", "nihil.dock.magnification": false, "nihil.controlCenter.controls": "round" }) },
        { id: "faded-light", name: "Faded Light", author: "iNiR", tags: ["analog", "film", "prism", "grain", "mono"],
            values: root.values({ "nihil.appearance.texture": "leak", "nihil.appearance.leak.grade": "prism", "nihil.appearance.leak.shape": "lens", "nihil.appearance.leak.light": 65,
                "nihil.appearance.leak.spill": 60, "nihil.appearance.leak.prism": 60, "nihil.appearance.leak.grain": 50, "nihil.appearance.leak.streaks": 0, "nihil.appearance.leak.backdrop": "light", "nihil.appearance.leak.wallpaper": 55,
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 400, "nihil.lock.type.clockTracking": 0, "nihil.lock.type.accent": "highlight",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "nihil.appearance.preset": "nihil", "theme.lines": 50, "theme.glow": 45, "theme.shadow": 100,
                "nihil.appearance.accent": "custom", "theme.accentHue": 252, "nihil.appearance.highlight": "custom", "theme.highlightHue": 188, "theme.badge": "highlight",
                "nihil.appearance.aura": "subtle", "nihil.appearance.fontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.titleFontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.numbersFontFamily": "JetBrainsMono Nerd Font",
                "nihil.appearance.figureWeight": "regular", "nihil.appearance.morph": "liquid", "nihil.bar.clockAccent": "highlight",
                "nihil.widgets.material": "tinted", "nihil.widgets.weight": "regular", "nihil.dock.material": "inherit", "nihil.controlCenter.controls": "tiles" }) },
        { id: "film-burn", name: "Film Burn", author: "iNiR", tags: ["analog", "film", "ember", "streaks", "warm"],
            values: root.values({ "nihil.appearance.texture": "leak", "nihil.appearance.leak.grade": "ember", "nihil.appearance.leak.shape": "burn", "nihil.appearance.leak.light": 70,
                "nihil.appearance.leak.spill": 60, "nihil.appearance.leak.prism": 35, "nihil.appearance.leak.grain": 55, "nihil.appearance.leak.streaks": 65, "nihil.appearance.leak.backdrop": "picture", "nihil.appearance.leak.wallpaper": 70,
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 700, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "accent",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "nihil.appearance.preset": "crisp", "theme.lines": 50, "theme.glow": 45, "theme.shadow": 110,
                "nihil.appearance.accent": "custom", "theme.accentHue": 26, "nihil.appearance.highlight": "custom", "theme.highlightHue": 44, "theme.badge": "accent",
                "nihil.appearance.aura": "vivid", "nihil.appearance.titleFontFamily": "Space Grotesk", "nihil.appearance.numbersFontFamily": "Space Grotesk",
                "nihil.appearance.figureWeight": "bold", "nihil.appearance.morph": "snap", "nihil.bar.clockAccent": "accent",
                "nihil.widgets.material": "tinted", "nihil.widgets.weight": "bold", "nihil.dock.material": "inherit", "nihil.controlCenter.controls": "tiles" }) },
        { id: "grain-orb", name: "Grain Orb", author: "iNiR", tags: ["analog", "grain", "gradient", "pink", "soft"],
            values: root.values({ "nihil.appearance.texture": "leak", "nihil.appearance.leak.grade": "orchid", "nihil.appearance.leak.shape": "orbs", "nihil.appearance.leak.light": 65,
                "nihil.appearance.leak.spill": 55, "nihil.appearance.leak.prism": 30, "nihil.appearance.leak.grain": 70, "nihil.appearance.leak.streaks": 0, "nihil.appearance.leak.backdrop": "light", "nihil.appearance.leak.wallpaper": 60,
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "nihil.appearance.preset": "soft", "theme.lines": 40, "theme.glow": 50, "theme.shadow": 100,
                "nihil.appearance.accent": "custom", "theme.accentHue": 326, "nihil.appearance.highlight": "custom", "theme.highlightHue": 250, "theme.badge": "accent",
                "nihil.appearance.aura": "vivid", "nihil.appearance.figureWeight": "light", "nihil.appearance.morph": "liquid", "nihil.bar.clockAccent": "accent",
                "nihil.widgets.material": "tinted", "nihil.widgets.weight": "regular", "nihil.dock.material": "inherit", "nihil.controlCenter.controls": "round" }) },
        { id: "polaroid", name: "Polaroid", author: "iNiR", tags: ["analog", "film", "flash", "beam", "mono"],
            values: root.values({ "nihil.appearance.texture": "leak", "nihil.appearance.leak.grade": "polaroid", "nihil.appearance.leak.shape": "beam", "nihil.appearance.leak.light": 65,
                "nihil.appearance.leak.spill": 55, "nihil.appearance.leak.prism": 55, "nihil.appearance.leak.grain": 60, "nihil.appearance.leak.streaks": 25, "nihil.appearance.leak.backdrop": "picture", "nihil.appearance.leak.wallpaper": 65,
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 500, "nihil.lock.type.clockTracking": 0, "nihil.lock.type.accent": "highlight",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "nihil.appearance.preset": "nihil", "theme.lines": 50, "theme.glow": 45, "theme.shadow": 100,
                "nihil.appearance.accent": "custom", "theme.accentHue": 18, "nihil.appearance.highlight": "custom", "theme.highlightHue": 196, "theme.badge": "highlight",
                "nihil.appearance.aura": "subtle", "nihil.appearance.fontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.titleFontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.numbersFontFamily": "JetBrainsMono Nerd Font",
                "nihil.appearance.figureWeight": "regular", "nihil.appearance.morph": "snap", "nihil.bar.clockAccent": "highlight",
                "nihil.widgets.material": "tinted", "nihil.widgets.weight": "regular", "nihil.dock.material": "inherit", "nihil.controlCenter.controls": "tiles" }) },
        { id: "twilight", name: "Twilight", author: "iNiR", tags: ["anime", "dusk", "glass", "menu bar"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "highlight", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 52, "glass.blur": 100, "theme.rim": false,
                "nihil.appearance.preset": "soft", "theme.shape": 115, "theme.melt": 70, "theme.lines": 25, "theme.shadow": 110, "theme.glow": 35,
                "nihil.appearance.accent": "custom", "theme.accentHue": 24, "nihil.appearance.highlight": "custom", "theme.highlightHue": 262,
                "nihil.appearance.aura": "vivid", "theme.lightReach": 170, "nihil.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 115,
                "nihil.appearance.figureWeight": "light", "nihil.bar.layout": "menubar", "nihil.bar.strip": "clear", "nihil.bar.notch": true, "nihil.bar.height": 40,
                "nihil.bar.composition": "unified", "nihil.bar.clockAccent": "accent", "nihil.surround.enable": false,
                "nihil.widgets.material": "glass", "nihil.widgets.radius": 24, "nihil.widgets.weight": "light",
                "nihil.dock.notch": false, "nihil.dock.material": "glass", "nihil.dock.iconSize": 42, "nihil.dock.magnification": false,
                "nihil.controlCenter.controls": "round" }) },
        { id: "daybreak", name: "Daybreak", author: "iNiR", tags: ["glass", "calm", "menu bar"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "graphite", "glass.mode": "wallpaper", "glass.tint": 66, "glass.blur": 100, "theme.rim": false,
                "nihil.appearance.preset": "soft", "theme.lines": 20, "theme.shadow": 90, "theme.melt": 40, "nihil.appearance.accent": "custom",
                "theme.accentHue": 205, "nihil.appearance.highlight": "custom", "theme.highlightHue": 38, "nihil.appearance.aura": "subtle",
                "nihil.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 105, "nihil.appearance.figureWeight": "regular",
                "nihil.bar.layout": "menubar", "nihil.bar.strip": "clear", "nihil.bar.notch": true, "nihil.bar.height": 38, "nihil.bar.composition": "unified",
                "nihil.bar.clockStyle": "dateTime", "nihil.bar.clockAccent": "highlight", "nihil.surround.enable": false,
                "nihil.widgets.material": "glass", "nihil.widgets.radius": 22, "nihil.widgets.weight": "regular",
                "nihil.dock.notch": false, "nihil.dock.material": "glass", "nihil.dock.iconSize": 44, "nihil.dock.magnification": false,
                "nihil.controlCenter.controls": "round" }) },
        { id: "horizon", name: "Horizon", author: "iNiR", tags: ["dark", "bar", "direct"],
            values: root.values({ "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 600, "nihil.lock.type.clockTracking": -3, "nihil.lock.type.accent": "highlight", "nihil.controlCenter.accent": "system", "nihil.controlCenter.sliders": "neutral", "theme.surface": "black", "glass.mode": "off", "theme.rim": false,
                "nihil.appearance.preset": "nihil", "nihil.appearance.accent": "blue", "nihil.appearance.highlight": "orange", "theme.badge": "alert", "nihil.appearance.aura": "subtle",
                "nihil.bar.layout": "full", "nihil.bar.notch": true, "nihil.bar.height": 40, "nihil.bar.composition": "unified",
                "nihil.bar.clockStyle": "dateTime", "nihil.bar.clockAccent": "highlight", "nihil.surround.enable": true, "nihil.surround.thickness": 10,
                "nihil.surround.radius": 22, "nihil.widgets.material": "solid", "nihil.widgets.radius": 22, "nihil.widgets.weight": "regular",
                "nihil.dock.notch": true, "nihil.dock.material": "solid", "nihil.dock.iconSize": 44, "nihil.dock.magnification": false,
                "nihil.controlCenter.controls": "tiles" }) },
        { id: "monolith", name: "Monolith", author: "iNiR", tags: ["minimal", "quiet"],
            values: root.values({ "nihil.lock.material": "none", "nihil.lock.type.clockWeight": 200, "nihil.lock.type.clockTracking": -3, "nihil.lock.type.accent": "plain", "nihil.controlCenter.accent": "mono", "nihil.controlCenter.sliders": "neutral", "nihil.surround.enable": false, "theme.lines": 0, "theme.rim": false, "theme.fill": 70,
                "theme.shadow": 60, "nihil.appearance.aura": "off", "nihil.appearance.accent": "custom", "theme.accentHue": 220,
                "nihil.appearance.highlight": "accent", "theme.badge": "neutral", "nihil.bar.clockAccent": "plain",
                "nihil.bar.composition": "unified", "nihil.bar.clockStyle": "time", "nihil.appearance.figureWeight": "light",
                "nihil.appearance.titleFontFamily": "Roboto Flex", "nihil.appearance.numbersFontFamily": "Roboto Flex",
                "nihil.appearance.fontFamily": "Roboto Flex", "nihil.appearance.morph": "glide", "theme.openTime": 120,
                "nihil.bar.notch": true, "nihil.bar.height": 36, "nihil.bar.clockScale": 108, "nihil.bar.satelliteScale": 90,
                "nihil.dock.notch": true, "nihil.dock.iconSize": 36, "nihil.dock.magnification": false,
                "nihil.widgets.material": "clear", "nihil.widgets.weight": "light", "nihil.widgets.radius": 0 }) },
        { id: "sakura", name: "Sakura", author: "iNiR", tags: ["anime", "pink", "round", "playful"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 60,
                "nihil.appearance.preset": "round", "theme.shape": 140, "theme.melt": 90, "theme.lines": 30, "theme.glow": 45,
                "nihil.appearance.accent": "custom", "theme.accentHue": 334, "nihil.appearance.highlight": "pink",
                "nihil.appearance.aura": "vivid", "theme.lightReach": 180, "nihil.appearance.morph": "liquid", "theme.bounce": 150,
                "nihil.appearance.titleFontFamily": "Gabarito", "nihil.bar.satelliteGap": 10, "nihil.bubbles.scale": 112, "nihil.bar.notch": true,
                "nihil.appearance.glass.edgeColour": "accent", "nihil.appearance.glass.edgeLight": 50, "nihil.appearance.glass.edgeLine": 14,
                "nihil.surround.thickness": 12, "nihil.surround.radius": 36, "nihil.widgets.material": "glass", "nihil.widgets.radius": 32,
                "nihil.dock.magnification": false, "nihil.dock.iconSize": 44, "nihil.controlCenter.controls": "round" }) },
        { id: "meadow", name: "Meadow", author: "iNiR", tags: ["warm", "soft", "organic"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 400, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "highlight", "nihil.controlCenter.accent": "colourful", "nihil.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 58,
                "nihil.appearance.preset": "round", "theme.shape": 150, "theme.melt": 110, "nihil.appearance.accent": "mint",
                "nihil.appearance.highlight": "custom", "theme.highlightHue": 40, "theme.lines": 35, "theme.contrast": 95,
                "nihil.appearance.aura": "subtle", "nihil.appearance.morph": "liquid", "theme.bounce": 160, "theme.curve": "gentle",
                "nihil.appearance.titleFontFamily": "Gabarito", "nihil.appearance.fontFamily": "Rubik", "nihil.bubbles.scale": 115, "nihil.bar.padding": 115,
                "nihil.bar.clockStyle": "weather", "nihil.bar.height": 46, "nihil.surround.thickness": 12, "nihil.surround.radius": 32, "nihil.widgets.material": "tinted", "nihil.widgets.radius": 28,
                "nihil.widgets.tint": "system", "nihil.dock.iconSize": 46, "nihil.dock.magnification": false, "nihil.controlCenter.controls": "round" }) },
        // AIRISU (the hub's designs/airisu): the Japanese look around tuning, stickers and seals, not racing. Lacquer
        // black, a vermilion seal for what is live, kerria amber for the glanced detail, wide Archivo figures.
        { id: "airisu", name: "AIRISU", author: "iNiR", tags: ["japanese", "sticker", "sharp", "vermilion"],
            values: root.values({ "nihil.appearance.design": "airisu",
                "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 800, "nihil.lock.type.clockTracking": -3, "nihil.lock.type.accent": "plain",
                "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "neutral", "nihil.controlCenter.controls": "tiles",
                "nihil.appearance.preset": "angular", "theme.shape": 40, "theme.pieceShape": "square", "theme.surface": "black",
                "theme.lines": 140, "theme.rim": false, "theme.shadow": 120, "theme.fill": 110, "theme.glow": 0,
                "nihil.appearance.aura": "off", "nihil.appearance.accent": "design", "nihil.appearance.highlight": "design", "theme.badge": "accent",
                "nihil.appearance.morph": "snap", "theme.curve": "swift", "theme.openTime": 85, "theme.press": 60,
                "nihil.appearance.fontFamily": "Archivo", "nihil.appearance.titleFontFamily": "Archivo SemiExpanded",
                "nihil.appearance.numbersFontFamily": "Archivo SemiExpanded", "nihil.appearance.figureWeight": "bold",
                "nihil.bar.clockStyle": "time", "nihil.bar.clockAccent": "plain", "nihil.bar.notchCurve": 55, "nihil.surround.radius": 6,
                "nihil.widgets.design": "instrument", "nihil.widgets.material": "solid", "nihil.widgets.radius": 4, "nihil.widgets.weight": "bold",
                "nihil.dock.material": "solid", "nihil.dock.magnification": false, "nihil.dock.notch": false, "nihil.appearance.expandedRadius": 16 }) },
        { id: "unit-01", name: "Unit-01", author: "iNiR", tags: ["anime", "mecha", "hard", "violet"],
            values: root.values({ "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 700, "nihil.lock.type.clockTracking": -1, "nihil.lock.type.accent": "highlight", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "theme.surface": "midnight", "nihil.appearance.preset": "contrast", "theme.shape": 75,
                "theme.pieceShape": "squircle", "nihil.appearance.accent": "custom", "theme.accentHue": 275,
                "nihil.appearance.highlight": "custom", "theme.highlightHue": 95, "theme.badge": "highlight",
                "theme.lines": 170, "theme.shadow": 150, "theme.glow": 30, "nihil.appearance.titleFontFamily": "Oxanium",
                "nihil.appearance.numbersFontFamily": "JetBrainsMono Nerd Font", "nihil.appearance.morph": "snap",
                "theme.curve": "swift", "nihil.bar.clockAccent": "highlight", "nihil.bar.clockStyle": "time", "nihil.bar.height": 44,
                "nihil.bar.clockScale": 112, "nihil.surround.thickness": 18, "nihil.surround.radius": 6, "nihil.bar.notchCurve": 60,
                "nihil.widgets.material": "solid", "nihil.widgets.radius": 4, "nihil.widgets.weight": "bold", "nihil.dock.material": "solid",
                "nihil.dock.iconSize": 42, "nihil.controlCenter.controls": "tiles", "theme.rim": false,
                "nihil.dock.notch": false, "nihil.appearance.expandedRadius": 16 }) },
        { id: "magical-girl", name: "Magical Girl", author: "iNiR", tags: ["anime", "rose", "gold", "playful"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "colourful", "nihil.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 58,
                "nihil.appearance.preset": "round", "theme.shape": 138, "theme.melt": 85, "theme.lines": 35, "theme.glow": 45,
                "nihil.appearance.accent": "custom", "theme.accentHue": 338, "nihil.appearance.highlight": "custom", "theme.highlightHue": 44,
                "nihil.appearance.anime.enabled": true, "nihil.appearance.anime.palette": "magical-girl", "nihil.appearance.anime.strength": 100, "nihil.appearance.anime.highlight": true,
                "nihil.appearance.aura": "vivid", "theme.lightReach": 185, "nihil.appearance.morph": "liquid", "theme.bounce": 145,
                "nihil.appearance.titleFontFamily": "Gabarito", "nihil.appearance.fontFamily": "Gabarito",
                "nihil.bubbles.scale": 112, "nihil.bar.notch": true, "nihil.bar.clockStyle": "dateTime", "nihil.bar.clockAccent": "highlight",
                "nihil.appearance.glass.edgeColour": "accent", "nihil.appearance.glass.edgeLight": 55, "nihil.appearance.glass.edgeLine": 16,
                "nihil.surround.thickness": 12, "nihil.surround.radius": 34, "nihil.widgets.material": "glass", "nihil.widgets.radius": 30,
                "nihil.dock.magnification": false, "nihil.dock.iconSize": 44, "nihil.controlCenter.controls": "round" }) },
        { id: "spirit-forest", name: "Spirit Forest", author: "iNiR", tags: ["anime", "green", "amber", "organic"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 400, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "highlight", "nihil.controlCenter.accent": "colourful", "nihil.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 56,
                "nihil.appearance.preset": "round", "theme.shape": 145, "theme.melt": 105, "theme.lines": 30, "theme.glow": 30,
                "nihil.appearance.accent": "mint", "nihil.appearance.highlight": "custom", "theme.highlightHue": 40,
                "nihil.appearance.anime.enabled": true, "nihil.appearance.anime.palette": "spirit-forest", "nihil.appearance.anime.strength": 100, "nihil.appearance.anime.highlight": true,
                "nihil.appearance.aura": "subtle", "nihil.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 120,
                "nihil.appearance.titleFontFamily": "Space Grotesk", "nihil.appearance.fontFamily": "Rubik",
                "nihil.bubbles.scale": 114, "nihil.bar.padding": 112, "nihil.bar.clockStyle": "weather", "nihil.bar.clockAccent": "highlight",
                "nihil.appearance.glass.edgeColour": "highlight", "nihil.appearance.glass.edgeLight": 50, "nihil.appearance.glass.edgeLine": 14,
                "nihil.bar.height": 46, "nihil.surround.thickness": 12, "nihil.surround.radius": 32, "nihil.widgets.material": "tinted", "nihil.widgets.radius": 28,
                "nihil.widgets.tint": "system", "nihil.dock.iconSize": 46, "nihil.dock.magnification": false, "nihil.controlCenter.controls": "round" }) },
        { id: "signal", name: "Signal", author: "iNiR", tags: ["contrast", "legible"],
            values: root.values({ "nihil.lock.material": "tint", "nihil.lock.type.clockWeight": 800, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent", "nihil.appearance.preset": "contrast", "theme.fill": 130, "theme.text": 110, "theme.lines": 160,
                "theme.contrast": 130, "nihil.appearance.aura": "off", "nihil.appearance.highlight": "yellow",
                "nihil.appearance.accent": "custom", "theme.accentHue": 52, "nihil.appearance.figureWeight": "bold",
                "theme.openTime": 80, "nihil.bar.height": 50, "nihil.bar.clockScale": 122, "nihil.dock.iconSize": 50,
                "nihil.dock.magnification": false, "nihil.widgets.material": "solid", "nihil.widgets.weight": "bold", "nihil.widgets.radius": 16,
                "nihil.widgets.tint": "system" }) },
        { id: "inir", name: "iNiR Theme", author: "iNiR", tags: ["system"],
            values: root.values({ "theme.surface": "theme", "nihil.appearance.accent": "theme", "nihil.appearance.highlight": "theme",
                "nihil.widgets.design": "material", "nihil.widgets.tint": "system", "nihil.controlCenter.controls": "tiles" }) },
        { id: "lume", name: "Lume", author: "iNiR", tags: ["wallpaper", "clear", "instrument", "menu bar"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 300, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "accent", "nihil.controlCenter.accent": "accent", "nihil.controlCenter.sliders": "accent",
                "nihil.appearance.adaptive": 60, "theme.surface": "wallpaper", "nihil.appearance.accent": "wallpaper", "nihil.appearance.highlight": "wallpaper",
                "nihil.appearance.aura": "subtle", "nihil.appearance.tint": 20, "theme.rim": false, "theme.lines": 20, "glass.mode": "wallpaper", "glass.tint": 40, "glass.blur": 100,
                "nihil.appearance.preset": "soft", "nihil.appearance.morph": "glide", "theme.curve": "gentle", "nihil.appearance.figureWeight": "light",
                "nihil.bar.layout": "menubar", "nihil.bar.strip": "clear", "nihil.bar.notch": true, "nihil.bar.height": 38, "nihil.bar.composition": "unified",
                "nihil.bar.clockStyle": "dateTime", "nihil.bar.clockAccent": "accent", "nihil.surround.enable": false,
                "nihil.widgets.design": "instrument", "nihil.widgets.tint": "wallpaper", "nihil.widgets.material": "clear", "nihil.widgets.weight": "light",
                "nihil.dock.notch": false, "nihil.dock.material": "glass", "nihil.dock.magnification": false, "nihil.controlCenter.controls": "round" }) },
        { id: "adaptive", name: "Adaptive", author: "iNiR", tags: ["wallpaper", "automatic"],
            values: root.values({ "nihil.lock.material": "glass", "nihil.lock.type.clockWeight": 400, "nihil.lock.type.clockTracking": -2, "nihil.lock.type.accent": "plain", "nihil.controlCenter.accent": "system", "nihil.controlCenter.sliders": "neutral", "nihil.appearance.adaptive": 80, "theme.surface": "wallpaper", "nihil.appearance.accent": "wallpaper",
                "nihil.appearance.highlight": "wallpaper", "nihil.appearance.aura": "subtle", "nihil.appearance.tint": 25,
                "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 52, "nihil.surround.thickness": 10, "nihil.surround.radius": 28,
                "nihil.widgets.material": "clear", "nihil.widgets.weight": "regular" }) }
    ]
}
