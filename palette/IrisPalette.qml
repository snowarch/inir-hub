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
            && (!root.spotlight || root.mathQuery || entry?.type !== Translation.tr("Math")))
        .slice(0, root.resultLimit)

    // Island design: with nothing typed, Spotlight offers the Dock's apps
    // (pinned first, then running) instead of an empty field.
    readonly property bool spotlight: IrisStyle.island
    readonly property bool browsing: root.spotlight && LauncherSearch.query.length === 0
    readonly property var suggestions: {
        if (!root.spotlight) return []
        return (TaskbarApps.apps ?? []).filter(app => app.appId !== "SEPARATOR").slice(0, 8).map(app => {
            const entry = AppSearch.lookupDesktopEntry(app.appId)
            const windows = app.toplevels ?? []
            return {
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
    readonly property bool clipboardMode: root.spotlight && LauncherSearch.query.startsWith(root.clipboardPrefix)
    onClipboardModeChanged: if (root.clipboardMode) Cliphist.refresh()
    property int selectedIndex: 0
    property bool presentationVisible: GlobalStates.searchOpen
    property bool presentationShown: false

    visible: root.spotlight ? (GlobalStates.searchOpen || (content.item?.progress ?? 0) > 0) : root.presentationVisible
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-palette"
    WlrLayershell.keyboardFocus: GlobalStates.searchOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    function focusInput(): void {
        Qt.callLater(() => content.item?.focusInput())
    }

    Component.onCompleted: {
        if (GlobalStates.searchOpen) {
            Qt.callLater(() => root.presentationShown = true)
            root.focusInput()
        }
    }

    Connections {
        target: GlobalStates
        function onSearchOpenChanged(): void {
            if (GlobalStates.searchOpen) {
                closePresentation.stop()
                root.presentationVisible = true
                root.selectedIndex = 0
                Qt.callLater(() => root.presentationShown = true)
                root.focusInput()
            } else if (root.presentationVisible && !root.spotlight) {
                root.presentationShown = false
                closePresentation.restart()
            }
        }
    }

    Timer {
        id: closePresentation
        interval: IrisStyle.duration(100)
        onTriggered: {
            root.presentationVisible = false
            LauncherSearch.query = ""
        }
    }

    onVisibleChanged: if (!visible) LauncherSearch.query = ""

    Connections {
        target: LauncherSearch
        function onQueryChanged(): void { root.selectedIndex = 0 }
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
            root.moveSelection(1)
        } else if (backward) {
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
            if (LauncherSearch.query.length > 0 && root.spotlight) LauncherSearch.query = ""
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
        sourceComponent: root.spotlight ? spotlightComponent : classicComponent
    }

    // ── Island: Spotlight ─────────────────────────────────────────────────
    Component {
        id: spotlightComponent

        Item {
            id: stage
            readonly property alias progress: surface.progress
            readonly property real d: IrisStyle.density
            function focusInput(): void { input.forceActiveFocus() }

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
                            color: IrisStyle.subtext
                        }
                        TextInput {
                            id: input
                            anchors.left: searchGlyph.right
                            anchors.leftMargin: 12 * stage.d
                            anchors.right: parent.right
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
                                readonly property Item target: tileRepeater.count > 0 ? tileRepeater.itemAt(root.selectedIndex) : null
                                visible: target !== null
                                x: target?.x ?? 0
                                width: tiles.tileWidth
                                height: tiles.height
                                radius: Math.round(16 * stage.d)
                                color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
                                Behavior on x { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
                            }

                            Row {
                                anchors.fill: parent
                                Repeater {
                                    id: tileRepeater
                                    model: root.browsing ? root.suggestions : []
                                    MouseArea {
                                        id: tile
                                        required property var modelData
                                        required property int index
                                        width: tiles.tileWidth
                                        height: tiles.height
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: tile.modelData.name
                                        onPositionChanged: if (root.selectedIndex !== tile.index) root.selectedIndex = tile.index
                                        onClicked: { root.selectedIndex = tile.index; root.executeSelected() }

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
                                            visible: tile.modelData.running
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
                                    implicitWidth: hintRow.implicitWidth + 18 * stage.d
                                    buttonRadius: height / 2
                                    buttonRadiusPressed: height / 2
                                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.07)
                                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.13)
                                    Accessible.name: hint.modelData.label
                                    onClicked: { LauncherSearch.query = hint.modelData.key; stage.focusInput() }
                                    Row {
                                        id: hintRow
                                        anchors.centerIn: parent
                                        spacing: 5 * stage.d
                                        IrisText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: hint.modelData.label
                                            color: IrisStyle.subtext
                                            font.pixelSize: 11.5 * IrisStyle.typeScale
                                        }
                                        IrisText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: hint.modelData.key
                                            color: IrisStyle.muted
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: 11.5 * IrisStyle.typeScale
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
                                            : Math.round((result.topHit ? 58 : 40) * stage.d)
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: String(result.modelData?.name ?? "")
                                        onPositionChanged: if (!result.selected) root.selectedIndex = result.index
                                        onClicked: { root.selectedIndex = result.index; root.executeSelected() }

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
                                                    text: result.clipImage
                                                        ? Translation.tr("Image") + (thumbLoader.item ? "  ·  " + thumbLoader.item.imageWidth + " × " + thumbLoader.item.imageHeight : "")
                                                        : String(result.modelData?.name ?? "")
                                                    font.family: result.modelData?.fontType === LauncherSearchResult.FontType.Monospace
                                                        ? Appearance.font.family.monospace : IrisStyle.fontMain
                                                    font.pixelSize: Math.round((result.topHit ? 16 : 13.5) * IrisStyle.typeScale)
                                                    font.weight: result.topHit ? Font.DemiBold : Font.Normal
                                                    elide: Text.ElideRight
                                                }
                                                IrisText {
                                                    Layout.fillWidth: true
                                                    visible: result.topHit && text.length > 0
                                                    text: result.modelData?.comment || result.modelData?.genericName || result.modelData?.type || ""
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
                                            MaterialSymbol {
                                                visible: result.selected
                                                text: "keyboard_return"
                                                iconSize: Math.round(15 * stage.d)
                                                color: IrisStyle.subtext
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

    // ── Classic: palette card ─────────────────────────────────────────────
    Component {
        id: classicComponent

        Item {
            function focusInput(): void { searchInput.forceActiveFocus() }

            Rectangle {
                anchors.fill: parent
                color: IrisStyle.scrim
                opacity: root.presentationShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutCubic } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.searchOpen = false
                }
            }

            IrisSurface {
                id: paletteSurface
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(72, Math.round(parent.height * 0.16))
                width: Math.max(280, Math.min(parent.width - 32,
                    Math.max(440, Number(root.options?.width ?? 640) * IrisStyle.density)))
                height: classicContent.implicitHeight + IrisStyle.panelPadding * 2
                raised: true
                radius: IrisStyle.radius
                opacity: root.presentationShown ? 1 : 0
                transform: Translate {
                    y: root.presentationShown ? 0 : -6 * IrisStyle.density
                    Behavior on y { NumberAnimation { duration: IrisStyle.duration(100); easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: classicContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: IrisStyle.panelPadding
                    spacing: 12 * IrisStyle.density

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: IrisStyle.headerHeight

                        IrisSectionHeader {
                            anchors.fill: parent
                            icon: "search"
                            eyebrow: "IRIS / PALETTE"
                            title: Translation.tr("Find anything")
                            subtitle: LauncherSearch.query.length > 0
                                ? Translation.tr("Search results")
                                : Translation.tr("Apps, actions, clipboard and math")
                            indexText: String(root.visibleResults.length).padStart(2, "0")
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 52 * IrisStyle.density

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 2 * IrisStyle.density
                            anchors.rightMargin: 2 * IrisStyle.density
                            spacing: 8 * IrisStyle.density

                            Rectangle {
                                Layout.preferredWidth: 3 * IrisStyle.density
                                Layout.preferredHeight: 30 * IrisStyle.density
                                radius: width / 2
                                color: IrisStyle.accent
                            }

                            IrisField {
                                id: searchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: LauncherSearch.query
                                placeholderText: Translation.tr("Search or type a command…")
                                font.pixelSize: 17 * IrisStyle.typeScale
                                focus: true
                                onTextChanged: {
                                    if (LauncherSearch.query !== text) LauncherSearch.query = text
                                }
                                Keys.onPressed: event => root.handleKey(event)
                            }

                            IrisKey {
                                visible: root.options?.showHints ?? true
                                key: "ESC"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: root.visibleResults
                            IrisButton {
                                id: resultButton
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 54 * IrisStyle.density
                                selected: index === root.selectedIndex
                                quiet: !selected
                                onClicked: {
                                    root.selectedIndex = index
                                    root.executeSelected()
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    width: resultButton.width - 16 * IrisStyle.density
                                    spacing: 10 * IrisStyle.density

                                    Rectangle {
                                        Layout.preferredWidth: 3 * IrisStyle.density
                                        Layout.preferredHeight: 28 * IrisStyle.density
                                        radius: width / 2
                                        color: resultButton.selected ? IrisStyle.accent : "transparent"
                                    }

                                    Item {
                                        Layout.preferredWidth: 28 * IrisStyle.density
                                        Layout.preferredHeight: 28 * IrisStyle.density

                                        Loader {
                                            anchors.centerIn: parent
                                            width: 24 * IrisStyle.density
                                            height: width
                                            active: resultButton.modelData?.iconType === LauncherSearchResult.IconType.System
                                            sourceComponent: SmartAppIcon {
                                                icon: resultButton.modelData?.iconName ?? "application-x-executable"
                                                fallback: "application-x-executable"
                                                iconSize: Math.round(24 * IrisStyle.density)
                                            }
                                        }
                                        Loader {
                                            anchors.centerIn: parent
                                            width: 22 * IrisStyle.density
                                            height: width
                                            active: resultButton.modelData?.iconType === LauncherSearchResult.IconType.Text
                                            sourceComponent: IrisText {
                                                text: resultButton.modelData?.iconName ?? ""
                                                font.pixelSize: 20 * IrisStyle.typeScale
                                                horizontalAlignment: Text.AlignHCenter
                                                color: resultButton.selected ? IrisStyle.accent : IrisStyle.subtext
                                            }
                                        }
                                        Loader {
                                            anchors.centerIn: parent
                                            width: 22 * IrisStyle.density
                                            height: width
                                            active: resultButton.modelData?.iconType !== LauncherSearchResult.IconType.System
                                                && resultButton.modelData?.iconType !== LauncherSearchResult.IconType.Text
                                            sourceComponent: MaterialSymbol {
                                                text: resultButton.modelData?.iconName || "search"
                                                iconSize: Math.round(21 * IrisStyle.density)
                                                color: resultButton.selected ? IrisStyle.accent : IrisStyle.subtext
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        IrisText {
                                            Layout.fillWidth: true
                                            text: resultButton.modelData?.name ?? ""
                                            font.family: IrisStyle.fontTitle
                                            font.pixelSize: 14 * IrisStyle.typeScale
                                            font.weight: resultButton.selected ? Font.Bold : Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        IrisText {
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                            text: resultButton.modelData?.comment || resultButton.modelData?.type || ""
                                            font.pixelSize: 11 * IrisStyle.typeScale
                                            color: IrisStyle.subtext
                                            elide: Text.ElideRight
                                        }
                                    }

                                    IrisKey {
                                        key: resultButton.modelData?.verb ?? ""
                                        visible: key.length > 0
                                    }
                                }
                            }
                        }

                        Item {
                            visible: LauncherSearch.query.length > 0 && root.visibleResults.length === 0
                            Layout.fillWidth: true
                            implicitHeight: 56 * IrisStyle.density
                            IrisText {
                                anchors.centerIn: parent
                                text: Translation.tr("No results")
                                color: IrisStyle.subtext
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2 * IrisStyle.density
                        visible: root.options?.showHints ?? true
                        spacing: 12 * IrisStyle.density
                        IrisKey { key: "/" }
                        IrisText { text: Translation.tr("actions"); role: IrisText.Meta }
                        IrisKey { key: ";" }
                        IrisText { text: Translation.tr("clipboard"); role: IrisText.Meta }
                        IrisKey { key: "=" }
                        IrisText { text: Translation.tr("math"); role: IrisText.Meta }
                        Item { Layout.fillWidth: true }
                        IrisKey { key: "↑↓" }
                        IrisKey { key: "ENTER" }
                    }
                }
            }
        }
    }
}
