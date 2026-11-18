pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common

// NiHiL's own panels, open or not; one open at a time. Start is the shell's search (GlobalStates.searchOpen) and the
// power menu its session screen (GlobalStates.sessionOpen), so the shared keys open NiHiL's.
Singleton {
    id: root

    property bool controlOpen: false
    property bool trayOpen: false
    // NiHiL's quick menu, opened by its bar button; everything else lives in its Settings window.
    property bool menuOpen: false
    // Today: the date, the month and every notification, opened from the time in the status pill.
    property bool todayOpen: false
    readonly property bool startOpen: GlobalStates.searchOpen
    readonly property bool powerOpen: GlobalStates.sessionOpen
    // The wallpapers and the clipboard answer the shell's own keys, so a keybind made for any family opens NiHiL's.
    readonly property bool wallpapersOpen: GlobalStates.wallpaperSelectorOpen || GlobalStates.wallpaperLauncherOpen
        || GlobalStates.coverflowSelectorOpen
    readonly property bool clipboardOpen: GlobalStates.clipboardOpen
    readonly property bool anyOpen: root.controlOpen || root.trayOpen || root.menuOpen || root.startOpen || root.powerOpen
        || root.todayOpen || root.wallpapersOpen || root.clipboardOpen

    function closeAll(): void {
        root.controlOpen = false
        root.trayOpen = false
        GlobalStates.searchOpen = false
        GlobalStates.sessionOpen = false
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.wallpaperLauncherOpen = false
        GlobalStates.coverflowSelectorOpen = false
        GlobalStates.clipboardOpen = false
        root.menuOpen = false
        root.todayOpen = false
    }
    function toggle(which: string): void {
        const was = which === "control" ? root.controlOpen : which === "tray" ? root.trayOpen
            : which === "start" ? root.startOpen
            : which === "power" ? root.powerOpen : which === "menu" ? root.menuOpen
            : which === "today" ? root.todayOpen : which === "wallpapers" ? root.wallpapersOpen
            : which === "clipboard" ? root.clipboardOpen : false
        root.closeAll()
        if (was) return
        if (which === "control") root.controlOpen = true
        else if (which === "tray") root.trayOpen = true
        else if (which === "start") GlobalStates.searchOpen = true
        else if (which === "power") GlobalStates.sessionOpen = true
        else if (which === "menu") root.menuOpen = true
        else if (which === "today") root.todayOpen = true
        else if (which === "wallpapers") GlobalStates.wallpaperSelectorOpen = true
        else if (which === "clipboard") GlobalStates.clipboardOpen = true
    }

    // NiHiL's Settings window, at a page of it. Already open, it hears the page through this file and comes forward.
    FileView { id: pageAsk; path: `${Directories.stateUserPath}/nihil/settings-page` }
    function openSettings(page: string): void {
        root.closeAll()
        if (page.length > 0) {
            pageAsk.setText(`${page} ${Date.now()}`)
            GlobalStates.openSettingsAt(page)
        } else {
            GlobalStates.openSettings()
        }
        const open = (NiriService.windows ?? []).find(entry => entry.title === Translation.tr("NiHiL Settings"))
        if (open) NiriService.focusWindow(open.id)
    }

    Connections {
        target: GlobalStates
        function onSearchOpenChanged() { if (GlobalStates.searchOpen) { root.controlOpen = false; root.trayOpen = false } }
        function onSessionOpenChanged() { if (GlobalStates.sessionOpen) { root.controlOpen = false; root.trayOpen = false } }
    }
}
