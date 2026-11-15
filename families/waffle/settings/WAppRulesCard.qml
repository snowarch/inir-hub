pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Settings › Windows › App rules, as Windows lists apps: each app with a rule is a card with its icon, its name and the
// rule in a line; a press opens it like an expander, with the window drawn as it will open and the rule's rows under
// it. Written at once through CompositorConfig.appRules (the base's one owner); a removed rule offers Undo. "Add an
// app" opens the apps open now and a field for an app id. Shown on Niri and Umbriel.
ColumnLayout {
    id: root

    readonly property var rules: CompositorConfig.appRules ?? null
    readonly property var list: root.rules?.rules ?? []
    property string picked: ""
    property bool adding: false
    property var removed: null
    property string typed: ""
    readonly property string showing: root.list.some(rule => rule.app === root.picked) ? root.picked : ""
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
    // The rule in a line: what differs from a window of any other app.
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
        root.typed = ""
    }
    readonly property var opens: [
        { displayName: Translation.tr("As usual"), value: "" }, { displayName: Translation.tr("Tiled"), value: "tiled" },
        { displayName: Translation.tr("Floating"), value: "floating" }, { displayName: Translation.tr("Maximized"), value: "maximized" },
        { displayName: Translation.tr("Fullscreen"), value: "fullscreen" }
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
    Layout.fillWidth: true
    spacing: Looks.settings.cardSpacing

    // The section's head, as WSettingsCard's open group draws it.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Looks.dp(18)
        Layout.bottomMargin: Looks.dp(6)
        Layout.leftMargin: Looks.dp(1)
        spacing: Looks.dp(2)
        WText {
            Layout.fillWidth: true
            text: Translation.tr("App rules")
            font.pixelSize: Looks.settings.body
            font.weight: Looks.font.weight.strong
            Accessible.role: Accessible.Heading
        }
        WText {
            Layout.fillWidth: true
            text: root.rules?.error ? Translation.tr("The compositor did not take that change: %1").arg(root.rules.error)
                : root.rules && !root.rules.ready ? Translation.tr("Reading the compositor's rules…")
                : Translation.tr("One app's windows open their own way: floating, on a workspace or screen, see-through, left out of captures.")
            font.pixelSize: Looks.settings.caption
            font.weight: Looks.font.weight.thin
            color: root.rules?.error ? Looks.colors.danger : Looks.colors.subfg
            wrapMode: Text.WordWrap
        }
    }

    WSettingsRow {
        visible: root.removed !== null
        enableSettingsSearch: false
        icon: "delete"
        label: root.removed ? Translation.tr("Removed") + ": " + root.nameOf(root.removed.app) : ""
        control: Component {
            WButton {
                text: Translation.tr("Undo")
                colBackground: Looks.colors.interactiveSurface
                colBackgroundHover: Looks.colors.interactiveSurfaceHover
                colBackgroundActive: Looks.colors.interactiveSurfaceActive
                onClicked: { root.rules.put(root.removed.app, root.removed); root.picked = root.removed.app; root.removed = null }
            }
        }
    }

    Repeater {
        model: ScriptModel { values: root.list.map(rule => rule.app) }
        ColumnLayout {
            id: entry
            required property string modelData
            readonly property bool open: root.showing === entry.modelData
            Layout.fillWidth: true
            spacing: 0
            AppLine {
                Layout.fillWidth: true
                app: entry.modelData
                caption: root.sayOf(root.list.find(rule => rule.app === entry.modelData) ?? null)
                head: true
                flatBottom: entry.open
                onPressed: { root.picked = entry.open ? "" : entry.modelData; root.adding = false }
            }
            Loader {
                Layout.fillWidth: true
                Layout.topMargin: -1
                active: entry.open
                visible: active
                sourceComponent: editor
            }
        }
    }

    // Add an app: an expander of the apps open now, and a field for any app id.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        WSettingsRow {
            enableSettingsSearch: false
            icon: "add"
            label: Translation.tr("Add an app")
            description: Translation.tr("Open the app to pick it here, or type its app id.")
            clickable: true
            flatBottom: root.adding
            endInset: Looks.dp(8)
            onClicked: { root.adding = !root.adding; root.picked = "" }
            control: Component { Chevron { open: root.adding } }
        }
        Plate {
            Layout.fillWidth: true
            Layout.topMargin: -1
            visible: root.adding
            ColumnLayout {
                width: parent.width
                spacing: 0
                Repeater {
                    model: ScriptModel { values: root.adding ? root.running : [] }
                    AppLine {
                        required property string modelData
                        Layout.fillWidth: true
                        app: modelData
                        caption: modelData
                        onPressed: root.add(modelData)
                    }
                }
                WSettingsRow {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    label: Translation.tr("App id")
                    description: Translation.tr("App id, as `%1 windows` shows it").arg(CompositorService.isUmbriel ? "umbriel" : "niri msg")
                    control: Component {
                        RowLayout {
                            spacing: Looks.dp(8)
                            Rectangle {
                                implicitWidth: Looks.dp(200)
                                implicitHeight: Looks.dp(32)
                                radius: Looks.settings.radiusMedium
                                color: Looks.colors.inputBg
                                border.width: idField.activeFocus ? 2 : 1
                                border.color: idField.activeFocus ? Looks.colors.accent : Looks.settings.strokeStrong
                                WTextInput {
                                    id: idField
                                    anchors.fill: parent
                                    anchors.leftMargin: Looks.dp(10)
                                    anchors.rightMargin: Looks.dp(10)
                                    font.pixelSize: Looks.font.pixelSize.normal
                                    color: Looks.colors.fg
                                    selectByMouse: true
                                    clip: true
                                    text: root.typed
                                    onTextEdited: root.typed = text
                                    onAccepted: root.add(root.typed)
                                }
                            }
                            WButton {
                                text: Translation.tr("Add")
                                enabled: root.typed.trim().length > 0
                                colBackground: Looks.colors.accent
                                colBackgroundHover: Looks.colors.accentHover
                                colBackgroundActive: Looks.colors.accentActive
                                colForeground: Looks.colors.accentFg
                                onClicked: root.add(root.typed)
                            }
                        }
                    }
                }
            }
        }
    }

    // The open rule: the window drawn as it will open, then each of its settings.
    Component {
        id: editor
        Plate {
            ColumnLayout {
                width: parent.width
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: drawing.implicitHeight + Looks.dp(32)
                    ColumnLayout {
                        id: drawing
                        anchors.centerIn: parent
                        width: Math.min(parent.width - Looks.dp(32), Looks.dp(420))
                        spacing: Looks.dp(8)
                        WindowRuleSketch {
                            id: sketch
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(width * 0.56)
                            rule: root.current
                            icon: root.iconOf(root.showing)
                            unit: Looks.dp(1)
                            radius: Looks.settings.radiusLarge
                            windowRadius: Looks.settings.radiusSmall
                            windowColor: Looks.colors.bg1Base
                            lineColor: Looks.settings.strokeStrong
                            duration: Looks.transition.enabled ? Looks.transition.duration.slow : 0
                            easing: Easing.BezierSpline
                            curve: Looks.transition.easing.bezierCurve.decelerate
                            // Left out of captures: the window says so on its corner.
                            Rectangle {
                                visible: root.current?.hidden === true
                                x: sketch.window.x + sketch.window.width - width - Looks.dp(6)
                                y: sketch.window.y + Looks.dp(6)
                                width: Looks.dp(24)
                                height: width
                                radius: Looks.settings.radiusSmall
                                color: Looks.settings.tileHover
                                FluentIcon {
                                    anchors.centerIn: parent
                                    icon: "eye-off"
                                    implicitSize: Looks.dp(14)
                                    color: Looks.colors.fg
                                }
                            }
                            // Names only the drawing cannot show: a named workspace, a screen of its own.
                            Row {
                                x: Looks.dp(6)
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Looks.dp(6)
                                spacing: Looks.dp(4)
                                Repeater {
                                    model: root.current ? [String(root.current.workspace ?? "").length > 0 && typeof root.current.workspace !== "number" ? String(root.current.workspace) : "",
                                        String(root.current.screen ?? "").length > 0 ? root.screenName(root.current.screen) : ""].filter(text => text.length > 0) : []
                                    Rectangle {
                                        required property string modelData
                                        width: tag.implicitWidth + Looks.dp(12)
                                        height: Looks.dp(20)
                                        radius: Looks.settings.radiusSmall
                                        color: Looks.colors.bg1Base
                                        WText {
                                            id: tag
                                            anchors.centerIn: parent
                                            text: parent.modelData
                                            font.pixelSize: Looks.settings.caption
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                WSettingsDropdown {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    label: Translation.tr("Opens")
                    description: Translation.tr("How its windows open. As usual follows the rest of your windows.")
                    options: root.opens
                    currentValue: String(root.current?.open ?? "")
                    onSelected: newValue => root.change({ open: newValue })
                }
                WSettingsDropdown {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    visible: root.current?.open !== "maximized" && root.current?.open !== "fullscreen"
                    label: Translation.tr("Width")
                    description: root.current?.open === "floating" ? Translation.tr("A share of the screen's width.") : Translation.tr("Its column's share of the screen's width.")
                    options: root.widths
                    currentValue: root.widths.find(pick => Math.abs(pick.value - Number(root.current?.width ?? 0)) < 0.01)?.value ?? 0
                    onSelected: newValue => root.change({ width: newValue })
                }
                WSettingsDropdown {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    visible: root.rules?.has("workspace") === true
                    label: Translation.tr("On workspace")
                    description: CompositorService.niriNative ? Translation.tr("Niri opens apps only on named workspaces.") : Translation.tr("Counted from the top of its screen; past its last workspace, the last one.")
                    options: root.workspaces
                    currentValue: root.workspaces.find(pick => String(pick.value) === String(root.current?.workspace ?? ""))?.value ?? ""
                    onSelected: newValue => root.change({ workspace: newValue })
                }
                WSettingsDropdown {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    visible: root.rules?.has("screen") === true
                    label: Translation.tr("On screen")
                    description: Translation.tr("Its windows open there, wherever you are working.")
                    options: root.screens
                    currentValue: String(root.current?.screen ?? "")
                    onSelected: newValue => root.change({ screen: newValue })
                }
                WSettingsSpinBox {
                    id: through
                    cardStyle: "item"
                    enableSettingsSearch: false
                    readonly property int held: Math.round(Number(root.current?.opacity ?? 1) * 100)
                    label: Translation.tr("See-through")
                    description: Translation.tr("How much of what is behind shows through its windows. Changes open windows too.")
                    suffix: " %"
                    from: 30
                    to: 100
                    stepSize: 5
                    Binding { target: through; property: "value"; value: through.held }
                    onValueChanged: if (root.current && through.value !== through.held) root.change({ opacity: through.value / 100 })
                }
                WSettingsSwitch {
                    id: hidden
                    cardStyle: "item"
                    enableSettingsSearch: false
                    label: Translation.tr("Left out of captures")
                    description: Translation.tr("Screenshots, recordings and screen sharing show a blank where its windows are.")
                    Binding { target: hidden; property: "checked"; value: root.current?.hidden === true }
                    onCheckedChanged: if (root.current && hidden.checked !== (root.current.hidden === true)) root.change({ hidden: hidden.checked })
                }
                WSettingsTextField {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    label: Translation.tr("Only windows titled")
                    description: Translation.tr("Words its title holds, for one kind of window of the app. Empty: every window.")
                    placeholderText: Translation.tr("Every window")
                    text: String(root.current?.title ?? "")
                    onEditingFinished: newText => { if (root.current && newText.trim() !== String(root.current.title ?? "")) root.change({ title: newText.trim() }) }
                }
                WSettingsRow {
                    cardStyle: "item"
                    enableSettingsSearch: false
                    label: Translation.tr("Remove rule")
                    description: Translation.tr("How and where a window opens applies to the next one the app opens.")
                    control: Component {
                        WButton {
                            text: Translation.tr("Remove rule")
                            colBackground: Looks.colors.interactiveSurface
                            colBackgroundHover: Looks.colors.interactiveSurfaceHover
                            colBackgroundActive: Looks.colors.interactiveSurfaceActive
                            onClicked: { root.removed = root.current; root.rules.put(root.showing, null); root.picked = "" }
                        }
                    }
                }
            }
        }
    }

    // An expander's body: one plate under its header, closed at the bottom.
    component Plate: Rectangle {
        default property alias body: inside.data
        implicitHeight: inside.childrenRect.height
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Looks.settings.radiusSmall
        bottomRightRadius: Looks.settings.radiusSmall
        color: Looks.settings.card
        border.width: 1
        border.color: Looks.settings.cardStroke
        Item {
            id: inside
            width: parent.width
            height: childrenRect.height
        }
    }

    component Chevron: Item {
        property bool open: false
        implicitWidth: Looks.dp(32)
        implicitHeight: Looks.dp(32)
        FluentIcon {
            anchors.centerIn: parent
            icon: "chevron-down"
            implicitSize: Looks.dp(13)
            color: Looks.colors.fg
            rotation: parent.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard } }
        }
    }

    // An app as Windows lists one: its icon, its name, a line under it; a head opens its rule (a chevron), a line in
    // the add list adds it.
    component AppLine: Rectangle {
        id: appLine
        property string app: ""
        property string caption: ""
        property bool head: false
        property bool flatBottom: false
        signal pressed()
        implicitHeight: Math.max(appLine.head ? Looks.settings.cardMinHeight : Looks.settings.cardItemMinHeight, words.implicitHeight + Looks.dp(20))
        radius: appLine.head ? Looks.settings.radiusSmall : 0
        bottomLeftRadius: appLine.flatBottom || !appLine.head ? 0 : Looks.settings.radiusSmall
        bottomRightRadius: appLine.flatBottom || !appLine.head ? 0 : Looks.settings.radiusSmall
        color: tap.pressed ? Looks.settings.cardPressed : tap.containsMouse ? Looks.settings.cardHover : appLine.head ? Looks.settings.card : "transparent"
        border.width: appLine.head ? 1 : 0
        border.color: Looks.settings.cardStroke
        Behavior on color { ColorAnimation { duration: Looks.transition.enabled ? 83 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard } }
        Rectangle { visible: !appLine.head; width: parent.width; height: 1; color: Looks.settings.cardStroke }
        activeFocusOnTab: true
        Keys.onReturnPressed: appLine.pressed()
        Keys.onSpacePressed: appLine.pressed()
        WFocusVisual { shown: appLine.activeFocus; radius: appLine.radius }
        MouseArea {
            id: tap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appLine.pressed()
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: appLine.head ? Looks.settings.cardPadding + Looks.dp(2) : Looks.dp(58)
            anchors.rightMargin: appLine.head ? Looks.dp(8) : Looks.dp(44)
            spacing: Looks.dp(20)
            Image {
                Layout.preferredWidth: Looks.settings.cardIconSize
                Layout.preferredHeight: Looks.settings.cardIconSize
                sourceSize: Qt.size(48, 48)
                source: root.iconOf(appLine.app)
                asynchronous: true
            }
            ColumnLayout {
                id: words
                Layout.fillWidth: true
                spacing: 0
                WText {
                    Layout.fillWidth: true
                    text: root.nameOf(appLine.app)
                    font.pixelSize: Looks.settings.body
                    font.weight: Looks.font.weight.thin
                    elide: Text.ElideRight
                }
                WText {
                    Layout.fillWidth: true
                    visible: appLine.caption.length > 0 && appLine.caption !== root.nameOf(appLine.app)
                    text: appLine.caption
                    font.pixelSize: Looks.settings.caption
                    font.weight: Looks.font.weight.thin
                    color: Looks.colors.subfg
                    elide: Text.ElideRight
                }
            }
            Chevron { visible: appLine.head; open: appLine.flatBottom }
            FluentIcon {
                visible: !appLine.head
                Layout.rightMargin: Looks.dp(-28)
                icon: "add"
                implicitSize: Looks.dp(16)
                color: Looks.colors.fg
            }
        }
    }
}
