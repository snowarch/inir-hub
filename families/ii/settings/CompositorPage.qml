pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit

// Settings › the compositor in use, when it is not Niri (Niri keeps its own page): screens, workspaces, layout,
// windows, glass, movement, keyboard and pointer, every row asked of the base and shown only when it can be done.
ContentPage {
    id: root
    settingsPageIndex: 30
    settingsPageName: CompositorConfig.compositorName

    readonly property var out: CompositorConfig.output
    readonly property bool several: CompositorConfig.outputs.length > 1
    function shows(key: string): bool { CompositorConfig.revision; return CompositorConfig.has("display", key) }
    function display(key: string): var { CompositorConfig.revision; return CompositorConfig.displayValue(key) }
    function picks(key: string): var {
        CompositorConfig.revision
        return CompositorConfig.displayChoices(key).map(pick => ({ displayName: Translation.tr(String(pick.label)), value: pick.value, icon: pick.glyph ?? "" }))
    }
    readonly property var kept: root.display("workspaces")
    readonly property bool fixedSet: root.kept !== "dynamic"
    readonly property var widths: [
        { displayName: Translation.tr("A third"), value: 0.333 }, { displayName: Translation.tr("Half"), value: 0.5 },
        { displayName: Translation.tr("Two thirds"), value: 0.667 }, { displayName: Translation.tr("Whole"), value: 1 }
    ]
    function nearest(list: var, value: real): var {
        return list.find(pick => Math.abs(Number(pick.value) - value) < 0.02)?.value ?? null
    }
    // A screen's own width wins over Layout's (Umbriel: output over [layout]): Layout names each such screen.
    readonly property var ownWidths: { CompositorConfig.revision; return CompositorConfig.outputs.filter(entry => Number(entry.new_width ?? 0) >= 0.1) }
    function widthName(value: real): string {
        return root.widths.find(pick => Math.abs(Number(pick.value) - value) < 0.02)?.displayName ?? `${Math.round(value * 100)} %`
    }
    function followRest(name: string): void {
        const keep = CompositorConfig.selectedOutput
        CompositorConfig.applyDisplay("screen", name)
        CompositorConfig.applyDisplay("new-width", 0)
        CompositorConfig.applyDisplay("screen", keep)
    }
    // Workspaces side by side turn the strip: a new window takes the screen's width and this share of its height.
    readonly property bool sideways: root.display("workspace-axis") === "horizontal"

    Component.onCompleted: CompositorConfig.ensure()

    NoticeBox {
        Layout.fillWidth: true
        visible: CompositorConfig.pending !== null
        materialIcon: "timer"
        text: Translation.tr("Keep this display setting? It goes back in %1 s.").arg(CompositorConfig.secondsLeft)
        RippleButton {
            buttonText: Translation.tr("Keep")
            onClicked: CompositorConfig.keepDisplay()
        }
        RippleButton {
            buttonText: Translation.tr("Revert")
            onClicked: CompositorConfig.revertDisplay()
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "monitor"
        title: Translation.tr("Displays")
        visible: CompositorConfig.outputs.length > 0

        SettingsGroup {
            RippleButtonWithIcon {
                visible: root.several
                materialIcon: "screen_search_desktop"
                mainText: Translation.tr("Identify")
                onClicked: identify.show()
                ScreenIdentify { id: identify }
            }
            ContentSubsection {
                title: Translation.tr("Screen")
                visible: root.several
                ConfigSelectionArray {
                    options: root.picks("screen")
                    currentValue: root.out?.name ?? ""
                    onSelected: newValue => CompositorConfig.selectedOutput = newValue
                }
            }
            ContentSubsection {
                title: Translation.tr("Position")
                visible: root.several
                ConfigSelectionArray {
                    options: root.picks("place")
                    currentValue: { CompositorConfig.revision; return root.out ? CompositorConfig.placeOf(root.out, CompositorConfig.neighbour(root.out)) : "" }
                    onSelected: newValue => CompositorConfig.place(newValue)
                }
            }
            ContentSubsection {
                title: Translation.tr("Scale")
                visible: root.shows("scale")
                ConfigSelectionArray {
                    options: root.picks("scale")
                    currentValue: root.display("scale")
                    onSelected: newValue => CompositorConfig.applyDisplay("scale", newValue)
                }
            }
            Repeater {
                model: ScriptModel { values: CompositorRows.of("Screen"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "view_carousel"
        title: Translation.tr("Workspaces")
        visible: root.shows("workspaces") || root.shows("new-width")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Workspaces on this screen")
                visible: root.shows("workspaces")
                ConfigSelectionArray {
                    options: [{ displayName: Translation.tr("As needed"), value: "dynamic", icon: "auto_awesome_motion" }, { displayName: Translation.tr("Fixed"), value: "fixed", icon: "lock" }]
                    currentValue: root.fixedSet ? "fixed" : "dynamic"
                    onSelected: newValue => {
                        if ((newValue === "fixed") === root.fixedSet) return
                        CompositorConfig.applyDisplay("workspaces", newValue === "fixed" ? Math.max(Number(root.display("min-workspaces")) || 1, 4) : "dynamic")
                    }
                }
            }
            ConfigSpinBox {
                id: count
                visible: root.shows("workspaces")
                text: root.fixedSet ? Translation.tr("How many") : Translation.tr("Always waiting")
                from: 1
                to: 20
                stepSize: 1
                Binding { target: count; property: "value"; value: root.fixedSet ? Number(root.kept) : Number(root.display("min-workspaces")) || 1 }
                onValueModified: CompositorConfig.applyDisplay(root.fixedSet ? "workspaces" : "min-workspaces", count.value)
            }
            ContentSubsection {
                title: Translation.tr("Workspaces run")
                visible: root.shows("workspace-axis")
                ConfigSelectionArray {
                    options: root.picks("workspace-axis")
                    currentValue: String(root.display("workspace-axis"))
                    onSelected: newValue => CompositorConfig.applyDisplay("workspace-axis", newValue)
                }
            }
            ConfigSwitch {
                id: loops
                visible: root.shows("workspaces")
                text: Translation.tr("Loops around")
                description: Translation.tr("Past the last comes the first.")
                Binding { target: loops; property: "checked"; value: root.display("cyclic") === true }
                onCheckedChanged: if (loops.checked !== (root.display("cyclic") === true)) CompositorConfig.applyDisplay("cyclic", loops.checked)
            }
            ContentSubsection {
                title: root.sideways ? Translation.tr("How tall new windows open on this screen") : Translation.tr("How wide new windows open on this screen")
                visible: root.shows("new-width") && root.several
                ConfigSelectionArray {
                    options: [{ displayName: Translation.tr("Like the rest"), value: 0 }].concat(root.widths)
                    currentValue: root.nearest(root.widths, Number(root.display("new-width")) || 0) ?? 0
                    onSelected: newValue => CompositorConfig.applyDisplay("new-width", newValue)
                }
            }
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "palette"
        title: Translation.tr("Colour")
        visible: CompositorRows.of("Colour").length > 0
        SettingsGroup {
            Repeater {
                model: ScriptModel { values: CompositorRows.of("Colour"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "grid_view"
        title: Translation.tr("Layout")
        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Arrangement")
                visible: { CompositorConfig.revision; return CompositorConfig.has("layout", "mode") }
                ConfigSelectionArray {
                    options: [
                        { displayName: Translation.tr("Scrolling"), value: "scrolling", icon: "view_column" },
                        { displayName: Translation.tr("Dwindle"), value: "dwindle", icon: "dashboard" },
                        { displayName: Translation.tr("Main and stack"), value: "master", icon: "view_quilt" },
                        { displayName: Translation.tr("Floating"), value: "stacking", icon: "filter_none" }
                    ]
                    currentValue: CompositorRows.layoutMode()
                    onSelected: newValue => CompositorConfig.set({ comp: "layout", key: "mode", fallback: "scrolling" }, newValue)
                }
            }
            ContentSubsection {
                title: Translation.tr("New windows open")
                visible: { CompositorConfig.revision; return CompositorConfig.has("layout", "new-width") && CompositorRows.layoutMode() === "scrolling" }
                ConfigSelectionArray {
                    options: root.widths
                    currentValue: { CompositorConfig.revision; return root.nearest(root.widths, Number(CompositorConfig.value({ comp: "layout", key: "new-width", fallback: 0.5 }))) }
                    onSelected: newValue => CompositorConfig.set({ comp: "layout", key: "new-width", fallback: 0.5 }, newValue)
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.sideways
                    wrapMode: Text.WordWrap
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Workspaces sit side by side on %1, so windows there stack top to bottom: this is how tall they open.").arg(CompositorConfig.screenName(root.out))
                }
                Repeater {
                    model: ScriptModel { values: root.ownWidths; objectProp: "name" }
                    NoticeBox {
                        required property var modelData
                        Layout.fillWidth: true
                        materialIcon: "monitor"
                        text: Translation.tr("%1 keeps its own: %2. It opens new windows that way whatever you choose here.").arg(CompositorConfig.screenName(modelData)).arg(root.widthName(Number(modelData.new_width)))
                        RippleButton {
                            buttonText: Translation.tr("Like the rest")
                            onClicked: root.followRest(String(modelData.name))
                        }
                    }
                }
            }
            Repeater {
                model: ScriptModel { values: CompositorRows.of("Layout"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }

    AppRulesCard {}

    Repeater {
        model: [
            { group: "Borders", icon: "border_style", title: Translation.tr("Borders") },
            { group: "Shape", icon: "rounded_corner", title: Translation.tr("Shape") },
            { group: "Tabs", icon: "tab", title: Translation.tr("Tabs") },
            { group: "Title bars", icon: "web_asset", title: Translation.tr("Title bars") },
            { group: "Glass behind apps", icon: "blur_on", title: Translation.tr("Glass behind apps") },
            { group: "Movement", icon: "animation", title: Translation.tr("Movement") },
            { group: "Keyboard", icon: "keyboard", title: Translation.tr("Keyboard") },
            { group: "Mouse", icon: "mouse", title: Translation.tr("Mouse") },
            { group: "Trackpad", icon: "touchpad_mouse", title: Translation.tr("Trackpad") },
            { group: "Pointer", icon: "arrow_selector_tool", title: Translation.tr("Pointer") },
            { group: "Tablet", icon: "stylus_note", title: Translation.tr("Tablet") },
            { group: "Touch screen", icon: "touch_app", title: Translation.tr("Touch screen") }
        ]
        SettingsCardSection {
            id: card
            required property var modelData
            readonly property var mine: CompositorRows.of(card.modelData.group)
            expanded: true
            icon: card.modelData.icon
            title: card.modelData.title
            visible: card.mine.length > 0
            SettingsGroup {
                Repeater {
                    model: ScriptModel { values: card.mine; objectProp: "key" }
                    CompositorRow {}
                }
            }
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "pan_tool_alt"
        title: Translation.tr("Hot corners")
        visible: { CompositorConfig.revision; return CompositorConfig.has("corners", "top-left") }
        SettingsGroup {
            Repeater {
                model: [
                    { comp: "corners", key: "top-left", label: Translation.tr("Top left"), kind: "choice", fallback: "" },
                    { comp: "corners", key: "top-right", label: Translation.tr("Top right"), kind: "choice", fallback: "" },
                    { comp: "corners", key: "bottom-left", label: Translation.tr("Bottom left"), kind: "choice", fallback: "" },
                    { comp: "corners", key: "bottom-right", label: Translation.tr("Bottom right"), kind: "choice", fallback: "" }
                ]
                CompositorRow {}
            }
            Repeater {
                model: ScriptModel { values: CompositorRows.of("Hot corners"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }
}
