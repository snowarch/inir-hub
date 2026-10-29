pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.ii.settings

// Material Settings inside the shell: a window over a dimmed desktop, the panel and the desktop live behind it so a
// change shows as it is made. SettingsChrome draws everything in it.
Scope {
    id: root

    property bool settingsOpen: GlobalStates.settingsOverlayOpen ?? false
    // keep the layer a moment after closing so the scrim fades instead of cutting
    property bool _closing: false
    onSettingsOpenChanged: {
        root._closing = !root.settingsOpen
        if (root._closing)
            closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: Appearance.animation.elementMoveFast.duration + 40
        onTriggered: root._closing = false
    }

    Loader {
        id: panelLoader
        active: root.settingsOpen || root._closing

        sourceComponent: PanelWindow {
            id: panel
            visible: root.settingsOpen || root._closing
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settingsOverlay"
            // a native file dialog has to come above it
            WlrLayershell.layer: GlobalStates.settingsNativeDialogOpen ? WlrLayer.Bottom : WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.settingsOpen && !GlobalStates.regionSelectorOpen && !GlobalStates.settingsNativeDialogOpen
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            readonly property var look: Config.options?.settingsUi?.overlayAppearance ?? ({})
            readonly property real bgOpacity: Math.max(0.6, panel.look.backgroundOpacity ?? 1.0)

            // Blurred desktop behind the scrim (Settings › Modules › Settings UI).
            Loader {
                anchors.fill: parent
                active: (panel.look.backdropBlur ?? 0) > 0 && Appearance.effectsEnabled
                visible: active && root.settingsOpen
                sourceComponent: GlassBackground {
                    radius: 0
                    forceBackdrop: true
                    blurStrength: (panel.look.backdropBlur ?? 0) / 100
                    screenWidth: panel.width
                    screenHeight: panel.height
                    fallbackColor: "transparent"
                    auroraTransparency: 0.35
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colScrim
                opacity: root.settingsOpen ? (panel.look.scrimDim ?? 35) / 100 : 0
                visible: opacity > 0
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                }
            }
            // its own sibling: a fully clear scrim (dim 0) still closes on a click outside
            MouseArea {
                anchors.fill: parent
                visible: root.settingsOpen
                enabled: !GlobalStates.settingsNativeDialogOpen
                onClicked: GlobalStates.settingsOverlayOpen = false
            }

            CompositorFocusGrab {
                id: grab
                windows: [panel]
                active: false
                onCleared: () => {
                    if (!active && !GlobalStates.settingsNativeDialogOpen)
                        GlobalStates.settingsOverlayOpen = false
                }
            }
            Timer {
                id: grabTimer
                interval: 100
                onTriggered: grab.active = root.settingsOpen && !GlobalStates.settingsNativeDialogOpen
            }
            Connections {
                target: GlobalStates
                function onSettingsOverlayOpenChanged() {
                    grabTimer.restart()
                    if (GlobalStates.settingsOverlayOpen) {
                        chrome.forceActiveFocus()
                        root.applyRequestedNavigation()
                    }
                }
                function onSettingsNativeDialogOpenChanged() { grabTimer.restart() }
                function onSettingsOverlayRequestedPageChanged() { root.applyRequestedNavigation() }
                function onSettingsOverlayRequestedSectionChanged() { root.applyRequestedNavigation() }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(panel.width - 64, Math.round(1320 * Appearance.fontSizeScale))
                height: Math.min(panel.height - 64, Math.round(900 * Appearance.fontSizeScale))
                radius: SettingsMaterialPreset.windowRadius
                color: SettingsMaterialPreset.glass || Appearance.regaliaEverywhere ? "transparent"
                    : CF.ColorUtils.applyAlpha(SettingsMaterialPreset.windowColor, panel.bgOpacity)
                // glass needs a lit rim to read as a pane over a dimmed desktop, not a patch of it
                border.width: Appearance.inirEverywhere || Appearance.angelEverywhere || Appearance.zzzEverywhere || SettingsMaterialPreset.glass ? 1 : 0
                border.color: Appearance.angelEverywhere ? Appearance.angel.colPanelBorder
                    : Appearance.zzzEverywhere ? Appearance.zzz.hairline
                    : Appearance.inirEverywhere ? Appearance.inir.colBorder
                    : SettingsMaterialPreset.glass ? CF.ColorUtils.transparentize(Appearance.colors.colOnSurface, SettingsMaterialPreset.dark ? 0.86 : 0.7)
                    : "transparent"
                opacity: root.settingsOpen ? 1 : 0
                visible: opacity > 0
                clip: true

                StyledRectangularShadow {
                    target: card
                    visible: !SettingsMaterialPreset.glass
                }

                RegaliaPlate {
                    anchors.fill: parent
                    z: -1
                    visible: Appearance.regaliaEverywhere
                    fillColor: CF.ColorUtils.applyAlpha(Appearance.regalia.bg0, panel.bgOpacity)
                    radius: card.radius
                    inset: Appearance.regalia.panelInset
                    elevated: true
                    glassEnabled: true
                }

                // aurora and angel: the wallpaper, blurred and tinted, is the window
                GlassBackground {
                    anchors.fill: parent
                    z: -1
                    visible: SettingsMaterialPreset.glass
                    screenX: card.x
                    screenY: card.y
                    screenWidth: panel.width
                    screenHeight: panel.height
                    // GameMode turns the blur off: an opaque window, never a vanished one
                    fallbackColor: Appearance.effectsEnabled ? "transparent" : Appearance.colors.colLayer0Base
                    auroraTransparency: {
                        const base = Appearance.angelEverywhere ? Appearance.angel.panelTransparentize : Appearance.aurora.overlayTransparentize
                        return base + (1 - base) * (1 - panel.bgOpacity)
                    }
                    radius: card.radius
                }

                // clicks inside never reach the scrim
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                SettingsChrome {
                    id: chrome
                    anchors.fill: parent
                    focus: true
                    active: root.settingsOpen
                    onCloseRequested: GlobalStates.settingsOverlayOpen = false
                    onWindowRequested: page => Quickshell.execDetached([Quickshell.shellPath("scripts/inir"),
                        "ipc", "settings", "openWindowAt", String(page)])
                    onCurrentPageChanged: GlobalStates.settingsOverlayCurrentPage = chrome.currentPage
                    Component.onCompleted: {
                        root.chrome = chrome
                        root.applyRequestedNavigation()
                        root.applyDevDestination()
                    }
                    Component.onDestruction: if (root.chrome === chrome) root.chrome = null
                }
            }
        }
    }

    property Item chrome: null

    function applyRequestedNavigation(): void {
        if (!root.settingsOpen || !root.chrome)
            return
        const page = GlobalStates.settingsOverlayRequestedPage ?? -1
        const section = String(GlobalStates.settingsOverlayRequestedSection ?? "")
        if (page < 0 && section.length === 0)
            return
        GlobalStates.settingsOverlayRequestedPage = -1
        GlobalStates.settingsOverlayRequestedSection = ""
        root.chrome.openPage(page, section)
    }

    function applyDevDestination(): void {
        if (!root.chrome || !DevNavigation.currentDestination.startsWith("settings/"))
            return
        const key = DevNavigation.currentDestination.substring("settings/".length)
        const index = SettingsPageRegistry.pages.findIndex(page => page.key === key)
        if (index >= 0)
            root.chrome.openPage(index, "")
    }
    Connections {
        target: DevNavigation
        function onCurrentDestinationChanged(): void { root.applyDevDestination() }
    }
    // another family's pages have other numbers
    Connections {
        target: Config.options ?? null
        function onPanelFamilyChanged() {
            if (root.chrome)
                root.chrome.currentPage = 0
        }
    }
}
