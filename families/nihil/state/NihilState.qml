pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

// NiHiL's own panels, open or not; one open at a time. Start is the shell's search (GlobalStates.searchOpen) and the
// power menu its session screen (GlobalStates.sessionOpen), so the shared keys open NiHiL's.
Singleton {
    id: root

    property bool controlOpen: false
    property bool trayOpen: false
    // NiHiL's menu (its Settings): opened by its bar button, or by the shell's Settings key while NiHiL keeps its own.
    property bool menuOpen: false
    readonly property bool startOpen: GlobalStates.searchOpen
    readonly property bool powerOpen: GlobalStates.sessionOpen
    readonly property bool anyOpen: root.controlOpen || root.trayOpen || root.menuOpen || root.startOpen || root.powerOpen

    function closeAll(): void {
        root.controlOpen = false
        root.trayOpen = false
        GlobalStates.searchOpen = false
        GlobalStates.sessionOpen = false
        root.menuOpen = false
    }
    function toggle(which: string): void {
        const was = which === "control" ? root.controlOpen : which === "tray" ? root.trayOpen
            : which === "start" ? root.startOpen
            : which === "power" ? root.powerOpen : which === "menu" ? root.menuOpen : false
        root.closeAll()
        if (was) return
        if (which === "control") root.controlOpen = true
        else if (which === "tray") root.trayOpen = true
        else if (which === "start") GlobalStates.searchOpen = true
        else if (which === "power") GlobalStates.sessionOpen = true
        else if (which === "menu") root.menuOpen = true
    }

    // Material's full Settings window, at a page: NiHiL's menu hands the Settings key to Material (the person can hand
    // it back from Extras), and the window opens once the key is on disk, since the window reads it from there.
    property string _materialPage: ""
    function openMaterial(page: string): void {
        root.closeAll()
        root._materialPage = page
        Config.setNestedValue("nihil.settings.useMaterial", true)
        materialDelay.restart()
    }
    Timer {
        id: materialDelay
        interval: 700
        onTriggered: root._materialPage.length > 0 ? GlobalStates.openSettingsAt(root._materialPage) : GlobalStates.openSettings()
    }

    onMenuOpenChanged: if (!root.menuOpen) GlobalStates.settingsOverlayOpen = false
    Connections {
        target: GlobalStates
        function onSettingsOverlayOpenChanged() {
            if (GlobalStates.settingsOverlayOpen && !root.menuOpen) root.toggle("menu")
            else if (!GlobalStates.settingsOverlayOpen) root.menuOpen = false
        }
        function onSearchOpenChanged() { if (GlobalStates.searchOpen) { root.controlOpen = false; root.trayOpen = false } }
        function onSessionOpenChanged() { if (GlobalStates.sessionOpen) { root.controlOpen = false; root.trayOpen = false } }
    }
}
