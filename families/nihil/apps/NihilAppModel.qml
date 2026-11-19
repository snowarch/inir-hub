pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common

// What the app grid holds: every launcher, the folders, the filter and the pages, all read from `nihil.apps` and
// `nihil.folders`. It draws nothing; the grid sets the page's measure and reads `pageItems`.
QtObject {
    id: root

    // What was typed. Two leading dots keep the search to system tools and settings.
    property string query: ""
    // How many fit, measured by the grid when the options leave them adaptive.
    property int fitColumns: 7
    property int fitRows: 4
    property int page: 0
    // The kind of app on show: "all", "internet", "creation", "games", "work" or "system".
    property string kind: "all"

    readonly property var options: Config.options?.nihil?.apps ?? ({})
    readonly property var folderOptions: Config.options?.nihil?.folders ?? ({})

    readonly property int columns: (root.options.columns ?? 0) > 0 ? root.options.columns : root.fitColumns
    readonly property int rows: (root.options.rows ?? 0) > 0 ? root.options.rows : root.fitRows
    readonly property int pageSize: Math.max(1, root.columns * root.rows)
    readonly property string order: root.options.order ?? "custom"
    readonly property string content: root.options.content ?? "noFavorites"
    readonly property var usage: root.options.usage ?? ({})
    readonly property bool _keepsGaps: root.order === "custom" && (root.options.incompletePages ?? false)

    readonly property string _typed: root.query.trim().toLowerCase()
    readonly property bool _systemOnly: root._typed.startsWith("..")
    readonly property var _terms: (root._systemOnly ? root._typed.slice(2) : root._typed)
        .split(/\s+/).filter(term => term.length > 0)
    readonly property bool filtering: root._typed.length > 0

    readonly property var _favorites: new Set(Array.from(Config.options?.apps?.pinned ?? []).map(id => root._plainId(id)))
    readonly property var _running: new Set((TaskbarApps.apps ?? [])
        .filter(app => (app.toplevels?.length ?? 0) > 0).map(app => root._plainId(app.appId)))

    // Each launcher once, with the words a search reads already folded to lower case.
    readonly property var _apps: (AppSearch.list ?? [])
        .filter(entry => entry && !entry.noDisplay)
        .map(entry => root._describe(entry))

    readonly property var _appsById: {
        const byId = {}
        for (const app of root._apps)
            byId[app.id] = app
        return byId
    }

    readonly property var folders: root.order === "usage" ? [] : root._sortedFolders(
        Array.from(root.options.folders ?? [])
            .map(folder => ({
                kind: "folder",
                id: folder.id,
                name: folder.name,
                apps: root._sortedInFolder(Array.from(folder.apps ?? [])
                    .map(id => root._appsById[id]).filter(app => app !== undefined))
            }))
            .filter(folder => folder.apps.length > 0))

    // The whole grid in order: search results while filtering, otherwise folders and the apps outside them.
    readonly property var items: {
        if (root.filtering)
            return root._searched()
        const filed = new Set()
        for (const folder of root.folders)
            folder.apps.forEach(app => filed.add(app.id))
        if (root.kind !== "all")
            return root._apps.filter(app => app.kinds.includes(root.kind)).sort(root._byName)
        const loose = root._apps.filter(app => !filed.has(app.id) && root._admitted(app))
        return root._arranged(root.folders, loose)
    }

    readonly property int pageCount: {
        if (root.items.length === 0)
            return 1
        return Math.ceil(root.items.length / root.pageSize)
    }
    readonly property int shownPage: Math.min(root.page, root.pageCount - 1)
    readonly property var pageItems: root.items.slice(root.shownPage * root.pageSize, (root.shownPage + 1) * root.pageSize)

    // The kinds this computer has at least one app of.
    readonly property var kindsHeld: {
        const held = new Set()
        for (const app of root._apps)
            app.kinds.forEach(kind => held.add(kind))
        return Array.from(held)
    }

    onQueryChanged: root.page = 0
    onKindChanged: root.page = 0
    onPageCountChanged: root.page = root.shownPage

    function goToPage(target: int): void {
        root.page = Math.max(0, Math.min(target, root.pageCount - 1))
    }

    function launch(app: var): void {
        if (app?.kind !== "app")
            return
        const counts = Object.assign({}, root.usage)
        counts[app.id] = (counts[app.id] ?? 0) + 1
        Config.setNestedValue("nihil.apps.usage", counts)
        AppSearch.launchEntry(app.entry)
    }

    // Hand arrangement: `id` moves to where `beforeId` stands, or to the end.
    function moveApp(id: string, beforeId: string): void {
        const arranged = root.items
            .map(item => item.id === id && root._keepsGaps ? "gap-" + Date.now() : item.id)
            .filter(other => other !== id)
        const at = arranged.indexOf(beforeId)
        arranged.splice(at < 0 ? arranged.length : at, 0, id)
        Config.setNestedValue("nihil.apps.customOrder", arranged)
    }

    function createFolder(name: string, appIds: var): void {
        const list = Array.from(root.options.folders ?? [])
        list.push({ id: "folder-" + Date.now(), name: name, apps: appIds })
        Config.setNestedValue("nihil.apps.folders", list)
    }

    function renameFolder(id: string, name: string): void {
        root._writeFolders(folder => folder.id === id ? Object.assign({}, folder, { name: name }) : folder)
    }

    function removeFolder(id: string): void {
        root._writeFolders(folder => folder.id === id ? null : folder)
    }

    function addToFolder(id: string, appId: string): void {
        root._writeFolders(folder => {
            const others = Array.from(folder.apps ?? []).filter(other => other !== appId)
            return Object.assign({}, folder, { apps: folder.id === id ? [...others, appId] : others })
        })
    }

    function removeFromFolder(id: string, appId: string): void {
        root._writeFolders(folder => folder.id !== id ? folder
            : Object.assign({}, folder, { apps: Array.from(folder.apps ?? []).filter(other => other !== appId) }))
    }

    function _writeFolders(change: var): void {
        const list = Array.from(root.options.folders ?? []).map(change).filter(folder => folder !== null)
        Config.setNestedValue("nihil.apps.folders", list)
    }

    function _describe(entry: var): var {
        const categories = Array.from(entry.categories ?? [])
        const command = Array.from(entry.command ?? [])
        const launcher = String(command[0] ?? "").split("/").pop()
        const line = command.join(" ").toLowerCase()
        return {
            kind: "app",
            id: entry.id ?? "",
            name: entry.name ?? "",
            icon: entry.icon ?? "",
            entry: entry,
            system: categories.includes("System") || categories.includes("Settings"),
            kinds: root._kindsOf(categories),
            package: line.includes("flatpak") ? "flatpak" : line.includes("snap") ? "snap"
                : line.includes(".appimage") ? "appimage" : "",
            nameKey: (entry.name ?? "").toLowerCase(),
            otherKey: [entry.genericName ?? "", entry.comment ?? "", ...Array.from(entry.keywords ?? []),
                       ...categories, launcher].join(" ").toLowerCase()
        }
    }

    function _kindsOf(categories: var): var {
        const has = names => names.some(name => categories.includes(name))
        const kinds = []
        if (has(["Network", "WebBrowser", "Email", "Chat"])) kinds.push("internet")
        if (has(["Graphics", "AudioVideo", "Audio", "Video"])) kinds.push("creation")
        if (has(["Game"])) kinds.push("games")
        if (has(["Office", "Development", "Education", "Science"])) kinds.push("work")
        if (has(["System", "Settings", "Utility"])) kinds.push("system")
        return kinds
    }

    function _plainId(id: var): string {
        return String(id ?? "").toLowerCase().replace(/\.desktop$/, "")
    }

    function _isFavorite(app: var): bool {
        return root._favorites.has(root._plainId(app.id))
    }

    function _isRunning(app: var): bool {
        return root._running.has(root._plainId(app.id))
    }

    function _admitted(app: var): bool {
        if (root.content === "noFavorites")
            return !root._isFavorite(app)
        if (root.content === "noRunning")
            return !root._isRunning(app)
        if (root.content === "noFavoritesNoRunning")
            return !root._isFavorite(app) && !root._isRunning(app)
        return true
    }

    function _byName(a: var, b: var): int {
        return a.name.localeCompare(b.name)
    }

    function _byUsage(a: var, b: var): int {
        return (root.usage[b.id] ?? 0) - (root.usage[a.id] ?? 0) || root._byName(a, b)
    }

    function _byHand(list: var): var {
        const placed = Array.from(root.options.customOrder ?? [])
        const rank = id => {
            const at = placed.indexOf(id)
            return at < 0 ? placed.length : at
        }
        return [...list].sort((a, b) => rank(a.id) - rank(b.id) || root._byName(a, b))
    }

    function _arranged(folders: var, loose: var): var {
        let ordered
        if (root.order === "usage")
            ordered = [...loose].sort(root._byUsage)
        else if (root.order === "name")
            ordered = [...folders, ...loose].sort(root._byName)
        else if (root.order === "foldersFirst")
            ordered = [...[...folders].sort(root._byName), ...[...loose].sort(root._byName)]
        else if (root.order === "foldersLast")
            ordered = [...[...loose].sort(root._byName), ...[...folders].sort(root._byName)]
        else
            ordered = root._withGaps(root._byHand([...folders, ...loose]))
        if (root.content !== "favoritesFirst")
            return ordered
        const first = item => item.kind === "app" && (root._isFavorite(item) || root._isRunning(item))
        return [...ordered.filter(first), ...ordered.filter(item => !first(item))]
    }

    // With incomplete pages a place someone emptied stays empty instead of pulling the next apps forward.
    function _withGaps(ordered: var): var {
        if (!root._keepsGaps)
            return ordered
        const byId = {}
        for (const item of ordered)
            byId[item.id] = item
        const placed = Array.from(root.options.customOrder ?? [])
        const known = new Set(placed)
        const laid = placed.map(id => byId[id] ?? { kind: "gap", id: id })
        while (laid.length > 0 && laid[laid.length - 1].kind === "gap")
            laid.pop()
        return [...laid, ...ordered.filter(item => !known.has(item.id))]
    }

    function _sortedFolders(list: var): var {
        return root.order === "custom" ? root._byHand(list) : [...list].sort(root._byName)
    }

    function _sortedInFolder(list: var): var {
        const order = root.folderOptions.order ?? "custom"
        if (order === "name")
            return [...list].sort(root._byName)
        return order === "usage" ? [...list].sort(root._byUsage) : list
    }

    // Every term has to land somewhere; a hit in the name outranks one in the launcher's other words.
    function _score(app: var): int {
        let total = 0
        for (const term of root._terms) {
            const at = app.nameKey.indexOf(term)
            if (at === 0)
                total += 400
            else if (at > 0 && /[\s\-_.]/.test(app.nameKey[at - 1]))
                total += 300
            else if (at > 0)
                total += 200
            else if (app.otherKey.includes(term))
                total += 100
            else if (Config.options?.nihil?.results?.fuzzy && root._loosely(app.nameKey, term))
                total += 50
            else
                return 0
        }
        return total
    }

    // The letters of `term`, in order, anywhere in `name`.
    function _loosely(name: string, term: string): bool {
        let from = 0
        for (const letter of term) {
            from = name.indexOf(letter, from) + 1
            if (from === 0)
                return false
        }
        return true
    }

    function _searched(): var {
        const includeSettings = Config.options?.nihil?.results?.includeSettings ?? true
        const pool = root._apps.filter(app => root._systemOnly ? app.system : (includeSettings || !app.system))
        if (root._terms.length === 0)
            return [...pool].sort(root._byName)
        return pool
            .map(app => ({ app: app, score: root._score(app) }))
            .filter(hit => hit.score > 0)
            .sort((a, b) => b.score - a.score || root._byName(a.app, b.app))
            .map(hit => hit.app)
    }
}
