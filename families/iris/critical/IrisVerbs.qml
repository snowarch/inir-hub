import QtQuick
import qs
import qs.modules.common
import qs.services
import qs.services.deferred
import qs.modules.iris.state
import qs.modules.iris.settings

// How iRiS answers the shell's shared verbs: its own Orbit, a Place in the chassis with one layout and no Studio,
// and Spotlight for task view, the overview and the clipboard. Cleared when iRiS goes, so Material's come back.
QtObject {
    id: root

    function _orbitOn(): bool { return Config.options?.iris?.orbit?.enable ?? false }
    function _spotlight(prefix: string): void {
        LauncherSearch.ensurePrefix(prefix)
        GlobalStates.searchOpen = true
    }
    readonly property string _clipboardPrefix: Config.options?.search?.prefix?.clipboard ?? ";"

    function _musicOn(mode: string): bool {
        const edge = Config.options?.background?.edgeWidgets?.organic ?? ({})
        return Boolean(edge.enable) && String(Config.options?.iris?.surround?.music ?? "widget") === mode
    }
    function _toggleMusic(mode: string): void {
        if (root._musicOn(mode)) {
            Config.setNestedValue("background.edgeWidgets.organic.enable", false)
            return
        }
        const updates = { "iris.surround.music": mode, "background.edgeWidgets.organic.enable": true }
        if (mode === "frame") updates["iris.surround.enable"] = true
        Config.setNestedValues(updates)
    }
    readonly property var _actions: [
        {
            id: "frame-music",
            name: Translation.tr("Frame Music"),
            description: Translation.tr("Toggle music on the iRiS frame"),
            icon: "graphic_eq",
            category: "appearance",
            keywords: ["iris", "frame", "chassis", "music", "visualizer"],
            isOn: () => root._musicOn("frame"),
            execute: () => root._toggleMusic("frame")
        },
        {
            id: "edge-music",
            name: Translation.tr("Edge Music"),
            description: Translation.tr("Toggle the Organic Edge music wave"),
            icon: "waves",
            category: "appearance",
            keywords: ["iris", "edge", "music", "wave", "visualizer"],
            isOn: () => root._musicOn("widget"),
            execute: () => root._toggleMusic("widget")
        }
    ]

    // What iRiS Settings can change, for the shell's settings door: each row over one config key whose value is a
    // switch, a choice or a range, as Settings has it now (the Design's own and the compositor's stay with them).
    // A change goes through the row itself, so whatever else that row does (a theme regeneration, a piece moved
    // off the bar) happens too, and Settings' own Undo has it.
    // Kept in a plain object: filling it while a binding reads it (Kira's chat buttons) must not notify that binding again.
    readonly property var _cache: ({ from: null, rows: [], specByKey: {} })
    function _settingsIndex(): var {
        const specs = IrisOptions.settings
        if (root._cache.from === specs) return root._cache.rows
        const kinds = { "switch": "bool", "choice": "choice", "range": "number" }
        const rows = [], byKey = {}
        for (const spec of specs) {
            const key = String(spec.path ?? "")
            const type = kinds[spec.kind]
            if (!type || !key || key === "panelFamily" || spec.mirror || key in byKey) continue
            if (spec.widget || spec.widgetDesign || spec.comp || spec.state || spec.set || spec.flags || spec.bundle || spec.numeric) continue
            if (!IrisOptions.fits(spec)) continue
            const section = IrisOptions.sectionById(IrisOptions.sectionOf(spec))
            const row = { key: key, type: type, label: String(spec.label ?? ""), section: String(spec.group ?? section?.title ?? ""),
                page: String(section?.title ?? ""), description: String(spec.description ?? ""), keywords: Array.from(spec.keywords ?? []) }
            if (type === "choice") {
                row.choices = Array.from(IrisOptions.choicesOf(spec) ?? []).map(choice => ({ value: choice.value, label: String(choice.label ?? choice.value) }))
                if (row.choices.length === 0) continue
            } else if (type === "number") {
                Object.assign(row, { min: Number(spec.min), max: Number(spec.max), step: Number(spec.step ?? 0), scale: Number(spec.scale ?? 1), unit: String(spec.unit ?? "").trim() })
                if (!Number.isFinite(row.min) || !Number.isFinite(row.max)) continue
            }
            byKey[key] = spec
            rows.push(row)
        }
        root._cache.from = specs
        root._cache.rows = rows
        root._cache.specByKey = byKey
        return rows
    }
    function _applySetting(key: string, value: var): bool {
        root._settingsIndex()
        const spec = root._cache.specByKey[key]
        if (!spec) return false
        IrisOptions.commit(spec, value)
        return true
    }

    readonly property var verbs: ({
        owner: "iris",
        settings: {
            index: () => root._settingsIndex(),
            apply: (key, value) => root._applySetting(key, value)
        },
        actions: {
            list: () => root._actions
        },
        media: {
            cover: player => AnimeWatch.ownsPlayer(player) ? AnimeWatch.playingCover : ""
        },
        family: {
            leave: () => IrisState.endEditing()
        },
        dev: {
            open: surface => {
                switch (surface) {
                case "iris-palette": GlobalStates.searchOpen = true; return true
                case "iris-controls": GlobalStates.controlPanelOpen = true; return true
                case "iris-session": GlobalStates.sessionOpen = true; return true
                }
                return false
            }
        },
        sidebar: {
            opens: side => Config.options?.iris?.sidebars?.[side]?.enable ?? true
        },
        taskview: {
            toggle: () => { if (root._orbitOn()) IrisState.orbitOpen = !IrisState.orbitOpen; else GlobalStates.searchOpen = !GlobalStates.searchOpen },
            open: () => { if (root._orbitOn()) IrisState.orbitOpen = true; else GlobalStates.searchOpen = true },
            close: () => { IrisState.orbitOpen = false; GlobalStates.searchOpen = false }
        },
        orbit: {
            toggle: () => { IrisState.orbitOpen = !IrisState.orbitOpen },
            open: () => { IrisState.orbitOpen = true },
            close: () => { IrisState.orbitOpen = false },
            pocket: () => { IrisState.orbitOpen = true },
            studio: () => {},
            stage: () => {},
            orbital: () => {},
            toggleView: () => {},
            find: query => { IrisState.orbitQuery = query; IrisState.orbitOpen = true },
            next: () => NiriService.focusWorkspaceDown(),
            previous: () => NiriService.focusWorkspaceUp(),
            status: () => JSON.stringify({ family: "iris", open: IrisState.orbitOpen, enabled: root._orbitOn(),
                output: GlobalStates.focusedScreen?.name ?? "" })
        },
        overview: {
            toggle: () => { GlobalStates.searchOpen = !GlobalStates.searchOpen },
            open: () => { GlobalStates.searchOpen = true },
            close: () => { GlobalStates.searchOpen = false },
            clipboardToggle: () => root._spotlight(root._clipboardPrefix),
            actionOpen: () => root._spotlight(Config.options?.search?.prefix?.action ?? "/")
        },
        clipboard: {
            open: () => root._spotlight(root._clipboardPrefix),
            close: () => { GlobalStates.searchOpen = false },
            toggle: () => { if (GlobalStates.searchOpen) GlobalStates.searchOpen = false; else root._spotlight(root._clipboardPrefix) }
        }
    })

    Component.onCompleted: GlobalStates.familyVerbs = root.verbs
    Component.onDestruction: if (GlobalStates.familyVerbs === root.verbs) GlobalStates.familyVerbs = ({})
}
