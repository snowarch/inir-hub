pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.waffle.looks

// Main Windows 11 style settings container
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

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Navigation pane (NavigationView, OpenPaneLength 320) ──
        Item {
            id: navPane
            Layout.fillHeight: true
            Layout.preferredWidth: root.navExpanded ? Looks.dp(320) : Looks.dp(56)

            Behavior on Layout.preferredWidth {
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: Looks.dp(14)
                    bottomMargin: Looks.dp(8)
                    leftMargin: root.navExpanded ? Looks.dp(16) : Looks.dp(4)
                    rightMargin: root.navExpanded ? Looks.dp(16) : Looks.dp(4)
                }
                spacing: Looks.dp(4)

                // the person, as Windows opens Settings: picture, name, and what this machine runs
                Revealer {
                    vertical: true
                    reveal: root.navExpanded
                    Layout.fillWidth: true
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Looks.dp(14)

                        WUserAvatar {
                            Layout.topMargin: Looks.dp(6)
                            Layout.bottomMargin: Looks.dp(14)
                            sourceSize: Qt.size(Looks.dp(64), Looks.dp(64))
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Looks.dp(2)
                            WText {
                                Layout.fillWidth: true
                                text: SystemInfo.displayName || SystemInfo.username
                                font.pixelSize: Looks.settings.body
                                font.weight: Looks.font.weight.strong
                                elide: Text.ElideRight
                            }
                            WText {
                                Layout.fillWidth: true
                                text: [SystemInfo.distroName, "iNiR " + Translation.tr("Waffle")].filter(t => t && t !== "Unknown").join(" \u00b7 ")
                                font.pixelSize: Looks.settings.caption
                                font.weight: Looks.font.weight.thin
                                color: Looks.colors.subfg
                                elide: Text.ElideRight
                            }
                        }
                        WBorderlessButton {
                            Layout.alignment: Qt.AlignTop
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
                }

                Revealer {
                    vertical: true
                    reveal: !root.navExpanded
                    Layout.fillWidth: true
                    Item {
                        implicitWidth: parent.width
                        implicitHeight: Looks.dp(40)
                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "settings"
                            implicitSize: Looks.dp(18)
                            color: Looks.colors.subfg
                        }
                    }
                }

                // Search bar (only when expanded)
                Revealer {
                    vertical: true
                    reveal: root.navExpanded
                    Layout.fillWidth: true
                Rectangle {
                    id: searchBarContainer
                    // Revealer sizes itself from its child's implicit size.
                    implicitWidth: parent.width
                    implicitHeight: Looks.dp(32)
                    radius: Looks.settings.radiusSmall
                    color: searchInput.activeFocus ? (Looks.dark ? Qt.rgba(0.12, 0.12, 0.12, 0.7) : "#FFFFFF")
                        : searchHover.hovered ? Looks.settings.cardHover : Looks.settings.card
                    border.width: 1
                    border.color: Looks.settings.cardStroke
                    clip: true
                    HoverHandler { id: searchHover }
                    // TextControlElevationBorder: a darker line at the bottom, the accent and 2 px on focus
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: searchInput.activeFocus ? 2 : 1
                        color: searchInput.activeFocus ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.54 : 0.45)
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Looks.dp(11)
                            rightMargin: Looks.dp(6)
                        }
                        spacing: Looks.dp(6)

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                color: Looks.colors.fg
                                selectionColor: Looks.colors.accent
                                selectedTextColor: Looks.colors.accentFg
                                font.family: Looks.font.family.ui
                                font.pixelSize: Looks.settings.body
                                clip: true
                                
                                onTextChanged: {
                                    root.searchText = text;
                                    root.recomputeSearchResults();
                                }
                                
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Down && root.searchResults.length > 0) {
                                        searchResultsList.forceActiveFocus();
                                        searchResultsList.currentIndex = 0;
                                        event.accepted = true;
                                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.searchResults.length > 0) {
                                        root.openSearchResult(root.searchResults[0]);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.openSearchResult({});
                                        event.accepted = true;
                                    }
                                }
                            }
                            
                            // Placeholder text (separate element to avoid overlap)
                            WText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: Translation.tr("Find a setting")
                                color: Looks.colors.subfg
                                font.family: Looks.font.family.ui
                                font.pixelSize: Looks.settings.body
                                font.weight: Looks.font.weight.thin
                                visible: !searchInput.text
                            }
                        }
                        
                        // Clear button
                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            visible: searchInput.text.length > 0
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10  // pill shape
                                color: clearMouse.containsMouse
                                    ? Looks.settings.tileHover : "transparent"
                                
                                FluentIcon {
                                    anchors.centerIn: parent
                                    icon: "dismiss"
                                    implicitSize: 12
                                    color: Looks.colors.subfg
                                }
                                
                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = "";
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                        FluentIcon {
                            Layout.rightMargin: Looks.dp(4)
                            icon: "search"
                            implicitSize: Looks.dp(14)
                            color: Looks.colors.subfg
                        }
                    }
                }
                }
                
                // Search results dropdown
                Revealer {
                    vertical: true
                    reveal: root.searchText.length > 0 && root.searchResults.length > 0
                    Layout.fillWidth: true
                Rectangle {
                    id: searchResultsDropdown
                    // Revealer sizes itself from its child's implicit size.
                    implicitWidth: parent.width
                    implicitHeight: Math.min(
                        (searchResultsList.contentHeight || 0) + Looks.dp(8),
                        Looks.dp(300))
                    radius: Looks.settings.radiusLarge
                    color: Looks.settings.tile
                    border.width: 1
                    border.color: Looks.settings.strokeStrong
                    
                    layer.enabled: Looks.effectsEnabled && searchResultsDropdown.visible
                    layer.effect: DropShadow {
                        color: Looks.colors.shadow
                        radius: 6
                        samples: 7
                        verticalOffset: 2
                    }
                    
                    ListView {
                        id: searchResultsList
                        anchors {
                            fill: parent
                            margins: 4
                        }
                        spacing: 2
                        model: root.searchResults
                        clip: true
                        currentIndex: -1
                        boundsBehavior: Flickable.StopAtBounds
                        
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up) {
                                if (currentIndex > 0) currentIndex--;
                                else searchInput.forceActiveFocus();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                if (currentIndex < count - 1) currentIndex++;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (currentIndex >= 0) root.openSearchResult(root.searchResults[currentIndex]);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.openSearchResult({});
                                searchInput.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                        
                        delegate: Rectangle {
                            id: resultDelegate
                            required property var modelData
                            required property int index
                            
                            width: searchResultsList.width
                            height: 44
                            radius: Looks.radius.medium
                            color: {
                                if (ListView.isCurrentItem) return Looks.colors.accent;
                                if (resultMouse.containsMouse) return Looks.settings.tileHover;
                                return "transparent";
                            }
                            
                              Behavior on color {
                                  animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                              }
                            
                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openSearchResult(resultDelegate.modelData)
                            }
                            
                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 10
                                
                                // Page icon
                                FluentIcon {
                                    icon: {
                                        var icons = ["home", "settings", "desktop", "image", "color", 
                                                    "apps", "settings-cog-multiple", "desktop", "info"];
                                        return icons[resultDelegate.modelData.pageIndex] || "settings";
                                    }
                                    implicitSize: 16
                                    color: resultDelegate.ListView.isCurrentItem 
                                        ? Looks.colors.accentFg 
                                        : Looks.colors.accent
                                }
                                
                                // Text content
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: resultDelegate.modelData.labelHighlighted || resultDelegate.modelData.label || ""
                                        textFormat: Text.StyledText
                                        font.family: Looks.font.family.ui
                                        font.pixelSize: Looks.font.pixelSize.normal
                                        font.weight: Font.Medium
                                        color: resultDelegate.ListView.isCurrentItem 
                                            ? Looks.colors.accentFg 
                                            : Looks.colors.fg
                                        elide: Text.ElideRight
                                    }
                                    
                                    WText {
                                        Layout.fillWidth: true
                                        text: resultDelegate.modelData.pageName + (resultDelegate.modelData.section ? " › " + resultDelegate.modelData.section : "")
                                        font.pixelSize: Looks.font.pixelSize.small
                                        color: resultDelegate.ListView.isCurrentItem 
                                            ? Looks.colors.accentFg 
                                            : Looks.colors.subfg
                                        elide: Text.ElideRight
                                        opacity: 0.8
                                    }
                                }
                                
                                // Arrow
                                FluentIcon {
                                    icon: "chevron-right"
                                    implicitSize: 12
                                    color: resultDelegate.ListView.isCurrentItem 
                                        ? Looks.colors.accentFg 
                                        : Looks.colors.subfg
                                    opacity: resultMouse.containsMouse || resultDelegate.ListView.isCurrentItem ? 1 : 0
                                    
                                      Behavior on opacity {
                                          animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                                      }
                                }
                            }
                        }
                    }
                }
                }
                
                // No results indicator
                Revealer {
                    vertical: true
                    reveal: root.searchText.length > 0 && root.searchResults.length === 0
                    Layout.fillWidth: true
                Rectangle {
                    implicitWidth: parent.width
                    implicitHeight: noResultsCol.implicitHeight + 16
                    radius: Looks.radius.medium
                    color: Looks.settings.tile

                    ColumnLayout {
                        id: noResultsCol
                        anchors.centerIn: parent
                        spacing: 6

                        MascotImage {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 88
                            pose: "settings-judging"
                            surface: "emptyStates"
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            FluentIcon {
                                icon: "search"
                                implicitSize: 14
                                color: Looks.colors.subfg
                            }

                            WText {
                                text: Translation.tr("No results")
                                font.pixelSize: Looks.font.pixelSize.small
                                color: Looks.colors.subfg
                            }
                        }
                    }
                }
                }


                Item { implicitHeight: Looks.dp(8) }

                Flickable {
                    id: navFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: navColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // NavigationView's menu is one Tab stop (TabFocusNavigation Once): ↑ ↓ open the category above or
                    // below; the entries were mouse-only before.
                    activeFocusOnTab: true
                    Accessible.role: Accessible.List
                    Keys.onUpPressed: if (root.activeCategory > 0) root.openCategory(root.activeCategory - 1)
                    Keys.onDownPressed: if (root.activeCategory < root.categories.length - 1) root.openCategory(root.activeCategory + 1)

                    ColumnLayout {
                        id: navColumn
                        width: parent.width
                        spacing: Looks.dp(4)

                        Repeater {
                            model: root.categories

                            // NavigationViewItem: 36 px, radius 4, 16 px icon, Body text; the chosen one on a subtle
                            // fill with a 3 x 16 accent pill at its left edge
                            Item {
                                id: navEntry
                                required property int index
                                required property var modelData
                                readonly property bool selected: root.activeCategory === navEntry.index
                                Layout.fillWidth: true
                                // the last one (About) stands apart, as Windows Update does
                                Layout.topMargin: navEntry.modelData.apart ? Looks.dp(12) : 0
                                implicitHeight: Looks.dp(36)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Looks.settings.radiusSmall
                                    color: navMouse.pressed ? Qt.alpha(Looks.colors.fg, 0.03)
                                        : navEntry.selected || navMouse.containsMouse ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.04)
                                        : "transparent"
                                    Behavior on color {
                                        animation: ColorAnimation { duration: Looks.transition.enabled ? 83 : 0 }
                                    }
                                }
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Looks.dp(3)
                                    height: navMouse.pressed && navEntry.selected ? Looks.dp(10) : Looks.dp(16)
                                    radius: width / 2
                                    color: Looks.colors.accent
                                    opacity: navEntry.selected ? 1 : 0
                                    Behavior on opacity {
                                        animation: NumberAnimation { duration: Looks.transition.enabled ? 120 : 0 }
                                    }
                                    Behavior on height {
                                        animation: NumberAnimation { duration: Looks.transition.enabled ? 120 : 0 }
                                    }
                                }
                                WFocusVisual {
                                    shown: navFlick.activeFocus && navEntry.selected
                                    margin: 0
                                    radius: Looks.settings.radiusSmall
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
                                    anchors.leftMargin: root.navExpanded ? Looks.dp(16) : 0
                                    spacing: Looks.dp(16)
                                    FluentIcon {
                                        Layout.alignment: root.navExpanded ? Qt.AlignVCenter : Qt.AlignCenter
                                        Layout.fillWidth: !root.navExpanded
                                        icon: navEntry.modelData.icon
                                        filled: true
                                        implicitSize: Looks.dp(18)
                                        // each category keeps its colour, as Windows' Settings icons do: found by hue
                                        color: Looks.dark ? navEntry.modelData.tintDark : navEntry.modelData.tint
                                    }
                                    WText {
                                        visible: root.navExpanded
                                        Layout.fillWidth: true
                                        text: navEntry.modelData.name
                                        font.pixelSize: Looks.settings.body
                                        font.weight: Looks.font.weight.thin
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                WBorderlessButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Looks.dp(36)
                    contentItem: RowLayout {
                        spacing: Looks.dp(16)
                        FluentIcon {
                            Layout.leftMargin: root.navExpanded ? Looks.dp(16) : 0
                            Layout.fillWidth: !root.navExpanded
                            Layout.alignment: root.navExpanded ? Qt.AlignVCenter : Qt.AlignCenter
                            icon: root.navExpanded ? "panel-left-contract" : "panel-left-expand"
                            implicitSize: Looks.dp(16)
                            color: Looks.colors.subfg
                        }
                        WText {
                            visible: root.navExpanded
                            Layout.fillWidth: true
                            text: Translation.tr("Collapse")
                            font.pixelSize: Looks.settings.body
                            font.weight: Looks.font.weight.thin
                            color: Looks.colors.subfg
                        }
                    }
                    onClicked: root.navExpanded = !root.navExpanded
                }
            }
        }

        // ── Content: a layer over the window with its top-left corner rounded, as Windows' Settings frame ──
        Rectangle {
            id: contentLayer
            Layout.fillWidth: true
            Layout.fillHeight: true
            topLeftRadius: Looks.dp(8)
            color: Looks.dark ? Qt.rgba(0.227, 0.227, 0.227, 0.3) : Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
            border.color: Looks.settings.cardStroke

            readonly property int sidePadding: width < Looks.dp(640) ? Looks.dp(20) : Looks.dp(40)
            readonly property int columnWidth: Math.min(width - sidePadding * 2, Looks.dp(1000))

            // breadcrumb: the category, then the page, in Windows' Title (28 semibold); the category goes back
            RowLayout {
                id: crumb
                x: contentLayer.sidePadding
                y: Looks.dp(26)
                width: contentLayer.columnWidth
                spacing: Looks.dp(14)
                readonly property var cat: root.categories[root.activeCategory] ?? null
                readonly property bool nested: crumb.cat !== null && crumb.cat.pages.length > 1 && root.landingCategory < 0
                // As WinUI's BreadcrumbBar: when the path runs out of room the category folds into "…", still the way back.
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
                    color: crumbMouse.containsMouse ? Looks.colors.fg : Looks.colors.subfg
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

            Item {
                id: pageStack
                anchors.fill: parent
                anchors.topMargin: crumb.y + crumb.height + Looks.dp(10)
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
                        opacity: visible ? 1 : 0
                        // Disabled pages must not intercept mouse events even at opacity 0
                        enabled: visible
                        // the breadcrumb above says the page's name: the page drops its own
                        onLoaded: if (item && item.hasOwnProperty("showHeader")) {
                            item.showHeader = false
                            item.sidePadding = Qt.binding(() => contentLayer.sidePadding)
                        }

                        Behavior on opacity {
                            animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.OutCubic }
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

            // a category's page: what is inside it, one link card per page (SettingsCard with an action chevron)
            Flickable {
                id: landing
                anchors.fill: parent
                anchors.topMargin: pageStack.anchors.topMargin
                visible: root.landingCategory >= 0
                clip: true
                contentHeight: landingColumn.implicitHeight + Looks.dp(32)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: WScrollBar {}

                ColumnLayout {
                    id: landingColumn
                    x: contentLayer.sidePadding
                    y: Looks.dp(8)
                    width: contentLayer.columnWidth
                    spacing: Looks.settings.cardSpacing

                    // Windows opens Personalization and System on the desktop itself: ours shows the real one
                    Rectangle {
                        id: hero
                        readonly property string kind: root.landingCategory >= 0 ? (root.categories[root.landingCategory].hero ?? "") : ""
                        visible: hero.kind !== ""
                        Layout.fillWidth: true
                        Layout.bottomMargin: Looks.dp(20)
                        implicitHeight: heroRow.implicitHeight + Looks.dp(32)
                        radius: Looks.settings.radiusSmall
                        color: Looks.settings.card
                        border.width: 1
                        border.color: Looks.settings.cardStroke

                        component FluentButton: Rectangle {
                            id: fb
                            property string text: ""
                            property bool accent: false
                            property bool chosen: false
                            signal clicked()
                            implicitWidth: fbText.implicitWidth + Looks.dp(24)
                            implicitHeight: Looks.dp(32)
                            radius: Looks.settings.radiusSmall
                            color: fb.accent || fb.chosen
                                ? (fbMouse.pressed ? Qt.alpha(Looks.colors.accent, 0.8) : fbMouse.containsMouse ? Qt.alpha(Looks.colors.accent, 0.9) : Looks.colors.accent)
                                : (fbMouse.pressed ? Qt.alpha(Looks.colors.fg, 0.03) : fbMouse.containsMouse ? Qt.alpha(Looks.colors.fg, 0.08) : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.7))
                            border.width: 1
                            border.color: Qt.alpha(fb.accent || fb.chosen ? "#FFFFFF" : Looks.colors.fg, fb.accent || fb.chosen ? 0.08 : 0.07)
                            WText {
                                id: fbText
                                anchors.centerIn: parent
                                text: fb.text
                                font.pixelSize: Looks.settings.body
                                font.weight: Looks.font.weight.thin
                                color: fb.accent || fb.chosen ? Looks.colors.accentFg : Looks.colors.fg
                            }
                            MouseArea {
                                id: fbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: fb.clicked()
                            }
                        }

                        RowLayout {
                            id: heroRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Looks.dp(16)
                            spacing: Looks.dp(24)

                            // the desktop at a glance: wallpaper and the bar where it sits
                            Rectangle {
                                Layout.preferredWidth: Looks.dp(256)
                                Layout.preferredHeight: Looks.dp(144)
                                radius: Looks.dp(6)
                                color: Looks.colors.bg0
                                border.width: 1
                                border.color: Looks.settings.cardStroke
                                clip: true
                                StyledImage {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    fillMode: Image.PreserveAspectCrop
                                    source: hero.visible ? Wallpapers.effectiveWallpaperUrl : ""
                                    sourceSize.width: 520
                                    asynchronous: true
                                    cache: false
                                }
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 1
                                    y: (Config.options?.waffles?.bar?.bottom ?? true) ? parent.height - height - 1 : 1
                                    height: Looks.dp(12)
                                    color: Qt.alpha(Looks.colors.bg1Base, 0.9)
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Looks.dp(3)
                                        Repeater {
                                            model: 5
                                            Rectangle {
                                                required property int index
                                                width: Looks.dp(6)
                                                height: Looks.dp(6)
                                                radius: Looks.dp(1.5)
                                                color: index === 0 ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, 0.6)
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: Looks.dp(4)

                                WText {
                                    Layout.fillWidth: true
                                    text: hero.kind === "system" ? (SystemInfo.hostname || SystemInfo.distroName) : Translation.tr("Your desktop")
                                    font.pixelSize: Looks.settings.subtitle
                                    font.weight: Looks.font.weight.strong
                                    elide: Text.ElideRight
                                }
                                WText {
                                    Layout.fillWidth: true
                                    text: hero.kind === "system"
                                        ? [SystemInfo.distroName, SystemInfo.windowingSystem, Array.from(Quickshell.screens).map(sc => `${sc.width}\u00d7${sc.height}`).join(", ")].filter(t => t && t !== "Unknown").join(" \u00b7 ")
                                        : decodeURIComponent(String(Wallpapers.effectiveWallpaperUrl).split("/").pop() || "")
                                    font.pixelSize: Looks.settings.caption
                                    font.weight: Looks.font.weight.thin
                                    color: Looks.colors.subfg
                                    elide: Text.ElideMiddle
                                }
                                RowLayout {
                                    visible: hero.kind === "desktop"
                                    Layout.topMargin: Looks.dp(10)
                                    spacing: Looks.dp(8)
                                    FluentButton {
                                        accent: true
                                        text: Translation.tr("Change wallpaper")
                                        onClicked: Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "wallpaperSelector", "toggle"])
                                    }
                                    FluentButton {
                                        text: Translation.tr("Light")
                                        chosen: !Looks.dark
                                        onClicked: MaterialThemeLoader.setDarkMode(false)
                                    }
                                    FluentButton {
                                        text: Translation.tr("Dark")
                                        chosen: Looks.dark
                                        onClicked: MaterialThemeLoader.setDarkMode(true)
                                    }
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.landingCategory >= 0 ? root.categories[root.landingCategory].pages : []
                        WSettingsRow {
                            required property int modelData
                            enableSettingsSearch: false
                            icon: root.pages[modelData]?.icon ?? ""
                            label: root.pages[modelData]?.name ?? ""
                            description: root.pages[modelData]?.desc ?? ""
                            clickable: true
                            showChevron: true
                            onClicked: root.openPage(modelData)
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
