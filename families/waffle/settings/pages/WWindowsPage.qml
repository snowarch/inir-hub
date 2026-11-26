pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

// Settings › Windows & layout › Windows, as Windows' Multitasking page: how windows are laid out, each app's own
// rules, then the compositor's groups for windows (borders, shape, tabs, title bars, glass, movement, hot corners)
// as expanders. Every row is asked of the compositor (CompositorConfig) and shown only when the one running can do it.
WSettingsPage {
    id: root
    settingsPageIndex: 20
    pageTitle: Translation.tr("Windows")
    pageIcon: "window-multiple"
    pageDescription: Translation.tr("Layout, app rules, borders, movement")

    readonly property var widths: [
        { displayName: Translation.tr("A third"), value: 0.333 }, { displayName: Translation.tr("Half"), value: 0.5 },
        { displayName: Translation.tr("Two thirds"), value: 0.667 }, { displayName: Translation.tr("Whole"), value: 1 }
    ]
    function widthName(value: real): string {
        return root.widths.find(pick => Math.abs(Number(pick.value) - value) < 0.02)?.displayName ?? `${Math.round(value * 100)} %`
    }
    // A screen's own width wins over Layout's (Umbriel: output over [layout]): Layout names each such screen.
    readonly property var ownWidths: { CompositorConfig.revision; return CompositorConfig.outputs.filter(entry => Number(entry.new_width ?? 0) >= 0.1) }
    function followRest(name: string): void {
        const keep = CompositorConfig.selectedOutput
        CompositorConfig.applyDisplay("screen", name)
        CompositorConfig.applyDisplay("new-width", 0)
        CompositorConfig.applyDisplay("screen", keep)
    }
    readonly property bool sideways: { CompositorConfig.revision; return CompositorConfig.displayValue("workspace-axis") === "horizontal" }
    readonly property var newWidth: ({ comp: "layout", key: "new-width", fallback: 0.5 })

    Component.onCompleted: CompositorConfig.ensure()

    WSettingsCard {
        title: Translation.tr("Layout")
        icon: "layout-column-two"

        WSettingsDropdown {
            visible: { CompositorConfig.revision; return CompositorConfig.has("layout", "mode") }
            label: Translation.tr("Arrangement")
            options: [
                { displayName: Translation.tr("Scrolling"), value: "scrolling" }, { displayName: Translation.tr("Dwindle"), value: "dwindle" },
                { displayName: Translation.tr("Main and stack"), value: "master" }, { displayName: Translation.tr("Floating"), value: "stacking" }
            ].filter(option => CompositorConfig.layoutModes.includes(option.value))
            currentValue: CompositorRows.layoutMode()
            onSelected: newValue => { if (newValue !== CompositorRows.layoutMode()) CompositorConfig.set({ comp: "layout", key: "mode", fallback: "scrolling" }, newValue) }
        }
        WSettingsDropdown {
            visible: { CompositorConfig.revision; return CompositorConfig.has("layout", "new-width") && CompositorRows.layoutMode() === "scrolling" }
            label: Translation.tr("New windows open")
            description: root.sideways ? Translation.tr("Workspaces sit side by side on %1, so windows there stack top to bottom: this is how tall they open.").arg(CompositorConfig.screenName(CompositorConfig.output)) : ""
            options: root.widths
            currentValue: { CompositorConfig.revision; return root.widths.find(pick => Math.abs(Number(pick.value) - Number(CompositorConfig.value(root.newWidth))) < 0.02)?.value ?? 0.5 }
            onSelected: newValue => CompositorConfig.set(root.newWidth, newValue)
        }
        // A screen that keeps its own width says so, with the way back to the rest.
        Repeater {
            model: ScriptModel { values: root.ownWidths; objectProp: "name" }
            WSettingsRow {
                id: own
                required property var modelData
                enableSettingsSearch: false
                icon: "desktop"
                label: Translation.tr("%1 keeps its own: %2. It opens new windows that way whatever you choose here.").arg(CompositorConfig.screenName(own.modelData)).arg(root.widthName(Number(own.modelData.new_width)))
                control: Component {
                    WButton {
                        text: Translation.tr("Like the rest")
                        colBackground: Looks.colors.interactiveSurface
                        colBackgroundHover: Looks.colors.interactiveSurfaceHover
                        colBackgroundActive: Looks.colors.interactiveSurfaceActive
                        onClicked: root.followRest(String(own.modelData.name))
                    }
                }
            }
        }
        Repeater {
            model: ScriptModel { values: CompositorRows.of("Layout"); objectProp: "key" }
            WCompositorRow {}
        }
    }

    WAppRulesCard {}

    // Each group its own expander, as Windows' Multitasking page stacks them, under a head of their own.
    WText {
        Layout.fillWidth: true
        Layout.topMargin: Looks.dp(18)
        Layout.bottomMargin: Looks.dp(6)
        Layout.leftMargin: Looks.dp(1)
        text: Translation.tr("Look and movement")
        font.pixelSize: Looks.settings.body
        font.weight: Looks.font.weight.strong
        Accessible.role: Accessible.Heading
    }
    Repeater {
        model: [
            { group: "Borders", icon: "border-all", title: Translation.tr("Borders"), line: Translation.tr("The line round each window and the ring on the focused one") },
            { group: "Shape", icon: "square-hint", title: Translation.tr("Shape"), line: Translation.tr("Rounded corners and shadows") },
            { group: "Tabs", icon: "tab-desktop", title: Translation.tr("Tabs"), line: Translation.tr("Windows stacked as tabs in one column") },
            { group: "Title bars", icon: "window", title: Translation.tr("Title bars"), line: CompositorService.isRin
                ? Translation.tr("A bar to drag a window by, with its buttons, on windows that leave their frame to the compositor.")
                : Translation.tr("A bar over each window, where it sits and how tall") },
            { group: "Glass behind apps", icon: "blur", title: CompositorService.isRin ? Translation.tr("Glass & liquid effects") : Translation.tr("Glass behind apps"), line: CompositorService.isRin ? Translation.tr("Compositor blur, liquid glass refraction, and blur radius") : Translation.tr("Blur behind see-through windows and how it looks") },
            { group: "Movement", icon: "slide-transition", title: CompositorService.isRin ? Translation.tr("Overview & movement") : Translation.tr("Movement"), line: Translation.tr("Animations, the overview and workspace changes") }
        ]
        WCompositorGroup {
            required property var modelData
            group: modelData.group
            icon: modelData.icon
            title: modelData.title
            description: modelData.line
        }
    }
    WCompositorGroup {
        icon: "arrow-up-left"
        title: Translation.tr("Hot corners")
        description: Translation.tr("What a corner does when the pointer rests in it")
        visible: { CompositorConfig.revision; return CompositorConfig.has("corners", "top-left") }
        rows: [
            { comp: "corners", key: "top-left", label: Translation.tr("Top left"), kind: "choice", fallback: "" },
            { comp: "corners", key: "top-right", label: Translation.tr("Top right"), kind: "choice", fallback: "" },
            { comp: "corners", key: "bottom-left", label: Translation.tr("Bottom left"), kind: "choice", fallback: "" },
            { comp: "corners", key: "bottom-right", label: Translation.tr("Bottom right"), kind: "choice", fallback: "" }
        ].concat(CompositorRows.of("Hot corners"))
    }
}
