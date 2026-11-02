pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// The community hub in Material Settings, built to browse hundreds: one toolbar (search, order, list or grid),
// kind chips with their counts, a small featured band, then the catalogue as Settings' own segmented rows.
// An item's page leads with its name, votes and action. Hub owns the catalogue and the installs.
ContentPage {
    id: root
    settingsPageIndex: 29
    settingsPageName: Translation.tr("Hub")

    property string kind: ""
    property string filter: "" // "", "installed" or "updates"
    property string query: ""
    property string openId: ""
    property real shelfScroll: 0
    property int shownCount: root.pageSize

    readonly property int pageSize: 40
    readonly property string family: Hub.family
    readonly property string sort: Config.options?.hub?.sort ?? "popular"
    readonly property bool grid: (Config.options?.hub?.view ?? "list") === "grid"
    readonly property var shown: Hub.sorted(Hub.items.filter(item => Hub.matches(item, root.kind, root.query, root.filter === "installed")
        && (root.filter !== "updates" || Hub.stateOf(item) === "update")), root.sort)
    readonly property var listed: root.shown.slice(0, root.shownCount)
    readonly property var opened: root.openId.length > 0 ? Hub.find(root.openId) : null
    readonly property bool browsing: root.kind === "" && root.query === "" && root.filter === ""
    readonly property bool hasStats: Hub.items.some(item => item.downloads !== undefined || Hub.votes(item) > 0)

    readonly property real usable: Math.min(root.maxContentWidth, Math.max(0, root.width - 2 * root._horizontalMargin))
    readonly property bool wideRows: root.usable >= 640
    // Three only on a wide page: at a third of ~860 px a summary had 133 px and was cut in the inir style's mono.
    readonly property int bandColumns: root.usable >= 1080 ? 3 : 2
    // A band of one only repeats the list's first row: it shows once it holds two.
    readonly property var featured: {
        const picks = root.browsing ? Hub.sorted(Hub.items.filter(item => item.featured === true && Hub.fits(item, root.family)
            && item.compatible !== false && !item.blocked), "popular").slice(0, root.bandColumns) : []
        return picks.length >= 2 ? picks : []
    }
    readonly property int gap: 12
    readonly property int columns: Math.max(2, Math.min(5, Math.floor((root.usable + root.gap) / (196 + root.gap))))
    readonly property real tileWidth: Math.floor((root.usable - (root.columns - 1) * root.gap) / root.columns)

    readonly property var permissionGlyphs: ({ process: "terminal", network: "public", files: "folder_open", inject: "code" })
    readonly property var kindGlyphs: ({ widget: "widgets", theme: "palette", "iris-theme": "style", webapp: "language", family: "dashboard" })
    readonly property var familyNames: ({ material: "Material", iris: "iRiS", waffle: "Waffle" })

    onKindChanged: root.shownCount = root.pageSize
    onFilterChanged: root.shownCount = root.pageSize
    onQueryChanged: root.shownCount = root.pageSize
    onSortChanged: root.shownCount = root.pageSize

    Component.onCompleted: {
        Hub.ensureLoaded()
        if (Hub.requestedId.length > 0)
            root.openItem(Hub.takeRequest())
    }
    Connections {
        target: Hub
        function onRequestedIdChanged(): void {
            if (Hub.requestedId.length > 0)
                root.openItem(Hub.takeRequest())
        }
    }

    // An item's page opens at its top; going back returns to where the list was.
    function openItem(id: string): void {
        if (root.openId.length === 0)
            root.shelfScroll = root.contentY
        root.openId = id
        root.contentY = 0
    }
    function closeItem(): void {
        root.openId = ""
        root.contentY = root.shelfScroll
    }
    function searchFor(text: string): void {
        root.closeItem()
        searchInput.text = text
        root.query = text
        root.contentY = 0
    }

    // What the main button says and does for an item in this family.
    function actionOf(item: var): var {
        switch (Hub.stateOf(item)) {
        case "installing": return { text: Translation.tr("Installing…"), icon: "downloading", busy: true }
        case "updating": return { text: Translation.tr("Updating…"), icon: "downloading", busy: true }
        case "removing": return { text: Translation.tr("Removing…"), icon: "delete", busy: true }
        case "failed": return { text: Translation.tr("Try again"), icon: "refresh", tone: "error", run: () => item.installed ? Hub.update(item.id) : Hub.install(item.id) }
        case "pulled": return { text: Translation.tr("Remove"), icon: "delete", tone: "error", run: () => Hub.remove(item.id) }
        case "blocked": return { text: Translation.tr("Pulled"), icon: "block", tone: "off" }
        case "update": return { text: Translation.tr("Update"), icon: "upgrade", tone: "primary", run: () => Hub.update(item.id) }
        case "conflict": return { text: Translation.tr("Name taken"), icon: "block", tone: "off" }
        case "incompatible": return { text: Translation.tr("Needs iNiR %1").arg(item.minInir), icon: "block", tone: "off" }
        case "get": return { text: Translation.tr("Get"), icon: "download", tone: Hub.fits(item, root.family) ? "primary" : "tonal", run: () => Hub.install(item.id) }
        case "active": return { text: Translation.tr("In use"), icon: "check", tone: "off" }
        case "present": return { text: Translation.tr("Use"), icon: "swap_horiz", tone: "tonal", run: () => Hub.useFamily(item.id) }
        }
        if (item.kind === "theme" && Hub.fits(item, root.family))
            return { text: Translation.tr("Use"), icon: "format_paint", tone: "tonal", run: () => Hub.useTheme(item.id) }
        if (item.kind === "widget" && Hub.fits(item, root.family) && root.family !== "waffle") {
            if (Hub.widgetInUse(item.id, root.family))
                return { text: Translation.tr("On your desktop"), icon: "check", tone: "off" }
            return { text: Translation.tr("Add to desktop"), icon: "add_to_home_screen", tone: "tonal", run: () => Hub.useWidget(item.id, root.family) }
        }
        return { text: Translation.tr("Installed"), icon: "check", tone: "off" }
    }
    function whereOf(item: var): string {
        return Hub.whereOf(item, root.family)
    }
    function authorsOf(item: var): string {
        return Array.from(item?.authors ?? []).join(", ")
    }
    // Other families an item works in, by name: "iRiS", "iRiS · Waffle".
    function otherFamilies(item: var): string {
        return Array.from(item?.families ?? []).filter(name => name !== root.family).map(name => root.familyNames[name] ?? name).join(" · ")
    }
    function likedText(item: var): string {
        const liked = Hub.liked(item)
        return liked < 0 ? "–" : `${Math.round(liked * 100)}%`
    }
    function votesText(item: var): string {
        return Hub.votes(item) > 0 ? Translation.tr("%1 of %2 people liked it").arg(item.votesUp ?? 0).arg(Hub.votes(item))
            : Translation.tr("No votes yet")
    }
    function dateText(date: string): string {
        if (!date)
            return ""
        const day = new Date(date + "T12:00:00")
        return Qt.formatDate(day, day.getFullYear() === new Date().getFullYear() ? "d MMM" : "MMM yyyy")
    }

    // ── Toolbar: search, order, view ──────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        visible: root.opened === null
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.full
            color: searchInput.activeFocus || searchHover.hovered ? SettingsMaterialPreset.tileHoverColor : SettingsMaterialPreset.tileColor
            border.width: searchInput.activeFocus ? 2 : 0
            border.color: Appearance.colors.colPrimary
            Behavior on color {
                enabled: Appearance.animationsEnabled
                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }
            HoverHandler { id: searchHover; cursorShape: Qt.IBeamCursor }
            TapHandler { onTapped: searchInput.forceActiveFocus() }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 4
                spacing: 10
                MaterialSymbol {
                    text: "search"
                    iconSize: SettingsMaterialPreset.iconSize
                    color: searchInput.activeFocus ? Appearance.colors.colPrimary : SettingsMaterialPreset.supportingColor
                }
                StyledTextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: SettingsMaterialPreset.labelSize
                    color: SettingsMaterialPreset.labelColor
                    clip: true
                    onTextChanged: searchDelay.restart()
                    Keys.onEscapePressed: event => {
                        if (text.length === 0) {
                            event.accepted = false
                            return
                        }
                        text = ""
                    }
                    Timer { id: searchDelay; interval: 140; onTriggered: root.query = searchInput.text.trim() }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        visible: searchInput.text.length === 0
                        text: !Hub.loaded ? Translation.tr("Reading the hub…")
                            : Hub.items.length > 0 ? Translation.tr("Search %1 items").arg(Hub.items.length) : Translation.tr("Search the hub")
                        font.pixelSize: SettingsMaterialPreset.labelSize
                        color: SettingsMaterialPreset.supportingColor
                        elide: Text.ElideRight
                    }
                }
                IconToolbarButton {
                    visible: searchInput.text.length > 0
                    implicitWidth: 32
                    implicitHeight: 32
                    iconSize: 18
                    text: "close"
                    onClicked: searchInput.text = ""
                    StyledToolTip { text: Translation.tr("Clear") }
                }
            }
        }

        StyledComboBox {
            Layout.preferredWidth: Math.round(176 * Appearance.fontSizeScale)
            enableSettingsSearch: false
            model: Hub.sorts.map(entry => ({ displayName: Translation.tr(entry.label) }))
            textRole: "displayName"
            currentIndex: Math.max(0, Hub.sorts.findIndex(entry => entry.id === root.sort))
            onActivated: index => Config.setNestedValue("hub.sort", Hub.sorts[index].id)
        }

        // List or grid: one connected pair, the chosen key filled.
        Rectangle {
            implicitWidth: viewKeys.implicitWidth + 8
            implicitHeight: 40
            radius: Appearance.rounding.full
            color: SettingsMaterialPreset.tileColor
            Row {
                id: viewKeys
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: [{ id: "list", icon: "view_agenda", tip: "List" }, { id: "grid", icon: "grid_view", tip: "Grid" }]
                    delegate: IconToolbarButton {
                        id: viewKey
                        required property var modelData
                        implicitWidth: 40
                        implicitHeight: 32
                        iconSize: 18
                        text: modelData.icon
                        toggled: root.grid === (modelData.id === "grid")
                        onClicked: Config.setNestedValue("hub.view", modelData.id)
                        StyledToolTip { text: Translation.tr(viewKey.modelData.tip) }
                    }
                }
            }
        }

        IconToolbarButton {
            id: refreshButton
            implicitWidth: 40
            implicitHeight: 40
            iconSize: SettingsMaterialPreset.iconSize
            text: "refresh"
            enabled: !Hub.loading
            onClicked: Hub.refresh(true)
            StyledToolTip {
                text: Hub.checkedAt > 0
                    ? Translation.tr("Checked %1 · check again").arg(Qt.formatTime(new Date(Hub.checkedAt), "hh:mm"))
                    : Translation.tr("Check the hub now")
            }
            RotationAnimator on rotation {
                running: Hub.loading && refreshButton.visible && Appearance.animationsEnabled
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
                onRunningChanged: if (!running) refreshButton.rotation = 0
            }
        }
    }

    // ── Kinds and states, with how many of each ───────────────────────
    Flow {
        Layout.fillWidth: true
        Layout.topMargin: -12
        visible: root.opened === null && Hub.items.length > 0
        spacing: 6

        FilterChip {
            text: `${Translation.tr("Everything")}  ${Hub.items.length}`
            selected: root.kind === "" && root.filter === ""
            onClicked: {
                root.kind = ""
                root.filter = ""
            }
        }
        Repeater {
            model: Hub.kinds.map(entry => Object.assign({ count: Hub.items.filter(item => item.kind === entry.id).length }, entry))
                .filter(entry => entry.count > 0)
            delegate: FilterChip {
                required property var modelData
                text: `${Translation.tr(modelData.label)}  ${modelData.count}`
                selected: root.kind === modelData.id
                onClicked: root.kind = root.kind === modelData.id ? "" : modelData.id
            }
        }
        FilterChip {
            readonly property int count: Hub.items.filter(item => Hub.owned(item)).length
            visible: count > 0
            text: `${Translation.tr("Installed")}  ${count}`
            selected: root.filter === "installed"
            onClicked: root.filter = root.filter === "installed" ? "" : "installed"
        }
        FilterChip {
            visible: Hub.updates > 0
            text: `${Translation.tr("Updates")}  ${Hub.updates}`
            selected: root.filter === "updates"
            onClicked: root.filter = root.filter === "updates" ? "" : "updates"
        }
    }

    // Offline or unreachable with a list in hand: the list from last time, said once.
    NoticeBox {
        Layout.fillWidth: true
        visible: root.opened === null && Hub.loaded && Hub.items.length > 0 && (!Hub.online || Hub.error.length > 0)
        materialIcon: Hub.online ? "cloud_off" : "wifi_off"
        text: !Hub.online ? Translation.tr("You're offline: this is the list from the last time the hub answered")
            : Translation.tr("The hub didn't answer: this is the list from the last time it did")
    }

    // ── Loading: the list's shape, quiet ──────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        visible: !Hub.loaded
        spacing: SettingsMaterialPreset.tileGap
        Repeater {
            model: 6
            delegate: Rectangle {
                id: ghost
                required property int index
                Layout.fillWidth: true
                implicitHeight: Math.round(64 * Appearance.fontSizeScale)
                topLeftRadius: ghost.index === 0 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                topRightRadius: topLeftRadius
                bottomLeftRadius: ghost.index === 5 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                bottomRightRadius: bottomLeftRadius
                color: SettingsMaterialPreset.tileColor
                Rectangle {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round((parent.height - 16) * 1.6)
                    height: parent.height - 16
                    radius: 8
                    color: SettingsMaterialPreset.controlColor
                }
                Column {
                    x: Math.round((parent.height - 16) * 1.6) + 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle { width: ghost.width * 0.22; height: 10; radius: 5; color: SettingsMaterialPreset.controlColor }
                    Rectangle { width: ghost.width * 0.44; height: 8; radius: 4; color: SettingsMaterialPreset.controlColor }
                }
                SequentialAnimation on opacity {
                    running: ghost.visible && Appearance.animationsEnabled
                    loops: Animation.Infinite
                    PauseAnimation { duration: ghost.index * 90 }
                    NumberAnimation { from: 1; to: 0.55; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.55; to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    MaterialPlaceholderMessage {
        Layout.fillWidth: true
        Layout.topMargin: 24
        shown: Hub.loaded && root.opened === null && root.shown.length === 0
        visible: shown
        icon: root.query.length > 0 ? "search_off" : root.filter === "installed" ? "download_done"
            : Hub.items.length === 0 && Hub.error.length > 0 ? (Hub.online ? "cloud_off" : "wifi_off") : "storefront"
        text: root.query.length > 0 ? Translation.tr("Nothing matches “%1”").arg(root.query)
            : root.filter === "installed" ? Translation.tr("Nothing installed from the hub yet")
            : Hub.items.length === 0 && Hub.error.length > 0 ? Translation.tr("The hub didn't answer")
            : Translation.tr("Nothing here yet")
        explanation: root.query.length > 0 ? Translation.tr("Try a shorter word, or look through everything")
            : root.filter === "installed" ? Translation.tr("What you get from the hub shows up here, with its updates")
            : Hub.cliMissing ? Translation.tr("The hub comes with the inir command: run inir update once to get it")
            : Hub.items.length === 0 && Hub.error.length > 0 ? Translation.tr("The hub didn't answer. Check your connection and try again")
            : ""
        actionIcon: root.browsing ? "refresh" : "filter_alt_off"
        helpfulAction: Action {
            text: root.browsing ? (Hub.error.length > 0 ? Translation.tr("Try again") : "") : Translation.tr("See everything")
            onTriggered: {
                if (root.browsing) {
                    Hub.refresh(true)
                    return
                }
                searchInput.text = ""
                root.query = ""
                root.kind = ""
                root.filter = ""
            }
        }
    }

    // ── Featured: a band, never a banner ──────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        visible: Hub.loaded && root.opened === null && root.featured.length > 0
        spacing: 8
        Subheader { text: Translation.tr("Featured") }
        RowLayout {
            Layout.fillWidth: true
            spacing: root.gap
            Repeater {
                model: root.featured
                delegate: FeaturedTile {}
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: root.bandColumns - root.featured.length
                visible: root.featured.length < root.bandColumns
            }
        }
    }

    // ── The catalogue ─────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        visible: Hub.loaded && root.opened === null && root.shown.length > 0
        spacing: 8

        Subheader {
            text: root.browsing ? Translation.tr("Everything") : Translation.tr("%1 results").arg(root.shown.length)
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.grid
            spacing: SettingsMaterialPreset.tileGap
            Repeater {
                model: root.grid ? [] : root.listed
                delegate: ItemRow {
                    count: root.listed.length
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.grid
            columns: root.columns
            columnSpacing: root.gap
            rowSpacing: root.gap
            Repeater {
                model: root.grid ? root.listed : []
                delegate: ItemTile {}
            }
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: root.shown.length > root.listed.length
            implicitHeight: 40
            horizontalPadding: 18
            buttonRadius: Appearance.rounding.full
            materialIcon: "expand_more"
            mainText: Translation.tr("Show %1 more").arg(Math.min(root.pageSize, root.shown.length - root.listed.length))
            colBackground: SettingsMaterialPreset.tileColor
            colBackgroundHover: SettingsMaterialPreset.tileHoverColor
            contentColor: SettingsMaterialPreset.labelColor
            onClicked: root.shownCount += root.pageSize
        }
    }

    // ── One item ──────────────────────────────────────────────────────
    Loader {
        Layout.fillWidth: true
        active: root.opened !== null
        visible: active
        sourceComponent: ItemPage {
            item: root.opened
        }
    }

    // ── Sources ───────────────────────────────────────────────────────
    SettingsCardSection {
        visible: root.opened === null && Hub.loaded
        expanded: false
        icon: "dns"
        title: Translation.tr("Sources")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Everything in the official hub is reviewed before it is published. Other sources are not: add only the ones you trust.")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: Hub.sources
                delegate: RowLayout {
                    id: sourceRow
                    required property var modelData
                    readonly property bool extra: Hub.extraSources.includes(modelData.source)
                    Layout.fillWidth: true
                    spacing: 10
                    MaterialSymbol {
                        text: sourceRow.modelData.error ? "error" : sourceRow.extra ? "folder_special" : "verified"
                        iconSize: Appearance.font.pixelSize.larger
                        color: sourceRow.modelData.error ? Appearance.colors.colError : Appearance.colors.colPrimary
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: sourceRow.modelData.name || sourceRow.modelData.source
                            font.pixelSize: Appearance.font.pixelSize.small
                            elide: Text.ElideMiddle
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: sourceRow.modelData.error && sourceRow.modelData.count === 0 ? Translation.tr("Didn't answer")
                                : Translation.tr("%1 items · %2").arg(sourceRow.modelData.count).arg(sourceRow.modelData.source)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideMiddle
                        }
                    }
                    IconToolbarButton {
                        visible: sourceRow.extra
                        text: "delete"
                        onClicked: Hub.removeSource(sourceRow.modelData.source)
                        StyledToolTip { text: Translation.tr("Remove this source") }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MaterialTextField {
                    id: sourceField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Address of an index.json, or a folder")
                    onAccepted: addSource.clicked()
                }
                RippleButtonWithIcon {
                    id: addSource
                    buttonRadius: Appearance.rounding.full
                    materialIcon: "add"
                    mainText: Translation.tr("Add")
                    enabled: sourceField.text.trim().length > 0
                    onClicked: {
                        Hub.addSource(sourceField.text)
                        sourceField.text = ""
                    }
                }
            }
        }
    }

    // ── Pieces ────────────────────────────────────────────────────────

    component Subheader: StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        font.pixelSize: SettingsMaterialPreset.subheaderSize
        font.weight: Font.Medium
        color: SettingsMaterialPreset.subheaderColor
        elide: Text.ElideRight
    }

    // The picture of an item: its preview, or its kind's glyph on a quiet plate while there is none.
    component Preview: ClippingRectangle {
        id: preview
        property var item
        property bool zoomed: false
        color: SettingsMaterialPreset.controlColor
        Image {
            id: previewImage
            anchors.fill: parent
            source: preview.item?.previewUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.ceil(preview.width * 1.5)
            sourceSize.height: Math.ceil(preview.height * 1.5)
            opacity: status === Image.Ready ? 1 : 0
            scale: preview.zoomed ? 1.035 : 1
            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }
            Behavior on scale {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
            }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            text: root.kindGlyphs[preview.item?.kind] ?? "extension"
            iconSize: Math.round(preview.height * 0.36)
            fill: 1
            color: Appearance.colors.colOutlineVariant
        }
    }

    // The main button, the same everywhere; `compact` is the list's size.
    component ActionButton: RippleButtonWithIcon {
        id: action
        property var item
        property bool compact: false
        // In a list a fresh "Get" is tonal: a column of filled buttons has no focal point.
        readonly property var plan: {
            const plan = root.actionOf(action.item)
            if (action.compact && plan.tone === "primary" && Hub.stateOf(action.item) === "get")
                plan.tone = "tonal"
            return plan
        }
        readonly property bool quiet: action.plan.tone === "off" || action.plan.busy === true
        implicitHeight: action.compact ? 32 : 40
        horizontalPadding: action.quiet ? (action.compact ? 4 : 8) : (action.compact ? 14 : 20)
        buttonRadius: Appearance.rounding.full
        materialIcon: action.plan.icon ?? ""
        mainText: action.plan.text
        enabled: typeof action.plan.run === "function"
        colBackground: action.plan.tone === "primary" ? Appearance.colors.colPrimary
            : action.plan.tone === "error" ? Appearance.colors.colErrorContainer
            : action.plan.tone === "tonal" ? Appearance.colors.colSecondaryContainer
            : "transparent"
        colBackgroundHover: action.plan.tone === "primary" ? Appearance.colors.colPrimaryHover
            : action.plan.tone === "error" ? Appearance.colors.colErrorContainerHover
            : action.plan.tone === "tonal" ? Appearance.colors.colSecondaryContainerHover
            : "transparent"
        contentColor: action.plan.tone === "primary" ? Appearance.colors.colOnPrimary
            : action.plan.tone === "error" ? Appearance.colors.colOnErrorContainer
            : action.plan.tone === "tonal" ? Appearance.colors.colOnSecondaryContainer
            : SettingsMaterialPreset.supportingColor
        onClicked: action.plan.run()
        StyledToolTip {
            text: Hub.stateOf(action.item) === "conflict" ? Translation.tr("A folder with this name is already there and did not come from the hub")
                : Hub.stateOf(action.item) === "failed" ? String(Hub.failures[action.item.id] ?? "")
                : String(action.item?.installedBlocked || action.item?.blocked || "")
        }
    }

    // A number with its glyph, for rows and tiles: votes, downloads, a date.
    component Stat: Row {
        id: stat
        property string glyph: ""
        property string text: ""
        property string tip: ""
        property color tint: SettingsMaterialPreset.supportingColor
        spacing: 4
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.glyph
            iconSize: 15
            fill: 1
            color: stat.tint
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.text
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.features: { "tnum": 1 }
            color: stat.tint
        }
        HoverHandler { id: statHover }
        StyledToolTip {
            text: stat.tip
            extraVisibleCondition: statHover.hovered && stat.tip.length > 0
        }
    }

    // One row of the catalogue, a tile of Settings' segmented groups: picture, name and who made it,
    // one line of what it is, then votes, downloads, the last update and the action.
    component ItemRow: Rectangle {
        id: row
        required property var modelData
        required property int index
        property int count: 1
        readonly property bool here: row.modelData.kind === "family" || Hub.fits(row.modelData, root.family)
        readonly property var permissions: Array.from(row.modelData.permissions ?? [])
        Layout.fillWidth: true
        implicitHeight: Math.round(64 * Appearance.fontSizeScale)
        topLeftRadius: row.index === 0 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
        topRightRadius: row.topLeftRadius
        bottomLeftRadius: row.index === row.count - 1 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
        bottomRightRadius: row.bottomLeftRadius
        color: rowTap.pressed ? SettingsMaterialPreset.tilePressColor
            : rowHover.hovered ? SettingsMaterialPreset.tileHoverColor : SettingsMaterialPreset.tileColor
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: rowTap; onTapped: root.openItem(row.modelData.id) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 12
            spacing: 14

            Preview {
                Layout.preferredHeight: row.height - 16
                Layout.preferredWidth: Math.round((row.height - 16) * 1.6)
                radius: Math.max(6, row.topLeftRadius - 6)
                item: row.modelData
                zoomed: rowHover.hovered
                opacity: row.here ? 1 : 0.7
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                // The name keeps its width; who made it and what kind elide beside it.
                Item {
                    Layout.fillWidth: true
                    implicitHeight: rowName.implicitHeight
                    StyledText {
                        id: rowName
                        width: Math.min(implicitWidth, parent.width)
                        text: row.modelData.name ?? row.modelData.id
                        font.pixelSize: SettingsMaterialPreset.labelSize
                        font.weight: Font.DemiBold
                        color: SettingsMaterialPreset.labelColor
                        elide: Text.ElideRight
                    }
                    StyledText {
                        x: rowName.width + 8
                        width: Math.max(0, parent.width - x)
                        anchors.baseline: rowName.baseline
                        visible: width > 30
                        text: [Translation.tr(Hub.kindName(row.modelData.kind)), root.authorsOf(row.modelData),
                            row.here ? "" : Translation.tr("For %1").arg(root.otherFamilies(row.modelData))]
                            .filter(part => part.length > 0).join(" · ")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: SettingsMaterialPreset.supportingColor
                        elide: Text.ElideRight
                    }
                }
                // Two lines fit the row; one cut every family's summary mid-word.
                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.summary ?? ""
                    font.pixelSize: SettingsMaterialPreset.supportingSize
                    color: SettingsMaterialPreset.supportingColor
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            MaterialSymbol {
                opacity: row.permissions.length > 0 ? 1 : 0
                text: "shield"
                iconSize: 16
                color: Appearance.colors.colTertiary
                HoverHandler { id: shieldHover }
                StyledToolTip {
                    text: row.permissions.map(permission => Translation.tr(Hub.permissionText[permission] ?? permission)).join("\n")
                    extraVisibleCondition: shieldHover.hovered
                }
            }
            Stat {
                Layout.preferredWidth: 52
                visible: root.wideRows && root.hasStats
                glyph: "thumb_up"
                text: root.likedText(row.modelData)
                tip: root.votesText(row.modelData)
            }
            Stat {
                Layout.preferredWidth: 58
                visible: root.wideRows && root.hasStats
                glyph: "download"
                text: Hub.countText(row.modelData.downloads ?? 0)
                tip: Translation.tr("%1 downloads").arg(Number(row.modelData.downloads ?? 0).toLocaleString(Qt.locale(), "f", 0))
            }
            StyledText {
                Layout.preferredWidth: 52
                visible: root.wideRows
                horizontalAlignment: Text.AlignRight
                text: root.dateText(row.modelData.updated ?? "")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.features: { "tnum": 1 }
                color: SettingsMaterialPreset.supportingColor
            }
            Item {
                Layout.preferredWidth: root.wideRows ? 152 : rowAction.implicitWidth
                Layout.fillHeight: true
                ActionButton {
                    id: rowAction
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    compact: true
                    item: row.modelData
                }
            }
        }
    }

    // A card of the grid: the picture, name, who made it, votes and downloads, the action.
    component ItemTile: ClippingRectangle {
        id: tile
        required property var modelData
        readonly property bool here: tile.modelData.kind === "family" || Hub.fits(tile.modelData, root.family)
        Layout.preferredWidth: root.tileWidth
        Layout.alignment: Qt.AlignTop
        implicitHeight: tileColumn.implicitHeight
        radius: SettingsMaterialPreset.tileOuterRadius
        color: tileTap.pressed ? SettingsMaterialPreset.tilePressColor
            : tileHover.hovered ? SettingsMaterialPreset.tileHoverColor : SettingsMaterialPreset.tileColor
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }
        HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tileTap; onTapped: root.openItem(tile.modelData.id) }

        ColumnLayout {
            id: tileColumn
            width: tile.width
            spacing: 0
            Preview {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(tile.width * 10 / 16)
                radius: 0
                item: tile.modelData
                zoomed: tileHover.hovered
                opacity: tile.here ? 1 : 0.7
            }
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 10
                text: tile.modelData.name ?? tile.modelData.id
                font.pixelSize: SettingsMaterialPreset.labelSize
                font.weight: Font.DemiBold
                color: SettingsMaterialPreset.labelColor
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: [Translation.tr(Hub.kindName(tile.modelData.kind)),
                    tile.here ? root.authorsOf(tile.modelData) : Translation.tr("For %1").arg(root.otherFamilies(tile.modelData))]
                    .filter(part => part.length > 0).join(" · ")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: SettingsMaterialPreset.supportingColor
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 8
                Layout.topMargin: 6
                Layout.bottomMargin: 8
                spacing: 10
                Stat {
                    visible: root.hasStats
                    glyph: "thumb_up"
                    text: root.likedText(tile.modelData)
                    tip: root.votesText(tile.modelData)
                }
                Stat {
                    visible: root.hasStats
                    glyph: "download"
                    text: Hub.countText(tile.modelData.downloads ?? 0)
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    compact: true
                    item: tile.modelData
                }
            }
        }
    }

    // A featured item: small, tonal, its picture beside two lines of what it is.
    component FeaturedTile: Rectangle {
        id: feature
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        // A third of the band leaves the words little room: three lines, and the tile grows to hold them.
        readonly property real baseHeight: Math.round(84 * Appearance.fontSizeScale)
        implicitHeight: Math.max(feature.baseHeight, featureWords.implicitHeight + 16)
        radius: SettingsMaterialPreset.tileOuterRadius
        color: featureHover.hovered ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }
        HoverHandler { id: featureHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.openItem(feature.modelData.id) }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            anchors.rightMargin: 14
            spacing: 12
            Preview {
                Layout.fillHeight: true
                // from the base height, never its own: the words' height feeds the tile's
                Layout.preferredWidth: Math.round((feature.baseHeight - 16) * 1.6)
                radius: Math.max(6, feature.radius - 8)
                item: feature.modelData
                zoomed: featureHover.hovered
            }
            ColumnLayout {
                id: featureWords
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    Layout.fillWidth: true
                    text: feature.modelData.name ?? ""
                    font.pixelSize: SettingsMaterialPreset.labelSize
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSecondaryContainer
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: feature.modelData.summary ?? ""
                    font.pixelSize: SettingsMaterialPreset.supportingSize
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.78
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
    }

    // An item's page: back, who made it with its votes and action, its picture, the facts, what it is beside
    // what it may do, then more of the same kind.
    component ItemPage: ColumnLayout {
        id: page
        property var item
        readonly property bool wide: page.width >= 720
        readonly property var related: Hub.sorted(Hub.items.filter(other => other.id !== page.item?.id && other.kind === page.item?.kind
            && Hub.fits(other, root.family)), "popular").slice(0, 4)
        readonly property var permissions: Array.from(page.item?.permissions ?? [])
        readonly property var hosts: Array.from(page.item?.hosts ?? [])
        readonly property string pulled: String(page.item?.installedBlocked || page.item?.blocked || "")
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            IconToolbarButton {
                text: "arrow_back"
                onClicked: root.closeItem()
                StyledToolTip { text: Translation.tr("Back to the hub") }
            }
            StyledText {
                text: Translation.tr("Hub")
                font.pixelSize: Appearance.font.pixelSize.small
                color: SettingsMaterialPreset.supportingColor
                TapHandler { onTapped: root.closeItem() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            MaterialSymbol {
                text: "chevron_right"
                iconSize: Appearance.font.pixelSize.normal
                color: SettingsMaterialPreset.supportingColor
            }
            StyledText {
                text: Translation.tr(Hub.kindLabel(page.item?.kind ?? ""))
                font.pixelSize: Appearance.font.pixelSize.small
                color: SettingsMaterialPreset.supportingColor
                TapHandler {
                    onTapped: {
                        root.kind = page.item.kind
                        root.closeItem()
                        root.contentY = 0
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        // Pulled from the hub: why, first, and the way out.
        NoticeBox {
            Layout.fillWidth: true
            visible: page.pulled.length > 0
            materialIcon: "gpp_bad"
            text: Translation.tr("Pulled from the hub: %1").arg(page.pulled)
        }

        // Who made it, how people took it, and what to do with it.
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: page.item?.icon || root.kindGlyphs[page.item?.kind] || "extension"
                iconSize: 24
                padding: 12
                fill: 1
                shape: MaterialShape.Shape.Cookie9Sided
                color: Appearance.colors.colPrimaryContainer
                colSymbol: Appearance.colors.colOnPrimaryContainer
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    Layout.fillWidth: true
                    text: page.item?.name ?? ""
                    font.family: Appearance.font.family.title
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.DemiBold
                    color: SettingsMaterialPreset.labelColor
                    wrapMode: Text.WordWrap
                }
                StyledText {
                    Layout.fillWidth: true
                    text: [Translation.tr("by %1").arg(root.authorsOf(page.item)), Translation.tr(Hub.kindName(page.item?.kind ?? "")),
                        root.whereOf(page.item)].join(" · ")
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: SettingsMaterialPreset.supportingColor
                    elide: Text.ElideRight
                }
                Row {
                    Layout.topMargin: 4
                    spacing: 14
                    visible: root.hasStats
                    Stat {
                        glyph: "thumb_up"
                        text: root.likedText(page.item)
                        tip: root.votesText(page.item)
                        tint: Hub.liked(page.item) >= 0.8 ? Appearance.colors.colPrimary : SettingsMaterialPreset.supportingColor
                    }
                    Stat {
                        glyph: "download"
                        text: Hub.countText(page.item?.downloads ?? 0)
                        tip: Translation.tr("%1 downloads").arg(Number(page.item?.downloads ?? 0).toLocaleString(Qt.locale(), "f", 0))
                    }
                }
            }
            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: Boolean(page.item?.installed) && Hub.stateOf(page.item) !== "removing" && Hub.stateOf(page.item) !== "pulled"
                implicitHeight: 40
                horizontalPadding: 14
                buttonRadius: Appearance.rounding.full
                materialIcon: "delete"
                mainText: Translation.tr("Remove")
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colError, 0.08)
                contentColor: Appearance.colors.colError
                onClicked: Hub.remove(page.item.id)
            }
            ActionButton {
                Layout.alignment: Qt.AlignVCenter
                item: page.item
            }
        }

        // A plugin's own choices (plugin.json `choices`), read as its page opens; a chip flips one.
        StyledText {
            readonly property string plugin: Hub.choicesTitle(page.item).length > 0 ? page.item.id : ""
            visible: plugin.length > 0
            text: Hub.choicesTitle(page.item)
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            onPluginChanged: if (plugin.length > 0) Hub.readChoices(plugin)
            Component.onCompleted: if (plugin.length > 0) Hub.readChoices(plugin)
        }
        Flow {
            Layout.fillWidth: true
            visible: Hub.choicesTitle(page.item).length > 0
            spacing: 6
            Repeater {
                model: Hub.choices[page.item?.id ?? ""] ?? []
                delegate: FilterChip {
                    required property var modelData
                    text: modelData.label
                    selected: modelData.on
                    onClicked: Hub.toggleChoice(page.item.id, modelData.id)
                }
            }
        }

        // Its picture, capped: a page about a clock is not a poster of it.
        Preview {
            Layout.preferredWidth: Math.min(page.width, 640)
            Layout.preferredHeight: Math.round(Layout.preferredWidth * 10 / 16)
            radius: SettingsMaterialPreset.tileOuterRadius
            item: page.item
        }

        // The facts, in one segmented strip.
        RowLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            Repeater {
                id: facts
                model: [
                    { label: Translation.tr("Version"), value: String(page.item?.version ?? ""),
                      note: page.item?.installed && page.item.installed !== page.item.version ? Translation.tr("you have %1").arg(page.item.installed) : "" },
                    { label: Translation.tr("Size"), value: page.item?.size ? Hub.sizeText(page.item.size) : "" },
                    { label: Translation.tr("Updated"), value: root.dateText(page.item?.updated ?? "") },
                    { label: Translation.tr("Added"), value: root.dateText(page.item?.added ?? "") },
                    { label: Translation.tr("License"), value: String(page.item?.license ?? "") },
                    { label: Translation.tr("Works in"), value: Hub.familyNames(page.item) }
                ].filter(fact => fact.value.length > 0)
                delegate: Rectangle {
                    id: fact
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: factColumn.implicitHeight + 20
                    topLeftRadius: fact.index === 0 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                    bottomLeftRadius: fact.topLeftRadius
                    topRightRadius: fact.index === facts.count - 1 ? SettingsMaterialPreset.tileOuterRadius : SettingsMaterialPreset.tileInnerRadius
                    bottomRightRadius: fact.topRightRadius
                    color: SettingsMaterialPreset.tileColor
                    ColumnLayout {
                        id: factColumn
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 1
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: fact.modelData.value
                            font.pixelSize: SettingsMaterialPreset.labelSize
                            font.weight: Font.DemiBold
                            color: SettingsMaterialPreset.labelColor
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: fact.modelData.note || fact.modelData.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: fact.modelData.note ? Appearance.colors.colPrimary : SettingsMaterialPreset.supportingColor
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // What it is, beside what it may do. Side by side when there is room.
        GridLayout {
            Layout.fillWidth: true
            columns: page.wide ? 2 : 1
            columnSpacing: 24
            rowSpacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Subheader {
                    Layout.leftMargin: 0
                    text: Translation.tr("About")
                }
                StyledText {
                    Layout.fillWidth: true
                    text: page.item?.description || page.item?.summary || ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: SettingsMaterialPreset.labelColor
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 6
                    visible: Array.from(page.item?.tags ?? []).length > 0
                    Repeater {
                        model: Array.from(page.item?.tags ?? [])
                        delegate: FilterChip {
                            required property string modelData
                            text: modelData
                            chipIcon: "tag"
                            onClicked: root.searchFor(modelData)
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 4
                    LinkButton {
                        visible: String(page.item?.page ?? "").length > 0
                        materialIcon: "code"
                        mainText: Translation.tr("Source and setup guide")
                        onClicked: Qt.openUrlExternally(page.item.page)
                    }
                    LinkButton {
                        visible: Hub.discussionUrl(page.item).length > 0
                        materialIcon: "forum"
                        mainText: Translation.tr("Reviews and votes")
                        onClicked: Qt.openUrlExternally(Hub.discussionUrl(page.item))
                    }
                    LinkButton {
                        visible: Hub.reportUrl(page.item).length > 0
                        materialIcon: "flag"
                        mainText: Translation.tr("Report")
                        contentColor: Appearance.colors.colError
                        onClicked: Qt.openUrlExternally(Hub.reportUrl(page.item))
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: !page.wide
                Layout.preferredWidth: page.wide ? 300 : -1
                Layout.alignment: Qt.AlignTop
                implicitHeight: trustColumn.implicitHeight + 32
                radius: SettingsMaterialPreset.tileOuterRadius
                color: SettingsMaterialPreset.tileColor

                ColumnLayout {
                    id: trustColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    InfoLine {
                        glyph: "place_item"
                        title: Translation.tr("Where it shows")
                        text: root.whereOf(page.item)
                    }
                    InfoLine {
                        glyph: page.permissions.length > 0 ? "shield" : "verified_user"
                        title: page.permissions.length > 0 ? Translation.tr("What it can do") : Translation.tr("Nothing beyond the shell")
                        text: page.permissions.length > 0 ? page.permissions.map(permission => Translation.tr(Hub.permissionText[permission] ?? permission)).join("\n")
                            : Translation.tr("It only draws inside the shell: it runs no commands, reaches no websites and reads no files of yours.")
                        tint: page.permissions.length > 0 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary
                    }
                    InfoLine {
                        glyph: "public"
                        title: page.hosts.length > 0 ? Translation.tr("Reaches") : ""
                        text: page.hosts.join(", ")
                        tint: Appearance.colors.colTertiary
                    }
                    InfoLine {
                        glyph: "dns"
                        title: Translation.tr("From")
                        text: String(page.item?.sourceName || page.item?.source || "")
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: page.related.length > 0
            spacing: 8
            Subheader {
                text: Translation.tr("More %1").arg(Translation.tr(Hub.kindLabel(page.item?.kind ?? "")).toLowerCase())
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: SettingsMaterialPreset.tileGap
                Repeater {
                    model: page.related
                    delegate: ItemRow {
                        count: page.related.length
                    }
                }
            }
        }
    }

    component LinkButton: RippleButtonWithIcon {
        implicitHeight: 36
        horizontalPadding: 12
        buttonRadius: Appearance.rounding.full
        colBackground: "transparent"
        colBackgroundHover: SettingsMaterialPreset.tileHoverColor
        contentColor: Appearance.colors.colPrimary
    }

    // A fact on an item's page: glyph, a short title, and a line under it.
    component InfoLine: RowLayout {
        id: line
        property string glyph: ""
        property string title: ""
        property string text: ""
        property color tint: SettingsMaterialPreset.supportingColor
        Layout.fillWidth: true
        visible: line.title.length > 0
        spacing: 12
        MaterialSymbol {
            Layout.alignment: Qt.AlignTop
            text: line.glyph
            iconSize: SettingsMaterialPreset.iconSize
            color: line.tint
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                text: line.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: SettingsMaterialPreset.labelColor
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.fillWidth: true
                visible: line.text.length > 0
                text: line.text
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: SettingsMaterialPreset.supportingColor
                wrapMode: Text.WordWrap
            }
        }
    }
}
