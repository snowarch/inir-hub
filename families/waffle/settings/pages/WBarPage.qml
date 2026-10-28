pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 2
    pageTitle: Translation.tr("Taskbar")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Taskbar appearance and behavior")
    
    property bool isWaffleActive: Config.options?.panelFamily === "waffle"
    
    WSettingsInfoBar {
        visible: !root.isWaffleActive
        severity: WSettingsInfoBar.Severity.Info
        message: Translation.tr("These settings only apply when using the Windows 11 (Waffle) panel style. Go to Modules to enable it.")
    }
    
    WSettingsCard {
        visible: root.isWaffleActive
        title: Translation.tr("Position & Layout")
        icon: "panel-left-expand"
        
        WSettingsSwitch {
            configPath: "waffles.bar.bottom"
            label: Translation.tr("Bottom position")
            icon: "caret-down"
            description: Translation.tr("Place taskbar at bottom of screen")
            checked: Config.options?.waffles?.bar?.bottom ?? true
            onCheckedChanged: Config.setNestedValue("waffles.bar.bottom", checked)
        }
        
        WSettingsSwitch {
            configPath: "waffles.bar.leftAlignApps"
            label: Translation.tr("Left-align apps")
            icon: "chevron-left"
            description: Translation.tr("Align taskbar apps to the left instead of center")
            checked: Config.options?.waffles?.bar?.leftAlignApps ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.leftAlignApps", checked)
        }
    }
    
    WSettingsCard {
        visible: root.isWaffleActive
        title: Translation.tr("Icons")
        icon: "apps"
        
        WSettingsSwitch {
            configPath: "waffles.bar.monochromeIcons"
            label: Translation.tr("Tint app icons")
            icon: "dark-theme"
            description: Translation.tr("Apply accent color to taskbar app icons")
            checked: Config.options?.waffles?.bar?.monochromeIcons ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.monochromeIcons", checked)
        }
        
        WSettingsSwitch {
            configPath: "waffles.bar.tintTrayIcons"
            label: Translation.tr("Tint tray icons")
            icon: "eyedropper"
            description: Translation.tr("Apply accent color to system tray icons")
            checked: Config.options?.waffles?.bar?.tintTrayIcons ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.tintTrayIcons", checked)
        }

        WSettingsSpinBox {
            configPath: "waffles.bar.iconSize"
            label: Translation.tr("Taskbar icon size")
            icon: "apps"
            suffix: "px"
            from: 20; to: 40; stepSize: 1
            value: Config.options?.waffles?.bar?.iconSize ?? 26
            onValueChanged: Config.setNestedValue("waffles.bar.iconSize", value)
        }

        WSettingsSpinBox {
            configPath: "waffles.bar.searchIconSize"
            label: Translation.tr("Search app icon size")
            icon: "search"
            suffix: "px"
            from: 16; to: 40; stepSize: 1
            value: Config.options?.waffles?.bar?.searchIconSize ?? 24
            onValueChanged: Config.setNestedValue("waffles.bar.searchIconSize", value)
        }
    }
    
    WSettingsCard {
        visible: root.isWaffleActive
        title: Translation.tr("Desktop Peek")
        icon: "eye"
        
        WSettingsSwitch {
            configPath: "waffles.bar.desktopPeek.hoverPeek"
            label: Translation.tr("Enable hover peek")
            icon: "eye"
            description: Translation.tr("Show desktop when hovering the corner button")
            checked: Config.options?.waffles?.bar?.desktopPeek?.hoverPeek ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.desktopPeek.hoverPeek", checked)
        }
        
        WSettingsSpinBox {
            configPath: "waffles.bar.desktopPeek.hoverDelay"
            visible: Config.options?.waffles?.bar?.desktopPeek?.hoverPeek ?? false
            label: Translation.tr("Hover delay")
            icon: "timer"
            suffix: "ms"
            from: 100; to: 2000; stepSize: 100
            value: Config.options?.waffles?.bar?.desktopPeek?.hoverDelay ?? 500
            onValueChanged: Config.setNestedValue("waffles.bar.desktopPeek.hoverDelay", value)
        }
    }
    
    WSettingsCard {
        visible: root.isWaffleActive
        title: Translation.tr("Clock & Notifications")
        icon: "arrow-clockwise"
        
        WSettingsSwitch {
            configPath: "time.secondPrecision"
            label: Translation.tr("Show seconds")
            icon: "timer"
            description: Translation.tr("Display seconds in taskbar clock")
            checked: Config.options?.time?.secondPrecision ?? false
            onCheckedChanged: Config.setNestedValue("time.secondPrecision", checked)
        }
        
        WSettingsSwitch {
            configPath: "waffles.bar.notifications.showUnreadCount"
            label: Translation.tr("Show unread count")
            icon: "alert-filled"
            description: Translation.tr("Display notification count badge on clock")
            checked: Config.options?.waffles?.bar?.notifications?.showUnreadCount ?? true
            onCheckedChanged: Config.setNestedValue("waffles.bar.notifications.showUnreadCount", checked)
        }

        WSettingsSwitch {
            configPath: "waffles.bar.activationWatermark.enable"
            label: Translation.tr("Activation watermark")
            icon: "key"
            description: Translation.tr("Show a fake activation message on the taskbar")
            checked: Config.options?.waffles?.bar?.activationWatermark?.enable ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.activationWatermark.enable", checked)
        }
    }
    
    WSettingsCard {
        visible: root.isWaffleActive
        title: Translation.tr("Updates")
        icon: "arrow-sync"
        
        WSettingsSpinBox {
            configPath: "updates.checkInterval"
            label: Translation.tr("Check interval")
            icon: "arrow-clockwise"
            suffix: "m"
            from: 15; to: 1440; stepSize: 15
            value: Config.options?.updates?.checkInterval ?? 120
            onValueChanged: Config.setNestedValue("updates.checkInterval", value)
        }
        
        WSettingsSpinBox {
            configPath: "updates.adviseUpdateThreshold"
            label: Translation.tr("Show icon threshold")
            icon: "alert"
            description: Translation.tr("Show update icon when packages exceed this")
            from: 1; to: 200; stepSize: 5
            value: Config.options?.updates?.adviseUpdateThreshold ?? 10
            onValueChanged: Config.setNestedValue("updates.adviseUpdateThreshold", value)
        }
        
        WSettingsSpinBox {
            configPath: "updates.stronglyAdviseUpdateThreshold"
            label: Translation.tr("Warning threshold")
            icon: "alert"
            description: Translation.tr("Show warning color when packages exceed this")
            from: 10; to: 500; stepSize: 10
            value: Config.options?.updates?.stronglyAdviseUpdateThreshold ?? 50
            onValueChanged: Config.setNestedValue("updates.stronglyAdviseUpdateThreshold", value)
        }
    }
}
