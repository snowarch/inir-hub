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

    Component.onCompleted: CompositorConfig.ensure()
    CompositorRows { id: rows }

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
                model: ScriptModel { values: rows.of("Screen"); objectProp: "key" }
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
                title: Translation.tr("New windows open")
                visible: root.shows("new-width")
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
        visible: rows.of("Colour").length > 0
        SettingsGroup {
            Repeater {
                model: ScriptModel { values: rows.of("Colour"); objectProp: "key" }
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
                    currentValue: rows.layoutMode()
                    onSelected: newValue => CompositorConfig.set({ comp: "layout", key: "mode", fallback: "scrolling" }, newValue)
                }
            }
            ContentSubsection {
                title: Translation.tr("New windows open")
                visible: { CompositorConfig.revision; return CompositorConfig.has("layout", "new-width") && rows.layoutMode() === "scrolling" }
                ConfigSelectionArray {
                    options: root.widths
                    currentValue: { CompositorConfig.revision; return root.nearest(root.widths, Number(CompositorConfig.value({ comp: "layout", key: "new-width", fallback: 0.5 }))) }
                    onSelected: newValue => CompositorConfig.set({ comp: "layout", key: "new-width", fallback: 0.5 }, newValue)
                }
            }
            Repeater {
                model: ScriptModel { values: rows.of("Layout"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }

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
            readonly property var mine: rows.of(card.modelData.group)
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
                model: ScriptModel { values: rows.of("Hot corners"); objectProp: "key" }
                CompositorRow {}
            }
        }
    }
}
