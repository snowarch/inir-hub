pragma ComponentBehavior: Bound

import qs
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.ii.settings

// Material Settings, whole: the nav pane, the page, search and where a result lands. The overlay and the window
// only host it. Android 16's two-pane Settings made ours: every page keeps one colour and one place in the list, so
// after a week the eye finds it before reading.
Item {
    id: root

    // pages load only while Settings is on screen
    property bool active: true
    // hosted in its own window: no "open as window", the window manager closes it
    property bool windowed: false
    signal closeRequested()
    signal windowRequested(int page)

    readonly property Item pageHostItem: pagesHost
    readonly property bool dark: SettingsMaterialPreset.dark

    // ── Pages ──
    readonly property var pages: SettingsPageRegistry.pages.map(p => {
        const entry = Object.assign({}, p)
        entry.component = Quickshell.shellPath(p.component)
        return entry
    })
    property int currentPage: 0
    property bool navEditMode: false
    property bool _navigationInitialized: false
    readonly property bool easyMode: Config.options?.settingsUi?.easyMode ?? false
    readonly property var currentMeta: root.pages[root.currentPage] ?? ({})

    // The nav: groups of the person's arrangement (Settings › Arrange), easy mode keeps the essentials.
    readonly property var navGroups: {
        const out = []
        const cats = SettingsPageRegistry.categories
        for (let c = 0; c < cats.length; ++c) {
            const entries = []
            for (let p = 0; p < cats[c].pages.length; ++p) {
                const index = cats[c].pages[p]
                if (index >= root.pages.length)
                    continue
                if (root.easyMode && root.pages[index].essential !== true)
                    continue
                const entry = Object.assign({}, root.pages[index])
                entry.realIndex = index
                entries.push(entry)
            }
            if (entries.length > 0)
                out.push({ label: cats[c].label, pages: entries })
        }
        return out
    }
    readonly property var navPageOrder: {
        const order = []
        for (const group of root.navGroups)
            for (const page of group.pages)
                order.push(page.realIndex)
        return order
    }

    function nextNavPage(current: int): int {
        const i = root.navPageOrder.indexOf(current)
        if (root.navPageOrder.length === 0)
            return 0
        return i < 0 ? root.navPageOrder[0] : root.navPageOrder[(i + 1) % root.navPageOrder.length]
    }
    function prevNavPage(current: int): int {
        const i = root.navPageOrder.indexOf(current)
        if (root.navPageOrder.length === 0)
            return 0
        return i < 0 ? root.navPageOrder[root.navPageOrder.length - 1]
            : root.navPageOrder[(i - 1 + root.navPageOrder.length) % root.navPageOrder.length]
    }

    function stepNav(forward: bool): void {
        root.currentPage = forward ? root.nextNavPage(root.currentPage) : root.prevNavPage(root.currentPage)
    }
    // The view follows the keyboard: whatever Tab reaches scrolls into its list or page with some air.
    readonly property Item keyed: root.Window.activeFocusItem
    onKeyedChanged: if (root.keyed) Qt.callLater(root.followFocus, root.keyed)
    function followFocus(item: Item): void {
        let scroller = null
        for (let p = item?.parent ?? null; p && p !== root; p = p.parent)
            if (p.contentItem !== undefined && p.contentY !== undefined && p.flickableDirection !== undefined) { scroller = p; break }
        if (!scroller || !item.visible || scroller.contentHeight <= scroller.height) return
        const top = item.mapToItem(scroller.contentItem, 0, 0).y
        const air = 24
        if (top - air < scroller.contentY) scroller.contentY = Math.max(0, top - air)
        else if (top + item.height + air > scroller.contentY + scroller.height)
            scroller.contentY = Math.min(scroller.contentHeight - scroller.height, top + item.height + air - scroller.height)
    }

    // A page by number, then a part of it by name (`inir settingsNav open bar modules`).
    function openPage(index: int, section: string): void {
        if (index >= 0 && index < root.pages.length)
            root.currentPage = index
        if (!section || section.length === 0)
            return
        root.resetSearchTarget()
        root.pendingSpotlightTask = section
        root.pendingSpotlightPageIndex = root.currentPage
        root.spotlightRetryCount = 0
        spotlightPageLoadTimer.restart()
    }

    function _persistPage(): void {
        if (root._navigationInitialized && Persistent.ready && Persistent.states?.settings)
            Persistent.states.settings.iiPage = Math.max(0, Math.min(root.currentPage, root.pages.length - 1))
    }
    function initializeNavigation(): void {
        if (root._navigationInitialized || !Persistent.ready)
            return
        const persisted = Persistent.states?.settings?.iiPage ?? 0
        root.currentPage = Math.max(0, Math.min(persisted, root.pages.length - 1))
        root._navigationInitialized = true
    }
    onCurrentPageChanged: root._persistPage()
    Component.onCompleted: root.initializeNavigation()
    Connections {
        target: Persistent
        function onReadyChanged() { root.initializeNavigation() }
    }
    onEasyModeChanged: {
        if (root.easyMode && root.currentMeta.essential !== true)
            root.currentPage = root.navPageOrder[0] ?? 0
        if (root.searchText.length > 0)
            root.recomputeSearch()
    }

    // ── Search ──
    property string searchText: ""
    property var searchResults: []
    property int selectedResult: 0
    property var searchTargetControl: null
    onSearchTextChanged: {
        root.selectedResult = 0
        searchDebounce.restart()
    }
    Timer {
        id: searchDebounce
        interval: 120
        onTriggered: root.recomputeSearch()
    }

    function recomputeSearch(): void {
        const q = String(root.searchText || "").toLowerCase().trim()
        if (!q.length) {
            root.searchResults = []
            return
        }
        const family = Config.options?.panelFamily ?? "ii"
        const allowed = index => SettingsPageRegistry.searchable(index, family)
            && !(root.easyMode && index >= 0 && index < root.pages.length && root.pages[index].essential !== true)
        let results = SettingsSearchRegistry.buildStaticResults(root.searchText, SettingsPageRegistry.searchIndex())
            .filter(entry => {
                const f = String(entry.panelFamily || "")
                return (f.length === 0 || f === family) && allowed(entry.pageIndex)
            })
        if (typeof SettingsSearchRegistry !== "undefined") {
            // live controls first: they land on the row itself
            const live = SettingsSearchRegistry.buildResults(root.searchText).filter(r => allowed(r.pageIndex))
            for (const r of live)
                r.score = (r.score || 0) + 2000
            results = results.concat(live)
        }
        results.sort((a, b) => b.score - a.score)
        const seen = {}
        const unique = []
        for (const r of results) {
            const key = [r.pageIndex, r.task || "", r.section || "", r.label || ""].join("|").toLowerCase()
            if (seen[key] === undefined) {
                seen[key] = { index: unique.length, hasOptionId: r.optionId !== undefined }
                unique.push(r)
            } else if (r.optionId !== undefined && !seen[key].hasOptionId) {
                unique[seen[key].index] = r
                seen[key].hasOptionId = true
            }
        }
        root.searchResults = unique.slice(0, 40)
    }

    property int pendingSpotlightOptionId: -1
    property string pendingSpotlightLabel: ""
    property string pendingSpotlightSection: ""
    property string pendingSpotlightTask: ""
    property int pendingSpotlightPageIndex: -1
    property bool pendingSpotlightIsSection: false
    property int spotlightRetryCount: 0
    readonly property int spotlightMaxRetries: 15

    function openSearchResult(entry): void {
        root.searchText = ""
        searchField.text = ""
        root.resetSearchTarget()
        if (!entry || entry.pageIndex === undefined || entry.pageIndex < 0)
            return
        root.pendingSpotlightOptionId = entry.optionId !== undefined ? entry.optionId : -1
        root.pendingSpotlightLabel = entry.label || ""
        root.pendingSpotlightSection = entry.section || ""
        root.pendingSpotlightTask = entry.task || ""
        root.pendingSpotlightPageIndex = entry.pageIndex
        root.pendingSpotlightIsSection = entry.optionId === undefined && entry.isSection === true
        root.currentPage = entry.pageIndex
        if (root.pendingSpotlightOptionId >= 0 || root.pendingSpotlightLabel.length > 0 || root.pendingSpotlightTask.length > 0) {
            root.spotlightRetryCount = 0
            spotlightPageLoadTimer.restart()
        }
    }

    Timer {
        id: spotlightPageLoadTimer
        interval: 150
        onTriggered: root.trySpotlight()
    }

    function trySpotlight(): void {
        const pageItem = pagesHost.currentItem
        let taskActivated = false
        if (pageItem && pagesHost.currentIndex === root.pendingSpotlightPageIndex) {
            const task = root.pendingSpotlightTask.length > 0 ? root.pendingSpotlightTask : root.pendingSpotlightSection
            if (task.length > 0)
                taskActivated = SettingsSearchRegistry.activatePageSection(pageItem, task)
        }
        if (taskActivated && root.pendingSpotlightOptionId < 0
                && root.pendingSpotlightLabel.length === 0 && root.pendingSpotlightSection.length === 0) {
            root.resetSearchTarget()
            return
        }
        let control = null
        if (root.pendingSpotlightOptionId >= 0)
            control = SettingsSearchRegistry.getControlById(root.pendingSpotlightOptionId)
        if (!control && pageItem)
            control = SettingsSearchRegistry.findLoadedTarget(pageItem, root.pendingSpotlightLabel,
                root.pendingSpotlightSection, root.pendingSpotlightIsSection)
        if (!control && pageItem && root.pendingSpotlightSection.length > 0
                && root.spotlightRetryCount < root.spotlightMaxRetries
                && SettingsSearchRegistry.revealLoadedSection(pageItem, root.pendingSpotlightSection)) {
            root.spotlightRetryCount++
            spotlightPageLoadTimer.restart()
            return
        }
        if (control) {
            root.navigateToControl(control)
        } else if (root.spotlightRetryCount < root.spotlightMaxRetries) {
            root.spotlightRetryCount++
            spotlightPageLoadTimer.restart()
        } else {
            root.resetSearchTarget()
        }
    }

    // Scrolls the row into the middle of the page and rings it for a moment: the eye lands where the search sent it.
    function navigateToControl(control): void {
        SettingsSearchRegistry.activateTaskSectionForControl(control)
        SettingsSearchRegistry.expandSectionForControl(control)
        let flick = control.parent
        while (flick && !(flick.hasOwnProperty("contentY") && flick.hasOwnProperty("contentItem")))
            flick = flick.parent
        if (flick) {
            const y = control.mapToItem(flick.contentItem, 0, 0).y
            const target = y - flick.height / 2 + control.height / 2
            flick.contentY = Math.max(0, Math.min(target, Math.max(0, flick.contentHeight - flick.height)))
        }
        root.resetSearchTarget()
        root.searchTargetControl = control
        landedRing.show(control)
    }

    function resetSearchTarget(): void {
        root.searchTargetControl = null
        root.pendingSpotlightOptionId = -1
        root.pendingSpotlightLabel = ""
        root.pendingSpotlightSection = ""
        root.pendingSpotlightTask = ""
        root.pendingSpotlightPageIndex = -1
        root.pendingSpotlightIsSection = false
    }

    // Esc backs out one step: the search, the arrangement, then Settings.
    function back(): void {
        if (root.searchText.length > 0) {
            searchField.text = ""
            root.searchText = ""
        } else if (root.navEditMode) {
            root.navEditMode = false
        } else {
            root.closeRequested()
        }
    }
    function focusSearch(): void {
        searchField.forceActiveFocus()
        searchField.selectAll()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.back()
            event.accepted = true
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
            root.focusSearch()
            event.accepted = true
        } else if (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab)) {
            root.currentPage = root.nextNavPage(root.currentPage)
            event.accepted = true
        } else if (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab)) {
            root.currentPage = root.prevNavPage(root.currentPage)
            event.accepted = true
        } else if (event.text.length === 1 && event.text.charCodeAt(0) > 32 && event.text.charCodeAt(0) !== 127
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            // Typing anywhere searches, as in GNOME Settings: the first letter lands in the field instead of nowhere.
            searchField.forceActiveFocus()
            searchField.insert(searchField.cursorPosition, event.text)
            event.accepted = true
        }
    }

    // ── Each page's colour: fixed hues, so a page is found by colour and place before its name is read ──
    readonly property var _pageHues: ({
        "quick": "blue", "hub": "orange", "themes": "purple", "effects": "teal", "wallpaper": "pink",
        "widgets": "yellow", "ricelin": "green", "bar": "orange", "iris": "pink", "shell-layout": "blue",
        "orbit": "purple", "panels": "green", "waffle-style": "blue", "dock": "teal", "sidebars": "yellow",
        "dashboard": "blue", "workspace-strip": "purple", "modules": "yellow", "compositor": "blue",
        "monitors": "teal", "system": "gray", "services": "teal", "tools": "orange", "autostart": "green",
        "ai": "yellow", "mascot": "pink", "advanced": "gray", "arrange": "gray", "shortcuts": "purple",
        "about": "gray"
    })
    readonly property var _hueColors: root.dark ? ({
        "blue": ["#a8c7fa", "#062e6f"], "green": ["#a8dab5", "#0d3b1f"], "orange": ["#ffb68a", "#4a1f00"],
        "pink": ["#ffb0c8", "#4a0b26"], "purple": ["#d0bcff", "#2a1360"], "yellow": ["#f2d675", "#3a2f00"],
        "teal": ["#8ed0d0", "#003737"], "gray": ["#c4c7c5", "#2d312f"]
    }) : ({
        "blue": ["#d3e3fd", "#041e49"], "green": ["#c4eed0", "#072711"], "orange": ["#ffdbc9", "#331200"],
        "pink": ["#ffd8e4", "#3e001d"], "purple": ["#e9ddff", "#22005d"], "yellow": ["#ffe08b", "#241a00"],
        "teal": ["#b2f0ef", "#002020"], "gray": ["#e1e3e1", "#191c1b"]
    })
    function hueOf(key: string): var {
        return root._hueColors[root._pageHues[key] ?? "gray"] ?? root._hueColors["gray"]
    }

    component PageBadge: Rectangle {
        id: badge
        property string pageKey: ""
        property string icon: ""
        property real iconRotation: 0
        property int size: 36
        readonly property var hue: root.hueOf(badge.pageKey)
        implicitWidth: badge.size
        implicitHeight: badge.size
        radius: badge.size / 2
        color: badge.hue[0]
        MaterialSymbol {
            anchors.centerIn: parent
            text: badge.icon
            iconSize: Math.round(badge.size * 0.56)
            fill: 1
            rotation: badge.iconRotation
            color: badge.hue[1]
        }
    }

    component IconAction: RippleButton {
        id: action
        property string symbol: ""
        property string tip: ""
        implicitWidth: 40
        implicitHeight: 40
        buttonRadius: 20
        colBackground: "transparent"
        colBackgroundHover: SettingsMaterialPreset.tileHoverColor
        colRipple: SettingsMaterialPreset.tilePressColor
        Accessible.name: action.tip
        contentItem: MaterialSymbol {
            text: action.symbol
            iconSize: 22
            color: SettingsMaterialPreset.supportingColor
        }
        StyledToolTip {
            text: action.tip
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Nav pane ──
        Item {
            id: navPane
            Layout.fillHeight: true
            Layout.preferredWidth: root.navEditMode ? 360 : 320

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                anchors.topMargin: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    spacing: 4
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Settings")
                        font.family: Appearance.font.family.title
                        font.pixelSize: Math.round(28 * Appearance.fontSizeScale)
                        color: SettingsMaterialPreset.labelColor
                        elide: Text.ElideRight
                    }
                    IconAction {
                        symbol: root.navEditMode ? "done" : "edit"
                        tip: root.navEditMode ? Translation.tr("Done arranging") : Translation.tr("Arrange this list")
                        toggled: root.navEditMode
                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                        onClicked: root.navEditMode = !root.navEditMode
                    }
                    IconAction {
                        visible: !root.windowed
                        symbol: "open_in_new"
                        tip: Translation.tr("Open as a window")
                        onClicked: root.windowRequested(root.currentPage)
                    }
                }

                // Search: the fastest way to any setting, so it sits first and takes Ctrl+F.
                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: height / 2
                    color: searchField.activeFocus ? SettingsMaterialPreset.controlHoverColor : SettingsMaterialPreset.controlColor
                    border.width: searchField.activeFocus ? 2 : 0
                    border.color: SettingsMaterialPreset.subheaderColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: searchField.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 12
                        MaterialSymbol {
                            text: "search"
                            iconSize: 22
                            color: SettingsMaterialPreset.supportingColor
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            StyledTextInput {
                                id: searchField
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: SettingsMaterialPreset.labelSize
                                color: SettingsMaterialPreset.labelColor
                                clip: true
                                onTextChanged: root.searchText = text
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Down) {
                                        root.selectedResult = Math.min(root.selectedResult + 1, root.searchResults.length - 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        root.selectedResult = Math.max(root.selectedResult - 1, 0)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.searchResults.length > 0)
                                            root.openSearchResult(root.searchResults[root.selectedResult])
                                        event.accepted = true
                                    }
                                }
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchField.text.length === 0
                                text: Translation.tr("Search settings")
                                font.pixelSize: SettingsMaterialPreset.labelSize
                                color: SettingsMaterialPreset.supportingColor
                            }
                        }
                        Rectangle {
                            visible: searchField.text.length === 0 && !searchField.activeFocus
                            implicitWidth: keyHint.implicitWidth + 14
                            implicitHeight: 24
                            radius: 6
                            color: "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant
                            Layout.rightMargin: 6
                            StyledText {
                                id: keyHint
                                anchors.centerIn: parent
                                text: "Ctrl F"
                                font.pixelSize: Math.round(12 * Appearance.fontSizeScale)
                                color: SettingsMaterialPreset.supportingColor
                            }
                        }
                        IconAction {
                            visible: searchField.text.length > 0
                            symbol: "close"
                            tip: Translation.tr("Clear the search")
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }

                // The list: each group of the arrangement is one segmented run.
                Flickable {
                    id: navFlick
                    visible: !root.navEditMode
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: navColumn.implicitHeight + 16
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: StyledScrollBar {}
                    // The rail is one Tab stop (thirty stood between the search and the page): the open page wears the
                    // ring, ↑ ↓ open the page above or below.
                    activeFocusOnTab: true
                    Accessible.role: Accessible.List
                    Accessible.name: Translation.tr("Pages")
                    Keys.onUpPressed: root.stepNav(false)
                    Keys.onDownPressed: root.stepNav(true)

                    ColumnLayout {
                        id: navColumn
                        width: navFlick.width - 4
                        spacing: 0

                        Repeater {
                            model: root.navGroups
                            delegate: ColumnLayout {
                                id: navGroup
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: SettingsMaterialPreset.tileGap

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.topMargin: navGroup.index === 0 ? 4 : 18
                                    Layout.bottomMargin: 6
                                    text: navGroup.modelData.label
                                    font.pixelSize: Math.round(13 * Appearance.fontSizeScale)
                                    font.weight: Font.Medium
                                    color: SettingsMaterialPreset.supportingColor
                                    elide: Text.ElideRight
                                }

                                Repeater {
                                    model: navGroup.modelData.pages
                                    delegate: RippleButton {
                                        id: navItem
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: root.currentPage === navItem.modelData.realIndex
                                        readonly property bool first: navItem.index === 0
                                        readonly property bool last: navItem.index === navGroup.modelData.pages.length - 1
                                        Layout.fillWidth: true
                                        implicitHeight: 52
                                        pressScaleEnabled: false
                                        focusRingInward: true
                                        // the chosen page morphs fully round (M3 Expressive's selected list item)
                                        buttonRadiusTop: navItem.current ? 26 : navItem.first ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                                        buttonRadiusBottom: navItem.current ? 26 : navItem.last ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                                        toggled: navItem.current
                                        colBackground: SettingsMaterialPreset.tileColor
                                        colBackgroundHover: SettingsMaterialPreset.tileHoverColor
                                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                                        colBackgroundToggledHover: CF.ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.92)
                                        colRipple: SettingsMaterialPreset.tilePressColor
                                        colRippleToggled: CF.ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.88)
                                        onClicked: {
                                            root.currentPage = navItem.modelData.realIndex
                                            if (root.searchText.length > 0) {
                                                searchField.text = ""
                                                root.searchText = ""
                                            }
                                        }
                                        Accessible.role: Accessible.PageTab
                                        Accessible.name: navItem.modelData.name
                                        focusPolicy: Qt.NoFocus
                                        focusRingShown: navFlick.activeFocus && navItem.current
                                        onFocusRingShownChanged: if (navItem.focusRingShown) Qt.callLater(root.followFocus, navItem)

                                        contentItem: RowLayout {
                                            spacing: 14
                                            PageBadge {
                                                Layout.leftMargin: 8
                                                pageKey: navItem.modelData.key
                                                icon: navItem.modelData.icon
                                                iconRotation: navItem.modelData.iconRotation ?? 0
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: navItem.modelData.name
                                                font.pixelSize: SettingsMaterialPreset.labelSize
                                                font.weight: navItem.current ? Font.Medium : Font.Normal
                                                color: navItem.current ? Appearance.colors.colOnSecondaryContainer : SettingsMaterialPreset.labelColor
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: navEditLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 8
                    active: root.navEditMode
                    visible: active
                    sourceComponent: SettingsNavEditPane {
                        currentPage: root.currentPage
                        onPageActivated: pageIndex => root.currentPage = pageIndex
                        onPageHidden: pageIndex => {
                            if (root.currentPage === pageIndex)
                                Qt.callLater(() => root.currentPage = root.navPageOrder[0] ?? 0)
                        }
                        onDoneRequested: root.navEditMode = false
                    }
                }
            }
        }

        // ── The page ──
        Item {
            id: contentPane
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Item {
                id: pageHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: headerColumn.implicitHeight + 36

                ColumnLayout {
                    id: headerColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 40
                    anchors.rightMargin: 72
                    anchors.topMargin: 28
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: root.searchText.length > 0 ? Translation.tr("Search") : (root.currentMeta.name ?? "")
                        font.family: Appearance.font.family.title
                        font.pixelSize: Math.round(36 * Appearance.fontSizeScale)
                        color: SettingsMaterialPreset.labelColor
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.searchText.length > 0
                            ? (root.searchResults.length > 0
                                ? Translation.tr("%1 settings match \"%2\"").arg(root.searchResults.length).arg(root.searchText.trim())
                                : Translation.tr("Nothing matches \"%1\"").arg(root.searchText.trim()))
                            : (root.currentMeta.desc ?? "")
                        font.pixelSize: SettingsMaterialPreset.supportingSize
                        color: SettingsMaterialPreset.supportingColor
                        elide: Text.ElideRight
                    }
                }

                IconAction {
                    visible: !root.windowed
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 16
                    anchors.topMargin: 16
                    symbol: "close"
                    tip: Translation.tr("Close (Esc)")
                    onClicked: root.closeRequested()
                }
            }

            SettingsPageHost {
                id: pagesHost
                visible: root.searchText.length === 0
                anchors.top: pageHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                pages: root.pages
                requestedIndex: root.currentPage
                loadEnabled: Config.ready && root.active
            }

            SettingsPageLoadingOverlay {
                anchors.fill: pagesHost
                visible: pagesHost.visible
                loading: pagesHost.loading
                text: Translation.tr("Loading page…")
                z: 15
            }

            // Results take the page's place while there is a query: what was typed, where each lands.
            ListView {
                id: resultsList
                visible: root.searchText.length > 0
                anchors.top: pageHeader.bottom
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 40
                width: Math.min(parent.width - 80, SettingsMaterialPreset.pageMaxWidth)
                clip: true
                spacing: SettingsMaterialPreset.tileGap
                model: root.searchResults
                currentIndex: root.selectedResult
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: StyledScrollBar {}
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: RippleButton {
                    id: result
                    required property var modelData
                    required property int index
                    readonly property var page: root.pages[result.modelData.pageIndex] ?? ({})
                    width: resultsList.width
                    implicitHeight: 68
                    pressScaleEnabled: false
                    focusRingInward: true
                    buttonRadiusTop: result.index === 0 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                    buttonRadiusBottom: result.index === resultsList.count - 1 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                    toggled: result.index === root.selectedResult
                    colBackground: SettingsMaterialPreset.tileColor
                    colBackgroundHover: SettingsMaterialPreset.tileHoverColor
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainer
                    colRipple: SettingsMaterialPreset.tilePressColor
                    onClicked: root.openSearchResult(result.modelData)
                    onHoveredChanged: if (hovered) root.selectedResult = result.index

                    contentItem: RowLayout {
                        spacing: 16
                        PageBadge {
                            Layout.leftMargin: 16
                            pageKey: result.page.key ?? ""
                            icon: result.page.icon ?? "settings"
                            iconRotation: result.page.iconRotation ?? 0
                            size: 40
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText {
                                Layout.fillWidth: true
                                text: result.modelData.label || result.modelData.section || result.page.name || ""
                                font.pixelSize: SettingsMaterialPreset.labelSize
                                color: result.toggled ? Appearance.colors.colOnSecondaryContainer : SettingsMaterialPreset.labelColor
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                // where it lands, outermost first
                                text: [result.page.name, result.modelData.section !== result.modelData.label ? result.modelData.section : ""]
                                    .filter(s => s && String(s).length > 0).join("  ›  ")
                                font.pixelSize: SettingsMaterialPreset.supportingSize
                                color: SettingsMaterialPreset.supportingColor
                                elide: Text.ElideRight
                            }
                        }
                        MaterialSymbol {
                            Layout.rightMargin: 16
                            visible: result.toggled
                            text: "keyboard_return"
                            iconSize: 20
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.searchText.length > 0 && root.searchResults.length === 0 && !searchDebounce.running
                anchors.top: pageHeader.bottom
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.topMargin: 24
                spacing: 8
                MaterialSymbol {
                    text: "search_off"
                    iconSize: 40
                    color: SettingsMaterialPreset.supportingColor
                }
                StyledText {
                    text: Translation.tr("Try a shorter word, or what the setting changes: \"blur\", \"clock\", \"dock\".")
                    font.pixelSize: SettingsMaterialPreset.supportingSize
                    color: SettingsMaterialPreset.supportingColor
                }
            }

            // Where a search result landed: a ring that fades on its own.
            Rectangle {
                id: landedRing
                property Item target: null
                function show(item: Item): void {
                    landedRing.target = item
                    landedFade.restart()
                }
                readonly property point at: target ? target.mapToItem(contentPane, 0, 0) : Qt.point(0, 0)
                visible: target !== null && opacity > 0
                x: at.x - 3
                y: at.y - 3
                width: target ? target.width + 6 : 0
                height: target ? target.height + 6 : 0
                radius: SettingsMaterialPreset.tileOuterRadius + 3
                color: "transparent"
                border.width: 3
                border.color: SettingsMaterialPreset.subheaderColor
                opacity: 0
                SequentialAnimation {
                    id: landedFade
                    NumberAnimation { target: landedRing; property: "opacity"; to: 1; duration: 120 }
                    PauseAnimation { duration: 1400 }
                    NumberAnimation { target: landedRing; property: "opacity"; to: 0; duration: 600 }
                    ScriptAction { script: landedRing.target = null }
                }
            }
        }
    }
}
