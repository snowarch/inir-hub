pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    function menu(screenName: string, wallpaper: string, preview: string): var {
        return [
            { type: "hero", text: Translation.tr("Wallpaper"), image: preview, iconName: "chevron_right",
                action: () => {
                    GlobalStates.wallpaperSelectorTargetMonitor = screenName
                    GlobalActions.runLauncher(["wallpaperSelector", "toggle"])
                } },
            { type: "separator" },
            { text: Translation.tr("Edit widgets"), iconName: "widgets", tint: "teal",
                action: () => {
                    Config.setNestedValue("iris.modules.desktopWidgets", true)
                    GlobalStates.setWidgetEditMode(true)
                } },
            { text: Translation.tr("Customize iRiS"), iconName: "palette", tint: "purple",
                action: () => { GlobalStates.irisEdit = true } },
            { type: "separator" },
            { text: Translation.tr("Settings"), iconName: "settings", tint: "gray",
                action: () => { Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "iris", "settings", ""]) } },
            { text: Translation.tr("Restart shell"), iconName: "restart_alt", tint: "gray",
                action: () => { Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "restart"]) } }
        ]
    }
}
