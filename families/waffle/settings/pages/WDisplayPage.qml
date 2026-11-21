pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

// Settings › System › Display, as Windows lays it out: the screens drawn at the top (pick one, drag it to where it
// stands), then the picked screen's own settings, its colour and its workspaces. Every row is asked of the
// compositor (CompositorConfig) and shown only when the one running can do it; a risky change asks Keep or Revert.
WSettingsPage {
    id: root
    settingsPageIndex: 19
    pageTitle: Translation.tr("Display")
    pageIcon: "desktop-edit"
    pageDescription: Translation.tr("Arrangement, scale, resolution, colour, workspaces")

    readonly property var out: CompositorConfig.output
    readonly property bool several: CompositorConfig.outputs.length > 1
    function shows(key: string): bool { CompositorConfig.revision; return CompositorConfig.has("display", key) }
    function display(key: string): var { CompositorConfig.revision; return CompositorConfig.displayValue(key) }
    function picks(key: string): var {
        CompositorConfig.revision
        return CompositorConfig.displayChoices(key).map(pick => ({ displayName: Translation.tr(String(pick.label)), value: pick.value }))
    }
    function same(list: var, value: var): var { return list.find(pick => String(pick.value) === String(value))?.value ?? value }
    readonly property var kept: root.display("workspaces")
    readonly property bool fixedSet: root.kept !== "dynamic"
    readonly property var widths: [
        { displayName: Translation.tr("Like the rest"), value: 0 }, { displayName: Translation.tr("A third"), value: 0.333 },
        { displayName: Translation.tr("Half"), value: 0.5 }, { displayName: Translation.tr("Two thirds"), value: 0.667 },
        { displayName: Translation.tr("Whole"), value: 1 }
    ]
    readonly property bool sideways: root.display("workspace-axis") === "horizontal"

    Component.onCompleted: CompositorConfig.ensure()

    WSettingsRow {
        visible: CompositorConfig.pending !== null
        enableSettingsSearch: false
        icon: "alert"
        label: Translation.tr("Keep this display setting? It goes back in %1 s.").arg(CompositorConfig.secondsLeft)
        control: Component {
            RowLayout {
                spacing: Looks.dp(8)
                WButton {
                    text: Translation.tr("Keep")
                    colBackground: Looks.colors.accent
                    colBackgroundHover: Looks.colors.accentHover
                    colBackgroundActive: Looks.colors.accentActive
                    colForeground: Looks.colors.accentFg
                    onClicked: CompositorConfig.keepDisplay()
                }
                WButton {
                    text: Translation.tr("Revert")
                    colBackground: Looks.colors.interactiveSurface
                    colBackgroundHover: Looks.colors.interactiveSurfaceHover
                    colBackgroundActive: Looks.colors.interactiveSurfaceActive
                    onClicked: CompositorConfig.revertDisplay()
                }
            }
        }
    }

    WSettingsCard {
        visible: CompositorConfig.outputs.length > 0
        WDisplayArrangement { Layout.fillWidth: true }
    }

    WSettingsCard {
        visible: CompositorConfig.outputs.length > 0
        title: CompositorConfig.screenName(root.out)

        WSettingsDropdown {
            visible: root.several
            label: Translation.tr("Position")
            options: root.picks("place")
            currentValue: { CompositorConfig.revision; return root.out ? CompositorConfig.placeOf(root.out, CompositorConfig.neighbour(root.out)) : "" }
            onSelected: newValue => CompositorConfig.place(newValue)
        }
        WSettingsDropdown {
            visible: root.shows("scale")
            label: Translation.tr("Scale")
            options: root.picks("scale")
            currentValue: root.same(root.picks("scale"), root.display("scale"))
            onSelected: newValue => { if (String(newValue) !== String(root.display("scale"))) CompositorConfig.applyDisplay("scale", newValue) }
        }
        Repeater {
            model: ScriptModel { values: CompositorRows.of("Screen"); objectProp: "key" }
            WCompositorRow {}
        }
    }

    WSettingsCard {
        title: Translation.tr("Colour")
        visible: CompositorRows.of("Colour").length > 0
        Repeater {
            model: ScriptModel { values: CompositorRows.of("Colour"); objectProp: "key" }
            WCompositorRow {}
        }
    }

    WSettingsCard {
        title: Translation.tr("Workspaces")
        visible: root.shows("workspaces") || root.shows("new-width")

        WSettingsDropdown {
            visible: root.shows("workspaces")
            label: Translation.tr("Workspaces on this screen")
            options: [{ displayName: Translation.tr("As needed"), value: "dynamic" }, { displayName: Translation.tr("Fixed"), value: "fixed" }]
            currentValue: root.fixedSet ? "fixed" : "dynamic"
            onSelected: newValue => {
                if ((newValue === "fixed") === root.fixedSet) return
                CompositorConfig.applyDisplay("workspaces", newValue === "fixed" ? Math.max(Number(root.display("min-workspaces")) || 1, 4) : "dynamic")
            }
        }
        WSettingsSpinBox {
            id: count
            visible: root.shows("workspaces")
            readonly property int held: root.fixedSet ? Number(root.kept) : Number(root.display("min-workspaces")) || 1
            label: root.fixedSet ? Translation.tr("How many") : Translation.tr("Always waiting")
            from: 1
            to: 20
            Binding { target: count; property: "value"; value: count.held }
            onValueChanged: if (count.value !== count.held) CompositorConfig.applyDisplay(root.fixedSet ? "workspaces" : "min-workspaces", count.value)
        }
        WSettingsDropdown {
            visible: root.shows("workspace-axis")
            label: Translation.tr("Workspaces run")
            options: root.picks("workspace-axis")
            currentValue: String(root.display("workspace-axis"))
            onSelected: newValue => { if (String(newValue) !== String(root.display("workspace-axis"))) CompositorConfig.applyDisplay("workspace-axis", newValue) }
        }
        WSettingsSwitch {
            visible: root.shows("workspaces")
            label: Translation.tr("Loops around")
            description: Translation.tr("Past the last comes the first.")
            checked: root.display("cyclic") === true
            onToggled: checked => { if (checked !== (root.display("cyclic") === true)) CompositorConfig.applyDisplay("cyclic", checked) }
        }
        WSettingsDropdown {
            visible: root.shows("new-width") && root.several
            label: root.sideways ? Translation.tr("How tall new windows open on this screen") : Translation.tr("How wide new windows open on this screen")
            options: root.widths
            currentValue: root.widths.find(pick => Math.abs(Number(pick.value) - (Number(root.display("new-width")) || 0)) < 0.02)?.value ?? 0
            onSelected: newValue => CompositorConfig.applyDisplay("new-width", newValue)
        }
    }
}
