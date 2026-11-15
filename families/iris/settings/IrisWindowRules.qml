pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Windows › App rules: each app's own way of opening, as pieces on a plate the way the Dock holds apps. A
// piece is an app with a rule and says it in a line; the last piece adds one, from the apps open now or by its app id.
// The picked piece opens its rule under the plate: a drawing of where and how its windows open, beside the controls
// that change it. Every change goes on Settings' history (Ctrl+Z). CompositorConfig.appRules writes the compositor.
ColumnLayout {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var rules: CompositorConfig.appRules ?? null
    readonly property var list: root.rules?.rules ?? []
    property string picked: ""
    property bool adding: false
    // The rule as a drag shows it before it is written (the see-through range), for the drawing.
    property var draft: null
    onShowingChanged: root.draft = null
    // The rule open under the plate: the one picked, else the first, so the card always shows a window (none while adding).
    readonly property string showing: root.picked.length > 0 && root.list.some(rule => rule.app === root.picked) ? root.picked
        : root.adding ? "" : String(root.list[0]?.app ?? "")
    readonly property var current: root.list.find(rule => rule.app === root.showing) ?? null
    // Apps open now, once each; the ones that already have a rule stay off the list.
    readonly property var running: {
        const seen = []
        for (const win of NiriService.windows ?? []) {
            const app = String(win?.app_id ?? "")
            if (app.length > 0 && !seen.includes(app) && !root.list.some(rule => rule.app === app)) seen.push(app)
        }
        return seen.sort((a, b) => root.nameOf(a).localeCompare(root.nameOf(b)))
    }
    readonly property bool wide: root.width >= Math.round(560 * root.d)

    function nameOf(app: string): string {
        const entry = AppSearch.lookupDesktopEntry(app)
        return AppSearch.cleanAppName(entry?.name) || app
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
    readonly property var opens: [
        { label: Translation.tr("As usual"), value: "" }, { label: Translation.tr("Tiled"), value: "tiled" },
        { label: Translation.tr("Floating"), value: "floating" }, { label: Translation.tr("Maximized"), value: "maximized" },
        { label: Translation.tr("Fullscreen"), value: "fullscreen" }
    ]
    readonly property var widths: [
        { label: Translation.tr("As usual"), value: 0 }, { label: Translation.tr("A third"), value: 0.33333 },
        { label: Translation.tr("Half"), value: 0.5 }, { label: Translation.tr("Two thirds"), value: 0.66667 }
    ]
    // The rule in a line: what differs from a window of any other app.
    function sayOf(rule: var): string {
        if (!rule) return ""
        const parts = []
        const open = root.opens.find(entry => entry.value === rule.open && entry.value.length > 0)
        if (open) parts.push(open.label)
        const width = root.widths.find(entry => Math.abs(entry.value - Number(rule.width ?? 0)) < 0.01 && entry.value > 0)
        if (width && rule.open !== "maximized" && rule.open !== "fullscreen") parts.push(width.label)
        if (String(rule.workspace ?? "").length > 0) parts.push(root.workspaceName(rule.workspace))
        if (String(rule.screen ?? "").length > 0) parts.push(root.screenName(rule.screen))
        if (Number(rule.opacity ?? 1) < 1) parts.push(`${Math.round(Number(rule.opacity) * 100)} %`)
        if (rule.hidden) parts.push(Translation.tr("Left out of captures"))
        if (String(rule.title ?? "").length > 0) parts.push(Translation.tr("Titled “%1”").arg(rule.title))
        return parts.join(" · ") || Translation.tr("As usual")
    }
    function blank(app: string): var {
        return { app: app, title: "", open: "", workspace: "", screen: "", opacity: 1, hidden: false, width: 0, extra: ({}) }
    }
    // One change to one app's rule, written at once; Ctrl+Z writes the rule it had back.
    function change(app: string, patch: var, say: string): void {
        const before = root.rules.rule(app)
        const after = patch === null ? null : Object.assign({}, before ?? root.blank(app), patch)
        root.rules.put(app, after)
        IrisOptions.remember({ kind: "rules", key: "rules:" + app, at: Date.now(), steps: [], glyph: "app_registration",
            name: root.nameOf(app), say: say, back: () => root.rules.put(app, before), again: () => root.rules.put(app, after) })
    }
    function add(app: string): void {
        const id = String(app).trim()
        if (id.length === 0) return
        if (!root.rules.rule(id)) root.change(id, { open: "floating" }, Translation.tr("Added"))
        root.picked = id
        root.adding = false
        field.text = ""
    }

    spacing: Math.round(10 * root.d)

    IrisText {
        Layout.fillWidth: true
        visible: text.length > 0
        wrapMode: Text.Wrap
        font.pixelSize: IrisStyle.typeMeta
        color: root.rules?.error ? IrisStyle.danger : IrisStyle.subtext
        text: root.rules?.error ? Translation.tr("The compositor did not take that change: %1").arg(root.rules.error)
            : root.rules && !root.rules.ready ? Translation.tr("Reading the compositor's rules…") : ""
    }

    Rectangle {
        id: plate
        Layout.fillWidth: true
        implicitHeight: strip.implicitHeight + Math.round(24 * root.d)
        radius: IrisStyle.radiusCard
        color: IrisStyle.fillQuiet

        Flow {
            id: strip
            x: Math.round(12 * root.d)
            y: Math.round(12 * root.d)
            width: plate.width - Math.round(24 * root.d)
            spacing: Math.round(4 * root.d)
            Repeater {
                model: ScriptModel { values: root.list.map(rule => rule.app) }
                delegate: Piece {
                    required property string modelData
                    app: modelData
                    line: root.sayOf(root.list.find(rule => rule.app === modelData))
                    lit: root.showing === modelData
                    onPressed: { root.picked = modelData; root.adding = false }
                }
            }
            Piece {
                glyph: root.adding ? "close" : "add"
                title: root.adding ? Translation.tr("Cancel") : Translation.tr("Add")
                line: root.list.length === 0 && !root.adding ? Translation.tr("No app has a rule yet") : ""
                lit: root.adding
                onPressed: { root.adding = !root.adding; root.picked = "" }
            }
        }
    }

    // Adding: the apps open now, or an app id typed out (an app that is not running).
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.adding
        spacing: Math.round(8 * root.d)
        IrisText {
            text: root.running.length > 0 ? Translation.tr("Open now") : Translation.tr("Open the app to pick it here, or type its app id.")
            font.pixelSize: IrisStyle.typeMeta
            color: IrisStyle.subtext
        }
        Flow {
            Layout.fillWidth: true
            spacing: Math.round(4 * root.d)
            Repeater {
                model: ScriptModel { values: root.running }
                delegate: Piece {
                    required property string modelData
                    app: modelData
                    // The app id under its name only when it says something the name does not.
                    line: root.nameOf(modelData).toLowerCase() === modelData.toLowerCase() ? "" : modelData
                    onPressed: root.add(modelData)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.d)
            IrisField {
                id: field
                Layout.fillWidth: true
                font.pixelSize: IrisStyle.typeBody
                placeholderText: Translation.tr("App id, as `%1 windows` shows it").arg(CompositorConfig.umbriel ? "umbriel" : "niri msg")
                onAccepted: root.add(field.text)
            }
            IrisButton {
                text: Translation.tr("Add")
                enabled: field.text.trim().length > 0
                onClicked: root.add(field.text)
            }
        }
    }

    // The picked app's rule: the drawing beside its controls (over them when narrow).
    GridLayout {
        Layout.fillWidth: true
        visible: root.current !== null
        columns: root.wide ? 2 : 1
        columnSpacing: Math.round(16 * root.d)
        rowSpacing: Math.round(12 * root.d)

        IrisWindowRuleSketch {
            Layout.preferredWidth: root.wide ? Math.round(Math.min(300 * root.d, root.width * 0.42)) : root.width
            Layout.preferredHeight: Math.round((root.wide ? Math.min(300 * root.d, root.width * 0.42) : root.width) * 0.62)
            Layout.alignment: Qt.AlignTop
            rule: root.draft ?? root.current
            icon: root.iconOf(root.showing)
            screenName: root.current && String(root.current.screen ?? "").length > 0 ? root.screenName(root.current.screen) : ""
            workspaceName: root.current ? root.workspaceName(root.current.workspace) : ""
            caption: root.sayOf(root.current)
        }

        IrisWindowRuleForm {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            host: root
            rule: root.current
        }
    }

    // An app piece: its icon on a tile, its name, and a line under it.
    component Piece: MouseArea {
        id: piece
        property string app: ""
        property string glyph: ""
        property string title: root.nameOf(piece.app)
        property string line: ""
        property bool lit: false
        width: Math.round(96 * root.d)
        height: Math.round((piece.line.length > 0 ? 100 : 82) * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: piece.title
        Rectangle {
            id: tile
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(6 * root.d)
            width: Math.round(44 * root.d)
            height: width
            radius: IrisStyle.iconRadius(width)
            color: piece.lit ? IrisStyle.tintFill(IrisStyle.accent) : piece.containsMouse ? IrisStyle.fillHover : IrisStyle.fill
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            Image {
                id: icon
                anchors.centerIn: parent
                visible: piece.glyph.length === 0 && icon.status === Image.Ready
                width: Math.round(30 * root.d)
                height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: piece.glyph.length === 0 ? root.iconOf(piece.app) : ""
                asynchronous: true
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !icon.visible
                text: piece.glyph.length > 0 ? piece.glyph : "web_asset"
                iconSize: Math.round(22 * root.d)
                color: piece.lit ? IrisStyle.accent : IrisStyle.textSecondary
            }
        }
        IrisText {
            id: name
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(56 * root.d)
            width: parent.width - Math.round(4 * root.d)
            horizontalAlignment: Text.AlignHCenter
            text: piece.title
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeFootnote
            font.weight: IrisStyle.weight(piece.lit ? Font.DemiBold : Font.Medium)
            color: piece.lit ? IrisStyle.text : IrisStyle.subtext
        }
        IrisText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: name.bottom
            width: parent.width - Math.round(4 * root.d)
            visible: piece.line.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: piece.line
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeCaption
            color: IrisStyle.muted
        }
    }
}
