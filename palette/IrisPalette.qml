pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root

    readonly property var options: Config.options?.iris?.palette ?? ({})
    readonly property int configuredResultLimit: Math.max(3, Math.min(14, Number(root.options?.maxResults ?? 8)))
    readonly property int heightResultLimit: Math.max(3, Math.floor(
        Math.max(180, ((root.screen?.height ?? 1080) * 0.72) - (120 * IrisStyle.density))
        / Math.max(42, 50 * IrisStyle.density)))
    readonly property int resultLimit: Math.min(root.configuredResultLimit, root.heightResultLimit)
    // Math is computed asynchronously; an empty answer is not a result.
    // Spotlight also drops the calculator fallback unless the query is maths.
    readonly property bool mathQuery: /[0-9]/.test(LauncherSearch.query)
    readonly property var searchResults: (LauncherSearch.results ?? [])
        .filter(entry => String(entry?.name ?? "").length > 0
            && (root.mathQuery || entry?.type !== Translation.tr("Math")))
        .slice(0, root.resultLimit)

    // Island design: with nothing typed, Spotlight offers the Dock's apps
    // (pinned first, then running) instead of an empty field.
    readonly property bool browsing: LauncherSearch.query.length === 0
    readonly property var suggestions: {
        return (TaskbarApps.apps ?? []).filter(app => app.appId !== "SEPARATOR").slice(0, 8).map(app => {
            const entry = AppSearch.lookupDesktopEntry(app.appId)
            const windows = app.toplevels ?? []
            return {
                appId: app.appId,
                name: entry?.name ?? app.appId,
                iconName: entry?.icon ?? app.appId,
                iconType: LauncherSearchResult.IconType.System,
                running: windows.length > 0,
                verb: windows.length > 0 ? Translation.tr("Switch to") : Translation.tr("Open"),
                execute: () => {
                    const focused = windows.find(window => window.activated) ?? windows[0]
                    if (focused && CompositorService.isNiri && focused.niriWindowId !== undefined)
                        NiriService.focusWindow(focused.niriWindowId)
                    else if (focused) focused.activate()
                    else if (entry) AppSearch.launchEntry(entry)
                }
            }
        })
    }
    readonly property var visibleResults: root.browsing ? root.suggestions : root.searchResults
    // Clipboard history (Super+V opens Spotlight on the clipboard prefix):
    // image entries render thumbnails, Delete removes the selected entry.
    readonly property string clipboardPrefix: Config.options?.search?.prefix?.clipboard ?? ";"
    readonly property bool clipboardMode: LauncherSearch.query.startsWith(root.clipboardPrefix)
    onClipboardModeChanged: if (root.clipboardMode) Cliphist.refresh()
    property int selectedIndex: 0
    property bool pointerSelectionArmed: false
    property point lastPointerPosition: Qt.point(-1, -1)

    function disarmPointerSelection(resetPosition = false) {
        root.pointerSelectionArmed = false
        if (resetPosition)
            root.lastPointerPosition = Qt.point(-1, -1)
    }

    function armPointerSelection(area, event) {
        const point = area.mapToItem(root.contentItem, event.x, event.y)
        if (root.lastPointerPosition.x < 0 || root.lastPointerPosition.y < 0) {
            root.lastPointerPosition = Qt.point(point.x, point.y)
            return false
        }
        const moved = Math.abs(point.x - root.lastPointerPosition.x) > 0.5
            || Math.abs(point.y - root.lastPointerPosition.y) > 0.5
        root.lastPointerPosition = Qt.point(point.x, point.y)
        if (moved) root.pointerSelectionArmed = true
        return root.pointerSelectionArmed
    }

    visible: GlobalStates.searchOpen || (content.item?.progress ?? 0) > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-palette"
    WlrLayershell.keyboardFocus: GlobalStates.searchOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    // Spotlight catches outside clicks only while the capsule is presented;
    // loading and collapsing yield everything but the capsule itself.
    mask: GlobalStates.searchOpen && (content.item?.armed ?? false) ? null : capsuleRegion
    Region { id: capsuleRegion; item: content.item?.surfaceItem ?? null }

    function focusInput(): void {
        Qt.callLater(() => content.item?.focusInput())
    }

    Component.onCompleted: if (GlobalStates.searchOpen) root.focusInput()

    Connections {
        target: GlobalStates
        function onSearchOpenChanged(): void {
            if (!GlobalStates.searchOpen) return
            root.selectedIndex = 0
            root.disarmPointerSelection(true)
            root.focusInput()
        }
    }

    onVisibleChanged: if (!visible) LauncherSearch.query = ""

    Connections {
        target: LauncherSearch
        function onQueryChanged(): void {
            root.selectedIndex = 0
            root.disarmPointerSelection()
        }
    }

    function executeSelected(): void {
        const entry = root.visibleResults[root.selectedIndex]
        if (!entry || typeof entry.execute !== "function") return
        entry.execute()
        GlobalStates.searchOpen = false
    }

    function moveSelection(step: int): void {
        const count = root.visibleResults.length
        if (count === 0) return
        root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + step))
    }

    function handleKey(event): void {
        const forward = event.key === Qt.Key_Down || event.key === Qt.Key_Tab
            || (root.browsing && event.key === Qt.Key_Right)
        const backward = event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
            || (root.browsing && event.key === Qt.Key_Left)
        if (forward) {
            root.disarmPointerSelection()
            root.moveSelection(1)
        } else if (backward) {
            root.disarmPointerSelection()
            root.moveSelection(-1)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.executeSelected()
        } else if (root.clipboardMode && event.key === Qt.Key_Delete) {
            const entry = root.visibleResults[root.selectedIndex]?.rawValue
            if (!entry) return
            Cliphist.deleteEntry(entry)
            root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.visibleResults.length - 2))
        } else {
            return
        }
        event.accepted = true
    }

    // Window-level, so Escape works whichever child holds focus: the first
    // press clears a query, the next closes.
    Shortcut {
        sequence: "Escape"
        enabled: GlobalStates.searchOpen
        onActivated: {
            if (LauncherSearch.query.length > 0) LauncherSearch.query = ""
            else GlobalStates.searchOpen = false
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.searchOpen = false
    }

    Loader {
        id: content
        anchors.fill: parent
        // Loader is a focus scope: without focus its field never gets active focus.
        focus: true
        sourceComponent: spotlightComponent
    }

    // ── Island: Spotlight ─────────────────────────────────────────────────
    Component {
        id: spotlightComponent

        Item {
            id: stage
            readonly property alias progress: surface.progress
            readonly property alias armed: surface.armed
            readonly property Item surfaceItem: surface
            readonly property real d: IrisStyle.density
            function focusInput(): void { input.forceActiveFocus() }

            // Apple-style match emphasis: the part of the name the query matched
            // stays full ink and weight, the remainder steps back.
            function escapeHtml(value: string): string {
                return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            }
            function emphasised(name: string): string {
                const query = LauncherSearch.query.trim()
                const at = query.length > 0 ? name.toLowerCase().indexOf(query.toLowerCase()) : -1
                const dim = ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                if (at < 0) return stage.escapeHtml(name)
                return "<font color='" + dim + "'>" + stage.escapeHtml(name.slice(0, at)) + "</font>"
                    + "<b>" + stage.escapeHtml(name.slice(at, at + query.length)) + "</b>"
                    + "<font color='" + dim + "'>" + stage.escapeHtml(name.slice(at + query.length)) + "</font>"
            }

            function sectionOf(entry): string {
                const type = String(entry?.type ?? "")
                if (type === Translation.tr("App")) return Translation.tr("Applications")
                if (type === Translation.tr("Action")) return Translation.tr("Actions")
                if (type === Translation.tr("Math")) return Translation.tr("Calculator")
                if (type === Translation.tr("Command")) return Translation.tr("Run command")
                if (type === Translation.tr("Web")) return Translation.tr("Search the web")
                return type.length > 0 ? type : Translation.tr("Other")
            }
            function sectionAt(index: int): string {
                if (root.clipboardMode) return Translation.tr("Clipboard history")
                return index === 0 ? Translation.tr("Top hit") : stage.sectionOf(root.visibleResults[index])
            }

            // Grows out of the Island (published on open) and settles as a
            // floating search capsule; results extend it downwards.
            IrisMorphSurface {
                id: surface
                open: GlobalStates.searchOpen
                radius: Math.round(26 * stage.d)
                width: Math.max(320, Math.min(root.width - 32, Math.max(480, Number(root.options?.width ?? 640) * stage.d)))
                x: (root.width - width) / 2
                y: Math.max(72, Math.round(root.height * 0.2))
                height: body.implicitHeight
                onClosed: LauncherSearch.query = ""
                // The layer surface may not be active when the open request
                // lands; settle is the last point to claim the field.
                onSettledChanged: if (surface.settled && surface.open) stage.focusInput()
                Behavior on height {
                    enabled: surface.settled
                    NumberAnimation { duration: IrisStyle.duration(150); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: body
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 0

                    // Search field: no box inside the box.
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(58 * stage.d)

                        MaterialSymbol {
                            id: searchGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: 20 * stage.d
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            iconSize: Math.round(22 * stage.d)
                            color: input.text.length > 0 ? IrisStyle.accent : IrisStyle.subtext
                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                        }
                        // Active search mode as a token at the end of the field, so a bare
                        // prefix character reads as the mode it switched to.
                        Rectangle {
                            id: modeToken
                            readonly property var modes: {
                                const prefix = Config.options?.search?.prefix ?? ({})
                                return [
                                    { key: prefix.clipboard ?? ";", label: Translation.tr("Clipboard"), glyph: "content_paste" },
                                    { key: prefix.math ?? "=", label: Translation.tr("Calculator"), glyph: "calculate" },
                                    { key: prefix.action ?? "/", label: Translation.tr("Actions"), glyph: "bolt" },
                                    { key: prefix.emojis ?? ":", label: Translation.tr("Emoji"), glyph: "mood" },
                                    { key: prefix.webSearch ?? "?", label: Translation.tr("Web"), glyph: "travel_explore" },
                                    { key: prefix.shellCommand ?? "$", label: Translation.tr("Command"), glyph: "terminal" }
                                ]
                            }
                            readonly property var mode: modeToken.modes.find(m => String(m.key).length > 0 && LauncherSearch.query.startsWith(m.key)) ?? null
                            visible: modeToken.mode !== null
                            anchors.right: parent.right
                            anchors.rightMargin: 16 * stage.d
                            anchors.verticalCenter: parent.verticalCenter
                            height: Math.round(26 * stage.d)
                            width: modeRow.implicitWidth + Math.round(20 * stage.d)
                            radius: height / 2
                            color: ColorUtils.applyAlpha(IrisStyle.accent, 0.18)
                            Row {
                                id: modeRow
                                anchors.centerIn: parent
                                spacing: 5 * stage.d
                                MaterialSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modeToken.mode?.glyph ?? ""
                                    fill: 1
                                    iconSize: Math.round(14 * stage.d)
                                    color: IrisStyle.accent
                                }
                                IrisText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modeToken.mode?.label ?? ""
                                    color: IrisStyle.accent
                                    font.pixelSize: 12 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                        TextInput {
                            id: input
                            anchors.left: searchGlyph.right
                            anchors.leftMargin: 12 * stage.d
                            anchors.right: modeToken.visible ? modeToken.left : parent.right
                            anchors.rightMargin: 20 * stage.d
                            anchors.verticalCenter: parent.verticalCenter
                            text: LauncherSearch.query
                            color: IrisStyle.text
                            selectionColor: IrisStyle.accentContainer
                            selectedTextColor: IrisStyle.onAccentContainer
                            font.family: IrisStyle.fontMain
                            font.pixelSize: Math.round(21 * IrisStyle.typeScale)
                            clip: true
                            focus: true
                            onTextChanged: if (LauncherSearch.query !== text) LauncherSearch.query = text
                            Keys.onPressed: event => root.handleKey(event)

                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text.length === 0
                                text: Translation.tr("Spotlight Search")
                                color: IrisStyle.muted
                                font.pixelSize: input.font.pixelSize
                                font.weight: Font.Normal
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        visible: results.visible || browse.visible
                        color: IrisStyle.hairline
                    }

                    // ── Suggestions ──────────────────────────────────────
                    ColumnLayout {
                        id: browse
                        Layout.fillWidth: true
                        visible: root.browsing && (root.suggestions.length > 0 || hints.visible)
                        spacing: 0

                        IrisText {
                            visible: root.suggestions.length > 0
                            Layout.leftMargin: 20 * stage.d
                            Layout.topMargin: 12 * stage.d
                            text: Translation.tr("Suggestions")
                            color: IrisStyle.muted
                            font.pixelSize: 11.5 * IrisStyle.typeScale
                            font.weight: Font.DemiBold
                        }

                        Item {
                            id: tiles
                            visible: root.suggestions.length > 0
                            Layout.fillWidth: true
                            Layout.leftMargin: 10 * stage.d
                            Layout.rightMargin: 10 * stage.d
                            Layout.topMargin: 6 * stage.d
                            readonly property real tileWidth: width / 8
                            implicitHeight: Math.round(84 * stage.d)

                            Rectangle {
                                // Placed by index: itemAt() is not reactive and was still null
                                // when Spotlight opened, so the first selection never showed.
                                visible: root.suggestions.length > 0
                                x: Math.min(root.selectedIndex, root.suggestions.length - 1) * tiles.tileWidth
                                width: tiles.tileWidth
                                height: tiles.height
                                radius: Math.round(16 * stage.d)
                                // Same selection language as the result list.
                                color: ColorUtils.applyAlpha(IrisStyle.accent, 0.18)
                                Behavior on x { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
                            }

                            Row {
                                anchors.fill: parent
                                Repeater {
                                    id: tileRepeater
                                    // Keyed by app: suggestions are rebuilt on every window
                                    // event (titles, focus), which must not recreate tiles.
                                    model: ScriptModel {
                                        objectProp: "appId"
                                        values: root.browsing ? root.suggestions : []
                                    }
                                    MouseArea {
                                        id: tile
                                        required property var modelData
                                        required property int index
                                        readonly property var live: root.suggestions[tile.index] ?? tile.modelData
                                        width: tiles.tileWidth
                                        height: tiles.height
                                        hoverEnabled: true
                                        cursorShape: root.pointerSelectionArmed ? Qt.PointingHandCursor : Qt.BlankCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: tile.modelData.name
                                        onPositionChanged: event => {
                                            if (root.armPointerSelection(tile, event) && root.selectedIndex !== tile.index)
                                                root.selectedIndex = tile.index
                                        }
                                        onClicked: {
                                            root.pointerSelectionArmed = true
                                            root.selectedIndex = tile.index
                                            root.executeSelected()
                                        }

                                        SmartAppIcon {
                                            id: tileIcon
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: 10 * stage.d
                                            icon: tile.modelData.iconName
                                            fallback: "application-x-executable"
                                            iconSize: Math.round(42 * stage.d)
                                            scale: tile.pressed ? 0.92 : 1
                                            Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration } }
                                        }
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: tileIcon.bottom
                                            anchors.topMargin: 3 * stage.d
                                            visible: tile.live.running
                                            width: 4 * stage.d
                                            height: width
                                            radius: width / 2
                                            color: ColorUtils.applyAlpha(IrisStyle.text, 0.5)
                                        }
                                        IrisText {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: 4 * stage.d
                                            anchors.rightMargin: 4 * stage.d
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 8 * stage.d
                                            horizontalAlignment: Text.AlignHCenter
                                            text: tile.modelData.name
                                            elide: Text.ElideRight
                                            font.pixelSize: 11 * IrisStyle.typeScale
                                            color: root.selectedIndex === tile.index ? IrisStyle.text : IrisStyle.subtext
                                        }
                                    }
                                }
                            }
                        }

                        // Search modes the shared launcher understands, as
                        // quiet tokens that type their prefix.
                        Flow {
                            id: hints
                            visible: root.options?.showHints ?? true
                            Layout.fillWidth: true
                            Layout.leftMargin: 16 * stage.d
                            Layout.rightMargin: 16 * stage.d
                            Layout.topMargin: 10 * stage.d
                            Layout.bottomMargin: 14 * stage.d
                            spacing: 6 * stage.d
                            Repeater {
                                model: {
                                    const prefix = Config.options?.search?.prefix ?? ({})
                                    return [
                                        { key: prefix.clipboard ?? ";", label: Translation.tr("Clipboard") },
                                        { key: prefix.math ?? "=", label: Translation.tr("Calculator") },
                                        { key: prefix.action ?? "/", label: Translation.tr("Actions") },
                                        { key: prefix.emojis ?? ":", label: Translation.tr("Emoji") },
                                        { key: prefix.webSearch ?? "?", label: Translation.tr("Web") },
                                        { key: prefix.shellCommand ?? "$", label: Translation.tr("Command") }
                                    ]
                                }
                                IrisButton {
                                    id: hint
                                    required property var modelData
                                    implicitHeight: Math.round(28 * stage.d)
                                    implicitWidth: hintRow.implicitWidth + 16 * stage.d
                                    buttonRadius: height / 2
                                    buttonRadiusPressed: height / 2
                                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.07)
                                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.13)
                                    Accessible.name: hint.modelData.label
                                    onClicked: { LauncherSearch.query = hint.modelData.key; stage.focusInput() }
                                    Row {
                                        id: hintRow
                                        anchors.centerIn: parent
                                        anchors.horizontalCenterOffset: -2 * stage.d
                                        spacing: 7 * stage.d
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.max(height, keyText.implicitWidth + 8 * stage.d)
                                            height: Math.round(18 * stage.d)
                                            radius: height / 2
                                            color: ColorUtils.applyAlpha(IrisStyle.accent, hint.buttonHovered ? 0.3 : 0.18)
                                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                                            IrisText {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: hint.modelData.key
                                                color: IrisStyle.accent
                                                font.family: Appearance.font.family.monospace
                                                font.pixelSize: 11.5 * IrisStyle.typeScale
                                                font.weight: Font.Bold
                                            }
                                        }
                                        IrisText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: hint.modelData.label
                                            color: hint.buttonHovered ? IrisStyle.text : IrisStyle.subtext
                                            font.pixelSize: 12 * IrisStyle.typeScale
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Results ──────────────────────────────────────────
                    Item {
                        id: results
                        Layout.fillWidth: true
                        visible: !root.browsing && LauncherSearch.query.length > 0
                        implicitHeight: resultColumn.implicitHeight + 16 * stage.d

                        Rectangle {
                            id: highlight
                            readonly property Item target: resultRepeater.count > 0 ? resultRepeater.itemAt(root.selectedIndex) : null
                            visible: target !== null
                            x: 8 * stage.d
                            width: parent.width - 16 * stage.d
                            y: resultColumn.y + (target ? target.y + target.rowY : 0)
                            height: target?.rowHeight ?? 0
                            radius: Math.round(14 * stage.d)
                            color: ColorUtils.applyAlpha(IrisStyle.accent, 0.2)
                            Behavior on y { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
                        }

                        Column {
                            id: resultColumn
                            y: 8 * stage.d
                            width: parent.width

                            Item {
                                width: parent.width
                                height: 44 * stage.d
                                visible: root.visibleResults.length === 0
                                IrisText {
                                    anchors.centerIn: parent
                                    text: Translation.tr("No results")
                                    color: IrisStyle.muted
                                }
                            }

                            Repeater {
                                id: resultRepeater
                                model: root.browsing ? [] : root.visibleResults
                                Column {
                                    id: result
                                    required property var modelData
                                    required property int index
                                    readonly property bool topHit: result.index === 0 && !root.clipboardMode
                                    readonly property bool mathHit: result.topHit && result.modelData?.type === Translation.tr("Math")
                                    readonly property bool clipImage: root.clipboardMode
                                        && Cliphist.entryIsImage(String(result.modelData?.rawValue ?? ""))
                                    readonly property bool selected: root.selectedIndex === result.index
                                    readonly property bool showHeader: result.index === 0
                                        || stage.sectionAt(result.index) !== stage.sectionAt(result.index - 1)
                                    readonly property real rowY: row.y
                                    readonly property real rowHeight: row.height
                                    width: resultColumn.width

                                    IrisText {
                                        visible: result.showHeader
                                        x: 20 * stage.d
                                        height: Math.round((result.index === 0 ? 24 : 30) * stage.d)
                                        verticalAlignment: Text.AlignBottom
                                        bottomPadding: 5 * stage.d
                                        text: stage.sectionAt(result.index)
                                        color: IrisStyle.muted
                                        font.pixelSize: 11.5 * IrisStyle.typeScale
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: row
                                        x: 8 * stage.d
                                        width: parent.width - 16 * stage.d
                                        height: result.clipImage ? Math.max(40 * stage.d, thumbLoader.height + 14 * stage.d)
                                            : Math.round((result.mathHit ? 66 : result.topHit ? 58 : 40) * stage.d)
                                        hoverEnabled: true
                                        cursorShape: root.pointerSelectionArmed ? Qt.PointingHandCursor : Qt.BlankCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: String(result.modelData?.name ?? "")
                                        onPositionChanged: event => {
                                            if (root.armPointerSelection(row, event) && !result.selected)
                                                root.selectedIndex = result.index
                                        }
                                        onClicked: {
                                            root.pointerSelectionArmed = true
                                            root.selectedIndex = result.index
                                            root.executeSelected()
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12 * stage.d
                                            anchors.rightMargin: 14 * stage.d
                                            spacing: 12 * stage.d

                                            Loader {
                                                id: thumbLoader
                                                active: result.clipImage
                                                visible: active
                                                Layout.preferredWidth: item?.implicitWidth ?? 0
                                                Layout.preferredHeight: item?.implicitHeight ?? 0
                                                sourceComponent: CliphistImage {
                                                    entry: String(result.modelData?.rawValue ?? "")
                                                    maxWidth: Math.round(220 * stage.d)
                                                    maxHeight: Math.round(120 * stage.d)
                                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                                                    radius: Math.round(10 * stage.d)
                                                }
                                            }
                                            Item {
                                                visible: !result.clipImage
                                                readonly property real size: Math.round((result.topHit ? 38 : 24) * stage.d)
                                                Layout.preferredWidth: size
                                                Layout.preferredHeight: size
                                                Loader {
                                                    anchors.fill: parent
                                                    active: result.modelData?.iconType === LauncherSearchResult.IconType.System
                                                    sourceComponent: SmartAppIcon {
                                                        icon: result.modelData?.iconName ?? "application-x-executable"
                                                        fallback: "application-x-executable"
                                                        iconSize: parent?.width ?? 24
                                                    }
                                                }
                                                Loader {
                                                    anchors.centerIn: parent
                                                    active: result.modelData?.iconType === LauncherSearchResult.IconType.Text
                                                    sourceComponent: IrisText {
                                                        text: result.modelData?.iconName ?? ""
                                                        font.pixelSize: Math.round((result.topHit ? 30 : 19) * IrisStyle.typeScale)
                                                    }
                                                }
                                                // Material glyphs sit in a quiet round well so actions,
                                                // math and commands read as system items next to app art.
                                                Rectangle {
                                                    anchors.fill: parent
                                                    visible: result.modelData?.iconType !== LauncherSearchResult.IconType.System
                                                        && result.modelData?.iconType !== LauncherSearchResult.IconType.Text
                                                    radius: width / 2
                                                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        text: result.modelData?.iconName || "search"
                                                        iconSize: Math.round(parent.width * 0.56)
                                                        color: IrisStyle.text
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                IrisText {
                                                    Layout.fillWidth: true
                                                    readonly property bool emphasise: !root.clipboardMode && !result.mathHit
                                                        && result.modelData?.fontType !== LauncherSearchResult.FontType.Monospace
                                                    textFormat: emphasise || result.mathHit || result.clipImage ? Text.StyledText : Text.PlainText
                                                    text: result.clipImage
                                                        ? "<b>" + Translation.tr("Image") + "</b>" + (thumbLoader.item
                                                            ? "  <font color='" + IrisStyle.muted + "'>" + thumbLoader.item.imageWidth + " × " + thumbLoader.item.imageHeight + "</font>" : "")
                                                        : result.mathHit
                                                            ? "<font color='" + IrisStyle.secondaryAccent + "'>=</font> " + stage.escapeHtml(String(result.modelData?.name ?? ""))
                                                        : emphasise ? stage.emphasised(String(result.modelData?.name ?? ""))
                                                        : String(result.modelData?.name ?? "")
                                                    font.family: result.mathHit ? IrisStyle.fontMain
                                                        : result.modelData?.fontType === LauncherSearchResult.FontType.Monospace
                                                        ? Appearance.font.family.monospace : IrisStyle.fontMain
                                                    font.features: result.mathHit ? ({ "tnum": 1 }) : ({})
                                                    font.pixelSize: Math.round((result.mathHit ? 28 : result.topHit ? 16 : 13.5) * IrisStyle.typeScale)
                                                    font.weight: result.mathHit ? Font.Bold : result.topHit ? Font.DemiBold : Font.Normal
                                                    font.letterSpacing: result.mathHit ? -0.5 : 0
                                                    elide: Text.ElideRight
                                                }
                                                IrisText {
                                                    Layout.fillWidth: true
                                                    visible: result.topHit && text.length > 0
                                                    text: result.mathHit ? LauncherSearch.query
                                                        : result.modelData?.comment || result.modelData?.genericName || result.modelData?.type || ""
                                                    color: IrisStyle.subtext
                                                    font.pixelSize: 12 * IrisStyle.typeScale
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            IrisText {
                                                visible: result.selected && text.length > 0
                                                text: String(result.modelData?.verb ?? "")
                                                color: IrisStyle.subtext
                                                font.pixelSize: 12 * IrisStyle.typeScale
                                            }
                                            Rectangle {
                                                visible: result.selected
                                                Layout.preferredWidth: Math.round(24 * stage.d)
                                                Layout.preferredHeight: Math.round(20 * stage.d)
                                                radius: Math.round(6 * stage.d)
                                                color: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "keyboard_return"
                                                    iconSize: Math.round(14 * stage.d)
                                                    color: IrisStyle.text
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
