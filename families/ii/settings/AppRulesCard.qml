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
    function iconOf(app: string): string {
        const entry = AppSearch.lookupDesktopEntry(app)
        return entry ? AppSearch.getIconSource(entry.icon, "") : AppSearch.getIconSource(app, "")
    }
    function workspaceName(ws: var): string {
        return typeof ws === "number" ? Translation.tr("Workspace %1").arg(ws) : String(ws ?? "")
    }
    function screenName(name: string): string {
        return CompositorConfig.screenName(CompositorConfig.outputs.find(out => out.name === name) ?? { name: name })
    }
    // The rule in a line, under its drawing: what differs from a window of any other app.
    function sayOf(rule: var): string {
        if (!rule) return ""
        const parts = []
        const open = root.opens.find(entry => entry.value === rule.open && entry.value.length > 0)
        if (open) parts.push(open.displayName)
        const width = root.widths.find(entry => Math.abs(entry.value - Number(rule.width ?? 0)) < 0.01 && entry.value > 0)
        if (width && rule.open !== "maximized" && rule.open !== "fullscreen") parts.push(width.displayName)
        if (String(rule.workspace ?? "").length > 0) parts.push(root.workspaceName(rule.workspace))
        if (String(rule.screen ?? "").length > 0) parts.push(root.screenName(rule.screen))
        if (Number(rule.opacity ?? 1) < 1) parts.push(`${Math.round(Number(rule.opacity) * 100)} %`)
        if (rule.hidden) parts.push(Translation.tr("Left out of captures"))
        if (String(rule.title ?? "").length > 0) parts.push(Translation.tr("Titled “%1”").arg(rule.title))
        return parts.join(" · ") || Translation.tr("As usual")
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

            // The rule drawn: the screen, the workspace and the window as it opens, moving to each new value.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 6
                WindowRuleSketch {
                    id: sketch
                    Layout.fillWidth: true
                    Layout.maximumWidth: 420
                    Layout.preferredHeight: Math.round(Math.min(width, 420) * 0.56)
                    Layout.alignment: Qt.AlignHCenter
                    rule: root.current
                    icon: root.iconOf(root.showing)
                    radius: Appearance.rounding.normal
                    windowRadius: Appearance.rounding.verysmall
                    windowColor: Appearance.colors.colSurfaceContainerHighest
                    lineColor: Appearance.colors.colOutlineVariant
                    duration: Appearance.animation.elementMove.duration
                    easing: Appearance.animation.elementMove.type
                    curve: Appearance.animation.elementMove.bezierCurve

                    // Left out of captures: the window says so on its corner.
                    Rectangle {
                        visible: root.current?.hidden === true
                        x: sketch.window.x + sketch.window.width - width - 6
                        y: sketch.window.y + 6
                        width: 24
                        height: 24
                        radius: 12
                        color: Appearance.colors.colSurfaceContainerLow
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "visibility_off"
                            iconSize: 14
                            color: Appearance.colors.colOnSurface
                        }
                    }
                    // Names only the drawing cannot show: a named workspace, a screen of its own.
                    Row {
                        x: 6
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        spacing: 4
                        Repeater {
                            model: root.current ? [String(root.current.workspace ?? "").length > 0 && typeof root.current.workspace !== "number" ? String(root.current.workspace) : "",
                                String(root.current.screen ?? "").length > 0 ? root.screenName(root.current.screen) : ""].filter(text => text.length > 0) : []
                            Rectangle {
                                required property string modelData
                                width: tag.implicitWidth + 12
                                height: 20
                                radius: 10
                                color: Appearance.colors.colSurfaceContainerLow
                                StyledText {
                                    id: tag
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurface
                                }
                            }
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: root.nameOf(root.showing) + " · " + root.sayOf(root.current)
                }
            }

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
