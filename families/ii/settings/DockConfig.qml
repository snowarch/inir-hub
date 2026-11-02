import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit

ContentPage {
    id: root

    function _log(...args): void {
        if (Quickshell.env("QS_DEBUG") === "1") console.log(...args);
    }

    settingsPageIndex: 22
    settingsPageName: Translation.tr("Dock")

    property bool isIiActive: (Config.options?.panelFamily ?? "ii") === "ii"

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "call_to_action"
        title: Translation.tr("Dock")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "dock_to_bottom"
                text: Translation.tr("Enable")
                checked: Config.options.material.dock.enable
                onCheckedChanged: {
                    Config.setNestedValue("material.dock.enable", checked);
                }
            }

            ContentSubsection {
                title: Translation.tr("Dock style")
                tooltip: Translation.tr("How the dock surface is drawn.")

                ConfigSelectionArray {
                    currentValue: Config.options?.material?.dock?.style ?? "panel"
                    onSelected: newValue => {
                        Config.setNestedValue("material.dock.style", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Panel"),  icon: "dock_to_bottom", value: "panel"  },
                        { displayName: Translation.tr("Pill"),   icon: "interests",      value: "pill"   },
                        { displayName: Translation.tr("macOS"),  icon: "desktop_mac",    value: "macos"  },
                        { displayName: Translation.tr("Island"), icon: "blur_on",        value: "island" },
                        { displayName: Translation.tr("M3"),     icon: "category",       value: "m3"     }
                    ]
                }

            }

            ContentSubsection {
                title: Translation.tr("Dock position")

                ConfigSelectionArray {
                    currentValue: Config.options?.material?.dock?.position ?? "bottom"
                    onSelected: newValue => {
                        Config.setNestedValue('material.dock.position', newValue);
                    }
                    options: [
                        { displayName: Translation.tr("Top"), icon: "arrow_upward", value: "top" },
                        { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
                        { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Reveal behavior")
                tooltip: Translation.tr("When the dock shows. Hover hides it until you reach the screen edge; Empty workspace keeps it visible on an empty desktop.")

                ConfigSelectionArray {
                    currentValue: Config.options?.material?.dock?.hoverToReveal ?? true
                    onSelected: newValue => {
                        Config.setNestedValue('material.dock.hoverToReveal', newValue);
                    }
                    options: [
                        { displayName: Translation.tr("Hover"), icon: "highlight_mouse_cursor", value: true },
                        { displayName: Translation.tr("Empty workspace"), icon: "desktop_windows", value: false }
                    ]
                }
            }

            // Both only mean something under Empty workspace: Hover already hides the dock, and a pinned dock would
            // cancel Hover. Disabled there so the contradiction shows.
            SettingsSwitch {
                buttonIcon: "desktop_windows"
                text: Translation.tr("Show on desktop")
                enabled: !(Config.options?.material?.dock?.hoverToReveal ?? true)
                checked: Config.options?.material?.dock?.showOnDesktop ?? true
                onCheckedChanged: Config.setNestedValue('material.dock.showOnDesktop', checked)
                StyledToolTip {
                    text: Translation.tr("Show dock when no window is focused (Empty workspace mode only)")
                }
            }
            SettingsSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pinned on startup")
                enabled: !(Config.options?.material?.dock?.hoverToReveal ?? true)
                checked: Config.options.material.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.setNestedValue("material.dock.pinnedOnStartup", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Keep dock visible at all times (Empty workspace mode only)")
                }
            }

            SettingsSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Tint app icons")
                checked: Config.options.material.dock.monochromeIcons
                onCheckedChanged: {
                    Config.setNestedValue("material.dock.monochromeIcons", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Apply accent color tint to dock app icons")
                }
            }
            SettingsSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Show dock background")
                checked: Config.options.material.dock.showBackground
                onCheckedChanged: Config.setNestedValue("material.dock.showBackground", checked)
                StyledToolTip {
                    text: Translation.tr("Show a background behind the dock")
                }
            }

            SettingsSwitch {
                buttonIcon: "splitscreen"
                text: Translation.tr("Separate pinned from running")
                checked: Config.options?.material?.dock?.separatePinnedFromRunning ?? true
                onCheckedChanged: Config.setNestedValue('material.dock.separatePinnedFromRunning', checked)
                StyledToolTip {
                    text: Translation.tr("Show pinned-only apps on the left, running apps on the right with a separator")
                }
            }

            SettingsSwitch {
                buttonIcon: "notifications"
                text: Translation.tr("Notification badges")
                checked: Config.options?.material?.dock?.notificationBadge ?? true
                onCheckedChanged: Config.setNestedValue('material.dock.notificationBadge', checked)
                StyledToolTip {
                    text: Translation.tr("Show the number of pending notifications on each app icon")
                }
            }

            SettingsSwitch {
                buttonIcon: "drag_indicator"
                text: Translation.tr("Drag to reorder")
                checked: Config.options?.material?.dock?.enableDragReorder ?? true
                onCheckedChanged: Config.setNestedValue('material.dock.enableDragReorder', checked)
                StyledToolTip {
                    text: Translation.tr("Long-press and drag dock icons to reorder pinned apps")
                }
            }

            ContentSubsection {
                title: Translation.tr("Appearance")

                SettingsSwitch {
                    buttonIcon: "branding_watermark"
                    text: Translation.tr("Use Card style")
                    checked: Config.options.material.dock?.cardStyle ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("material.dock.cardStyle", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Use the new Card style (lighter background, specific rounding) generic to settings")
                    }
                }

                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Dock height (px)")
                    value: Config.options.material.dock.height ?? 60
                    from: 40
                    to: 100
                    stepSize: 5
                    onValueModified: {
                        Config.setNestedValue("material.dock.height", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Height of the dock container")
                    }
                }

                ConfigSpinBox {
                    icon: "aspect_ratio"
                    text: Translation.tr("Icon size (px)")
                    value: Config.options.material.dock.iconSize ?? 35
                    from: 20
                    to: 60
                    stepSize: 5
                    onValueModified: {
                        Config.setNestedValue("material.dock.iconSize", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Size of application icons in the dock")
                    }
                }

                ConfigSpinBox {
                    icon: {
                        const pos = Config.options?.material?.dock?.position ?? "bottom"
                        switch (pos) {
                            case "top": return "vertical_align_top"
                            case "left": return "align_horizontal_left"
                            case "right": return "align_horizontal_right"
                            default: return "vertical_align_bottom"
                        }
                    }
                    text: Translation.tr("Hover reveal region size (px)")
                    value: Config.options.material.dock.hoverRegionHeight ?? 2
                    from: 1
                    to: 20
                    stepSize: 1
                    enabled: Config.options.material.dock.hoverToReveal
                    onValueModified: {
                        Config.setNestedValue("material.dock.hoverRegionHeight", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Size of the invisible area at screen edge that triggers dock reveal")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Window indicators")

                SettingsSwitch {
                    buttonIcon: "my_location"
                    text: Translation.tr("Smart indicator (highlight focused window)")
                    checked: Config.options.material.dock.smartIndicator !== false
                    onCheckedChanged: {
                        Config.setNestedValue("material.dock.smartIndicator", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("When multiple windows of the same app are open, highlight which one is focused")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "more_horiz"
                    text: Translation.tr("Show dots for inactive apps")
                    checked: Config.options.material.dock.showAllWindowDots !== false
                    onCheckedChanged: {
                        Config.setNestedValue("material.dock.showAllWindowDots", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show a dot per window even for apps that aren't currently focused")
                    }
                }

                ConfigSpinBox {
                    icon: "filter_5"
                    text: Translation.tr("Maximum indicator dots")
                    value: Config.options.material.dock.maxIndicatorDots ?? 5
                    from: 1
                    to: 10
                    stepSize: 1
                    onValueModified: {
                        Config.setNestedValue("material.dock.maxIndicatorDots", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Limit the number of open window dots shown below an app icon")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Window preview")

                SettingsSwitch {
                    buttonIcon: "preview"
                    text: Translation.tr("Show preview on hover")
                    checked: Config.options.material.dock.hoverPreview !== false
                    onCheckedChanged: {
                        Config.setNestedValue("material.dock.hoverPreview", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Display a live preview of windows when hovering over dock icons")
                    }
                }

                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Hover delay (ms)")
                    value: Config.options.material.dock.hoverPreviewDelay ?? 400
                    from: 0
                    to: 1000
                    stepSize: 50
                    enabled: Config.options.material.dock.hoverPreview !== false
                    onValueModified: {
                        Config.setNestedValue("material.dock.hoverPreviewDelay", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Time to wait before showing window preview")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Keep preview on click")
                    enabled: Config.options.material.dock.hoverPreview !== false
                    checked: Config.options?.material?.dock?.keepPreviewOnClick ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("material.dock.keepPreviewOnClick", checked)
                    }
                    StyledToolTip {
                        text: Translation.tr("Keeps the preview open while you click through windows.")
                    }
                }
            }
        }
    }

}
