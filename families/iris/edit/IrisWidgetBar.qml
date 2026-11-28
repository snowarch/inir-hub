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
    // Typing in a field (a search, a name, a widget's text row): the arrows, Delete and Undo are the field's.
    readonly property Item focusItem: root.Window.activeFocusItem
    readonly property bool typing: root.present && root.focusItem !== null && root.focusItem.cursorPosition !== undefined

    property string page: "widgets"
    property string category: ""
    readonly property string searchQuery: searchBox.text
    property bool confirmingClear: false

    readonly property var pages: [
        { value: "widgets", label: Translation.tr("Widgets"), glyph: "widgets" },
        { value: "look", label: Translation.tr("Look"), glyph: "wallpaper", section: "desktop", only: true,
            order: ["Design", "Accents", "Material", "Legibility", "Widgets"] },
        { value: "bar", label: Translation.tr("Island"), glyph: "toolbar", section: "bar", only: false, order: [] },
        { value: "dock", label: Translation.tr("Dock"), glyph: "dock_to_bottom", section: "dock", only: false, order: [] },
        { value: "appearance", label: Translation.tr("Style"), glyph: "palette", section: "appearance", only: false,
            order: ["Design", "Scheme", "Accent", "Faces", "Text", "Material", "Glass", "Shape", "Highlight", "Intensity", "Signal", "Look",
                "Presets", "Edges", "Light", "Icons", "Wallpaper tint", "Colour theme", "Day and night", "Dark look", "Ink look",
                "Light look", "Texture", "Frame", "Menus", "Badges", "Previews", "Customize", "Adaptive"] },
        { value: "presets", label: Translation.tr("Presets"), glyph: "dashboard_customize" }
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
        DesktopEditStage.tiles = ({})
        if (!root.present) DesktopEditStage.unpark()
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.holdsKeyboard
        onActivated: {
            GlobalStates.clearDesktopWidgetSelection()
            if (root.onOptionsPage && optionsLoader.item) optionsLoader.item.focusSearch()
            else { root.page = "widgets"; searchBox.focusInput() }
        }
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.holdsKeyboard
        onActivated: {
            if (root.confirmingClear) { root.confirmingClear = false }
            else if (root.searchQuery.length > 0) searchBox.clear()
            else if (root.onOptionsPage && optionsLoader.item?.clearSearch()) {}
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
    readonly property real bodyRadius: IrisStyle.radiusSheet

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
    onPresentChanged: {
        if (root.present) { root.confirmingClear = false; root.prepare() }
        tilesLater.restart()
    }
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

    // Where each widget's card sits on screen, for one taken off the desktop (a right click on it) to shrink into. A card
    // scrolled out of view lands on the gallery's nearest edge; one not listed (a search, another page) on the panel's top.
    function publishTiles(): void {
        if (!root.present) {
            DesktopEditStage.tiles = ({})
            return
        }
        const cardH = Math.round(116 * root.d)
        const listed = galleryView.visible && galleryView.height > 0
        const view = galleryView.mapToItem(null, 0, 0)
        const cards = {}
        for (let i = 0; listed && i < galleryCards.count; i++) {
            const card = galleryCards.itemAt(i)
            if (card) cards[card.modelData.key] = card
        }
        const out = {}
        for (const entry of root.allEntries) {
            const card = cards[entry.key]
            if (card) {
                const at = card.mapToItem(null, 0, 0)
                const y = Math.max(view.y, Math.min(view.y + galleryView.height - card.height, at.y))
                out[entry.key] = Qt.rect(at.x, y, card.width, card.height)
            } else {
                out[entry.key] = Qt.rect(root.bodyX + root.bodyWidth / 4, root.bodyY + cardH / 2, root.bodyWidth / 2, cardH)
            }
        }
        DesktopEditStage.tiles = out
    }
    Timer { id: tilesLater; interval: 120; onTriggered: root.publishTiles() }
    onShownChanged: tilesLater.restart()
    onPageChanged: tilesLater.restart()
    onFilteredEntriesChanged: tilesLater.restart()
    onBodyXChanged: tilesLater.restart()

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
            plateRadius: IrisStyle.radiusTile
            optionRows: rowsComponent
        }
    }

    // Every card's picture: the widget's own while it is out, its last look on disk, or one made once off screen.
    WidgetPortraits {
        id: portraits
        keys: root.allEntries.map(entry => entry.key)
        outputName: root.outputName
        screenWidth: root.width
        screenHeight: root.height
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
                    tooltip: Translation.tr("Back to widgets")
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
                    tooltip: Translation.tr("Undo")
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
                    tooltip: Translation.tr("Redo")
                    onClicked: DesktopEditHistory.redo()
                }
            }

            // The six pages as one segmented control, each its glyph over its name: found by shape before it is read.
            IrisSegmented {
                Layout.fillWidth: true
                visible: !root.inspecting
                pictured: true
                options: root.pages
                current: root.page
                accessibleName: Translation.tr("Customize Desktop")
                onPicked: value => root.page = value
            }

            IrisEditSearch {
                id: searchBox
                Layout.fillWidth: true
                visible: !root.inspecting && root.page === "widgets"
                placeholder: Translation.tr("Search widgets...")
            }

            // Category filters on the Widgets gallery: none lit shows every widget, a tap on the lit one shows all again.
            // They wrap, so every category shows whole without sliding sideways.
            Flow {
                Layout.fillWidth: true
                visible: !root.inspecting && root.page === "widgets" && root.searchQuery.trim().length === 0 && root.categories.length > 1
                spacing: Math.round(4 * root.d)
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
                id: galleryView
                onContentYChanged: tilesLater.restart()
                onHeightChanged: tilesLater.restart()
                onVisibleChanged: tilesLater.restart()
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
                        id: galleryCards
                        model: root.filteredEntries
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property bool active: root.widgetEnabled(card.modelData.key)
                            readonly property bool hovered: cardMouse.containsMouse
                            readonly property string shotUrl: portraits.url(card.modelData.key)

                            width: galleryGrid.cellW
                            height: Math.round(116 * root.d)
                            radius: IrisStyle.radiusTile
                            color: card.hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
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

                            // A window onto the widget: its own picture from the stage when it is on the desktop, else its glyph
                            // large on a quiet well. Every card has the same shape, so the grid reads as one set.
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.round(6 * root.d)
                                spacing: Math.round(6 * root.d)

                                ClippingRectangle {
                                    id: well
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Math.max(2, IrisStyle.radiusTile - Math.round(6 * root.d))
                                    color: card.active ? IrisStyle.tintFill(IrisStyle.accent) : IrisStyle.fillQuiet

                                    // Its picture stays on screen when a newer one is taken (each entry retakes them): the latch
                                    // keeps it through the reload, where a fade gated on status === Ready blinked every card.
                                    IrisImage {
                                        id: shotImg
                                        anchors.fill: parent
                                        anchors.margins: Math.round(4 * root.d)
                                        source: card.shotUrl
                                        fillMode: Image.PreserveAspectFit
                                        mipmap: false
                                        opacity: shotImg.painted ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                                    }
                                    // No picture yet (never seen in this look): its glyph stands in.
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        visible: card.shotUrl.length === 0 || shotImg.status === Image.Error
                                        text: card.modelData.glyph || "widgets"
                                        iconSize: Math.round(26 * root.d)
                                        color: card.active ? IrisStyle.accent : IrisStyle.textSecondary
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Math.round(4 * root.d)
                                    Layout.rightMargin: Math.round(2 * root.d)
                                    spacing: Math.round(6 * root.d)
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: Translation.tr(card.modelData.name)
                                        font.pixelSize: IrisStyle.typeMeta
                                        font.weight: IrisStyle.weight(card.active ? Font.DemiBold : Font.Medium)
                                        color: card.active ? IrisStyle.text : IrisStyle.textSecondary
                                        elide: Text.ElideRight
                                    }
                                    MaterialSymbol {
                                        visible: card.active
                                        text: "check_circle"
                                        fill: 1
                                        iconSize: Math.round(16 * root.d)
                                        color: IrisStyle.accent
                                    }
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
                                    color: removeMouse.containsMouse ? IrisStyle.inkOnDanger : IrisStyle.text
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

            // ── Look / Island / Dock / Style: Settings' rows, by section ──
            Loader {
                id: optionsLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !root.inspecting && root.onOptionsPage && root.shown
                visible: active
                sourceComponent: IrisEditOptions {
                    page: root.currentPageDef
                }
            }

            // ── Presets: saved desktops, each a picture of what it brings back ──
            Loader {
                id: presetsLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !root.inspecting && root.page === "presets" && root.shown
                visible: active
                sourceComponent: IrisEditPresets {
                    outputName: root.outputName
                    screenWidth: root.width
                    screenHeight: root.height
                    pictureOf: key => portraits.url(key)
                }
            }

            // What the panel just did (saved, worn, undone), above the actions.
            IrisText {
                Layout.fillWidth: true
                visible: DesktopEditHistory.notice.length > 0 && !root.inspecting
                text: DesktopEditHistory.notice
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeMeta
                elide: Text.ElideRight
            }

            // ── Foot: the desktop-wide switches, then the way out ──
            RowLayout {
                id: foot
                Layout.fillWidth: true
                visible: !root.inspecting
                spacing: Math.round(4 * root.d)
                readonly property real key: Math.round(32 * root.d)
                // Every widget's background or outline away or back in one tap (each widget's own rows say the same):
                // lit while any widget still shows it.
                readonly property string plates: DesktopWidgetOptions.everyState("showBackground")
                readonly property string outlines: DesktopWidgetOptions.everyState("showBorder")
                readonly property bool gridOn: Config.options?.background?.widgets?.editGrid?.snap ?? true

                IrisIconButton {
                    visible: !root.confirmingClear && foot.plates !== ""
                    implicitWidth: foot.key
                    implicitHeight: foot.key
                    materialIcon: foot.plates !== "false" ? "layers" : "layers_clear"
                    iconSize: Math.round(17 * root.d)
                    selected: foot.plates !== "false"
                    Accessible.name: Translation.tr("Background")
                    tooltip: Translation.tr("Background")
                    tooltipPosition: "top"
                    Accessible.checkable: true
                    Accessible.checked: selected
                    onClicked: DesktopWidgetOptions.setEvery("showBackground", !selected)
                }
                IrisIconButton {
                    visible: !root.confirmingClear && foot.outlines !== ""
                    implicitWidth: foot.key
                    implicitHeight: foot.key
                    materialIcon: "border_style"
                    iconSize: Math.round(17 * root.d)
                    selected: foot.outlines !== "false"
                    Accessible.name: Translation.tr("Outline")
                    tooltip: Translation.tr("Outline")
                    tooltipPosition: "top"
                    Accessible.checkable: true
                    Accessible.checked: selected
                    onClicked: DesktopWidgetOptions.setEvery("showBorder", !selected)
                }
                IrisIconButton {
                    visible: !root.confirmingClear
                    implicitWidth: foot.key
                    implicitHeight: foot.key
                    materialIcon: "grid_4x4"
                    iconSize: Math.round(17 * root.d)
                    selected: foot.gridOn
                    Accessible.name: Translation.tr("Snap to grid")
                    tooltip: Translation.tr("Snap to grid")
                    tooltipPosition: "top"
                    Accessible.checkable: true
                    Accessible.checked: selected
                    onClicked: Config.setNestedValue("background.widgets.editGrid.snap", !foot.gridOn)
                }
                IrisIconButton {
                    visible: !root.confirmingClear && root.page === "widgets"
                    implicitWidth: foot.key
                    implicitHeight: foot.key
                    materialIcon: "delete_sweep"
                    iconSize: Math.round(17 * root.d)
                    enabled: root.enabledCount > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Clear")
                    tooltip: Translation.tr("Clear")
                    tooltipPosition: "top"
                    onClicked: root.confirmingClear = true
                }
                IrisIconButton {
                    visible: !root.confirmingClear
                    implicitWidth: foot.key
                    implicitHeight: foot.key
                    materialIcon: "settings"
                    iconSize: Math.round(17 * root.d)
                    Accessible.name: Translation.tr("Settings")
                    tooltip: Translation.tr("Settings")
                    tooltipPosition: "top"
                    onClicked: {
                        DesktopEditHistory.finish()
                        GlobalStates.settingsOverlayRequestedKey = "desktop"
                        GlobalStates.settingsOverlayOpen = true
                    }
                }

                Item { Layout.fillWidth: true }

                // Clearing asks once: the same place, Cancel or the red Clear.
                IrisButton {
                    implicitHeight: foot.key
                    text: Translation.tr("Cancel")
                    enabled: root.confirmingClear || DesktopEditHistory.changed
                    opacity: enabled ? 1 : 0.38
                    onClicked: {
                        if (root.confirmingClear) root.confirmingClear = false
                        else DesktopEditHistory.cancel()
                    }
                }
                IrisButton {
                    visible: root.confirmingClear
                    implicitHeight: foot.key
                    text: Translation.tr("Clear")
                    emphasized: true
                    danger: true
                    onClicked: root.clearAllWidgets()
                }
                IrisButton {
                    visible: !root.confirmingClear
                    implicitHeight: foot.key
                    text: Translation.tr("Done")
                    emphasized: true
                    onClicked: DesktopEditHistory.finish()
                }
            }
        }
    }
}
