import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.services
import qs.modules.iris.components

// The desktop's right-click menu under iRiS, handed to the shared Background as its part `desktopMenu`.
IrisDesktopMenu {
    id: menu
    property string screenName: ""
    property string wallpaperPath: ""
    readonly property int gridSize: Config.getNestedValue("background.widgets.editGrid.size", 32)
    readonly property bool gridSnap: Config.getNestedValue("background.widgets.editGrid.snap", true)
    readonly property var hostWindow: menu.anchorItem?.QsWindow.window ?? null
    // The hero's still, decoded here once and held: each open finds it in the image cache instead of decoding the
    // wallpaper again while the menu grows.
    IrisWallpaperView {
        visible: false
        active: IrisDesktopActions.showWallpaper && menu.wallpaperPath.length > 0
        path: menu.wallpaperPath
        live: false
        screen: menu.hostWindow?.screen ?? null
        decodeSize: menu.heroDecodeSize(menu.hostWindow?.screen ?? null, menu.hostWindow?.devicePixelRatio ?? 1)
    }
    model: GlobalStates.widgetEditMode ? [
        { text: Translation.tr("Add widgets"), iconName: "dashboard_customize", tint: "teal",
            action: () => { GlobalStates.widgetSearchOpen = true } },
        { text: Translation.tr("Snap to grid"), iconName: "grid_on", checked: menu.gridSnap, keepOpen: true,
            action: () => Config.setNestedValue("background.widgets.editGrid.snap", !menu.gridSnap) },
        { type: "separator" },
        { text: Translation.tr("Grid size"), iconName: "grid_4x4", detail: menu.gridSize + " px",
            action: () => {
                const sizes = [16, 32, 48, 64]
                Config.setNestedValue("background.widgets.editGrid.size",
                    sizes[(sizes.indexOf(menu.gridSize) + 1) % sizes.length])
            } },
        { text: Translation.tr("Widget settings"), iconName: "settings",
            action: () => GlobalStates.openSettingsAt("widgets") },
        { type: "separator" },
        { text: Translation.tr("Done"), iconName: "check", tint: "green",
            action: () => DesktopEditHistory.finish() }
    ] : IrisDesktopActions.menu(menu.screenName, menu.wallpaperPath, menu.wallpaperPath)
}
