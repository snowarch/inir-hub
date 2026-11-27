pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.modules.shared.background.edit
import qs.modules.shared.background.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.components
import qs.modules.iris.widgets
import qs.modules.iris.prism.core

// Unified right-side desk editor panel combining rin-shell's clean side-panel geometry with every
// iNiR desktop customization tool: Widget Gallery (with fuzzy search, categories, cached previews,
// quick add/remove and clear-all), in-place Widget Inspector (IrisWidgetControls), Look / Island /
// Dock / Style live option pages (IrisSheetRows), and Presets.
Item {
    id: root

    property var screenData: null
    property real topReserve: 0

    readonly property real d: IrisStyle.density
    readonly property string outputName: root.screenData?.name ?? ""
    readonly property bool present: GlobalStates.widgetEditMode
    readonly property real presentation: presentSpring.value
    readonly property bool shown: root.presentation > 0.002
    readonly property bool holdsKeyboard: root.present && (GlobalStates.focusedScreen?.name ?? root.outputName) === root.outputName
        && !GlobalStates.searchOpen && !GlobalStates.settingsOverlayOpen && !GlobalStates.controlPanelOpen
    readonly property bool selecting: GlobalStates.selectedDesktopWidget.length > 0
    readonly property bool typing: root.present && (searchField.activeFocus || (inspectorLoader.item?.activeFocusItem ?? null) !== null)

    property string page: "widgets"
    property string category: ""
    property string searchQuery: ""
    property bool confirmingClear: false

    readonly property var pages: [
        { value: "widgets", label: Translation.tr("Widgets") },
        { value: "look", label: Translation.tr("Look"), section: "desktop", only: true,
            order: ["Design", "Accents", "Material", "Legibility", "Widgets"] },
        { value: "bar", label: Translation.tr("Island"), section: "bar", only: false, order: [] },
        { value: "dock", label: Translation.tr("Dock"), section: "dock", only: false, order: [] },
        { value: "appearance", label: Translation.tr("Style"), section: "appearance", only: false,
            order: ["Design", "Scheme", "Accent", "Faces", "Text", "Material", "Glass", "Shape", "Highlight", "Intensity", "Signal", "Look",
                "Presets", "Edges", "Light", "Icons", "Wallpaper tint", "Colour theme", "Day and night", "Dark look", "Ink look",
                "Light look", "Texture", "Frame", "Menus", "Badges", "Previews", "Customize", "Adaptive"] },
        { value: "presets", label: Translation.tr("Presets") }
    ]
    readonly property var currentPageDef: root.pages.find(entry => entry.value === root.page) ?? root.pages[0]
    readonly property bool onOptionsPage: ["look", "bar", "dock", "appearance"].includes(root.page)

    readonly property var inspectedWidget: {
        const ins = DesktopEditStage.inspected
        if (ins && ins.output === root.outputName && ins.widget) return ins.widget
        const ch = DesktopEditStage.chosen
        if (ch && ch.output === root.outputName && ch.widget) return ch.widget
        return null
    }
    readonly property bool inspecting: root.inspectedWidget !== null

    function takeAskedPage(): void {
        const asked = GlobalStates.desktopShelfPage
        if (asked.length === 0 || !root.pages.some(entry => entry.value === asked)) return
        root.page = asked
        GlobalStates.desktopShelfPage = ""
    }
    Connections {
        target: GlobalStates
        function onDesktopShelfPageChanged(): void { root.takeAskedPage() }
    }

    Component.onCompleted: {
        DesktopEditStage.setSheetHost(root.outputName, true)
        root.takeAskedPage()
        enterTimer.start()
        root.prepare()
    }
    Component.onDestruction: {
        DesktopEditStage.setSheetHost(root.outputName, false)
        DesktopEditStage.setAside(root.outputName, 0, 0)
        DesktopEditStage.setStage(root.outputName, 0, 0, 0)
        if (!root.present) DesktopEditStage.unpark()
    }

    Shortcut { sequence: "Ctrl+F"; enabled: root.holdsKeyboard; onActivated: { root.page = "widgets"; GlobalStates.clearDesktopWidgetSelection(); searchField.forceActiveFocus() } }
    Shortcut {
        sequence: "Escape"
        enabled: root.holdsKeyboard
        onActivated: {
            if (root.confirmingClear) { root.confirmingClear = false }
            else if (root.searchQuery.length > 0) { root.searchQuery = ""; searchField.focus = false }
            else if (root.inspecting || root.selecting) {
                if (DesktopEditStage.inspected?.widget) DesktopEditStage.inspected.widget.closeQuickControls()
                GlobalStates.clearDesktopWidgetSelection()
            } else {
                GlobalStates.setWidgetEditMode(false)
            }
        }
    }
    Shortcut { sequences: [StandardKey.Undo]; enabled: root.holdsKeyboard && !root.typing; onActivated: DesktopEditHistory.undo() }
    Shortcut { sequences: [StandardKey.Redo, "Ctrl+Y"]; enabled: root.holdsKeyboard && !root.typing; onActivated: DesktopEditHistory.redo() }
    readonly property bool nudging: root.holdsKeyboard && root.selecting && !root.typing
    Shortcut { sequence: "Left"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(-1, 0) }
    Shortcut { sequence: "Right"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(1, 0) }
    Shortcut { sequence: "Up"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(0, -1) }
    Shortcut { sequence: "Down"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(0, 1) }
    Shortcut { sequence: "Shift+Left"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(-10, 0) }
    Shortcut { sequence: "Shift+Right"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(10, 0) }
    Shortcut { sequence: "Shift+Up"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(0, -10) }
    Shortcut { sequence: "Shift+Down"; enabled: root.nudging; onActivated: GlobalStates.desktopWidgetNudge(0, 10) }
    Shortcut {
        sequences: [StandardKey.Delete, "Backspace"]
        enabled: root.nudging
        onActivated: {
            const key = GlobalStates.selectedDesktopWidget
            if (key.length > 0) {
                const pureKey = key.includes("::") ? key.split("::")[1] : key
                root.removeWidget(pureKey, null)
            }
        }
    }

    // Right-side panel geometry matching rin-shell's desk editor (~388 px wide, 16 px margin).
    readonly property real edge: Math.round(16 * root.d)
    readonly property real panelWidth: Math.round(Math.min(410 * root.d, Math.max(348 * root.d, root.width * 0.22)))
    readonly property real panelReserve: root.panelWidth + root.edge * 2
    readonly property real grow: Math.max(0, Math.min(1, root.presentation))
    readonly property real bodyWidth: root.panelWidth
    readonly property real bodyHeight: Math.max(200, root.height - root.edge * 2)
    readonly property real bodyX: Math.round(root.width - root.edge - root.bodyWidth + (1 - root.grow) * (root.bodyWidth + root.edge + 20))
    readonly property real bodyY: root.edge
    readonly property real bodyRadius: Math.round(20 * root.d)

    readonly property var hitRect: root.shown
        ? Qt.rect(root.bodyX, root.bodyY, root.bodyWidth, root.bodyHeight)
        : Qt.rect(0, 0, 0, 0)
    readonly property var fieldShapes: root.shown ? [{
        x: root.bodyX, y: root.bodyY, width: root.bodyWidth, height: root.bodyHeight,
        radius: root.bodyRadius, fuse: 0, paints: true, id: "editpanel", joins: "",
        frost: Math.min(1, root.presentation * 1.4)
    }] : []

    readonly property var stageNow: [root.outputName, Math.max(0, Math.min(1.15, root.presentation)), root.topReserve, root.edge]
    onStageNowChanged: {
        DesktopEditStage.setAside(root.outputName, 0, root.grow > 0.001 ? root.panelReserve : 0)
        DesktopEditStage.setStage(root.stageNow[0], root.stageNow[1], root.stageNow[2], root.stageNow[3])
    }
    readonly property bool parks: root.present && (GlobalStates.focusedScreen?.name ?? root.outputName) === root.outputName
    onParksChanged: if (root.parks) DesktopEditStage.park(root.outputName)
    readonly property bool settledHome: !root.present && root.presentation < 0.04
    onSettledHomeChanged: if (root.settledHome) DesktopEditStage.unpark()

    IrisSpring {
        id: presentSpring
        surface: "panels"
        to: root.entered && root.present ? 1 : 0
        intent: "auto"
        minimum: 0
    }
    property bool entered: false
    Timer { id: enterTimer; interval: 0; onTriggered: root.entered = true }

    readonly property string look: (IrisStyle.light ? "light" : "dark") + "-" + IrisDesign.current
    onLookChanged: if (root.present) DesktopEditStage.look = root.look
    onPresentChanged: if (root.present) { root.confirmingClear = false; root.prepare() }
    function prepare(): void {
        DesktopEditStage.look = root.look
        Quickshell.execDetached(["mkdir", "-p", DesktopEditStage.pictureDir])
    }

    // Categories and fuzzy-searchable widget entries (built-in + Hub custom widgets).
    readonly property var categoryNames: ({
        today: Translation.tr("Today"),
        media: Translation.tr("Media"),
        system: Translation.tr("System"),
        notes: Translation.tr("Notes"),
        decor: Translation.tr("Decor")
    })
    readonly property var allEntries: {
        const list = IrisFaceData.galleryEntries.concat(IrisFaceData.otherEntries).map(entry => {
            const cat = DesktopWidgetRegistry.categoryOf(entry.key)
            return IrisSearch.prepare({
                key: entry.key,
                glyph: entry.glyph,
                name: entry.label,
                english: entry.english ?? entry.label,
                tint: entry.tint,
                category: cat,
                words: [entry.key, DesktopWidgetRegistry.keywordsOf(entry.key), root.categoryNames[cat] ?? cat].join(" ")
            })
        })
        for (const custom of (CustomWidgets.ready ? CustomWidgets.widgets : [])) {
            const cat = DesktopWidgetRegistry.customCategory(custom)
            list.push(IrisSearch.prepare({
                key: "custom." + custom.id,
                glyph: custom.icon || "widgets",
                name: custom.name,
                english: custom.name,
                tint: DesktopWidgetRegistry.customTint,
                category: cat,
                words: DesktopWidgetRegistry.customWords(custom)
            }))
        }
        return list
    }
    readonly property var categories: DesktopWidgetRegistry.categoryOrder
        .filter(id => root.allEntries.some(entry => entry.category === id))
    readonly property var filteredEntries: {
        const q = root.searchQuery.trim()
        const base = root.category.length > 0 && q.length === 0
            ? root.allEntries.filter(entry => entry.category === root.category)
            : root.allEntries
        if (q.length === 0) return base
        return base
            .map(entry => ({ entry: entry, score: IrisSearch.score(q, entry) }))
            .filter(item => item.score > 0)
            .sort((a, b) => b.score - a.score)
            .map(item => item.entry)
    }
    readonly property int enabledCount: {
        Config.revision
        let n = 0
        for (const entry of root.allEntries) if (root.widgetEnabled(entry.key)) n++
        return n
    }

    function widgetEnabled(key: string): bool {
        return DesktopWidgetLayout.enabled(root.outputName, key, Config.getNestedValue("background.widgets." + key + ".enable", false))
    }

    function toggleWidget(key: string, sourceItem: Item): void {
        const on = root.widgetEnabled(key)
        const at = sourceItem ? sourceItem.mapToItem(null, 0, 0) : Qt.point(root.bodyX, root.bodyY)
        const rect = Qt.rect(at.x, at.y, sourceItem?.width ?? 120, sourceItem?.height ?? 64)
        if (on) {
            GlobalStates.selectDesktopWidget(root.outputName + "::" + key)
            DesktopArrange.ping(root.outputName, root.outputName + "::" + key)
        } else {
            DesktopEditStage.arrive(root.outputName, key, null, rect)
        }
    }

    function removeWidget(key: string, sourceItem: Item): void {
        if (!root.widgetEnabled(key)) return
        if (GlobalStates.selectedDesktopWidget === root.outputName + "::" + key)
            GlobalStates.clearDesktopWidgetSelection()
        const at = sourceItem ? sourceItem.mapToItem(null, 0, 0) : Qt.point(root.bodyX, root.bodyY)
        const rect = Qt.rect(at.x, at.y, sourceItem?.width ?? 120, sourceItem?.height ?? 64)
        DesktopEditStage.depart(root.outputName, key, rect)
    }

    function clearAllWidgets(): void {
        root.confirmingClear = false
        GlobalStates.clearDesktopWidgetSelection()
        for (const entry of root.allEntries) {
            if (root.widgetEnabled(entry.key))
                DesktopEditStage.depart(root.outputName, entry.key, Qt.rect(root.bodyX, root.bodyY, 80, 40))
        }
    }

    Component {
        id: rowsComponent
        IrisSheetRows {}
    }

    Component {
        id: inspectorComponent
        IrisWidgetControls {
            widget: root.inspectedWidget
            plateRadius: Math.round(12 * root.d)
            optionRows: rowsComponent
        }
    }

    // Grouped vertical Prism options for Look / Island / Dock / Style inside the right panel.
    Component {
        id: optionsPageComponent
        Item {
            id: optRoot
            readonly property string section: String(root.currentPageDef.section ?? root.page)
            readonly property bool only: Boolean(root.currentPageDef.only)
            readonly property var order: root.currentPageDef.order ?? []
            readonly property var drawn: ["switch", "choice", "range", "text", "action"]
            readonly property var groups: {
                Config.revision
                const order = Array.from(optRoot.order ?? [])
                const rank = spec => { const at = order.indexOf(String(spec.group ?? "")); return at < 0 ? order.length : at }
                const specs = IrisOptions.settings
                    .filter(spec => spec.section === optRoot.section
                        && (!optRoot.only || order.includes(String(spec.group ?? "")))
                        && !spec.mirror && spec.shelf !== false
                        && optRoot.drawn.includes(spec.kind) && IrisOptions.shown(spec))
                    .map((spec, at) => ({ spec: spec, at: at }))
                    .sort((a, b) => rank(a.spec) - rank(b.spec) || a.at - b.at)
                    .map(item => item.spec)
                const out = []
                for (const spec of specs) {
                    const name = String(spec.group ?? "")
                    let grp = out.find(g => g.name === name)
                    if (!grp) { grp = { name: name, specs: [] }; out.push(grp) }
                    grp.specs.push(spec)
                }
                return out
            }
            property string activeGroup: ""
            readonly property var visibleGroups: optRoot.activeGroup.length > 0 && optRoot.groups.some(g => g.name === optRoot.activeGroup)
                ? optRoot.groups.filter(g => g.name === optRoot.activeGroup)
                : optRoot.groups

            onSectionChanged: { optRoot.activeGroup = ""; optFlick.contentY = 0 }

            ColumnLayout {
                anchors.fill: parent
                spacing: Math.round(8 * root.d)

                // Chapter filter strip when a section has multiple groups.
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(28 * root.d)
                    visible: optRoot.groups.length > 1
                    contentWidth: chapterRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: chapterRow
                        spacing: Math.round(4 * root.d)
                        IrisChip {
                            implicitHeight: Math.round(26 * root.d)
                            label: Translation.tr("All")
                            selected: optRoot.activeGroup.length === 0
                            quiet: !selected
                            onClicked: { optRoot.activeGroup = ""; optFlick.contentY = 0 }
                        }
                        Repeater {
                            model: optRoot.groups
                            delegate: IrisChip {
                                required property var modelData
                                implicitHeight: Math.round(26 * root.d)
                                label: Translation.tr(modelData.name)
                                selected: optRoot.activeGroup === modelData.name
                                quiet: !selected
                                onClicked: { optRoot.activeGroup = selected ? "" : modelData.name; optFlick.contentY = 0 }
                            }
                        }
                    }
                }

                Flickable {
                    id: optFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: optCol.implicitHeight + Math.round(12 * root.d)
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: optCol
                        width: optFlick.width
                        spacing: Math.round(14 * root.d)

                        Repeater {
                            model: optRoot.visibleGroups
                            delegate: ColumnLayout {
                                id: grpBox
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: Math.round(6 * root.d)

                                IrisText {
                                    visible: grpBox.modelData.name.length > 0
                                    text: Translation.tr(grpBox.modelData.name)
                                    color: IrisStyle.textSecondary
                                    font.pixelSize: IrisStyle.typeMeta
                                    font.weight: IrisStyle.weight(Font.DemiBold)
                                }
                                IrisSheetRows {
                                    specs: grpBox.modelData.specs
                                    firstNumber: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Right Panel Contents ──
    Item {
        id: panelBody
        x: root.bodyX
        y: root.bodyY
        width: root.bodyWidth
        height: root.bodyHeight
        clip: true
        visible: root.shown
        opacity: Math.min(1, root.presentation * 1.4)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(16 * root.d)
            spacing: Math.round(10 * root.d)

            // Header row: title/back + Undo/Redo + Done
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)

                IrisIconButton {
                    visible: root.inspecting
                    implicitWidth: Math.round(32 * root.d)
                    implicitHeight: Math.round(32 * root.d)
                    materialIcon: "arrow_back"
                    iconSize: Math.round(18 * root.d)
                    Accessible.name: Translation.tr("Back to widgets")
                    onClicked: {
                        if (DesktopEditStage.inspected?.widget) DesktopEditStage.inspected.widget.closeQuickControls()
                        GlobalStates.clearDesktopWidgetSelection()
                    }
                }

                IrisText {
                    Layout.fillWidth: true
                    text: root.inspecting
                        ? Translation.tr("Widget")
                        : Translation.tr("Customize Desktop")
                    font.pixelSize: IrisStyle.typeTitle
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }

                IrisIconButton {
                    implicitWidth: Math.round(32 * root.d)
                    implicitHeight: Math.round(32 * root.d)
                    materialIcon: "undo"
                    iconSize: Math.round(17 * root.d)
                    enabled: DesktopEditHistory.undoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Undo")
                    onClicked: DesktopEditHistory.undo()
                }
                IrisIconButton {
                    implicitWidth: Math.round(32 * root.d)
                    implicitHeight: Math.round(32 * root.d)
                    materialIcon: "redo"
                    iconSize: Math.round(17 * root.d)
                    enabled: DesktopEditHistory.redoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Redo")
                    onClicked: DesktopEditHistory.redo()
                }

                Rectangle {
                    implicitWidth: doneLabel.implicitWidth + Math.round(22 * root.d)
                    implicitHeight: Math.round(32 * root.d)
                    radius: Math.round(10 * root.d)
                    color: doneMouse.containsMouse ? ColorUtils.mix(IrisStyle.accent, "#ffffff", 0.14) : IrisStyle.accent
                    IrisText {
                        id: doneLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Done")
                        color: IrisStyle.inkOnAccent
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    MouseArea {
                        id: doneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalStates.setWidgetEditMode(false)
                    }
                }
            }

            // Scrollable navigation tabs (all 6 iNiR pages: Widgets, Look, Island, Dock, Style, Presets).
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(32 * root.d)
                visible: !root.inspecting
                contentWidth: navRow.implicitWidth
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: navRow
                    spacing: Math.round(4 * root.d)
                    Repeater {
                        model: root.pages
                        delegate: IrisChip {
                            required property var modelData
                            implicitHeight: Math.round(30 * root.d)
                            label: modelData.label
                            selected: root.page === modelData.value
                            quiet: !selected
                            onClicked: root.page = modelData.value
                        }
                    }
                }
            }

            // Search box on Widgets gallery.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(36 * root.d)
                visible: !root.inspecting && root.page === "widgets"
                radius: Math.round(11 * root.d)
                color: IrisStyle.fillQuiet
                border.width: searchField.activeFocus ? 1.5 : 1
                border.color: searchField.activeFocus ? IrisStyle.accent : IrisStyle.hairline

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(10 * root.d)
                    anchors.rightMargin: Math.round(8 * root.d)
                    spacing: Math.round(8 * root.d)

                    MaterialSymbol {
                        text: "search"
                        iconSize: Math.round(17 * root.d)
                        color: IrisStyle.textSecondary
                    }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: IrisStyle.text
                        selectionColor: IrisStyle.accent
                        selectedTextColor: IrisStyle.inkOnAccent
                        font.family: IrisStyle.fontMain
                        font.pixelSize: IrisStyle.typeBody
                        clip: true
                        text: root.searchQuery
                        onTextChanged: root.searchQuery = text

                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Search widgets...")
                            color: IrisStyle.textTertiary
                            font.pixelSize: IrisStyle.typeBody
                            visible: searchField.text.length === 0
                        }
                    }
                    IrisIconButton {
                        visible: root.searchQuery.length > 0
                        implicitWidth: Math.round(24 * root.d)
                        implicitHeight: Math.round(24 * root.d)
                        materialIcon: "close"
                        iconSize: Math.round(15 * root.d)
                        onClicked: { root.searchQuery = ""; searchField.text = "" }
                    }
                }
            }

            // Category filter pills on Widgets gallery.
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(26 * root.d)
                visible: !root.inspecting && root.page === "widgets" && root.searchQuery.trim().length === 0 && root.categories.length > 1
                contentWidth: catRow.implicitWidth
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: catRow
                    spacing: Math.round(4 * root.d)
                    IrisChip {
                        implicitHeight: Math.round(24 * root.d)
                        label: Translation.tr("All")
                        selected: root.category.length === 0
                        quiet: !selected
                        onClicked: root.category = ""
                    }
                    Repeater {
                        model: root.categories
                        delegate: IrisChip {
                            required property string modelData
                            implicitHeight: Math.round(24 * root.d)
                            label: root.categoryNames[modelData] ?? modelData
                            selected: root.category === modelData
                            quiet: !selected
                            onClicked: root.category = selected ? "" : modelData
                        }
                    }
                }
            }

            // ── Inspector View (when a widget is selected on the card) ──
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.inspecting
                clip: true
                contentWidth: width
                contentHeight: inspectorWrap.implicitHeight + Math.round(12 * root.d)
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: inspectorWrap
                    width: parent.width
                    spacing: Math.round(10 * root.d)

                    Loader {
                        id: inspectorLoader
                        Layout.fillWidth: true
                        active: root.inspecting && root.shown && root.inspectedWidget !== null
                        sourceComponent: active ? inspectorComponent : null
                    }
                }
            }

            // ── Widget Gallery Grid (2 columns, cached snapshot thumbnails, zero live clones) ──
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.inspecting && root.page === "widgets"
                clip: true
                contentWidth: width
                contentHeight: galleryGrid.implicitHeight + Math.round(12 * root.d)
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: galleryGrid
                    width: parent.width
                    columns: 2
                    columnSpacing: Math.round(10 * root.d)
                    rowSpacing: Math.round(10 * root.d)
                    readonly property real cellW: Math.floor((width - columnSpacing) / 2)

                    Repeater {
                        model: root.filteredEntries
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property bool active: root.widgetEnabled(card.modelData.key)
                            readonly property bool hovered: cardMouse.containsMouse
                            readonly property var shot: DesktopEditStage.pictures[card.modelData.key] ?? null
                            readonly property string shotUrl: card.shot?.url ?? ""

                            width: galleryGrid.cellW
                            height: Math.round(88 * root.d)
                            radius: Math.round(14 * root.d)
                            color: card.active
                                ? IrisStyle.tintFill(IrisStyle.accent)
                                : card.hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                            border.width: card.active ? 1.5 : 1
                            border.color: card.active ? IrisStyle.accent
                                : card.hovered ? IrisStyle.hairlineStrong : IrisStyle.hairline

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleWidget(card.modelData.key, card)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.round(10 * root.d)
                                spacing: Math.round(6 * root.d)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(8 * root.d)

                                    Item {
                                        implicitWidth: Math.round(34 * root.d)
                                        implicitHeight: Math.round(34 * root.d)

                                        ClippingRectangle {
                                            anchors.fill: parent
                                            visible: shotImg.status === Image.Ready
                                            radius: Math.round(9 * root.d)
                                            color: IrisStyle.fillQuiet
                                            Image {
                                                id: shotImg
                                                anchors.fill: parent
                                                source: card.shotUrl
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: true
                                                sourceSize: Qt.size(68, 68)
                                            }
                                        }
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: shotImg.status !== Image.Ready
                                            radius: Math.round(10 * root.d)
                                            color: card.active
                                                ? ColorUtils.applyAlpha(IrisStyle.accent, 0.22)
                                                : IrisStyle.fillActive
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: card.modelData.glyph || "widgets"
                                                iconSize: Math.round(18 * root.d)
                                                color: card.active ? IrisStyle.accent : IrisStyle.text
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    MaterialSymbol {
                                        visible: card.active && !card.hovered
                                        text: "check_circle"
                                        iconSize: Math.round(16 * root.d)
                                        color: IrisStyle.accent
                                    }
                                }

                                IrisText {
                                    Layout.fillWidth: true
                                    text: Translation.tr(card.modelData.name)
                                    font.pixelSize: IrisStyle.typeMeta
                                    font.weight: IrisStyle.weight(card.active ? Font.DemiBold : Font.Medium)
                                    color: card.active ? IrisStyle.text : IrisStyle.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                visible: card.active && card.hovered
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Math.round(6 * root.d)
                                width: Math.round(22 * root.d)
                                height: Math.round(22 * root.d)
                                radius: width / 2
                                color: removeMouse.containsMouse ? IrisStyle.danger : IrisStyle.fillActive
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Math.round(13 * root.d)
                                    color: removeMouse.containsMouse ? "#ffffff" : IrisStyle.text
                                }
                                MouseArea {
                                    id: removeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeWidget(card.modelData.key, card)
                                }
                            }
                        }
                    }
                }
            }

            // ── Look / Island / Dock / Style Live Options Page ──
            Loader {
                id: optionsLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !root.inspecting && root.onOptionsPage && root.shown
                visible: active
                sourceComponent: active ? optionsPageComponent : null
            }

            // ── Presets Page ──
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.inspecting && root.page === "presets"
                clip: true
                contentWidth: width
                contentHeight: presetsCol.implicitHeight + Math.round(12 * root.d)
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: presetsCol
                    width: parent.width
                    spacing: Math.round(8 * root.d)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(40 * root.d)
                        radius: Math.round(12 * root.d)
                        color: savePresetMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                        border.width: 1
                        border.color: IrisStyle.hairline
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Math.round(8 * root.d)
                            MaterialSymbol { text: "add"; iconSize: Math.round(18 * root.d); color: IrisStyle.accent }
                            IrisText { text: Translation.tr("Save current layout"); font.pixelSize: IrisStyle.typeMeta; font.weight: IrisStyle.weight(Font.Medium) }
                        }
                        MouseArea {
                            id: savePresetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DesktopPresets.save("")
                        }
                    }

                    Repeater {
                        model: DesktopPresets.factory.concat(DesktopPresets.presets)
                        delegate: Rectangle {
                            id: presetCard
                            required property var modelData
                            readonly property bool worn: DesktopPresets.wornId() === presetCard.modelData.id
                            readonly property bool userOwned: DesktopPresets.presets.some(p => p.id === presetCard.modelData.id)
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(52 * root.d)
                            radius: Math.round(12 * root.d)
                            color: presetCard.worn ? IrisStyle.tintFill(IrisStyle.accent)
                                : presetMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                            border.width: presetCard.worn ? 1.5 : 1
                            border.color: presetCard.worn ? IrisStyle.accent : IrisStyle.hairline

                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DesktopPresets.wear(presetCard.modelData.id)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Math.round(12 * root.d)
                                spacing: Math.round(10 * root.d)
                                MaterialSymbol {
                                    text: presetCard.worn ? "check_circle" : "dashboard"
                                    iconSize: Math.round(19 * root.d)
                                    color: presetCard.worn ? IrisStyle.accent : IrisStyle.textSecondary
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    text: presetCard.modelData.name
                                    font.pixelSize: IrisStyle.typeBody
                                    font.weight: IrisStyle.weight(presetCard.worn ? Font.DemiBold : Font.Medium)
                                    elide: Text.ElideRight
                                }
                                IrisIconButton {
                                    visible: presetCard.userOwned
                                    implicitWidth: Math.round(28 * root.d)
                                    implicitHeight: Math.round(28 * root.d)
                                    materialIcon: "delete"
                                    iconSize: Math.round(16 * root.d)
                                    Accessible.name: Translation.tr("Delete")
                                    onClicked: DesktopPresets.remove(presetCard.modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer: Clear desktop (with confirmation) + Settings shortcut ──
            RowLayout {
                Layout.fillWidth: true
                visible: !root.inspecting
                spacing: Math.round(8 * root.d)

                IrisText {
                    visible: DesktopEditHistory.notice.length > 0 && !root.confirmingClear
                    Layout.fillWidth: true
                    text: DesktopEditHistory.notice
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeMeta
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: !root.confirmingClear && root.page === "widgets" && DesktopEditHistory.notice.length === 0
                    implicitWidth: clearRow.implicitWidth + Math.round(16 * root.d)
                    implicitHeight: Math.round(30 * root.d)
                    radius: Math.round(9 * root.d)
                    opacity: root.enabledCount > 0 ? 1 : 0.35
                    color: clearMouse.containsMouse && root.enabledCount > 0 ? IrisStyle.fillHover : "transparent"
                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol { text: "delete_sweep"; iconSize: Math.round(16 * root.d); color: IrisStyle.textSecondary }
                        IrisText { text: Translation.tr("Clear"); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeMeta }
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        enabled: root.enabledCount > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmingClear = true
                    }
                }

                RowLayout {
                    visible: root.confirmingClear
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.d)
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: cancelLbl.implicitWidth + Math.round(16 * root.d)
                        implicitHeight: Math.round(28 * root.d)
                        radius: Math.round(9 * root.d)
                        color: cancelMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                        IrisText { id: cancelLbl; anchors.centerIn: parent; text: Translation.tr("Cancel"); font.pixelSize: IrisStyle.typeMeta }
                        MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmingClear = false }
                    }
                    Rectangle {
                        implicitWidth: confirmLbl.implicitWidth + Math.round(16 * root.d)
                        implicitHeight: Math.round(28 * root.d)
                        radius: Math.round(9 * root.d)
                        color: IrisStyle.danger
                        IrisText { id: confirmLbl; anchors.centerIn: parent; text: Translation.tr("Clear"); color: "#ffffff"; font.pixelSize: IrisStyle.typeMeta; font.weight: IrisStyle.weight(Font.DemiBold) }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clearAllWidgets() }
                    }
                }

                Item { Layout.fillWidth: true; visible: !root.confirmingClear && DesktopEditHistory.notice.length === 0 }

                IrisIconButton {
                    visible: !root.confirmingClear
                    implicitWidth: Math.round(30 * root.d)
                    implicitHeight: Math.round(30 * root.d)
                    materialIcon: "settings"
                    iconSize: Math.round(17 * root.d)
                    Accessible.name: Translation.tr("Settings")
                    onClicked: {
                        GlobalStates.setWidgetEditMode(false)
                        GlobalStates.settingsOverlayRequestedKey = "desktop"
                        GlobalStates.settingsOverlayOpen = true
                    }
                }
            }
        }
    }
}
