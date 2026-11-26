pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 16
    pageTitle: Translation.tr("Effects")
    pageIcon: "eye"
    pageDescription: Translation.tr("Blur, glass, motion and rendering policy")

    readonly property var backendOptions: [
        { displayName: Translation.tr("Style default"), value: "auto" },
        { displayName: Translation.tr("Wallpaper glass"), value: "wallpaper" },
        { displayName: Translation.tr("Compositor blur"), value: "compositor" },
        { displayName: Translation.tr("Off"), value: "off" }
    ]
    readonly property var areaDescriptors: [
        { key: "bar", icon: "desktop", label: Translation.tr("Bars") },
        { key: "dock", icon: "apps", label: Translation.tr("Dock") },
        { key: "panels", icon: "panel-left-expand", label: Translation.tr("Panels and popups") },
        { key: "islands", icon: "paint-bucket", label: Translation.tr("Islands and Ricelin") },
        { key: "widgets", icon: "widgets", label: Translation.tr("Desktop widgets") }
    ]

    WSettingsCard {
        title: Translation.tr("Blur and glass")
        icon: "options"
        WSettingsDropdown {
            label: Translation.tr("Default blur backend")
            icon: "server"
            currentValue: Config.options?.performance?.blurBackend ?? "auto"
            options: root.backendOptions
            onSelected: value => Config.setNestedValue("performance.blurBackend", value)
        }
        WSettingsSwitch {
            visible: Appearance.nativeBlurSupported
            label: Translation.tr("Allow compositor blur")
            icon: "eye"
            checked: Config.options?.performance?.compositorBlur ?? true
            onToggled: checked => Config.setNestedValue("performance.compositorBlur", checked)
        }
        WSettingsDropdown {
            visible: CompositorService.isRin && (Config.options?.performance?.compositorBlur ?? true)
            label: Translation.tr("Rin glass material")
            description: Translation.tr("Glass blurs what lies behind; Liquid adds GPU lens refraction.")
            icon: "blur"
            Component.onCompleted: if (CompositorService.isRin) CompositorConfig.ensure()
            currentValue: { CompositorConfig.revision; return String(CompositorConfig.value({ comp: "glass", key: "style", fallback: "liquid" })) }
            options: [
                { displayName: Translation.tr("Solid"), value: "solid" },
                { displayName: Translation.tr("Glass"), value: "glass" },
                { displayName: Translation.tr("Liquid"), value: "liquid" }
            ]
            onSelected: value => CompositorConfig.set({ comp: "glass", key: "style" }, value)
        }
        WSettingsSpinBox {
            visible: CompositorService.isRin && (Config.options?.performance?.compositorBlur ?? true)
            label: Translation.tr("Blur radius")
            description: Translation.tr("How far the compositor blur reaches in logical pixels.")
            icon: "blur"
            from: 0
            to: 128
            stepSize: 2
            suffix: " px"
            value: { CompositorConfig.revision; return Math.round(Number(CompositorConfig.value({ comp: "glass", key: "blur-radius", fallback: 32 }))) }
            onValueChanged: {
                const current = Math.round(Number(CompositorConfig.value({ comp: "glass", key: "blur-radius", fallback: 32 })))
                if (value !== current) CompositorConfig.set({ comp: "glass", key: "blur-radius" }, value)
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Per-area overrides")
        icon: "settings-cog-multiple"
        Repeater {
            model: root.areaDescriptors
            delegate: WSettingsDropdown {
                required property var modelData
                label: modelData.label
                icon: modelData.icon
                currentValue: Config.options?.performance?.blurAreas?.[modelData.key] ?? "inherit"
                options: [{ displayName: Translation.tr("Inherit"), value: "inherit" }].concat(root.backendOptions)
                onSelected: value => Config.setNestedValue("performance.blurAreas." + modelData.key, value)
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Motion and power")
        icon: "settings-cog-multiple"
        WSettingsSwitch {
            label: Translation.tr("Reduce animations")
            icon: "eye-off"
            checked: Config.options?.performance?.reduceAnimations ?? false
            onToggled: checked => Config.setNestedValue("performance.reduceAnimations", checked)
        }
        WSettingsSwitch {
            label: Translation.tr("Low power effects")
            icon: "leaf-two"
            checked: Config.options?.performance?.lowPower ?? false
            onToggled: checked => Config.setNestedValue("performance.lowPower", checked)
        }
        WSettingsSwitch {
            label: Translation.tr("Notify when a restart would free memory")
            icon: "alert"
            checked: Config.options?.performance?.memoryWarningNotification ?? false
            onToggled: checked => Config.setNestedValue("performance.memoryWarningNotification", checked)
        }
    }
}
