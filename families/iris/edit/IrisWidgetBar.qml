pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.modules.shared.background.edit
import qs.modules.shared.background.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Unified right-side panel for Widget Edit Mode (1:1 with rin-shell's desk editor):
// hosts Widget Gallery / Look / Style / Presets when browsing, and switches cleanly in place to
// the selected widget's Inspector controls without overlapping the live desktop card.
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
    property string searchQuery: ""

    readonly property var inspectedWidget: {
        const ins = DesktopEditStage.inspected
        if (ins && ins.output === root.outputName && ins.widget) return ins.widget
        const ch = DesktopEditStage.chosen
        if (ch && ch.output === root.outputName && ch.widget) return ch.widget
        return null
    }
    readonly property bool inspecting: root.inspectedWidget !== null

    Component.onCompleted: {
        DesktopEditStage.setSheetHost(root.outputName, true)
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
            if (root.searchQuery.length > 0) { root.searchQuery = ""; searchField.focus = false }
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
                Config.setNestedValue(`background.widgets.${pureKey}.enable`, false)
                GlobalStates.clearDesktopWidgetSelection()
            }
        }
    }

    // 1:1 rin-shell right-side panel geometry (388 px wide, 16 px margin, full height).
    readonly property real edge: Math.round(16 * root.d)
    readonly property real panelWidth: Math.round(Math.min(400 * root.d, Math.max(336 * root.d, root.width * 0.22)))
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

    // Reserve right panel and top wallpaper strip so DesktopEditStage.cardFor places the live card
    // squarely in the left stage room with zero overlap.
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
    onPresentChanged: if (root.present) root.prepare()
    function prepare(): void {
        DesktopEditStage.look = root.look
        Quickshell.execDetached(["mkdir", "-p", DesktopEditStage.pictureDir])
    }

    // All built-in + custom desktop widgets.
    readonly property var allEntries: {
        const list = IrisFaceData.galleryEntries.concat(IrisFaceData.otherEntries).map(entry => ({
            key: entry.key,
            glyph: entry.glyph,
            name: entry.label,
            english: entry.english ?? entry.label,
            searchText: (entry.label + " " + (entry.english ?? "") + " " + entry.key + " " + DesktopWidgetRegistry.keywordsOf(entry.key)).toLowerCase()
        }))
        for (const custom of (CustomWidgets.ready ? CustomWidgets.widgets : [])) {
            list.push({
                key: "custom." + custom.id,
                glyph: custom.icon || "widgets",
                name: custom.name,
                english: custom.name,
                searchText: (custom.name + " custom " + custom.id).toLowerCase()
            })
        }
        return list
    }
    readonly property var filteredEntries: {
        const q = root.searchQuery.trim().toLowerCase()
        if (q.length === 0) return root.allEntries
        return root.allEntries.filter(entry => entry.searchText.includes(q))
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

    Component {
        id: rowsComponent
        IrisSheetRows {}
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
            spacing: Math.round(12 * root.d)

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
                        ? String(root.inspectedWidget?.widgetDisplayName ?? root.inspectedWidget?.configEntryName ?? Translation.tr("Widget"))
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

            // Segmented navigation tabs when browsing (hidden while inspecting a widget).
            IrisSegmented {
                Layout.fillWidth: true
                visible: !root.inspecting
                options: [
                    { value: "widgets", label: Translation.tr("Widgets") },
                    { value: "look", label: Translation.tr("Look") },
                    { value: "presets", label: Translation.tr("Presets") },
                    { value: "appearance", label: Translation.tr("Style") }
                ]
                current: root.page
                accessibleName: Translation.tr("Desktop editor sections")
                onPicked: value => root.page = value
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
                        active: root.inspecting && root.shown
                        source: active ? Qt.resolvedUrl("../widgets/IrisWidgetControls.qml") : ""
                        onLoaded: {
                            item.widget = Qt.binding(() => root.inspectedWidget)
                            item.plateRadius = Qt.binding(() => Math.round(12 * root.d))
                            item.optionRows = rowsComponent
                        }
                    }
                }
            }

            // ── Widget Gallery Grid (2 columns, fast, zero heavy previews) ──
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.inspecting && root.page === "widgets"
                clip: true
                contentWidth: width
                contentHeight: galleryGrid.implicitHeight + Math.round(12 * root.d)
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: galleryGrid
                    width: parent.width
                    columns: 2
                    columnSpacing: Math.round(10 * root.d)
                    rowSpacing: Math.round(10 * root.d)

                    Repeater {
                        model: root.filteredEntries
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property bool active: root.widgetEnabled(card.modelData.key)
                            readonly property bool hovered: cardMouse.containsMouse

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(78 * root.d)
                            radius: Math.round(14 * root.d)
                            color: card.active
                                ? IrisStyle.tintFill(IrisStyle.accent)
                                : card.hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                            border.width: card.active ? 1.5 : 1
                            border.color: card.active ? IrisStyle.accent : IrisStyle.hairline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Math.round(11 * root.d)
                                spacing: Math.round(10 * root.d)

                                Rectangle {
                                    Layout.preferredWidth: Math.round(36 * root.d)
                                    Layout.preferredHeight: Math.round(36 * root.d)
                                    radius: Math.round(10 * root.d)
                                    color: card.active ? IrisStyle.accent : IrisStyle.fill
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: card.modelData.glyph
                                        iconSize: Math.round(19 * root.d)
                                        color: card.active ? IrisStyle.inkOnAccent : IrisStyle.text
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(2 * root.d)
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: card.modelData.name
                                        font.pixelSize: IrisStyle.typeMeta
                                        font.weight: IrisStyle.weight(Font.Medium)
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: card.active ? Translation.tr("On desktop") : Translation.tr("Click to add")
                                        color: card.active ? IrisStyle.accent : IrisStyle.textTertiary
                                        font.pixelSize: IrisStyle.typeFootnote
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && card.active)
                                        root.removeWidget(card.modelData.key, card)
                                    else
                                        root.toggleWidget(card.modelData.key, card)
                                }
                            }

                            // Quick remove pill on active cards when hovered.
                            Rectangle {
                                visible: card.active && (card.hovered || removeMouse.containsMouse)
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Math.round(6 * root.d)
                                width: Math.round(20 * root.d)
                                height: Math.round(20 * root.d)
                                radius: width / 2
                                color: removeMouse.containsMouse ? IrisStyle.signal : IrisStyle.raised
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

            // ── Look / Style Options Page ──
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !root.inspecting && (root.page === "look" || root.page === "appearance") && root.shown
                visible: active
                source: active ? Qt.resolvedUrl("IrisShelfOptions.qml") : ""
                onLoaded: {
                    item.section = Qt.binding(() => root.page === "look" ? "desktop" : "appearance")
                    item.only = Qt.binding(() => root.page === "look")
                    item.order = Qt.binding(() => root.page === "look"
                        ? ["Design", "Accents", "Material", "Legibility", "Widgets"]
                        : ["Design", "Scheme", "Accent", "Material", "Glass", "Shape"])
                }
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
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(52 * root.d)
                            radius: Math.round(12 * root.d)
                            color: presetCard.worn ? IrisStyle.tintFill(IrisStyle.accent)
                                : presetMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                            border.width: presetCard.worn ? 1.5 : 1
                            border.color: presetCard.worn ? IrisStyle.accent : IrisStyle.hairline

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
                            }
                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DesktopPresets.wear(presetCard.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
