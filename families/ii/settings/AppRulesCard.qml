pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit

// Settings › the compositor › App rules: each app's own way of opening (floating, on a workspace or screen, how wide,
// see-through, left out of captures), one chip per app, the picked one's rule under them. Written at once through
// CompositorConfig.appRules (the base's one owner); a removed rule offers Undo. Shown on Niri and Umbriel.
SettingsCardSection {
    id: root

    readonly property var rules: CompositorConfig.appRules ?? null
    readonly property var list: root.rules?.rules ?? []
    property string picked: ""
    property bool adding: false
    property var removed: null
    readonly property string showing: root.list.some(rule => rule.app === root.picked) ? root.picked
        : root.adding ? "" : String(root.list[0]?.app ?? "")
    readonly property var current: root.list.find(rule => rule.app === root.showing) ?? null
    readonly property var running: {
        const seen = []
        for (const win of NiriService.windows ?? []) {
            const app = String(win?.app_id ?? "")
            if (app.length > 0 && !seen.includes(app) && !root.list.some(rule => rule.app === app)) seen.push(app)
        }
        return seen.sort((a, b) => root.nameOf(a).localeCompare(root.nameOf(b)))
    }
    function nameOf(app: string): string {
        return AppSearch.cleanAppName(AppSearch.lookupDesktopEntry(app)?.name) || app
    }
    function change(patch: var): void {
        const app = root.showing
        root.rules.put(app, Object.assign({ app: app, title: "", open: "", workspace: "", screen: "", opacity: 1, hidden: false, width: 0, extra: ({}) }, root.rules.rule(app) ?? {}, patch))
    }
    function add(app: string): void {
        const id = String(app).trim()
        if (id.length === 0) return
        if (!root.rules.rule(id)) root.rules.put(id, { app: id, title: "", open: "floating", workspace: "", screen: "", opacity: 1, hidden: false, width: 0, extra: ({}) })
        root.picked = id
        root.adding = false
        root.removed = null
        field.text = ""
    }
    readonly property var opens: [
        { displayName: Translation.tr("As usual"), value: "", icon: "auto_awesome_mosaic" },
        { displayName: Translation.tr("Tiled"), value: "tiled", icon: "view_column" },
        { displayName: Translation.tr("Floating"), value: "floating", icon: "filter_none" },
        { displayName: Translation.tr("Maximized"), value: "maximized", icon: "crop_square" },
        { displayName: Translation.tr("Fullscreen"), value: "fullscreen", icon: "fullscreen" }
    ]
    readonly property var widths: [
        { displayName: Translation.tr("As usual"), value: 0 }, { displayName: Translation.tr("A third"), value: 0.33333 },
        { displayName: Translation.tr("Half"), value: 0.5 }, { displayName: Translation.tr("Two thirds"), value: 0.66667 }
    ]
    readonly property var workspaces: {
        const out = [{ displayName: Translation.tr("Any"), value: "" }]
        for (let at = 1; at <= (root.rules?.positions ?? 0); at++) out.push({ displayName: String(at), value: at })
        for (const name of root.rules?.workspaceNames ?? []) out.push({ displayName: name, value: name })
        return out
    }
    readonly property var screens: [{ displayName: Translation.tr("Any"), value: "" }]
        .concat(CompositorConfig.outputs.map(out => ({ displayName: CompositorConfig.screenName(out), value: String(out.name) })))

    visible: root.rules !== null && (CompositorService.niriNative || CompositorService.isUmbriel)
    expanded: true
    icon: "app_registration"
    title: Translation.tr("App rules")

    SettingsGroup {
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: root.rules?.error ? Appearance.colors.colError : Appearance.colors.colSubtext
            text: root.rules?.error ? Translation.tr("The compositor did not take that change: %1").arg(root.rules.error)
                : root.rules && !root.rules.ready ? Translation.tr("Reading the compositor's rules…")
                : Translation.tr("One app's windows open their own way: floating, on a workspace or screen, see-through, left out of captures.")
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ScriptModel { values: root.list.map(rule => rule.app) }
                FilterChip {
                    required property string modelData
                    text: root.nameOf(modelData)
                    chipIcon: "web_asset"
                    selected: root.showing === modelData
                    onClicked: { root.picked = modelData; root.adding = false }
                }
            }
            FilterChip {
                text: root.adding ? Translation.tr("Cancel") : Translation.tr("Add")
                chipIcon: root.adding ? "close" : "add"
                selected: false
                onClicked: { root.adding = !root.adding; root.picked = "" }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: root.removed !== null
            materialIcon: "delete"
            text: root.removed ? Translation.tr("Removed") + ": " + root.nameOf(root.removed.app) : ""
            RippleButton {
                buttonText: Translation.tr("Undo")
                onClicked: { root.rules.put(root.removed.app, root.removed); root.picked = root.removed.app; root.removed = null }
            }
        }

        ContentSubsection {
            visible: root.adding
            title: root.running.length > 0 ? Translation.tr("Open now") : Translation.tr("Open the app to pick it here, or type its app id.")
            Flow {
                Layout.fillWidth: true
                spacing: 8
                visible: root.running.length > 0
                Repeater {
                    model: ScriptModel { values: root.running }
                    FilterChip {
                        required property string modelData
                        text: root.nameOf(modelData)
                        chipIcon: "add"
                        onClicked: root.add(modelData)
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MaterialTextField {
                    id: field
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    placeholderText: Translation.tr("App id, as `%1 windows` shows it").arg(CompositorService.isUmbriel ? "umbriel" : "niri msg")
                    onAccepted: root.add(field.text)
                }
                RippleButton {
                    buttonText: Translation.tr("Add")
                    enabled: field.text.trim().length > 0
                    onClicked: root.add(field.text)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.current !== null
            spacing: 4

            ContentSubsection {
                title: Translation.tr("Opens")
                tooltip: Translation.tr("How its windows open. As usual follows the rest of your windows.")
                ConfigSelectionArray {
                    enableSettingsSearch: false
                    options: root.opens
                    currentValue: String(root.current?.open ?? "")
                    onSelected: newValue => root.change({ open: newValue })
                }
            }
            ContentSubsection {
                visible: root.current?.open !== "maximized" && root.current?.open !== "fullscreen"
                title: Translation.tr("Width")
                tooltip: root.current?.open === "floating" ? Translation.tr("A share of the screen's width.") : Translation.tr("Its column's share of the screen's width.")
                ConfigSelectionArray {
                    enableSettingsSearch: false
                    options: root.widths
                    currentValue: root.widths.find(pick => Math.abs(pick.value - Number(root.current?.width ?? 0)) < 0.01)?.value ?? 0
                    onSelected: newValue => root.change({ width: newValue })
                }
            }
            ContentSubsection {
                visible: root.rules?.has("workspace") === true
                title: Translation.tr("On workspace")
                tooltip: CompositorService.niriNative ? Translation.tr("Niri opens apps only on named workspaces.") : Translation.tr("Counted from the top of its screen; past its last workspace, the last one.")
                ConfigSelectionArray {
                    enableSettingsSearch: false
                    options: root.workspaces
                    currentValue: root.current?.workspace ?? ""
                    onSelected: newValue => root.change({ workspace: newValue })
                }
            }
            ContentSubsection {
                visible: root.rules?.has("screen") === true
                title: Translation.tr("On screen")
                tooltip: Translation.tr("Its windows open there, wherever you are working.")
                ConfigSelectionArray {
                    enableSettingsSearch: false
                    options: root.screens
                    currentValue: String(root.current?.screen ?? "")
                    onSelected: newValue => root.change({ screen: newValue })
                }
            }
            ConfigSpinBox {
                id: through
                enableSettingsSearch: false
                text: Translation.tr("See-through")
                description: Translation.tr("How much of what is behind shows through its windows. Changes open windows too.")
                unit: "%"
                from: 30
                to: 100
                stepSize: 5
                Binding { target: through; property: "value"; value: Math.round(Number(root.current?.opacity ?? 1) * 100) }
                onValueModified: root.change({ opacity: through.value / 100 })
            }
            ConfigSwitch {
                id: hidden
                enableSettingsSearch: false
                buttonIcon: "visibility_off"
                text: Translation.tr("Left out of captures")
                description: Translation.tr("Screenshots, recordings and screen sharing show a blank where its windows are.")
                Binding { target: hidden; property: "checked"; value: root.current?.hidden === true }
                onCheckedChanged: if (root.current && hidden.checked !== (root.current.hidden === true)) root.change({ hidden: hidden.checked })
            }
            ContentSubsection {
                title: Translation.tr("Only windows titled")
                tooltip: Translation.tr("Words its title holds, for one kind of window of the app. Empty: every window.")
                MaterialTextField {
                    id: titled
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    placeholderText: Translation.tr("Every window")
                    text: String(root.current?.title ?? "")
                    onAccepted: titled.focus = false
                    onEditingFinished: if (titled.text.trim() !== String(root.current?.title ?? "")) root.change({ title: titled.text.trim() })
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("How and where a window opens applies to the next one the app opens.")
                }
                RippleButtonWithIcon {
                    materialIcon: "delete"
                    mainText: Translation.tr("Remove rule")
                    onClicked: { root.removed = root.current; root.rules.put(root.showing, null); root.picked = "" }
                }
            }
        }
    }
}
