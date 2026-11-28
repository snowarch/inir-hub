pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.waffle.looks

// Waffle Settings: a mica window, a pane of tinted tiles, a page that rises into place
Item {
    id: root
    
    signal closeRequested()
    
    property var pages: []
    property int currentPage: 0
    property bool loadEnabled: true
    // Parent/child currentPage is bidirectional. Delay child writeback until
    // construction finishes so a persisted or command-line page is not reset
    // by this component's initial default value.
    property bool navigationReady: false
    property string searchText: ""
    property var searchResults: []
    property bool navExpanded: width > Looks.dp(760)

    // Windows' Settings opens with the keyboard in "Find a setting": open it and type.
    Component.onCompleted: Qt.callLater(() => { root.navigationReady = true; searchInput.forceActiveFocus() })
    
    // Every row of every page, read from the pages by dev/tools/generate-waffle-search-index.py: a row is found
    // before its page was ever opened, by its words in the person's language or in English
    FileView {
        id: searchIndexFile
        path: Qt.resolvedUrl("search-index.generated.json")
        blockLoading: true
        printErrors: false
        watchChanges: false
    }
    readonly property var searchIndex: {
        if (!searchIndexFile.loaded)
            return []
        let raw = []
        try {
            raw = JSON.parse(searchIndexFile.text())
        } catch (e) {
            return []
        }
        return raw.filter(e => e.pageIndex >= 0 && e.pageIndex < root.pages.length).map(e => {
            const target = e.targetLabel !== undefined ? e.targetLabel : e.label
            return {
                pageIndex: e.pageIndex,
                pageName: root.pages[e.pageIndex]?.name ?? "",
                section: e.section ? Translation.tr(e.section) : "",
                label: Translation.tr(e.label),
                description: e.description ? Translation.tr(e.description) : "",
                targetLabel: target ? Translation.tr(target) : "",
                sectionSource: e.section || "",
                labelSource: e.label,
                english: [e.label, e.section || "", e.description || ""].join(" ").toLowerCase(),
                keywords: e.keywords ?? []
            }
        })
    }
    
    function highlightTerms(text: string, terms: list<string>): string {
        if (!text || !terms || terms.length === 0) return text;
        var result = text;
        for (var i = 0; i < terms.length; i++) {
            var term = terms[i];
            var idx = result.toLowerCase().indexOf(term.toLowerCase());
            if (idx >= 0) {
                var original = result.substring(idx, idx + term.length);
                result = result.substring(0, idx) + "<b>" + original + "</b>" + result.substring(idx + term.length);
            }
        }
        return result;
    }
    
    function recomputeSearchResults(): void {
        var q = String(searchText || "").toLowerCase().trim();
        if (!q.length) {
            searchResults = [];
            return;
        }
        
        var terms = q.split(/\s+/).filter(t => t.length > 0);
        var results = [];
        
        // Runtime gate checks — items inside conditionally-visible sections
        var clockEnabled = Config.options?.waffles?.background?.widgets?.clock?.enable ?? false
        var blurEnabled = Config.options?.waffles?.background?.effects?.enableBlur ?? false
        var backdropEnabled = Config.options?.waffles?.background?.backdrop?.enable ?? true
        var vignetteEnabled = Config.options?.waffles?.background?.backdrop?.vignetteEnabled ?? false
        
        for (var i = 0; i < searchIndex.length; i++) {
            var entry = searchIndex[i];
            
            // Skip Desktop Clock sub-options when the clock is disabled.
            if (entry.sectionSource === "Desktop Clock" && entry.labelSource !== "Enable clock" && !clockEnabled) {
                continue;
            }
            
            // Skip "Blur radius" when blur is disabled (it's hidden by visible: in the card).
            if (entry.sectionSource === "Wallpaper Effects" && entry.labelSource === "Blur radius" && !blurEnabled) {
                continue;
            }
            
            // Skip Backdrop sub-options (anything except "Enable backdrop") when backdrop is disabled.
            if (entry.sectionSource === "Backdrop (Overview)" && entry.labelSource !== "Enable backdrop" && !backdropEnabled) {
                continue;
            }
            
            // Skip vignette sub-options when vignette is disabled.
            if (entry.sectionSource === "Backdrop (Overview)" && (entry.labelSource === "Vignette intensity" || entry.labelSource === "Vignette radius") && !vignetteEnabled) {
                continue;
            }
            
            var label = (entry.label || "").toLowerCase();
            var section = (entry.section || "").toLowerCase();
            var page = (entry.pageName || "").toLowerCase();
            var kw = (entry.keywords || []).join(" ").toLowerCase();
            // "wifi" finds "Wi-Fi"
            var about = (entry.description || "").toLowerCase().replace(/-/g, "");
            var english = (entry.english || "").replace(/-/g, "");
            
            var matchCount = 0;
            var score = 0;
            
            for (var j = 0; j < terms.length; j++) {
                var term = terms[j];
                if (label.indexOf(term) >= 0 || section.indexOf(term) >= 0 || page.indexOf(term) >= 0
                    || kw.indexOf(term) >= 0 || about.indexOf(term) >= 0 || english.indexOf(term) >= 0) {
                    matchCount++;
                    if (label.indexOf(term) === 0) score += 800;
                    else if (label.indexOf(term) > 0) score += 400;
                    if (kw.indexOf(term) >= 0) score += 300;
                    if (section.indexOf(term) >= 0) score += 200;
                    if (about.indexOf(term) >= 0) score += 60;
                }
            }
            // the row named exactly what was typed leads ("show notifications" before "show reload notifications")
            if (label === q)
                score += 1500;
            else if (label.indexOf(q) >= 0)
                score += 600;
            // a page's own entry follows its rows; the rows answer the question
            if (!entry.targetLabel && !entry.section)
                score -= 100;
            
            if (matchCount === terms.length) {
                results.push({
                    pageIndex: entry.pageIndex,
                    pageName: entry.pageName,
                    section: entry.section,
                    label: entry.label,
                    labelHighlighted: highlightTerms(entry.label, terms),
                    targetLabel: entry.targetLabel || "",
                    score: score
                });
            }
        }
        
        // Also search in dynamic registry if available
        if (typeof SettingsSearchRegistry !== "undefined") {
            var widgetResults = SettingsSearchRegistry.buildResults(searchText);
            results = results.concat(widgetResults);
        }
        
        results.sort((a, b) => b.score - a.score);
        
        // Remove duplicates
        var seen = {};
        var unique = [];
        for (var k = 0; k < results.length; k++) {
            var key = (results[k].label || "") + "|" + results[k].pageIndex;
            if (!seen[key]) {
                seen[key] = true;
                unique.push(results[k]);
            }
        }
        
        searchResults = unique.slice(0, 30);
    }
    
    function openSearchResult(entry: var): void {
        if (entry && entry.pageIndex !== undefined && entry.pageIndex >= 0) {
            root.landingCategory = -1;
            currentPage = entry.pageIndex;
            
            // Focus option - try optionId first (dynamic registry), then targetLabel (static index)
            if (typeof SettingsSearchRegistry !== "undefined") {
                if (entry.optionId !== undefined) {
                    // Dynamic registry entry - use optionId
                    const optionId = entry.optionId;
                    Qt.callLater(() => {
                        SettingsSearchRegistry.focusOption(optionId);
                    });
                } else if (entry.targetLabel) {
                    // Static index entry - find widget by label after page loads
                    const targetLabel = entry.targetLabel;
                    spotlightTimer.targetLabel = targetLabel;
                    spotlightTimer.restart();
                }
            }
        }
        
        searchText = "";
        searchInput.text = "";
    }
    
    // Timer to wait for page load before focusing target
    Timer {
        id: spotlightTimer
        interval: 100
        repeat: true
        property string targetLabel: ""
        property int retries: 0
        property int maxRetries: 60  // a heavy page (Mascot's poses) takes over 2 s to build in a slow session
        
        onTriggered: {
            if (!targetLabel || typeof SettingsSearchRegistry === "undefined") {
                stop();
                return;
            }
            
            // Find entry by label in registry
            var entries = SettingsSearchRegistry.entries;
            
            for (var i = 0; i < entries.length; i++) {
                if (entries[i].label === targetLabel && entries[i].pageIndex === root.currentPage) {
                    SettingsSearchRegistry.focusOption(entries[i].id);
                    retries = 0;
                    stop();
                    return;
                }
            }
            
            // Retry until found or max retries
            retries++;
            if (retries >= maxRetries) {
                retries = 0;
                stop();
            }
        }
    }
    
    // ── Windows 11 Settings: categories in the pane, pages inside them, a breadcrumb over the page ──
    property var categories: []
    // a category's own page (its pages as link cards) while >= 0
    property int landingCategory: -1
    function categoryOf(page: int): int {
        for (let i = 0; i < root.categories.length; ++i)
            if (root.categories[i].pages.indexOf(page) >= 0)
                return i
        return -1
    }
    readonly property int activeCategory: root.landingCategory >= 0 ? root.landingCategory : root.categoryOf(root.currentPage)
    function openCategory(index: int): void {
        const cat = root.categories[index]
        if (!cat)
            return
        if (cat.pages.length === 1) {
            root.landingCategory = -1
            root.currentPage = cat.pages[0]
        } else {
            root.landingCategory = index
        }
    }
    function openPage(page: int): void {
        root.landingCategory = -1
        root.currentPage = page
    }


    readonly property string titleKey: root.landingCategory + ":" + root.currentPage
    onTitleKeyChanged: {
        titleIn.restart()
        if (root.landingCategory >= 0)
            landingIn.restart()
    }

    // a tile in a category's page: the page's icon on its category's colour, its name, what is inside
    component PageTile: Rectangle {
        id: tile
        property int page: -1
        property var category: null
        readonly property color tint: tile.category ? (Looks.dark ? tile.category.tintDark : tile.category.tint) : Looks.colors.accent
        Layout.fillWidth: true
        implicitHeight: Looks.dp(80)
        radius: Looks.settings.radiusMedium
        color: tileMouse.pressed ? Looks.settings.cardPressed : tileMouse.containsMouse ? Looks.settings.cardHover : Looks.settings.card
        border.width: 1
        border.color: Looks.settings.cardStroke
        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? 90 : 0 }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Looks.dp(16)
            anchors.rightMargin: Looks.dp(16)
            spacing: Looks.dp(14)
            Rectangle {
                implicitWidth: Looks.dp(42)
                implicitHeight: Looks.dp(42)
                radius: Looks.dp(12)
                color: Qt.alpha(tile.tint, Looks.dark ? 0.18 : 0.13)
                FluentIcon {
                    anchors.centerIn: parent
                    icon: root.pages[tile.page]?.icon ?? ""
                    filled: true
                    implicitSize: Looks.dp(20)
                    color: tile.tint
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Looks.dp(2)
                WText {
                    Layout.fillWidth: true
                    text: root.pages[tile.page]?.name ?? ""
                    font.pixelSize: Looks.settings.body
                    font.weight: Looks.font.weight.strong
                    elide: Text.ElideRight
                }
                WText {
                    Layout.fillWidth: true
                    text: root.pages[tile.page]?.desc ?? ""
                    font.pixelSize: Looks.settings.caption
                    color: Looks.colors.subfg
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
            FluentIcon {
                icon: "chevron-right"
                implicitSize: Looks.dp(14)
                color: Looks.colors.subfg
                transform: Translate { x: tileMouse.containsMouse ? Looks.dp(3) : 0
                    Behavior on x { animation: NumberAnimation { duration: Looks.transition.enabled ? 160 : 0; easing.type: Easing.OutCubic } }
                }
            }
        }
        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openPage(tile.page)
        }
    }

    // one half of the light and dark pill
    component ModeHalf: Item {
        id: modeHalf
        property bool dark: false
        property string icon: ""
        property string label: ""
        readonly property bool chosen: Looks.dark === modeHalf.dark
        implicitWidth: modeLabel.implicitWidth + Looks.dp(42)
        implicitHeight: Looks.dp(26)
        RowLayout {
            anchors.centerIn: parent
            spacing: Looks.dp(6)
            FluentIcon {
                icon: modeHalf.icon
                implicitSize: Looks.dp(14)
                color: modeHalf.chosen ? Looks.colors.accentFg : Looks.colors.fg
            }
            WText {
                id: modeLabel
                text: modeHalf.label
                font.pixelSize: Looks.settings.body
                color: modeHalf.chosen ? Looks.colors.accentFg : Looks.colors.fg
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: MaterialThemeLoader.setDarkMode(modeHalf.dark)
        }
    }

    // a small button of the frame: accent or quiet, or the chosen half of a pair
    component PillButton: Rectangle {
        id: pb
        property string text: ""
        property string icon: ""
        property bool accent: false
        property bool chosen: false
        signal clicked()
        implicitWidth: pbRow.implicitWidth + Looks.dp(28)
        implicitHeight: Looks.dp(34)
        radius: height / 2
        readonly property bool lit: pb.accent || pb.chosen
        color: pb.lit
            ? (pbMouse.pressed ? Looks.colors.accentActive : pbMouse.containsMouse ? Looks.colors.accentHover : Looks.colors.accent)
            : (pbMouse.pressed ? Looks.settings.tilePressed : pbMouse.containsMouse ? Looks.settings.tileHover : Looks.settings.tile)
        border.width: pb.lit ? 0 : 1
        border.color: Looks.settings.cardStroke
        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? 90 : 0 }
        }
        scale: pbMouse.pressed ? 0.97 : 1
        Behavior on scale {
            animation: NumberAnimation { duration: Looks.transition.enabled ? 140 : 0; easing.type: Easing.OutCubic }
        }
        RowLayout {
            id: pbRow
            anchors.centerIn: parent
            spacing: Looks.dp(8)
            FluentIcon {
                visible: pb.icon !== ""
                icon: pb.icon
                implicitSize: Looks.dp(15)
                color: pb.lit ? Looks.colors.accentFg : Looks.colors.fg
            }
            WText {
                text: pb.text
                font.pixelSize: Looks.settings.body
                font.weight: pb.lit ? Looks.font.weight.strong : Looks.font.weight.regular
                color: pb.lit ? Looks.colors.accentFg : Looks.colors.fg
            }
        }
        MouseArea {
            id: pbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }

    // the window: deeper than the cards, with the accent's light pooled in a corner
    Rectangle {
        anchors.fill: parent
        color: Looks.settings.canvas
    }
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width * 0.7
        height: Looks.dp(260)
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Qt.alpha(Looks.colors.accent, Looks.dark ? 0.07 : 0.06) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── The pane: the app's mark, the person, a search, and the categories as tinted tiles ──
        Item {
            id: navPane
            Layout.fillHeight: true
            Layout.preferredWidth: root.navExpanded ? Looks.dp(304) : Looks.dp(68)
            clip: true

            Behavior on Layout.preferredWidth {
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.slow : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
            }

            Rectangle {
                anchors.fill: parent
                color: Looks.settings.pane
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Looks.settings.cardStroke
            }

            ColumnLayout {
                id: paneColumn
                anchors {
                    fill: parent
                    topMargin: Looks.dp(14)
                    bottomMargin: Looks.dp(10)
                    leftMargin: Looks.dp(12)
                    rightMargin: Looks.dp(12)
                }
                spacing: Looks.dp(8)

                // the app's mark and name, and the way out
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Looks.dp(8)
                    Layout.preferredHeight: Looks.dp(32)
                    spacing: Looks.dp(10)
                    Rectangle {
                        implicitWidth: Looks.dp(28)
                        implicitHeight: Looks.dp(28)
                        radius: Looks.dp(8)
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.lighter(Looks.colors.accent, 1.3) }
                            GradientStop { position: 1; color: Looks.colors.accent }
                        }
                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "settings"
                            filled: true
                            implicitSize: Looks.dp(16)
                            color: Looks.colors.accentFg
                        }
                    }
                    WText {
                        visible: root.navExpanded
                        Layout.fillWidth: true
                        text: Translation.tr("Settings")
                        font.pixelSize: Looks.settings.body
                        font.weight: Looks.font.weight.strong
                        elide: Text.ElideRight
                    }
                    WBorderlessButton {
                        visible: root.navExpanded
                        implicitWidth: Looks.dp(32)
                        implicitHeight: Looks.dp(32)
                        onClicked: root.closeRequested()
                        contentItem: FluentIcon {
                            anchors.centerIn: parent
                            icon: "dismiss"
                            implicitSize: Looks.dp(14)
                            color: Looks.colors.subfg
                        }
                    }
                }

                // the person: picture, name, and what this machine runs; it opens About
                Rectangle {
                    id: userCard
                    visible: root.navExpanded
                    Layout.fillWidth: true
                    Layout.topMargin: Looks.dp(6)
                    implicitHeight: Looks.dp(70)
                    radius: Looks.settings.radiusLarge
                    color: userMouse.pressed ? Looks.settings.cardPressed : userMouse.containsMouse ? Looks.settings.cardHover : Looks.settings.card
                    border.width: 1
                    border.color: Looks.settings.cardStroke
                    Behavior on color {
                        animation: ColorAnimation { duration: Looks.transition.enabled ? 90 : 0 }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Looks.dp(12)
                        anchors.rightMargin: Looks.dp(14)
                        spacing: Looks.dp(12)
                        WUserAvatar {
                            sourceSize: Qt.size(Looks.dp(46), Looks.dp(46))
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Looks.dp(1)
                            WText {
                                Layout.fillWidth: true
                                text: SystemInfo.displayName || SystemInfo.username
                                font.pixelSize: Looks.settings.body
                                font.weight: Looks.font.weight.strong
                                elide: Text.ElideRight
                            }
                            WText {
                                Layout.fillWidth: true
                                text: [SystemInfo.distroName, SystemInfo.hostname].filter(t => t && t !== "Unknown").join(" · ")
                                font.pixelSize: Looks.settings.caption
                                color: Looks.colors.subfg
                                elide: Text.ElideRight
                            }
                        }
                        FluentIcon {
                            icon: "chevron-right"
                            implicitSize: Looks.dp(12)
                            color: Looks.colors.subfg
                        }
                    }
                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openCategory(root.categories.length - 1)
                    }
                }

                // Find a setting: a pill that lights with the accent while typed in
                Rectangle {
                    id: searchPill
                    visible: root.navExpanded
                    Layout.fillWidth: true
                    Layout.topMargin: Looks.dp(4)
                    implicitHeight: Looks.dp(38)
                    radius: height / 2
                    color: searchInput.activeFocus ? (Looks.dark ? Looks.settings.cardPressed : Looks.colors.bg0Opaque)
                        : searchHover.hovered ? Looks.settings.cardHover : Looks.settings.card
                    border.width: searchInput.activeFocus ? 2 : 1
                    border.color: searchInput.activeFocus ? Looks.colors.accent : Looks.settings.cardStroke
                    Behavior on border.color {
                        animation: ColorAnimation { duration: Looks.transition.enabled ? 120 : 0 }
                    }
                    HoverHandler { id: searchHover; cursorShape: Qt.IBeamCursor }
                    TapHandler { onTapped: searchInput.forceActiveFocus() }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Looks.dp(14)
                        anchors.rightMargin: Looks.dp(8)
                        spacing: Looks.dp(10)
                        FluentIcon {
                            icon: "search"
                            implicitSize: Looks.dp(15)
                            color: searchInput.activeFocus ? Looks.colors.accent : Looks.colors.subfg
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                cursorDelegate: TextCursor { accent: Looks.colors.accent }
                                color: Looks.colors.fg
                                selectionColor: Looks.colors.accent
                                selectedTextColor: Looks.colors.accentFg
                                font.family: Looks.font.family.ui
                                font.pixelSize: Looks.settings.body
                                clip: true
                                onTextChanged: {
                                    root.searchText = text
                                    root.recomputeSearchResults()
                                    searchResultsList.currentIndex = root.searchResults.length > 0 ? 0 : -1
                                }
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Down && root.searchResults.length > 0) {
                                        searchResultsList.currentIndex = Math.min(searchResultsList.currentIndex + 1, searchResultsList.count - 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up && root.searchResults.length > 0) {
                                        searchResultsList.currentIndex = Math.max(searchResultsList.currentIndex - 1, 0)
                                        event.accepted = true
                                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.searchResults.length > 0) {
                                        root.openSearchResult(root.searchResults[Math.max(0, searchResultsList.currentIndex)])
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape && text.length > 0) {
                                        text = ""
                                        event.accepted = true
                                    }
                                }
                            }
                            WText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text.length === 0
                                text: Translation.tr("Find a setting")
                                font.pixelSize: Looks.settings.body
                                color: Looks.colors.subfg
                            }
                        }
                        // the key that brings you here, until something is typed; then the way to clear it
                        Rectangle {
                            visible: searchInput.text.length === 0
                            implicitWidth: keyHint.implicitWidth + Looks.dp(12)
                            implicitHeight: Looks.dp(22)
                            radius: Looks.dp(6)
                            color: Looks.settings.tile
                            border.width: 1
                            border.color: Looks.settings.cardStroke
                            WText {
                                id: keyHint
                                anchors.centerIn: parent
                                text: "Ctrl F" // literal: the key names on the keyboard
                                font.pixelSize: Looks.settings.caption - 1
                                color: Looks.colors.subfg
                            }
                        }
                        WBorderlessButton {
                            visible: searchInput.text.length > 0
                            implicitWidth: Looks.dp(26)
                            implicitHeight: Looks.dp(26)
                            onClicked: {
                                searchInput.text = ""
                                searchInput.forceActiveFocus()
                            }
                            contentItem: FluentIcon {
                                anchors.centerIn: parent
                                icon: "dismiss"
                                implicitSize: Looks.dp(11)
                                color: Looks.colors.subfg
                            }
                        }
                    }
                }

                // the categories: the chosen one's plate glides to it
                Flickable {
                    id: navFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Looks.dp(6)
                    contentHeight: navColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // one Tab stop, as NavigationView: up and down open the category above or below
                    activeFocusOnTab: true
                    Accessible.role: Accessible.List
                    Keys.onUpPressed: if (root.activeCategory > 0) root.openCategory(root.activeCategory - 1)
                    Keys.onDownPressed: if (root.activeCategory < root.categories.length - 1) root.openCategory(root.activeCategory + 1)

                    Item {
                        id: navColumn
                        width: navFlick.width
                        implicitHeight: navList.implicitHeight

                        Rectangle {
                            id: navIndicator
                            readonly property Item target: {
                                navRepeater.count
                                return navRepeater.itemAt(root.activeCategory)
                            }
                            visible: target !== null
                            width: parent.width
                            y: target ? target.y : 0
                            height: target ? target.height : 0
                            radius: Looks.settings.radiusMedium
                            color: Looks.colors.accentWash
                            Behavior on y {
                                enabled: root.navigationReady
                                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.slow + 60 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: Looks.dp(3)
                                height: Looks.dp(18)
                                radius: width / 2
                                color: Looks.colors.accent
                            }
                        }

                        ColumnLayout {
                            id: navList
                            width: parent.width
                            spacing: Looks.dp(2)

                            Repeater {
                                id: navRepeater
                                model: root.categories

                                Item {
                                    id: navEntry
                                    required property int index
                                    required property var modelData
                                    readonly property bool selected: root.activeCategory === navEntry.index
                                    Layout.fillWidth: true
                                    // the last one (About) stands apart
                                    Layout.topMargin: navEntry.modelData.apart ? Looks.dp(14) : 0
                                    implicitHeight: Looks.dp(42)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Looks.settings.radiusMedium
                                        color: navMouse.pressed ? Looks.settings.tilePressed
                                            : navMouse.containsMouse && !navEntry.selected ? Looks.settings.tile : "transparent"
                                        Behavior on color {
                                            animation: ColorAnimation { duration: Looks.transition.enabled ? 90 : 0 }
                                        }
                                    }
                                    WFocusVisual {
                                        shown: navFlick.activeFocus && navEntry.selected
                                        margin: 0
                                        radius: Looks.settings.radiusMedium
                                    }
                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openCategory(navEntry.index)
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Looks.dp(8)
                                        anchors.rightMargin: Looks.dp(8)
                                        spacing: Looks.dp(12)
                                        // the category's own colour and a white glyph: found by hue at a glance
                                        Rectangle {
                                            implicitWidth: Looks.dp(28)
                                            implicitHeight: Looks.dp(28)
                                            radius: Looks.dp(8)
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: Qt.lighter(navEntry.modelData.tint, 1.25) }
                                                GradientStop { position: 1; color: navEntry.modelData.tint }
                                            }
                                            scale: navMouse.pressed ? 0.9 : 1
                                            Behavior on scale {
                                                animation: NumberAnimation { duration: Looks.transition.enabled ? 180 : 0; easing.type: Easing.OutBack; easing.overshoot: 2 }
                                            }
                                            FluentIcon {
                                                anchors.centerIn: parent
                                                icon: navEntry.modelData.icon
                                                filled: true
                                                implicitSize: Looks.dp(16)
                                                color: "#FFFFFF" // literal: a white glyph on the category's own colour
                                            }
                                        }
                                        WText {
                                            visible: root.navExpanded
                                            Layout.fillWidth: true
                                            text: navEntry.modelData.name
                                            font.pixelSize: Looks.settings.body
                                            font.weight: navEntry.selected ? Looks.font.weight.strong : Looks.font.weight.regular
                                            elide: Text.ElideRight
                                        }
                                    }
                                    WToolTip {
                                        visible: !root.navExpanded && navMouse.containsMouse
                                        text: navEntry.modelData.name
                                    }
                                }
                            }
                        }
                    }
                }

                WBorderlessButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Looks.dp(38)
                    contentItem: RowLayout {
                        spacing: Looks.dp(12)
                        FluentIcon {
                            Layout.leftMargin: Looks.dp(14)
                            icon: root.navExpanded ? "panel-left-contract" : "panel-left-expand"
                            implicitSize: Looks.dp(16)
                            color: Looks.colors.subfg
                        }
                        WText {
                            visible: root.navExpanded
                            Layout.fillWidth: true
                            text: Translation.tr("Collapse")
                            font.pixelSize: Looks.settings.body
                            color: Looks.colors.subfg
                        }
                    }
                    onClicked: root.navExpanded = !root.navExpanded
                }
            }

            // what the search finds, floating over the categories
            Rectangle {
                id: searchResultsDropdown
                readonly property bool shown: root.navExpanded && root.searchText.length > 0
                x: paneColumn.x
                y: paneColumn.y + searchPill.y + searchPill.height + Looks.dp(8)
                z: 10
                width: paneColumn.width
                height: Math.min(root.searchResults.length > 0 ? searchResultsList.contentHeight + Looks.dp(12) : noResultsCol.implicitHeight + Looks.dp(28),
                    navPane.height - y - Looks.dp(16))
                radius: Looks.settings.radiusLarge
                color: Looks.colors.bg0Opaque
                border.width: 1
                border.color: Looks.settings.strokeStrong
                visible: opacity > 0
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.97
                transformOrigin: Item.Top
                Behavior on opacity {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? 140 : 0; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? 220 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                }

                ListView {
                    id: searchResultsList
                    anchors.fill: parent
                    anchors.margins: Looks.dp(6)
                    visible: root.searchResults.length > 0
                    spacing: Looks.dp(2)
                    model: root.searchResults
                    clip: true
                    currentIndex: -1
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: WScrollBar {}

                    delegate: Rectangle {
                        id: resultDelegate
                        required property var modelData
                        required property int index
                        readonly property bool current: resultDelegate.ListView.isCurrentItem
                        width: searchResultsList.width
                        height: Looks.dp(48)
                        radius: Looks.settings.radiusMedium
                        color: resultMouse.pressed ? Looks.settings.tilePressed
                            : resultDelegate.current ? Looks.colors.accentWash
                            : resultMouse.containsMouse ? Looks.settings.tile : "transparent"
                        Behavior on color {
                            animation: ColorAnimation { duration: Looks.transition.enabled ? 80 : 0 }
                        }
                        MouseArea {
                            id: resultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: searchResultsList.currentIndex = resultDelegate.index
                            onClicked: root.openSearchResult(resultDelegate.modelData)
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Looks.dp(10)
                            anchors.rightMargin: Looks.dp(10)
                            spacing: Looks.dp(10)
                            Rectangle {
                                readonly property var cat: root.categories[root.categoryOf(resultDelegate.modelData.pageIndex)] ?? null
                                implicitWidth: Looks.dp(28)
                                implicitHeight: Looks.dp(28)
                                radius: Looks.dp(8)
                                color: Qt.alpha(cat ? (Looks.dark ? cat.tintDark : cat.tint) : Looks.colors.accent, Looks.dark ? 0.18 : 0.13)
                                FluentIcon {
                                    anchors.centerIn: parent
                                    icon: root.pages[resultDelegate.modelData.pageIndex]?.icon || "settings"
                                    filled: true
                                    implicitSize: Looks.dp(15)
                                    color: parent.cat ? (Looks.dark ? parent.cat.tintDark : parent.cat.tint) : Looks.colors.accent
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: resultDelegate.modelData.labelHighlighted || resultDelegate.modelData.label || ""
                                    textFormat: Text.StyledText
                                    font.family: Looks.font.family.ui
                                    font.pixelSize: Looks.settings.body
                                    color: Looks.colors.fg
                                    elide: Text.ElideRight
                                }
                                WText {
                                    Layout.fillWidth: true
                                    text: resultDelegate.modelData.pageName + (resultDelegate.modelData.section ? " › " + resultDelegate.modelData.section : "")
                                    font.pixelSize: Looks.settings.caption
                                    color: Looks.colors.subfg
                                    elide: Text.ElideRight
                                }
                            }
                            FluentIcon {
                                icon: "arrow-enter-left"
                                implicitSize: Looks.dp(13)
                                color: Looks.colors.subfg
                                opacity: resultDelegate.current ? 1 : 0
                                Behavior on opacity {
                                    animation: NumberAnimation { duration: Looks.transition.enabled ? 100 : 0 }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: noResultsCol
                    visible: root.searchResults.length === 0
                    anchors.centerIn: parent
                    width: parent.width - Looks.dp(24)
                    spacing: Looks.dp(6)
                    MascotImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Looks.dp(84)
                        Layout.preferredHeight: Looks.dp(84)
                        pose: "settings-judging"
                        surface: "emptyStates"
                    }
                    WText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Voice.miss(Translation.tr("No results"), root.searchText)
                        font.pixelSize: Looks.settings.caption
                        color: Looks.colors.subfg
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // ── The page: its place in the categories as a title, then its cards ──
        Item {
            id: contentLayer
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property int sidePadding: width < Looks.dp(640) ? Looks.dp(20) : Looks.dp(44)
            readonly property int columnWidth: Math.min(width - sidePadding * 2, Looks.dp(1000))
            // how far the open page has scrolled: the header takes a hairline once it has
            readonly property real pageScroll: {
                if (root.landingCategory >= 0)
                    return landing.contentY
                pageRepeater.count
                const loader = pageRepeater.itemAt(root.currentPage)
                return loader && loader.item && loader.item.contentY !== undefined ? loader.item.contentY : 0
            }

            Item {
                id: header
                z: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: crumbColumn.y + crumbColumn.implicitHeight + Looks.dp(16)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Looks.settings.cardStroke
                    opacity: contentLayer.pageScroll > 2 ? 1 : 0
                    Behavior on opacity {
                        animation: NumberAnimation { duration: Looks.transition.enabled ? 160 : 0 }
                    }
                }

                ColumnLayout {
                    id: crumbColumn
                    x: contentLayer.sidePadding
                    y: Looks.dp(26)
                    width: contentLayer.columnWidth
                    spacing: Looks.dp(4)
                    opacity: 1
                    transform: Translate { id: titleShift }

                    ParallelAnimation {
                        id: titleIn
                        NumberAnimation { target: crumbColumn; property: "opacity"; from: 0.2; to: 1; duration: Looks.transition.enabled ? 260 : 0; easing.type: Easing.OutCubic }
                        NumberAnimation { target: titleShift; property: "x"; from: Looks.dp(-10); to: 0; duration: Looks.transition.enabled ? Looks.transition.duration.page : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                    }

                    // the category, then the page; the category goes back. As WinUI's BreadcrumbBar, a path too long
                    // for the room folds the category into "…", still the way back.
                    RowLayout {
                        id: crumb
                        Layout.fillWidth: true
                        spacing: Looks.dp(12)
                        readonly property var cat: root.categories[root.activeCategory] ?? null
                        readonly property bool nested: crumb.cat !== null && crumb.cat.pages.length > 1 && root.landingCategory < 0
                        readonly property bool folded: {
                            crumbType.font
                            return crumb.nested && crumbType.advanceWidth(crumb.cat.name) + crumbType.advanceWidth(pageCrumb.text)
                                + Looks.dp(16) + 2 * crumb.spacing > crumb.width
                        }
                        FontMetrics { id: crumbType; font: pageCrumb.font }

                        WText {
                            visible: crumb.nested
                            text: crumb.folded ? "…" : crumb.cat ? crumb.cat.name : ""
                            Accessible.name: crumb.cat ? crumb.cat.name : ""
                            font.pixelSize: Looks.settings.title
                            font.weight: Looks.font.weight.strong
                            color: crumbMouse.containsMouse ? Looks.colors.accent : Looks.colors.subfg
                            Behavior on color {
                                animation: ColorAnimation { duration: Looks.transition.enabled ? 100 : 0 }
                            }
                            MouseArea {
                                id: crumbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.landingCategory = root.activeCategory
                            }
                        }
                        FluentIcon {
                            visible: crumb.nested
                            icon: "chevron-right"
                            implicitSize: Looks.dp(16)
                            color: Looks.colors.subfg
                        }
                        WText {
                            id: pageCrumb
                            Layout.fillWidth: true
                            text: root.landingCategory >= 0 ? (crumb.cat ? crumb.cat.name : "")
                                : (root.pages[root.currentPage]?.name ?? "")
                            font.pixelSize: Looks.settings.title
                            font.weight: Looks.font.weight.strong
                            elide: Text.ElideRight
                            Accessible.role: Accessible.Heading
                        }
                    }
                    WText {
                        Layout.fillWidth: true
                        text: root.landingCategory >= 0 ? (crumb.cat?.desc ?? "") : (root.pages[root.currentPage]?.desc ?? "")
                        visible: text.length > 0
                        font.pixelSize: Looks.settings.body
                        color: Looks.colors.subfg
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                id: pageStack
                anchors.fill: parent
                anchors.topMargin: header.height
                visible: root.landingCategory < 0

                // Keep only the active page alive. Search navigates to an unloaded page and the targetLabel focus
                // retry waits for it to register its controls.
                property int keepRadius: 0

                Repeater {
                    id: pageRepeater
                    model: root.pages.length

                    Loader {
                        id: pageLoader
                        required property int index
                        anchors.fill: parent
                        active: root.loadEnabled && Math.abs(index - root.currentPage) <= pageStack.keepRadius
                        asynchronous: index !== root.currentPage
                        source: root.pages[index].component
                        visible: index === root.currentPage && status === Loader.Ready
                        // Disabled pages must not intercept mouse events
                        enabled: visible
                        // the header above says the page's name: the page drops its own
                        onLoaded: if (item && item.hasOwnProperty("showHeader")) {
                            item.showHeader = false
                            item.sidePadding = Qt.binding(() => contentLayer.sidePadding)
                        }

                        Connections {
                            target: pageLoader.item
                            ignoreUnknownSignals: true
                            function onNavigateRequested(pageIndex) {
                                if (pageIndex < 0 || pageIndex >= root.pages.length)
                                    return
                                root.openPage(pageIndex)
                            }
                        }
                    }
                }
            }

            // a category's page: the desktop or the machine at a glance, then each page as a tile
            Flickable {
                id: landing
                anchors.fill: parent
                anchors.topMargin: header.height
                visible: root.landingCategory >= 0
                clip: true
                contentHeight: landingColumn.implicitHeight + Looks.dp(40)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: WScrollBar {}

                ColumnLayout {
                    id: landingColumn
                    x: contentLayer.sidePadding
                    y: Looks.dp(4)
                    width: contentLayer.columnWidth
                    spacing: Looks.dp(20)
                    transform: Translate { id: landingShift }

                    ParallelAnimation {
                        id: landingIn
                        NumberAnimation { target: landingColumn; property: "opacity"; from: 0; to: 1; duration: Looks.transition.enabled ? 260 : 0; easing.type: Easing.OutCubic }
                        NumberAnimation { target: landingShift; property: "y"; from: Looks.dp(18); to: 0; duration: Looks.transition.enabled ? Looks.transition.duration.page : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                    }

                    Rectangle {
                        id: hero
                        readonly property string kind: root.landingCategory >= 0 ? (root.categories[root.landingCategory].hero ?? "") : ""
                        visible: hero.kind !== ""
                        Layout.fillWidth: true
                        implicitHeight: heroRow.implicitHeight + Looks.dp(40)
                        radius: Looks.settings.radiusXLarge
                        color: Looks.settings.card
                        border.width: 1
                        border.color: Looks.settings.cardStroke
                        clip: true

                        // the accent's light behind the desktop
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.alpha(Looks.colors.accent, Looks.dark ? 0.14 : 0.10) }
                                GradientStop { position: 0.6; color: "transparent" }
                            }
                        }

                        RowLayout {
                            id: heroRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Looks.dp(20)
                            spacing: Looks.dp(28)

                            // the desktop at a glance: the wallpaper, and the taskbar floating where it sits
                            Rectangle {
                                readonly property real span: landingColumn.width > Looks.dp(820) ? Looks.dp(288) : Looks.dp(208)
                                Layout.preferredWidth: span
                                Layout.preferredHeight: Math.round(span * 9 / 16)
                                radius: Looks.dp(12)
                                color: Looks.colors.bg0Opaque
                                border.width: 4
                                border.color: Looks.dark ? Looks.settings.pane : Looks.colors.bg0Opaque
                                clip: true
                                StyledImage {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectCrop
                                    source: hero.visible ? Wallpapers.effectiveWallpaperUrl : ""
                                    sourceSize.width: 580
                                    asynchronous: true
                                    cache: false
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: (Config.options?.waffles?.bar?.bottom ?? true) ? parent.height - height - Looks.dp(10) : Looks.dp(10)
                                    width: Looks.dp(96)
                                    height: Looks.dp(14)
                                    radius: Looks.dp(5)
                                    color: Qt.alpha(Looks.colors.bg1Base, 0.92)
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Looks.dp(4)
                                        Repeater {
                                            model: 6
                                            Rectangle {
                                                required property int index
                                                width: Looks.dp(7)
                                                height: Looks.dp(7)
                                                radius: Looks.dp(2)
                                                color: index === 0 ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, 0.55)
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: Looks.dp(6)

                                WText {
                                    Layout.fillWidth: true
                                    text: hero.kind === "system" ? (SystemInfo.hostname || SystemInfo.distroName) : Translation.tr("Your desktop")
                                    font.pixelSize: Looks.settings.subtitle + Looks.dp(2)
                                    font.weight: Looks.font.weight.strong
                                    elide: Text.ElideRight
                                }
                                WText {
                                    Layout.fillWidth: true
                                    text: hero.kind === "system"
                                        ? [SystemInfo.distroName, SystemInfo.windowingSystem].filter(t => t && t !== "Unknown").join(" · ")
                                        : decodeURIComponent(String(Wallpapers.effectiveWallpaperUrl).split("/").pop() || "")
                                    font.pixelSize: Looks.settings.body
                                    color: Looks.colors.subfg
                                    elide: Text.ElideMiddle
                                }
                                // each screen, as a chip
                                Flow {
                                    visible: hero.kind === "system"
                                    Layout.fillWidth: true
                                    Layout.topMargin: Looks.dp(8)
                                    spacing: Looks.dp(6)
                                    Repeater {
                                        model: hero.kind === "system" ? Array.from(Quickshell.screens) : []
                                        Rectangle {
                                            id: screenChip
                                            required property var modelData
                                            implicitWidth: chipRow.implicitWidth + Looks.dp(20)
                                            implicitHeight: Looks.dp(28)
                                            radius: height / 2
                                            color: Looks.settings.tile
                                            border.width: 1
                                            border.color: Looks.settings.cardStroke
                                            RowLayout {
                                                id: chipRow
                                                anchors.centerIn: parent
                                                spacing: Looks.dp(6)
                                                FluentIcon { icon: "desktop"; implicitSize: Looks.dp(13); color: Looks.colors.subfg }
                                                WText {
                                                    text: (screenChip.modelData?.name ?? "") + "  " + (screenChip.modelData?.width ?? 0) + "×" + (screenChip.modelData?.height ?? 0)
                                                    font.pixelSize: Looks.settings.caption
                                                }
                                            }
                                        }
                                    }
                                }
                                Flow {
                                    visible: hero.kind === "desktop"
                                    Layout.fillWidth: true
                                    Layout.topMargin: Looks.dp(12)
                                    spacing: Looks.dp(8)
                                    PillButton {
                                        accent: true
                                        icon: "image"
                                        text: Translation.tr("Change wallpaper")
                                        onClicked: ShellExec.ipc("wallpaperSelector", "toggle")
                                    }
                                    // light and dark, one pill split in two
                                    Rectangle {
                                        implicitWidth: modeRow.implicitWidth + Looks.dp(8)
                                        implicitHeight: Looks.dp(34)
                                        radius: height / 2
                                        color: Looks.settings.tile
                                        border.width: 1
                                        border.color: Looks.settings.cardStroke
                                        Rectangle {
                                            x: Looks.dp(4) + (Looks.dark ? lightHalf.width : 0)
                                            y: Looks.dp(4)
                                            width: Looks.dark ? darkHalf.width : lightHalf.width
                                            height: parent.height - Looks.dp(8)
                                            radius: height / 2
                                            color: Looks.colors.accent
                                            Behavior on x {
                                                animation: NumberAnimation { duration: Looks.transition.enabled ? 280 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                                            }
                                        }
                                        Row {
                                            id: modeRow
                                            anchors.centerIn: parent
                                            ModeHalf {
                                                id: lightHalf
                                                dark: false
                                                icon: "weather-sunny"
                                                label: Translation.tr("Light mode")
                                            }
                                            ModeHalf {
                                                id: darkHalf
                                                dark: true
                                                icon: "weather-moon"
                                                label: Translation.tr("Dark mode")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: landingColumn.width > Looks.dp(720) ? 2 : 1
                        columnSpacing: Looks.dp(8)
                        rowSpacing: Looks.dp(8)
                        Repeater {
                            model: root.landingCategory >= 0 ? root.categories[root.landingCategory].pages : []
                            PageTile {
                                required property int modelData
                                page: modelData
                                category: root.categories[root.landingCategory] ?? null
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard shortcut for search
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: {
            if (!root.navExpanded) root.navExpanded = true;
            searchInput.forceActiveFocus();
        }
    }
}
