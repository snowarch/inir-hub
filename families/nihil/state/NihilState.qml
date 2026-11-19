pragma Singleton

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.services
import "NihilProfiles.js" as Profiles

// What is open in NiHiL, and the desktop as the overview reads it.
Singleton {
    id: root

    readonly property var nihil: Config.options?.nihil
    // The windows view is the compositor's own overview, with NiHiL's parts injected over and behind it, wherever the
    // compositor has one (Niri and Umbriel). "shell" draws NiHiL's own pages instead.
    readonly property bool nativeStage: (root.nihil?.overview?.engine ?? "compositor") === "compositor"
        && (CompositorService.niriNative || CompositorService.isUmbriel)

    property bool overviewOpen: false
    // "windows", "apps" or "search".
    property string view: "windows"
    property string query: ""
    // What the search looks through: "all", "windows" or "recent".
    property string searchScope: "all"
    // Windows left in place for this opening, whatever the mode says.
    property bool holdStatic: false
    property bool controlOpen: false
    property bool todayOpen: false
    // Windows pinned as floating thumbnails.
    property var pips: []

    readonly property bool powerOpen: GlobalStates.sessionOpen
    readonly property bool clipboardOpen: GlobalStates.clipboardOpen
    readonly property bool wallpapersOpen: GlobalStates.wallpaperSelectorOpen || GlobalStates.wallpaperLauncherOpen
        || GlobalStates.coverflowSelectorOpen

    // The apps and the search are a page of the sheet; the windows are the overview's.
    readonly property bool launcherOpen: root.overviewOpen && root.view !== "windows"
    // Where the search falls back to once its words are gone, and whether the windows wait under the launcher.
    property string launcherHome: "windows"
    property bool overWindows: false

    // The one page the sheet carries: "apps", "control", "today", "clipboard", "wallpapers" or nothing.
    readonly property string page: root.launcherOpen ? "apps" : root.controlOpen ? "control" : root.todayOpen ? "today" : root.clipboardOpen ? "clipboard"
        : root.wallpapersOpen ? "wallpapers" : ""
    function closePages(except: string): void {
        if (except !== "apps" && root.launcherOpen) root.leaveLauncher()
        if (except !== "control") root.controlOpen = false
        if (except !== "today") root.todayOpen = false
        if (except !== "clipboard") GlobalStates.clipboardOpen = false
        if (except !== "wallpapers") {
            GlobalStates.wallpaperSelectorOpen = false
            GlobalStates.wallpaperLauncherOpen = false
            GlobalStates.coverflowSelectorOpen = false
        }
    }
    // The screen whose bar asked for what is open; empty is the screen with the keys.
    property string askedOn: ""
    function toggleOn(which: string, output: string): void {
        root.askedOn = output
        root.toggle(which)
    }
    onPageChanged: if (root.page.length === 0 && !root.powerOpen) root.askedOn = ""
    // A click beside the sheet, or Escape.
    function dismiss(): void {
        root.closePages("")
        GlobalStates.sessionOpen = false
    }
    onLauncherOpenChanged: if (root.launcherOpen) root.closePages("apps")
    onControlOpenChanged: if (root.controlOpen) root.closePages("control")
    onTodayOpenChanged: if (root.todayOpen) root.closePages("today")
    onClipboardOpenChanged: if (root.clipboardOpen) root.closePages("clipboard")
    onWallpapersOpenChanged: if (root.wallpapersOpen) root.closePages("wallpapers")
    onPowerOpenChanged: if (root.powerOpen) root.closePages("")

    function leaveLauncher(): void {
        if (!root.overWindows) {
            root.closeOverview()
            return
        }
        root.showWindows()
    }
    function showWindows(): void {
        root.query = ""
        root.searchScope = "all"
        root.view = "windows"
    }
    function openOverview(which: string): void {
        root.overWindows = root.overviewOpen && root.view === "windows" && which !== "windows"
        root.launcherHome = which === "windows" ? "windows" : "apps"
        root.view = which
        root.query = ""
        root.searchScope = "all"
        root.holdStatic = false
        root.controlOpen = false
        root.todayOpen = false
        root.overviewOpen = true
    }
    function closeOverview(): void {
        root.overviewOpen = false
        root.query = ""
        root.view = "windows"
        root.searchScope = "all"
        root.holdStatic = false
    }
    function toggleOverview(which: string): void {
        if (root.overviewOpen && root.view === which) root.closeOverview()
        else root.openOverview(which)
    }
    function setQuery(text: string): void {
        root.query = text
        root.view = text.length > 0 || root.searchScope !== "all" ? "search" : root.launcherHome
    }
    function searchFor(text: string, scope: string): void {
        root.openOverview("search")
        root.searchScope = scope
        root.query = text
    }
    function closeAll(): void {
        root.closeOverview()
        root.dismiss()
    }
    function toggle(which: string): void {
        switch (which) {
        case "overview": root.toggleOverview("windows"); break
        case "apps": root.toggleOverview("apps"); break
        case "search": root.toggleOverview("search"); break
        case "control": root.controlOpen = !root.controlOpen; break
        case "today": root.todayOpen = !root.todayOpen; break
        case "power": GlobalStates.sessionOpen = !GlobalStates.sessionOpen; break
        }
    }

    // One action by name: the Super key, the hot corner.
    function trigger(action: string): void {
        switch (action) {
        case "follow": root.toggleOverview("windows"); break
        case "windows": root.openOverview("windows"); break
        case "apps": root.toggleOverview("apps"); break
        case "staticWindows":
        case "staticWorkspace":
            root.openOverview("windows")
            root.holdStatic = true
            break
        case "searchWindows": root.searchFor("", "windows"); break
        case "recentFiles": root.searchFor("", "recent"); break
        }
    }
    // A second press soon after the first is the double action.
    property double _lastSuper: 0
    function pressSuper(): void {
        const now = Date.now()
        const twice = now - root._lastSuper < 320
        root._lastSuper = twice ? 0 : now
        root.trigger(twice ? (root.nihil?.overview?.superKeyDouble ?? "apps") : (root.nihil?.overview?.superKey ?? "follow"))
    }

    // What a window's mouse buttons and icon can be set to do.
    function windowAction(action: string, win: var): void {
        switch (action) {
        case "activate":
            NiriService.focusWindow(win.id)
            root.closeOverview()
            break
        case "close": NiriService.closeWindow(win.id); break
        case "minimize": MinimizedWindows.minimize(win.id); break
        case "next": {
            const list = root.cycleOn(root.outputOf(win))
            const at = list.findIndex(ws => ws.id === win.workspace_id)
            const next = list[at + 1] ?? list[0]
            if (next) NiriService.moveWindowToWorkspaceById(win.id, next.id, false)
            break
        }
        case "search": root.searchFor(win.title ?? "", "windows"); break
        case "thumbnail": root.pin(win); break
        }
    }
    function pin(win: var): void {
        if (!root.pips.some(item => item.id === win.id)) root.pips = [...root.pips, { id: win.id, appId: win.app_id }]
    }
    function unpin(id: var): void { root.pips = root.pips.filter(item => item.id !== id) }

    // The compositor's overview stands under NiHiL only while the windows are on show. The apps and a search are a page of
    // the sheet over the desktop, and the compositor would keep Escape for itself.
    function followStage(): void {
        if (!root.nativeStage) return
        const wantsStage = root.overviewOpen && root.view === "windows"
        if (wantsStage !== NiriService.inOverview) NiriService.toggleOverview()
    }

    // Keeps the shell's shared flags and NiHiL's overview saying the same thing.
    onOverviewOpenChanged: {
        root.followStage()
        CompositorService.setSortingConsumer("nihil-overview", root.overviewOpen)
        if (root.overviewOpen) WindowPreviewService.captureForTaskView()
        if (GlobalStates.overviewOpen !== root.overviewOpen) GlobalStates.overviewOpen = root.overviewOpen
        if (!root.overviewOpen && GlobalStates.searchOpen) GlobalStates.searchOpen = false
    }
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged(): void {
            if (GlobalStates.overviewOpen !== root.overviewOpen) {
                if (GlobalStates.overviewOpen) root.openOverview("windows")
                else root.closeOverview()
            }
        }
        function onSearchOpenChanged(): void {
            if (GlobalStates.searchOpen) root.openOverview("search")
            else if (root.view === "search") root.closeOverview()
        }
    }

    // The compositor's overview opened or closed on its own (its key, a hot corner, a click on a window): NiHiL follows.
    Connections {
        target: NiriService
        enabled: root.nativeStage
        function onInOverviewChanged(): void {
            if (NiriService.inOverview && !root.overviewOpen) root.openOverview("windows")
            else if (!NiriService.inOverview && root.overviewOpen && root.view === "windows") root.closeOverview()
            else if (NiriService.inOverview && root.launcherOpen) root.showWindows()
        }
    }
    onViewChanged: if (root.overviewOpen) root.followStage()

    // The session starts where the person asked.
    Connections {
        target: Config
        enabled: !root._started
        function onReadyChanged(): void { root.start() }
    }
    property bool _started: false
    function start(): void {
        if (root._started || !Config.ready) return
        root._started = true
        if (root.nativeStage && NiriService.inOverview && !root.overviewOpen) {
            root.openOverview("windows")
            return
        }
        const startup = root.nihil?.overview?.startup ?? "desktop"
        if (startup !== "desktop") root.openOverview(startup === "apps" ? "apps" : "windows")
    }
    Component.onCompleted: root.start()

    // A window asking for attention, handled once each time it asks.
    property var _urgent: ({})
    Connections {
        target: NiriService
        function onWindowsChanged(): void {
            const mode = root.nihil?.attention?.mode ?? "show"
            const seen = {}
            for (const win of NiriService.windows ?? []) {
                if (!win.is_urgent) continue
                seen[win.id] = true
                if (root._urgent[win.id] || mode === "hide") continue
                if (mode === "focus") {
                    NiriService.focusWindow(win.id)
                } else {
                    const pinned = (TaskbarApps.apps ?? []).some(app => app.appId === win.app_id && app.pinned)
                    if (pinned || !(root.nihil?.attention?.favoritesNotify ?? false))
                        Quickshell.execDetached(["notify-send", "-a", String(win.app_id ?? ""), String(win.title ?? ""),
                            Translation.tr("Needs your attention")])
                }
            }
            root._urgent = seen
        }
    }

    // The desktop, per screen.
    function workspacesOn(output: string): var {
        return (NiriService.allWorkspaces ?? []).filter(ws => ws.output === output).sort((a, b) => a.idx - b.idx)
    }
    function outputOf(win: var): string {
        return (NiriService.allWorkspaces ?? []).find(ws => ws.id === win.workspace_id)?.output ?? NiriService.currentOutput
    }
    // The workspaces a step moves through: the empty last one can be left out.
    function cycleOn(output: string): var {
        const list = root.workspacesOn(output)
        const last = list[list.length - 1]
        if ((root.nihil?.switcher?.ignoreLast ?? false) && list.length > 1 && last && root.windowsOn(last.id).length === 0)
            return list.slice(0, -1)
        return list
    }
    function windowsOn(workspaceId: var): var {
        const list = (NiriService.windows ?? []).filter(win => win.workspace_id === workspaceId)
        const order = root.nihil?.overview?.sortWindows ?? "position"
        if (order === "stable") return list.sort((a, b) => a.id - b.id)
        if (order === "recent") {
            const recent = NiriService.mruWindowIds ?? []
            const rank = id => { const at = recent.indexOf(id); return at < 0 ? recent.length : at }
            return list.sort((a, b) => rank(a.id) - rank(b.id))
        }
        return list
    }
    function activeIndexOn(output: string): int {
        return Math.max(0, root.workspacesOn(output).findIndex(ws => ws.is_active))
    }
    function stepWorkspace(output: string, by: int): void {
        const list = root.cycleOn(output)
        if (list.length === 0) return
        const at = list.findIndex(ws => ws.is_active)
        const wrap = root.nihil?.switcher?.wrap ?? false
        const next = wrap ? list[(at + by + list.length) % list.length] : list[at + by]
        if (next) NiriService.switchToWorkspaceById(next.id)
    }

    // Profiles: whole desktop layouts. A preset can be saved over and restored to how it came.
    readonly property var profiles: Profiles.list
    readonly property var savedProfiles: root.nihil?.savedProfiles ?? ({})
    function profileValues(id: string): var {
        const preset = Profiles.list.find(item => item.id === id)
        return root.savedProfiles[id] ?? preset?.values ?? null
    }
    function applyProfile(id: string): void {
        const values = root.profileValues(id)
        if (!values) return
        const updates = { "nihil.profile": id }
        for (const key in values) updates["nihil." + key] = values[key]
        Config.setNestedValues(updates)
    }
    // Keeps the current structure as this profile.
    function saveProfile(id: string): void {
        const values = {}
        for (const key of Profiles.keys) values[key] = Config.getNestedValue("nihil." + key, undefined)
        Config.setNestedValue("nihil.savedProfiles", Object.assign({}, root.savedProfiles, { [id]: values }))
    }
    function restoreProfile(id: string): void {
        const saved = Object.assign({}, root.savedProfiles)
        delete saved[id]
        Config.setNestedValue("nihil.savedProfiles", saved)
        root.applyProfile(id)
    }
}
