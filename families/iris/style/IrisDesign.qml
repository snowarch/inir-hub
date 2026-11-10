pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

// The Designs iRiS can wear (DESIGN.md › Layers, L3): iRiS's own, in designs/iris, and every hub plugin of kind
// "design" made for iRiS (plugin.json `families: ["iris"]`), linked at its `provides`. A Design is data: design.json
// holds its values (tokens, designs/design.schema.json), read over iRiS's own, so a value it leaves out is iRiS's and
// one it sets is its. A value the person also sets (a face, the preset, the motion) is theirs under iRiS and the
// Design's under a Design; their config is never written, so taking a Design off gives their own look back. Beyond
// its values a Design draws at most three parts of its own: the Island's resting face, its insignia and its picture.
Singleton {
    id: root

    readonly property var installed: Object.keys(Plugins.manifests).filter(id => {
        const manifest = Plugins.manifests[id]
        return manifest?.kind === "design" && Array.from(manifest.families ?? []).includes("iris")
    }).sort()
    readonly property var known: ["iris"].concat(root.installed)
    readonly property string requested: String(Config.options?.iris?.appearance?.design ?? "iris")
    // A Design asked for and not installed (removed, or not fetched yet) shows iRiS; the person's choice stays.
    readonly property string current: root.known.includes(root.requested) ? root.requested : "iris"
    readonly property bool custom: root.current !== "iris"
    readonly property var plugin: root.custom ? Plugins.manifests[root.current] ?? null : null
    readonly property string name: root.custom ? String(root.plugin?.name ?? root.current) : "iRiS"

    function parse(text: string, where: string): var {
        if (text.length === 0) return ({})
        try {
            const tokens = JSON.parse(text)?.tokens
            return tokens && typeof tokens === "object" ? tokens : ({})
        } catch (e) {
            console.warn(`[IrisDesign] ${where}/design.json: ${e}`)
            return ({})
        }
    }
    readonly property FileView baseFile: FileView {
        path: Quickshell.shellPath("modules/iris/designs/iris/design.json")
        blockLoading: true
    }
    // An author editing their design.json sees it on the desktop as they save.
    readonly property FileView ownFile: FileView {
        path: root.custom ? Quickshell.shellPath(`${root.plugin?.provides ?? `modules/${root.current}`}/design.json`) : ""
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: this.reload()
        // The tokens and the folder they came from are taken together once the file is in: its path moves first,
        // and a binding over both read one Design's fonts in the next one's folder mid-switch.
        onLoaded: root.read = ({ dir: path.slice(0, path.lastIndexOf("/")), tokens: root.parse(text(), root.current) })
        onLoadFailed: root.read = ({ dir: "", tokens: ({}) })
        onPathChanged: if (path.length === 0) root.read = ({ dir: "", tokens: ({}) })
    }
    readonly property var base: root.parse(root.baseFile.text(), "iris")
    property var read: ({ dir: "", tokens: ({}) })
    readonly property var own: root.custom ? root.read.tokens : ({})

    function at(tree: var, path: string): var {
        let node = tree
        for (const key of path.split(".")) {
            if (node === undefined || node === null || typeof node !== "object") return undefined
            node = node[key]
        }
        return node
    }
    function given(value: var): bool {
        if (value === undefined || value === null || value === "") return false
        if (Array.isArray(value)) return value.length > 0
        return typeof value !== "object" || Object.keys(value).length > 0
    }
    // The worn Design's own value at a token path, or undefined where it leaves the choice to iRiS and the person.
    function ownToken(path: string): var {
        const value = root.at(root.own, path)
        return root.given(value) ? value : undefined
    }
    // What is worn: the Design's value, else iRiS's.
    function token(path: string): var {
        const value = root.ownToken(path)
        return value !== undefined ? value : root.at(root.base, path)
    }
    // A value the person sets too: the Design's wins, then theirs, then iRiS's.
    function worn(path: string, person: var): var {
        const value = root.ownToken(path)
        if (value !== undefined) return value
        return root.given(person) ? person : root.at(root.base, path)
    }

    // What the surfaces read, as primitives (one change of Design re-runs each binding once).
    readonly property string palette: String(root.ownToken("colour.language") ?? "")
    // The accent or highlight a surface paints with: the Design's own pigment when it names one (colour.accent,
    // colour.highlight), else the person's choice, or the colour theme's while they follow one.
    function colourChoice(role: string, person: string, followsTheme: bool): string {
        const own = String(root.ownToken(`colour.${role}`) ?? "")
        return own.length > 0 ? own : followsTheme ? "theme" : person
    }
    readonly property string preset: String(root.ownToken("colour.preset") ?? "")
    readonly property var schemes: Array.from(root.token("colour.schemes") ?? ["dark", "ink", "light"])
    function roles(scheme: string): var { return root.ownToken(`colour.roles.${scheme}`) ?? null }
    readonly property bool fixesColour: ["dark", "ink", "light"].some(scheme => root.roles(scheme) !== null)
    function font(role: string): string { return String(root.ownToken(`type.${role}`) ?? "") }
    function baseFont(role: string): string { return String(root.at(root.base, `type.${role}`) ?? "") }
    readonly property real figureLean: Number(root.token("type.figureLean") ?? 0)
    readonly property string figureWeight: String(root.ownToken("type.figureWeight") ?? "")
    readonly property var ladder: root.token("shape.ladder") ?? ({})
    function rung(name: string): int {
        const own = root.ownToken(`shape.ladder.${name}`)
        return Number(own ?? root.at(root.base, `shape.ladder.${name}`) ?? 0)
    }
    readonly property string piece: String(root.ownToken("shape.piece") ?? "")
    readonly property real tileShare: Number(root.token("shape.tile") ?? 0.26)
    readonly property bool refusesGlass: root.token("material.glass") === "refuse"
    readonly property string texture: String(root.ownToken("material.texture") ?? "")
    readonly property string edge: String(root.ownToken("material.edge") ?? "")
    readonly property int edgeWidth: Number(root.ownToken("material.edgeWidth") ?? 0)
    readonly property real shadow: Number(root.token("material.shadow") ?? 1)
    function plate(tone: string, rungIndex: int): string { return String(root.token(`material.plates.${tone}`)?.[rungIndex] ?? "#000000") }
    readonly property string morph: String(root.ownToken("motion.morph") ?? "")
    readonly property int motionDuration: Number(root.ownToken("motion.duration") ?? 0)
    readonly property string look: String(root.ownToken("look.look") ?? "")
    // The design every desktop widget wears while this Design is on (`DesktopWidgetDesign.worn`); a widget's own pick stays.
    readonly property string widgets: String(root.ownToken("look.widgets") ?? "")
    // How the Design reads, as traits any surface honours: marks "glyph" (no tinted squircles), selection "plate" (the
    // chosen row is a solid plate, not an accent wash), index (lists numbered 01, 02…), captions "mono" (labels in mono
    // capitals), titles "lower" (page titles in lower case), sections "line", hover "plate", rings "edge", pages "hang".
    readonly property var traits: root.ownToken("look.traits") ?? ({})
    function trait(name: string): var { return root.traits?.[name] }

    // The faces a Design brings, loaded from its folder.
    readonly property var fontFiles: !root.custom || root.read.dir.length === 0 ? [] : Array.from(root.at(root.read.tokens, "type.files") ?? [])
        .map(file => `${root.read.dir}/${file}`)
    readonly property Instantiator fontLoaders: Instantiator {
        model: root.fontFiles
        delegate: FontLoader {
            required property string modelData
            source: "file://" + modelData
        }
    }

    // A Design's own parts: nothing else of iRiS is drawn by a Design (one component set).
    readonly property var partNames: ["islandFace", "insignia", "preview"]
    function skin(part: string): string {
        return root.custom && root.partNames.includes(part) ? Plugins.part(root.current, part) : ""
    }
    function has(part: string): bool { return root.skin(part).length > 0 }

    // Every Design installed, with its name and its picture for Settings › Style › Design.
    readonly property var catalogue: root.known.map(id => ({
        value: id,
        label: id === "iris" ? "iRiS" : String(Plugins.manifests[id]?.name ?? id),
        preview: id === "iris" ? Qt.resolvedUrl("../designs/iris/parts/Preview.qml").toString() : Plugins.part(id, "preview"),
        folder: id === "iris" ? "" : Quickshell.shellPath(String(Plugins.manifests[id]?.provides ?? `modules/${id}`))
    }))

    // The rows a worn Design decides for itself: Settings leaves them out, and they apply again under another Design.
    readonly property var ownedBy: ({
        "iris.appearance.language": "colour.language",
        "iris.appearance.variant": "colour.language",
        "iris.appearance.preset": "colour.preset",
        "iris.appearance.fontFamily": "type.text",
        "iris.appearance.titleFontFamily": "type.title",
        "iris.appearance.figureWeight": "type.figureWeight",
        "iris.appearance.theme.pieceShape": "shape.piece",
        "iris.appearance.texture": "material.texture",
        "iris.appearance.theme.edges": "material.edge",
        "iris.appearance.theme.rim": "material.edge",
        "iris.appearance.morph": "motion.morph",
        "iris.appearance.look": "look.look"
    })
    function fixedRole(role: string): bool {
        return ["dark", "ink", "light"].some(scheme => root.ownToken(`colour.roles.${scheme}.${role}`) !== undefined)
    }
    function owns(path: string): bool {
        if (!root.custom) return false
        const token = root.ownedBy[path]
        if (token) return root.ownToken(token) !== undefined
        switch (path) {
        case "iris.appearance.numbersFontFamily": return root.font("dot").length > 0 || root.font("numbers").length > 0
        case "iris.appearance.theme.rimWidth": return root.edgeWidth > 0
        case "iris.appearance.motionDuration": return root.motionDuration > 0
        case "iris.appearance.glass.mode": return root.refusesGlass
        case "iris.appearance.scheme": return Array.from(root.ownToken("colour.schemes") ?? []).length === 1
        case "iris.appearance.accent": return root.fixedRole("accent") || String(root.ownToken("colour.accent") ?? "").length > 0
        case "iris.appearance.highlight": return root.fixedRole("highlight") || String(root.ownToken("colour.highlight") ?? "").length > 0
        case "iris.appearance.theme.surface": return root.fixedRole("surface")
        case "iris.widgets.design": return root.widgets.length > 0
        // A Design that draws the resting Island decides its design and the time's accent; a bar across the edge still
        // shows the engine's clock in its zones.
        case "iris.bar.design": return root.has("islandFace")
        case "iris.bar.clockAccent": return root.has("islandFace")
            && !["full", "menubar", "pods"].includes(String(Config.options?.iris?.bar?.layout ?? "island"))
        }
        return false
    }
}
