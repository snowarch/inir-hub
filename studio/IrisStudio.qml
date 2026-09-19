pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.preview

PanelWindow {
    id: root
    readonly property real d: IrisStyle.density
    property string target: "material"

    readonly property var targets: [
        { id: "material", label: "Material", glyph: "layers" },
        { id: "colour", label: "Colour", glyph: "palette" },
        { id: "type", label: "Type", glyph: "text_fields" },
        { id: "motion", label: "Motion", glyph: "animation" },
        { id: "island", label: "Island", glyph: "pill" },
        { id: "pieces", label: "Pieces", glyph: "bubble_chart" },
        { id: "bodies", label: "Bodies", glyph: "web_asset" },
        { id: "places", label: "Places", glyph: "space_dashboard" },
        { id: "transients", label: "Feedback", glyph: "notifications" },
        { id: "dock", label: "Dock", glyph: "dock_to_bottom" },
        { id: "desktop", label: "Desktop", glyph: "widgets" },
        { id: "themes", label: "Themes", glyph: "style" }
    ]
    readonly property var presetOrder: ["iris", "soft", "round", "crisp", "angular", "contrast"]

    readonly property var specifications: IrisOptions.studio
    function shown(spec: var): bool {
        const when = String(spec.visibleWhen ?? "")
        if (when.length === 0) return true
        if (when.includes("=")) return String(Config.getNestedValue(when.split("=")[0], "")) === when.split("=")[1]
        const negated = when.startsWith("!")
        const on = Boolean(Config.getNestedValue(negated ? when.slice(1) : when, false))
        return negated ? !on : on
    }
    readonly property var groups: {
        Config.revision
        const out = []
        for (const spec of root.specifications) {
            if (spec.target !== root.target || !root.shown(spec)) continue
            if (out.length === 0 || out[out.length - 1].title !== spec.group) out.push({ title: spec.group, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }

    readonly property var themeTargets: ["material", "colour", "type", "motion"]
    readonly property var themePaths: ["iris.appearance.preset"].concat(root.specifications
        .filter(spec => String(spec.path).startsWith("iris.")
            && (root.themeTargets.includes(spec.target) || String(spec.path).startsWith("iris.appearance.surfaces.")))
        .map(spec => spec.path))
    function fallbackOf(path: string): var {
        if (path === "iris.appearance.preset") return "iris"
        return root.specifications.find(spec => spec.path === path)?.fallback
    }
    function currentValues(): var {
        const values = {}
        for (const path of root.themePaths) values[path] = IrisOptions.plain(Config.getNestedValue(path, root.fallbackOf(path)))
        return values
    }
    function applyValues(values: var): void {
        const updates = {}
        for (const path of root.themePaths) {
            updates[path] = Object.prototype.hasOwnProperty.call(values ?? {}, path) ? values[path] : root.fallbackOf(path)
        }
        Config.setNestedValues(updates)
    }
    readonly property var looks: [
        { name: "iRiS", description: "Black, direct, lit by what things are.", material: "black", accent: IrisStyle.accents.blue, values: {} },
        { name: "Obsidian", description: "Sharper, quieter, no light.", material: "black", accent: IrisStyle.accents.lilac,
            values: { "iris.appearance.preset": "crisp", "iris.appearance.theme.lines": 60, "iris.appearance.theme.shadow": 140,
                "iris.appearance.aura": "off", "iris.appearance.accent": "lilac" } },
        { name: "Aurora", description: "The wallpaper's own colour and vivid, far-reaching light.", material: "wallpaper", accent: IrisStyle.wallpaperLight,
            values: { "iris.appearance.theme.surface": "wallpaper", "iris.appearance.aura": "vivid", "iris.appearance.theme.lightReach": 200,
                "iris.appearance.accent": "wallpaper",
                "iris.appearance.highlight": "wallpaper", "iris.appearance.tint": 40 } },
        { name: "Paper", description: "Soft and round, no lines, barely a shadow.", material: "graphite", accent: IrisStyle.accents.mint,
            values: { "iris.appearance.preset": "soft", "iris.appearance.theme.surface": "graphite", "iris.appearance.theme.lines": 0,
                "iris.appearance.theme.shadow": 40, "iris.appearance.theme.shape": 130, "iris.appearance.theme.fill": 80,
                "iris.appearance.accent": "mint" } },
        { name: "Midnight", description: "Deep blue material, violet highlight.", material: "midnight", accent: Qt.hsla(0.64, 0.7, 0.78, 1), // iris-literal: look swatch
            values: { "iris.appearance.theme.surface": "midnight", "iris.appearance.accent": "custom", "iris.appearance.theme.accentHue": 230,
                "iris.appearance.highlight": "custom", "iris.appearance.theme.highlightHue": 280, "iris.appearance.theme.contrast": 110 } },
        { name: "Signal", description: "High contrast, larger text, crisp joins.", material: "black", accent: IrisStyle.highlights.yellow,
            values: { "iris.appearance.preset": "contrast", "iris.appearance.theme.fill": 130, "iris.appearance.theme.text": 108,
                "iris.appearance.aura": "off",
                "iris.appearance.highlight": "yellow", "iris.appearance.accent": "custom", "iris.appearance.theme.accentHue": 52 } },
        { name: "iNiR Theme", description: "Follows the global iNiR theme: its preset or the wallpaper's Material You colours.", material: "theme", accent: IrisStyle.themeAccent,
            values: { "iris.appearance.theme.surface": "theme", "iris.appearance.accent": "theme", "iris.appearance.highlight": "theme" } },
        { name: "Adaptive", description: "Shaped by the wallpaper: its colour, brightness and calm or busy mood.", material: "wallpaper", accent: IrisStyle.wallpaperLight,
            values: { "iris.appearance.adaptive": 80, "iris.appearance.theme.surface": "wallpaper", "iris.appearance.accent": "wallpaper",
                "iris.appearance.highlight": "wallpaper", "iris.appearance.aura": "subtle", "iris.appearance.tint": 25 } },
        { name: "Sakura", description: "Soft graphite, petal pink and generous curves.", material: "graphite", accent: Qt.hsla(0.92, 0.75, 0.8, 1), // iris-literal: look swatch
            values: { "iris.appearance.preset": "soft", "iris.appearance.theme.surface": "graphite", "iris.appearance.accent": "custom",
                "iris.appearance.theme.accentHue": 330, "iris.appearance.highlight": "pink", "iris.appearance.aura": "vivid",
                "iris.appearance.theme.shape": 125, "iris.appearance.theme.lines": 50 } },
        { name: "Neo Tokyo", description: "Midnight glass lit in cyan and magenta.", material: "midnight", accent: Qt.hsla(0.51, 0.9, 0.62, 1), // iris-literal: look swatch
            values: { "iris.appearance.preset": "crisp", "iris.appearance.theme.surface": "midnight", "iris.appearance.accent": "custom",
                "iris.appearance.theme.accentHue": 185, "iris.appearance.highlight": "custom", "iris.appearance.theme.highlightHue": 300,
                "iris.appearance.aura": "vivid", "iris.appearance.theme.lightReach": 180, "iris.appearance.theme.shadow": 130 } },
        { name: "Ghibli", description: "Paper-soft, meadow green and a warm sun.", material: "graphite", accent: IrisStyle.accents.mint,
            values: { "iris.appearance.preset": "soft", "iris.appearance.theme.surface": "graphite", "iris.appearance.accent": "mint",
                "iris.appearance.highlight": "custom", "iris.appearance.theme.highlightHue": 40, "iris.appearance.theme.lines": 40,
                "iris.appearance.theme.shape": 135, "iris.appearance.theme.contrast": 95 } },
        { name: "Evangelion", description: "Deep violet, warning green, hard contrast.", material: "midnight", accent: Qt.hsla(0.76, 0.7, 0.7, 1), // iris-literal: look swatch
            values: { "iris.appearance.preset": "contrast", "iris.appearance.theme.surface": "midnight", "iris.appearance.accent": "custom",
                "iris.appearance.theme.accentHue": 275, "iris.appearance.highlight": "custom", "iris.appearance.theme.highlightHue": 95,
                "iris.appearance.theme.shadow": 140 } }
    ]
    readonly property var saved: Array.from(Config.options?.iris?.appearance?.saved ?? [])
    property string notice: ""
    Timer { id: noticeTimer; interval: 2400; onTriggered: root.notice = "" }
    function say(text: string): void { root.notice = text; noticeTimer.restart() }
    function saveCurrent(name: string): void {
        const clean = name.trim().length > 0 ? name.trim() : Translation.tr("My look %1").arg(root.saved.length + 1)
        const next = root.saved.filter(entry => entry.name !== clean)
        next.push({ name: clean, values: root.currentValues() })
        Config.setNestedValue("iris.appearance.saved", next)
        root.say(Translation.tr("Saved “%1”").arg(clean))
    }
    function removeSaved(name: string): void {
        Config.setNestedValue("iris.appearance.saved", root.saved.filter(entry => entry.name !== name))
    }
    function exportLook(entry: var): void {
        Quickshell.clipboardText = JSON.stringify({ iris: "look", name: entry.name, values: entry.values }, null, 2)
        root.say(Translation.tr("Copied “%1” — paste it anywhere to share it").arg(entry.name))
    }
    function importLook(): void {
        try {
            const data = JSON.parse(String(Quickshell.clipboardText ?? ""))
            if (data?.iris !== "look" || typeof data.values !== "object") throw new Error()
            const values = {}
            for (const path of root.themePaths) if (Object.prototype.hasOwnProperty.call(data.values, path)) values[path] = data.values[path]
            const name = String(data.name ?? Translation.tr("Imported look"))
            const next = root.saved.filter(entry => entry.name !== name)
            next.push({ name: name, values: values })
            Config.setNestedValue("iris.appearance.saved", next)
            root.say(Translation.tr("Imported “%1”").arg(name))
        } catch (error) {
            root.say(Translation.tr("The clipboard does not hold an iRiS look"))
        }
    }

    readonly property bool showPreview: Config.options?.iris?.appearance?.studioPreview ?? true
    property bool desktopPreview: false
    onDesktopPreviewChanged: root.preview(root.target, root.desktopPreview)
    function preview(id: string, on: bool): void {
        if (on && !root.desktopPreview) return
        switch (id) {
        case "island":
            if (on) GlobalStates.irisIslandPageRequest = "desktop"
            else GlobalStates.irisArrange = false
            break
        case "bodies":
            GlobalStates.controlPanelOpen = on
            break
        case "places":
            if (on) GlobalStates.openSidebarRight("")
            else GlobalStates.sidebarRightOpen = false
            break
        case "dock":
            GlobalStates.irisDockShown = on
            break
        }
    }
    function select(id: string): void {
        if (id === root.target) return
        root.preview(root.target, false)
        root.target = id
        root.preview(id, true)
        flick.contentY = 0
    }
    function takeRequest(): void {
        const wanted = GlobalStates.irisStudioTarget
        if (wanted.length === 0) return
        GlobalStates.irisStudioTarget = ""
        if (root.targets.some(entry => entry.id === wanted)) root.select(wanted)
    }
    Component.onCompleted: root.takeRequest()
    Connections {
        target: GlobalStates
        function onIrisStudioTargetChanged(): void { root.takeRequest() }
        function onIrisStudioOpenChanged(): void {
            if (GlobalStates.irisStudioOpen) root.preview(root.target, true)
            else root.preview(root.target, false)
        }
    }
    function resetTarget(): void {
        const updates = {}
        for (const spec of root.specifications) {
            if (spec.target === root.target && String(spec.path).startsWith("iris.")) updates[spec.path] = spec.fallback
        }
        Config.setNestedValues(updates)
    }

    readonly property var descriptions: ({
        material: "What every surface is made of: its character, corners, lines and the frame.",
        colour: "Accent, highlight, the light bodies carry and how much wallpaper iRiS takes in.",
        type: "Typefaces, figures and how large text reads.",
        motion: "How shapes open, move and settle — everywhere at once, or per surface.",
        island: "Its shape on the edge, what it shows at rest, and its pages.",
        pieces: "Bubbles off the Island and the bars they form.",
        bodies: "Cards, the Control Center and the player.",
        places: "Side panels, Spotlight, the gallery, Settings and menus.",
        transients: "Notifications and level feedback.",
        dock: "The Dock's shape and its icons.",
        desktop: "Widgets on the desktop.",
        themes: "Curated looks, and the ones you save and share."
    })
    readonly property var railSections: [["material", "colour", "type", "motion"],
        ["island", "pieces", "bodies", "places", "transients", "dock", "desktop"], ["themes"]]
    function targetOf(id: string): var { return root.targets.find(entry => entry.id === id) ?? root.targets[0] }
    function modifiedIn(id: string): int {
        void Config.revision
        let count = 0
        for (const spec of root.specifications) {
            if (spec.target !== id || !String(spec.path).startsWith("iris.") || spec.fallback === undefined) continue
            if (!IrisOptions.same(Config.getNestedValue(spec.path, spec.fallback), spec.fallback)) count++
        }
        return count
    }

    property string query: ""
    readonly property var matches: {
        void Config.revision
        const q = root.query.trim().toLowerCase()
        if (q.length === 0) return []
        const out = []
        for (const spec of root.specifications) {
            if (!root.shown(spec)) continue
            const text = [spec.label, spec.description ?? "", spec.group, root.targetOf(spec.target).label].join(" ").toLowerCase()
            if (!text.includes(q)) continue
            const title = root.targetOf(spec.target).label + " · " + spec.group
            if (out.length === 0 || out[out.length - 1].title !== title) out.push({ title: title, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }

    readonly property var trackedPaths: {
        const set = {}
        set["iris.appearance.preset"] = true
        for (const spec of root.specifications) if (String(spec.path).startsWith("iris.")) set[spec.path] = true
        return Object.keys(set)
    }
    function snapshot(): var {
        const values = {}
        for (const path of root.trackedPaths) values[path] = IrisOptions.plain(Config.getNestedValue(path, root.fallbackOf(path)))
        return values
    }
    property var undoStack: []
    property var redoStack: []
    property var lastSnapshot: null
    property string lastKey: ""
    property bool restoring: false
    function recordHistory(): void {
        const snap = root.snapshot()
        const key = JSON.stringify(snap)
        if (key === root.lastKey) return
        if (root.lastSnapshot && !root.restoring) {
            root.undoStack = root.undoStack.concat([root.lastSnapshot]).slice(-60)
            root.redoStack = []
        }
        root.restoring = false
        root.lastSnapshot = snap
        root.lastKey = key
    }
    function undo(): void {
        if (root.undoStack.length === 0) return
        const previous = root.undoStack[root.undoStack.length - 1]
        root.undoStack = root.undoStack.slice(0, -1)
        root.redoStack = root.redoStack.concat([root.snapshot()])
        root.restoring = true
        Config.setNestedValues(previous)
        root.say(Translation.tr("Undone"))
    }
    function redo(): void {
        if (root.redoStack.length === 0) return
        const next = root.redoStack[root.redoStack.length - 1]
        root.redoStack = root.redoStack.slice(0, -1)
        root.undoStack = root.undoStack.concat([root.snapshot()])
        root.restoring = true
        Config.setNestedValues(next)
        root.say(Translation.tr("Redone"))
    }
    Timer {
        id: historyTimer
        interval: 320
        onTriggered: root.recordHistory()
    }
    Connections {
        target: Config
        enabled: GlobalStates.irisStudioOpen
        function onRevisionChanged(): void { historyTimer.restart() }
    }
    Connections {
        target: GlobalStates
        function onIrisStudioOpenChanged(): void {
            if (!GlobalStates.irisStudioOpen) return
            root.lastSnapshot = root.snapshot()
            root.lastKey = JSON.stringify(root.lastSnapshot)
            root.undoStack = []
            root.redoStack = []
        }
    }

    readonly property var presentedRect: GlobalStates.irisStudioOpen && frame.armed
        ? { screen: root.screen?.name ?? "", x: frame.x, y: frame.y, width: frame.width, height: frame.height } : null
    onPresentedRectChanged: GlobalStates.irisStudioRect = root.presentedRect
    Component.onDestruction: GlobalStates.irisStudioRect = null

    visible: GlobalStates.irisStudioOpen || frame.progress > 0
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; top: true; bottom: true }
    implicitWidth: frame.width + Math.round(24 * root.d) + IrisFrame.band
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:iris-studio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.irisStudioOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: frame }

    Shortcut {
        sequence: "Escape"
        enabled: GlobalStates.irisStudioOpen
        onActivated: {
            if (root.query.length > 0) { root.query = ""; searchField.text = "" }
            else GlobalStates.irisStudioOpen = false
        }
    }
    Shortcut { sequences: [StandardKey.Undo]; enabled: GlobalStates.irisStudioOpen; onActivated: root.undo() }
    Shortcut { sequences: [StandardKey.Redo, "Ctrl+Shift+Z"]; enabled: GlobalStates.irisStudioOpen; onActivated: root.redo() }
    Shortcut { sequence: "Ctrl+F"; enabled: GlobalStates.irisStudioOpen; onActivated: searchField.forceActiveFocus() }

    IrisMorphSurface {
        id: frame
        open: GlobalStates.irisStudioOpen
        motionSurface: "settings"
        radius: IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel)
        light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
        x: Math.round(12 * root.d) + IrisFrame.band
        y: (parent.height - height) / 2
        width: Math.min((root.screen?.width ?? 1920) - Math.round(48 * root.d) - IrisFrame.band * 2, Math.round(540 * root.d))
        height: Math.min(parent.height - Math.round(24 * root.d) - IrisFrame.band * 2, Math.round(960 * root.d))
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(16 * root.d)
            spacing: Math.round(12 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                IrisMark { implicitSize: Math.round(24 * root.d) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    IrisText {
                        text: Translation.tr("Studio")
                        font.family: IrisStyle.fontTitle
                        font.pixelSize: 19 * IrisStyle.typeScale
                        font.weight: Font.Bold
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: root.notice.length > 0 ? root.notice : Translation.tr("Everything you change is the shell itself")
                        color: root.notice.length > 0 ? IrisStyle.accent : IrisStyle.muted
                        font.pixelSize: 11.5 * IrisStyle.typeScale
                        elide: Text.ElideRight
                    }
                }
                IrisIconButton {
                    materialIcon: "undo"
                    enabled: root.undoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Undo")
                    onClicked: root.undo()
                }
                IrisIconButton {
                    materialIcon: "redo"
                    enabled: root.redoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Redo")
                    onClicked: root.redo()
                }
                Rectangle { implicitWidth: 1; implicitHeight: Math.round(18 * root.d); color: IrisStyle.hairline }
                IrisIconButton {
                    materialIcon: "edit"
                    selected: GlobalStates.irisEdit
                    Accessible.name: Translation.tr("Edit iRiS in place")
                    onClicked: {
                        GlobalStates.irisEdit = !GlobalStates.irisEdit
                        if (GlobalStates.irisEdit) GlobalStates.irisStudioOpen = false
                    }
                }
                IrisIconButton {
                    materialIcon: "tune"
                    Accessible.name: Translation.tr("All settings")
                    onClicked: { GlobalStates.irisStudioOpen = false; GlobalStates.openSettings() }
                }
                IrisIconButton {
                    materialIcon: "close"
                    Accessible.name: Translation.tr("Close Studio")
                    onClicked: GlobalStates.irisStudioOpen = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(34 * root.d)
                radius: height / 2
                color: searchField.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                Behavior on color { ColorAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(12 * root.d)
                    anchors.rightMargin: Math.round(6 * root.d)
                    spacing: Math.round(8 * root.d)
                    MaterialSymbol { text: "search"; iconSize: Math.round(17 * root.d); color: IrisStyle.muted }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: IrisStyle.text
                        selectionColor: IrisStyle.accentContainer
                        font.family: IrisStyle.fontMain
                        font.pixelSize: 13 * IrisStyle.typeScale
                        clip: true
                        onTextChanged: { root.query = text; flick.contentY = 0 }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text.length === 0
                            text: Translation.tr("Search every option")
                            color: IrisStyle.muted
                            font.pixelSize: searchField.font.pixelSize
                        }
                    }
                    IrisIconButton {
                        visible: searchField.text.length > 0
                        implicitWidth: Math.round(24 * root.d)
                        materialIcon: "close"
                        iconSize: Math.round(14 * root.d)
                        Accessible.name: Translation.tr("Clear search")
                        onClicked: searchField.text = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(12 * root.d)

                Flickable {
                    Layout.preferredWidth: Math.round(58 * root.d)
                    Layout.fillHeight: true
                    contentHeight: rail.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    opacity: root.query.length > 0 ? 0.4 : 1
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140) } }

                    ColumnLayout {
                        id: rail
                        width: parent.width
                        spacing: Math.round(2 * root.d)
                        Repeater {
                            model: root.railSections
                            ColumnLayout {
                                id: railSection
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: Math.round(2 * root.d)
                                Rectangle {
                                    visible: railSection.index > 0
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: Math.round(5 * root.d)
                                    Layout.bottomMargin: Math.round(5 * root.d)
                                    implicitWidth: Math.round(24 * root.d)
                                    implicitHeight: 1
                                    color: IrisStyle.hairline
                                }
                                Repeater {
                                    model: railSection.modelData
                                    RailButton {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        entry: root.targetOf(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(10 * root.d)

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.query.length === 0
                        spacing: Math.round(8 * root.d)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(1 * root.d)
                            IrisText {
                                text: Translation.tr(root.targetOf(root.target).label)
                                font.family: IrisStyle.fontTitle
                                font.pixelSize: 17 * IrisStyle.typeScale
                                font.weight: Font.Bold
                            }
                            IrisText {
                                Layout.fillWidth: true
                                text: Translation.tr(root.descriptions[root.target] ?? "")
                                color: IrisStyle.muted
                                font.pixelSize: 11.5 * IrisStyle.typeScale
                                wrapMode: Text.WordWrap
                            }
                        }
                        IrisButton {
                            readonly property int changed: root.modifiedIn(root.target)
                            visible: root.target !== "themes" && changed > 0
                            quiet: true
                            buttonRadius: height / 2
                            text: Translation.tr("Reset %1").arg(changed)
                            Accessible.name: Translation.tr("Reset what changed here")
                            onClicked: root.resetTarget()
                        }
                        IrisButton {
                            visible: root.target === "themes"
                            quiet: true
                            buttonRadius: height / 2
                            text: Translation.tr("Paste a look")
                            onClicked: root.importLook()
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round((root.target === "island" || root.target === "dock" ? 150 : 206) * root.d)
                        active: root.showPreview && root.query.length === 0 && root.target !== "themes"
                        visible: active
                        sourceComponent: root.target === "island" || root.target === "dock" ? screenPreview : scenePreview
                    }
                    Component {
                        id: screenPreview
                        IrisScreenPreview {
                            id: screenMiniature
                            screen: root.screen
                            focusRect: root.target === "dock" ? screenMiniature.dockReach : screenMiniature.islandReach
                        }
                    }
                    Component {
                        id: scenePreview
                        IrisTargetPreview {
                            target: root.target
                            playing: GlobalStates.irisStudioOpen
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: root.query.length === 0 && root.target !== "themes"
                        spacing: Math.round(6 * root.d)
                        ActionChip {
                            glyph: root.showPreview ? "visibility" : "visibility_off"
                            label: root.showPreview ? Translation.tr("Preview") : Translation.tr("Preview hidden")
                            on: root.showPreview
                            onActivated: Config.setNestedValue("iris.appearance.studioPreview", !root.showPreview)
                        }
                        ActionChip {
                            glyph: "desktop_windows"
                            label: Translation.tr("Live on screen")
                            on: root.desktopPreview
                            onActivated: root.desktopPreview = !root.desktopPreview
                        }
                        ActionChip {
                            visible: root.target === "island"
                            glyph: "open_in_full"
                            label: Translation.tr("Open the Island")
                            onActivated: GlobalStates.irisIslandPageRequest = "desktop"
                        }
                        ActionChip {
                            visible: root.target === "island"
                            glyph: "dashboard_customize"
                            label: GlobalStates.irisArrange ? Translation.tr("Arranging") : Translation.tr("Arrange blocks")
                            on: GlobalStates.irisArrange
                            onActivated: {
                                if (!GlobalStates.irisArrange) GlobalStates.irisIslandPageRequest = "desktop"
                                GlobalStates.irisArrange = !GlobalStates.irisArrange
                            }
                        }
                        ActionChip {
                            visible: root.target === "bodies"
                            glyph: "partly_cloudy_day"
                            label: Translation.tr("Show a card")
                            onActivated: { GlobalStates.controlPanelOpen = false; GlobalStates.irisBubbleCardRequest = "weather" }
                        }
                        ActionChip {
                            visible: root.target === "bodies"
                            glyph: "toggle_on"
                            label: Translation.tr("Control Center")
                            on: GlobalStates.controlPanelOpen
                            onActivated: GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen
                        }
                        ActionChip {
                            visible: root.target === "transients"
                            glyph: "volume_up"
                            label: Translation.tr("Show a level")
                            onActivated: GlobalStates.osdVolumeOpen = true
                        }
                        ActionChip {
                            visible: root.target === "dock"
                            glyph: "dock_to_bottom"
                            label: Translation.tr("Reveal the Dock")
                            on: GlobalStates.irisDockShown
                            onActivated: GlobalStates.irisDockShown = !GlobalStates.irisDockShown
                        }
                        ActionChip {
                            visible: root.target === "places"
                            glyph: "view_sidebar"
                            label: Translation.tr("Open Today")
                            onActivated: GlobalStates.openSidebarRight("")
                        }
                        ActionChip {
                            visible: root.target === "pieces" || root.target === "desktop" || root.target === "dock"
                            glyph: "edit"
                            label: Translation.tr("Edit in place")
                            onActivated: { GlobalStates.irisEdit = true; GlobalStates.irisStudioOpen = false }
                        }
                    }

                    Flickable {
                        id: flick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: rows.implicitHeight + Math.round(8 * root.d)
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: rows
                            width: flick.width
                            spacing: Math.round(14 * root.d)

                            IrisText {
                                visible: root.query.length > 0 && root.matches.length === 0
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: Math.round(24 * root.d)
                                text: Translation.tr("Nothing matches “%1”").arg(root.query)
                                color: IrisStyle.muted
                            }

                            GroupCard {
                                Layout.fillWidth: true
                                visible: root.query.length === 0 && root.target === "material"
                                title: Translation.tr("Character")
                                plain: true
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.d)
                                    Repeater {
                                        model: root.presetOrder
                                        PresetTile {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            name: modelData
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.query.length > 0 ? root.matches : root.target === "themes" ? [] : root.groups
                                GroupCard {
                                    id: groupCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: groupCard.modelData.title
                                    Repeater {
                                        model: groupCard.modelData.rows
                                        IrisSetting {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            spec: modelData
                                            last: index === groupCard.modelData.rows.length - 1
                                        }
                                    }
                                }
                            }

                            GroupCard {
                                Layout.fillWidth: true
                                visible: root.query.length === 0 && root.target === "themes"
                                title: Translation.tr("Looks")
                                plain: true
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: Math.round(8 * root.d)
                                    columnSpacing: Math.round(8 * root.d)
                                    Repeater {
                                        model: root.target === "themes" ? root.looks : []
                                        LookTile {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            look: modelData
                                        }
                                    }
                                }
                            }
                            GroupCard {
                                Layout.fillWidth: true
                                visible: root.query.length === 0 && root.target === "themes"
                                title: Translation.tr("Yours")
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.margins: Math.round(12 * root.d)
                                    spacing: Math.round(8 * root.d)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: Math.round(32 * root.d)
                                        radius: height / 2
                                        color: nameField.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                                        TextInput {
                                            id: nameField
                                            anchors.fill: parent
                                            anchors.leftMargin: Math.round(14 * root.d)
                                            anchors.rightMargin: Math.round(14 * root.d)
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: IrisStyle.text
                                            selectionColor: IrisStyle.accentContainer
                                            font.family: IrisStyle.fontMain
                                            font.pixelSize: 13 * IrisStyle.typeScale
                                            clip: true
                                            onAccepted: { root.saveCurrent(text); text = "" }
                                            IrisText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: nameField.text.length === 0
                                                text: Translation.tr("Name this look")
                                                color: IrisStyle.muted
                                                font.pixelSize: nameField.font.pixelSize
                                            }
                                        }
                                    }
                                    IrisButton {
                                        emphasized: true
                                        text: Translation.tr("Save")
                                        buttonRadius: height / 2
                                        onClicked: { root.saveCurrent(nameField.text); nameField.text = "" }
                                    }
                                }
                                Repeater {
                                    model: root.target === "themes" ? root.saved : []
                                    SavedRow {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        entry: modelData
                                    }
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Math.round(14 * root.d)
                                    Layout.rightMargin: Math.round(14 * root.d)
                                    Layout.bottomMargin: Math.round(12 * root.d)
                                    visible: root.saved.length === 0
                                    text: Translation.tr("Saved looks keep every value you set here, and can be shared as text.")
                                    color: IrisStyle.muted
                                    font.pixelSize: 11.5 * IrisStyle.typeScale
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component RailButton: MouseArea {
        id: railButton
        required property var entry
        readonly property bool selected: root.target === railButton.entry.id && root.query.length === 0
        readonly property int changed: root.modifiedIn(railButton.entry.id)
        implicitHeight: Math.round(50 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.PageTab
        Accessible.name: Translation.tr(railButton.entry.label)
        Accessible.checked: railButton.selected
        onClicked: {
            if (root.query.length > 0) searchField.text = ""
            root.select(railButton.entry.id)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(2 * root.d)
            width: Math.round(40 * root.d)
            height: Math.round(28 * root.d)
            radius: height / 2
            color: railButton.selected ? IrisStyle.tintFill(IrisStyle.accent)
                : railButton.containsMouse ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: railButton.entry.glyph
                iconSize: Math.round(19 * root.d)
                fill: railButton.selected ? 1 : 0
                animateFill: true
                color: railButton.selected ? IrisStyle.accent : IrisStyle.textSecondary
            }
            Rectangle {
                visible: railButton.changed > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: Math.round(4 * root.d)
                anchors.topMargin: Math.round(3 * root.d)
                width: Math.round(6 * root.d)
                height: width
                radius: width / 2
                color: IrisStyle.accent
            }
        }
        IrisText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(3 * root.d)
            text: Translation.tr(railButton.entry.label)
            color: railButton.selected ? IrisStyle.text : IrisStyle.muted
            font.pixelSize: 10 * IrisStyle.typeScale
            font.weight: railButton.selected ? Font.DemiBold : Font.Normal
        }
    }

    component ActionChip: MouseArea {
        id: chip
        property string glyph: ""
        property string label: ""
        property bool on: false
        signal activated
        implicitWidth: chipRow.implicitWidth + Math.round(20 * root.d)
        implicitHeight: Math.round(28 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: chip.label
        onClicked: chip.activated()
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.on ? IrisStyle.tintFill(IrisStyle.accent) : chip.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Math.round(6 * root.d)
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.glyph
                iconSize: Math.round(15 * root.d)
                fill: chip.on ? 1 : 0
                color: chip.on ? IrisStyle.accent : IrisStyle.textSecondary
            }
            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: chip.on ? IrisStyle.text : IrisStyle.subtext
                font.pixelSize: 12 * IrisStyle.typeScale
            }
        }
    }

    component GroupCard: ColumnLayout {
        id: card
        property string title: ""
        property bool plain: false
        default property alias rows: body.data
        spacing: Math.round(6 * root.d)
        IrisText {
            Layout.leftMargin: Math.round(14 * root.d)
            text: Translation.tr(card.title)
            color: IrisStyle.muted
            font.pixelSize: 12 * IrisStyle.typeScale
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: body.implicitHeight
            radius: IrisStyle.radiusTile
            color: card.plain ? "transparent" : IrisStyle.surfaceHigh
            ColumnLayout {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0
            }
        }
    }

    component PresetTile: MouseArea {
        id: tile
        required property string name
        readonly property var values: IrisStyle.presets[tile.name] ?? IrisStyle.presets.iris
        readonly property bool selected: IrisStyle.presetName === tile.name
        implicitHeight: Math.round(66 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.RadioButton
        Accessible.name: tile.name
        Accessible.checked: tile.selected
        onClicked: Config.setNestedValue("iris.appearance.preset", tile.name)
        Rectangle {
            id: miniature
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(44 * root.d)
            radius: Math.round(12 * tile.values.shape * root.d)
            color: IrisStyle.surfaceOpaque
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? IrisStyle.accent : (tile.containsMouse ? IrisStyle.borderStrong : IrisStyle.border)
            Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(110) } }
            Column {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.d)
                spacing: Math.round(4 * root.d)
                Rectangle {
                    width: parent.width
                    height: Math.round(16 * root.d)
                    radius: Math.round(7 * tile.values.shape * root.d)
                    color: Qt.alpha(IrisStyle.text, Math.min(0.5, 0.12 * tile.values.fill))
                }
                Row {
                    spacing: Math.round(4 * root.d)
                    Rectangle { width: Math.round(18 * root.d); height: Math.round(9 * root.d); radius: height / 2; color: IrisStyle.accent }
                    Rectangle { width: Math.round(26 * root.d); height: Math.round(9 * root.d); radius: height / 2; color: Qt.alpha(IrisStyle.text, tile.values.textTertiary) }
                }
            }
        }
        IrisText {
            anchors.top: miniature.bottom
            anchors.topMargin: Math.round(4 * root.d)
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr(tile.name.charAt(0).toUpperCase() + tile.name.slice(1))
            color: tile.selected ? IrisStyle.text : IrisStyle.subtext
            font.pixelSize: 11.5 * IrisStyle.typeScale
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
        }
    }

    component LookTile: MouseArea {
        id: lookTile
        required property var look
        implicitHeight: Math.round(92 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: lookTile.look.name
        onClicked: { root.applyValues(lookTile.look.values); root.say(Translation.tr("Applied %1").arg(lookTile.look.name)) }
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.radiusTile
            color: IrisStyle.materialSwatch(lookTile.look.material)
            border.width: 1
            border.color: lookTile.containsMouse ? IrisStyle.borderStrong : IrisStyle.border
            Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(110) } }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(10 * root.d)
                spacing: Math.round(3 * root.d)
                RowLayout {
                    spacing: Math.round(6 * root.d)
                    Rectangle { implicitWidth: Math.round(10 * root.d); implicitHeight: implicitWidth; radius: width / 2; color: lookTile.look.accent }
                    IrisText { text: lookTile.look.name; font.weight: Font.DemiBold; font.pixelSize: 13 * IrisStyle.typeScale }
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr(lookTile.look.description)
                    color: IrisStyle.textSecondary
                    font.pixelSize: 11 * IrisStyle.typeScale
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
    }

    component SavedRow: Item {
        id: savedRow
        required property var entry
        implicitHeight: Math.round(46 * root.d)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Math.round(16 * root.d)
            height: 1
            color: IrisStyle.hairline
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(16 * root.d)
            anchors.rightMargin: Math.round(8 * root.d)
            spacing: Math.round(4 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: String(savedRow.entry?.name ?? "")
                font.pixelSize: 13.5 * IrisStyle.typeScale
                elide: Text.ElideRight
            }
            IrisButton {
                text: Translation.tr("Apply")
                buttonRadius: height / 2
                onClicked: { root.applyValues(savedRow.entry.values); root.say(Translation.tr("Applied %1").arg(savedRow.entry.name)) }
            }
            IrisIconButton { materialIcon: "ios_share"; Accessible.name: Translation.tr("Copy to share"); onClicked: root.exportLook(savedRow.entry) }
            IrisIconButton { materialIcon: "delete"; Accessible.name: Translation.tr("Delete"); onClicked: root.removeSaved(savedRow.entry.name) }
        }
    }
}
