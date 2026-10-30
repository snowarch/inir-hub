pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.settings

// The community hub in Waffle Settings, laid out like the Store's library: search, order and view on one line,
// counted pills, then the catalogue as Settings cards (or a grid), a page per item. Hub owns the catalogue.
WSettingsPage {
    id: root
    settingsPageIndex: 18
    pageTitle: Translation.tr("Hub")
    pageIcon: "store-microsoft"
    pageDescription: Translation.tr("Widgets, themes and web apps made by people who use iNiR")

    property string kind: ""
    property string filter: "" // "", "installed" or "updates"
    property string query: ""
    property string openId: ""
    property int shownCount: 40

    readonly property string sort: Config.options?.hub?.sort ?? "popular"
    readonly property bool grid: (Config.options?.hub?.view ?? "list") === "grid"
    readonly property var shown: Hub.sorted(Hub.items.filter(item => Hub.matches(item, root.kind, root.query, root.filter === "installed")
        && (root.filter !== "updates" || Hub.stateOf(item) === "update")), root.sort)
    readonly property var listed: root.shown.slice(0, root.shownCount)
    readonly property var opened: root.openId.length > 0 ? Hub.find(root.openId) : null
    readonly property bool hasStats: Hub.items.some(item => item.downloads !== undefined || Hub.votes(item) > 0)
    readonly property bool wideRows: root.width >= Looks.dp(620)
    readonly property int gap: Looks.dp(8)
    readonly property int columns: Math.max(2, Math.floor((root.width - Looks.dp(56) + root.gap) / (Looks.dp(200) + root.gap)))
    readonly property bool customCards: Config.options?.waffles?.widgetsPanel?.showCustom ?? true

    readonly property var permissionGlyphs: ({ process: "terminal", network: "globe-search", files: "folder", inject: "wand" })
    readonly property var kindGlyphs: ({ widget: "widgets", theme: "paint-bucket", "iris-theme": "wand", webapp: "globe-search" })

    Component.onCompleted: Hub.ensureLoaded()
    onOpenIdChanged: root.contentY = 0
    onKindChanged: root.shownCount = 40
    onFilterChanged: root.shownCount = 40
    onQueryChanged: root.shownCount = 40
    onSortChanged: root.shownCount = 40

    function actionOf(item: var): var {
        switch (Hub.stateOf(item)) {
        case "installing": return { text: Translation.tr("Installing…"), busy: true }
        case "updating": return { text: Translation.tr("Updating…"), busy: true }
        case "removing": return { text: Translation.tr("Removing…"), busy: true }
        case "failed": return { text: Translation.tr("Try again"), run: () => item.installed ? Hub.update(item.id) : Hub.install(item.id) }
        case "pulled": return { text: Translation.tr("Remove"), run: () => Hub.remove(item.id) }
        case "blocked": return { text: Translation.tr("Pulled") }
        case "update": return { text: Translation.tr("Update"), accent: true, run: () => Hub.update(item.id) }
        case "conflict": return { text: Translation.tr("Name taken") }
        case "incompatible": return { text: Translation.tr("Needs iNiR %1").arg(item.minInir) }
        case "get": return { text: Translation.tr("Get"), accent: true, run: () => Hub.install(item.id) }
        case "active": return { text: Translation.tr("In use") }
        case "present": return { text: Translation.tr("Use"), run: () => Hub.useFamily(item.id) }
        }
        if (item.kind === "theme")
            return { text: Translation.tr("Use"), run: () => Hub.useTheme(item.id) }
        if (item.kind === "widget" && Hub.fits(item, "waffle")) {
            if (root.customCards)
                return { text: Translation.tr("In use") }
            return { text: Translation.tr("Use"), run: () => Config.setNestedValue("waffles.widgetsPanel.showCustom", true) }
        }
        return { text: Translation.tr("Installed") }
    }
    function whereOf(item: var): string {
        return Hub.whereOf(item, "waffle")
    }
    // The Store's measure: votes as stars out of five.
    function starsText(item: var): string {
        const liked = Hub.liked(item)
        return liked < 0 ? "–" : (1 + 4 * liked).toFixed(1)
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

    // ── Search, filters, state ────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Looks.dp(8)
        visible: root.opened === null

        WTextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: Hub.loaded ? Translation.tr("Search %1 items").arg(Hub.items.length) : Translation.tr("Reading the hub…")
            onTextChanged: searchDelay.restart()
            Timer { id: searchDelay; interval: 140; onTriggered: root.query = searchField.text.trim() }
        }
        WComboBox {
            model: Hub.sorts.map(entry => ({ displayName: Translation.tr(entry.label), value: entry.id }))
            currentIndex: Math.max(0, Hub.sorts.findIndex(entry => entry.id === root.sort))
            onActivated: index => Config.setNestedValue("hub.sort", Hub.sorts[index].id)
        }
        Row {
            spacing: Looks.dp(2)
            Repeater {
                model: [{ id: "list", icon: "list", tip: "List" }, { id: "grid", icon: "apps", tip: "Grid" }]
                delegate: WButton {
                    id: viewKey
                    required property var modelData
                    implicitWidth: Looks.dp(36)
                    implicitHeight: Looks.dp(32)
                    checked: root.grid === (modelData.id === "grid")
                    colBackground: Looks.settings.tile
                    colBackgroundHover: Looks.settings.tileHover
                    colBackgroundActive: Looks.settings.tilePressed
                    contentItem: FluentIcon {
                        anchors.centerIn: parent
                        icon: viewKey.modelData.icon
                        implicitSize: Looks.dp(16)
                        color: viewKey.checked ? Looks.colors.accentFg : Looks.colors.fg
                    }
                    onClicked: Config.setNestedValue("hub.view", modelData.id)
                    WToolTip { text: Translation.tr(viewKey.modelData.tip) }
                }
            }
        }
        WButton {
            visible: Hub.updates > 0
            text: Translation.tr("Update all (%1)").arg(Hub.updates)
            colBackground: Looks.colors.accent
            colBackgroundHover: Looks.colors.accentHover
            colForeground: Looks.colors.accentFg
            font.pixelSize: Looks.font.pixelSize.normal
            onClicked: Hub.updateAll()
        }
        WBorderlessButton {
            implicitWidth: Looks.dp(36)
            implicitHeight: Looks.dp(36)
            enabled: !Hub.loading
            contentItem: FluentIcon { anchors.centerIn: parent; icon: "arrow-sync"; implicitSize: Looks.dp(18) }
            onClicked: Hub.refresh(true)
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: root.opened === null
        spacing: Looks.dp(8)
        FilterPill {
            text: `${Translation.tr("Everything")}  ${Hub.items.length}`
            checked: root.kind === "" && root.filter === ""
            onClicked: {
                root.kind = ""
                root.filter = ""
            }
        }
        Repeater {
            model: Hub.kinds.map(entry => Object.assign({ count: Hub.items.filter(item => item.kind === entry.id).length }, entry))
                .filter(entry => entry.count > 0)
            delegate: FilterPill {
                required property var modelData
                text: `${Translation.tr(modelData.label)}  ${modelData.count}`
                checked: root.kind === modelData.id
                onClicked: root.kind = root.kind === modelData.id ? "" : modelData.id
            }
        }
        FilterPill {
            readonly property int count: Hub.items.filter(item => Hub.owned(item)).length
            visible: count > 0
            text: `${Translation.tr("Installed")}  ${count}`
            checked: root.filter === "installed"
            onClicked: root.filter = root.filter === "installed" ? "" : "installed"
        }
        FilterPill {
            visible: Hub.updates > 0
            text: `${Translation.tr("Updates")}  ${Hub.updates}`
            checked: root.filter === "updates"
            onClicked: root.filter = root.filter === "updates" ? "" : "updates"
        }
    }

    WSettingsInfoBar {
        Layout.fillWidth: true
        visible: Hub.loaded && (!Hub.online || Hub.error.length > 0)
        severity: WSettingsInfoBar.Severity.Warning
        message: !Hub.online ? Translation.tr("You're offline: this is the list from the last time the hub answered")
            : Hub.items.length > 0 ? Translation.tr("The hub didn't answer: this is the list from the last time it did")
            : Hub.cliMissing ? Translation.tr("The hub comes with the inir command: run inir update once to get it")
            : Translation.tr("The hub didn't answer. Check your connection and try again")
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Looks.dp(32)
        visible: !Hub.loaded || (root.opened === null && root.shown.length === 0)
        spacing: Looks.dp(8)
        FluentIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: !Hub.loaded ? "arrow-sync" : root.query.length > 0 ? "search" : "store-microsoft"
            implicitSize: Looks.dp(36)
            color: Looks.colors.subfg
        }
        WText {
            Layout.alignment: Qt.AlignHCenter
            color: Looks.colors.subfg
            text: !Hub.loaded ? Translation.tr("Reading the hub…")
                : root.query.length > 0 ? Translation.tr("Nothing matches “%1”").arg(root.query)
                : root.filter === "installed" ? Translation.tr("Nothing installed from the hub yet")
                : Translation.tr("Nothing here yet")
        }
    }

    // ── The catalogue ─────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.opened === null && root.shown.length > 0 && !root.grid
        spacing: Looks.dp(3)
        Repeater {
            model: root.grid ? [] : root.listed
            delegate: ItemRow {}
        }
    }
    GridLayout {
        Layout.fillWidth: true
        visible: root.opened === null && root.shown.length > 0 && root.grid
        columns: root.columns
        columnSpacing: root.gap
        rowSpacing: root.gap
        Repeater {
            model: root.grid ? root.listed : []
            delegate: ItemCard {}
        }
    }
    WBorderedButton {
        Layout.alignment: Qt.AlignHCenter
        visible: root.opened === null && root.shown.length > root.listed.length
        text: Translation.tr("Show %1 more").arg(Math.min(40, root.shown.length - root.listed.length))
        onClicked: root.shownCount += 40
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
    WSettingsCard {
        visible: root.opened === null
        title: Translation.tr("Sources")
        icon: "globe-shield"
        description: Translation.tr("Everything in the official hub is reviewed before it is published. Other sources are not: add only the ones you trust.")
        collapsible: true
        expanded: false

        Repeater {
            model: Hub.sources
            delegate: WSettingsRow {
                id: sourceRow
                required property var modelData
                readonly property bool extra: Hub.extraSources.includes(modelData.source)
                enableSettingsSearch: false
                icon: modelData.error ? "alert" : extra ? "folder" : "shield"
                label: modelData.name || modelData.source
                description: modelData.error && modelData.count === 0 ? Translation.tr("Didn't answer")
                    : Translation.tr("%1 items · %2").arg(modelData.count).arg(modelData.source)
                control: Component {
                    WBorderedButton {
                        visible: sourceRow.extra
                        text: Translation.tr("Remove")
                        onClicked: Hub.removeSource(sourceRow.modelData.source)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Looks.dp(6)
            spacing: Looks.dp(8)
            WTextField {
                id: sourceField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Address of an index.json, or a folder")
                onAccepted: addButton.clicked()
            }
            WBorderedButton {
                id: addButton
                text: Translation.tr("Add")
                enabled: sourceField.text.trim().length > 0
                onClicked: {
                    Hub.addSource(sourceField.text)
                    sourceField.text = ""
                }
            }
        }
    }

    // ── Pieces ────────────────────────────────────────────────────────

    component FilterPill: WButton {
        id: pill
        implicitHeight: Looks.dp(30)
        horizontalPadding: Looks.dp(11)
        radius: height / 2
        colBackground: Looks.settings.tile
        colBackgroundHover: Looks.settings.tileHover
        colBackgroundActive: Looks.settings.tilePressed
        font.pixelSize: Looks.font.pixelSize.normal
        border.width: pill.checked ? 0 : 1
        border.color: Looks.settings.stroke
    }

    // The Store's rating and the download count, small, in the secondary ink.
    component Stats: Row {
        id: stats
        property var item
        property bool brief: false
        spacing: Looks.dp(10)
        visible: root.hasStats
        Row {
            spacing: Looks.dp(3)
            FluentIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "star-filled"
                implicitSize: Looks.dp(12)
                color: Hub.liked(stats.item) >= 0 ? Looks.colors.accent : Looks.colors.subfg
            }
            WText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.starsText(stats.item)
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.subfg
            }
            HoverHandler { id: starsHover }
            WToolTip {
                text: root.votesText(stats.item)
                extraVisibleCondition: starsHover.hovered
            }
        }
        WText {
            anchors.verticalCenter: parent.verticalCenter
            text: stats.brief ? Hub.countText(stats.item?.downloads ?? 0) : Translation.tr("%1 downloads").arg(Hub.countText(stats.item?.downloads ?? 0))
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
            HoverHandler { id: downloadsHover }
            WToolTip {
                text: Translation.tr("%1 downloads").arg(Number(stats.item?.downloads ?? 0).toLocaleString(Qt.locale(), "f", 0))
                extraVisibleCondition: stats.brief && downloadsHover.hovered
            }
        }
    }

    // One row of the catalogue, a Settings card: picture, name, who made it and one line of what it is,
    // then rating, downloads, the last change and the action.
    component ItemRow: Rectangle {
        id: row
        required property var modelData
        readonly property var permissions: Array.from(row.modelData.permissions ?? [])
        Layout.fillWidth: true
        implicitHeight: Looks.dp(60)
        radius: Looks.settings.radiusSmall
        color: rowTap.pressed ? Looks.settings.cardPressed : rowHover.hovered ? Looks.settings.cardHover : Looks.settings.card
        border.width: 1
        border.color: Looks.settings.cardStroke
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: rowTap; onTapped: root.openId = row.modelData.id }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Looks.dp(10)
            anchors.rightMargin: Looks.dp(12)
            spacing: Looks.dp(14)
            Preview {
                Layout.preferredHeight: row.height - Looks.dp(18)
                Layout.preferredWidth: Math.round((row.height - Looks.dp(18)) * 1.6)
                radius: Looks.settings.radiusSmall
                item: row.modelData
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Looks.dp(1)
                Item {
                    Layout.fillWidth: true
                    implicitHeight: rowName.implicitHeight
                    WText {
                        id: rowName
                        width: Math.min(implicitWidth, parent.width)
                        text: row.modelData.name ?? row.modelData.id
                        font.pixelSize: Looks.font.pixelSize.large
                        font.weight: Looks.font.weight.strong
                        elide: Text.ElideRight
                    }
                    WText {
                        x: rowName.width + Looks.dp(8)
                        width: Math.max(0, parent.width - x)
                        anchors.baseline: rowName.baseline
                        visible: width > 30
                        text: [Translation.tr(Hub.kindName(row.modelData.kind)), Array.from(row.modelData.authors ?? []).join(", ")]
                            .filter(part => part.length > 0).join(" · ")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                        elide: Text.ElideRight
                    }
                }
                WText {
                    Layout.fillWidth: true
                    text: row.modelData.summary ?? ""
                    font.pixelSize: Looks.font.pixelSize.normal
                    color: Looks.colors.fg1
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
            FluentIcon {
                opacity: row.permissions.length > 0 ? 1 : 0
                icon: "shield"
                implicitSize: Looks.dp(14)
                color: Looks.colors.subfg
                HoverHandler { id: shieldHover }
                WToolTip {
                    text: row.permissions.map(permission => Translation.tr(Hub.permissionText[permission] ?? permission)).join("\n")
                    extraVisibleCondition: shieldHover.hovered && row.permissions.length > 0
                }
            }
            Stats {
                Layout.preferredWidth: Looks.dp(84)
                visible: root.wideRows && root.hasStats
                brief: true
                item: row.modelData
            }
            WText {
                Layout.preferredWidth: Looks.dp(40)
                visible: root.wideRows
                horizontalAlignment: Text.AlignRight
                text: root.dateText(row.modelData.updated ?? "")
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.subfg
            }
            Item {
                Layout.preferredWidth: root.wideRows ? Math.max(Looks.dp(64), rowAction.implicitWidth) : rowAction.implicitWidth
                Layout.fillHeight: true
                ActionButton {
                    id: rowAction
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    item: row.modelData
                }
            }
        }
    }

    component Preview: ClippingRectangle {
        id: preview
        property var item
        color: Looks.colors.bg2
        Image {
            id: previewImage
            anchors.fill: parent
            source: preview.item?.previewUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.ceil(preview.width * 2)
            sourceSize.height: Math.ceil(preview.height * 2)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0 }
            }
        }
        FluentIcon {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            icon: root.kindGlyphs[preview.item?.kind] ?? "apps"
            implicitSize: Math.round(preview.height * 0.26)
            color: Looks.colors.subfg
        }
    }

    component ActionButton: WButton {
        id: action
        property var item
        readonly property var plan: root.actionOf(action.item)
        text: action.plan.text
        enabled: typeof action.plan.run === "function"
        horizontalPadding: Looks.dp(14)
        font.pixelSize: Looks.font.pixelSize.normal
        colBackground: action.plan.accent ? Looks.colors.accent : Looks.settings.tile
        colBackgroundHover: action.plan.accent ? Looks.colors.accentHover : Looks.settings.tileHover
        colBackgroundActive: action.plan.accent ? Looks.colors.accentActive : Looks.settings.tilePressed
        colForeground: action.plan.accent ? Looks.colors.accentFg : Looks.colors.fg
        border.width: action.plan.accent ? 0 : 1
        border.color: Looks.settings.stroke
        onClicked: action.plan.run()
    }

    component ItemCard: ClippingRectangle {
        id: card
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredWidth: Looks.dp(200)
        implicitHeight: cardColumn.implicitHeight
        radius: Looks.settings.radiusXLarge
        color: cardHover.hovered ? Looks.settings.tileHover : Looks.settings.tile
        border.width: 1
        border.color: Looks.settings.stroke

        HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.openId = card.modelData.id }

        ColumnLayout {
            id: cardColumn
            width: card.width
            spacing: 0
            Preview {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(card.width * 10 / 16)
                item: card.modelData
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Looks.dp(12)
                spacing: Looks.dp(2)
                WText {
                    Layout.fillWidth: true
                    text: card.modelData.name
                    font.pixelSize: Looks.font.pixelSize.large
                    font.weight: Looks.font.weight.strong
                    elide: Text.ElideRight
                }
                WText {
                    Layout.fillWidth: true
                    text: [Translation.tr(Hub.kindName(card.modelData.kind)), Array.from(card.modelData.authors ?? []).join(", ")]
                        .filter(part => part.length > 0).join(" · ")
                    font.pixelSize: Looks.font.pixelSize.small
                    color: Looks.colors.subfg
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Looks.dp(8)
                    spacing: Looks.dp(6)
                    Stats {
                        brief: true
                        item: card.modelData
                    }
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        item: card.modelData
                    }
                }
            }
        }
    }

    component ItemPage: ColumnLayout {
        id: page
        property var item
        spacing: Looks.dp(12)

        WBorderlessButton {
            implicitHeight: Looks.dp(32)
            contentItem: RowLayout {
                spacing: Looks.dp(8)
                FluentIcon { icon: "arrow-left"; implicitSize: Looks.dp(16) }
                WText { text: Translation.tr("Hub"); font.pixelSize: Looks.font.pixelSize.normal }
            }
            onClicked: root.openId = ""
        }

        WSettingsInfoBar {
            Layout.fillWidth: true
            readonly property string why: String(page.item?.installedBlocked || page.item?.blocked || "")
            visible: why.length > 0
            severity: WSettingsInfoBar.Severity.Error
            message: Translation.tr("Pulled from the hub: %1").arg(why)
        }

        WSettingsCard {
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Looks.dp(6)
                Layout.bottomMargin: Looks.dp(6)
                spacing: Looks.dp(18)
                Preview {
                    Layout.preferredWidth: Math.round(Math.min(Looks.dp(360), page.width * 0.5))
                    Layout.preferredHeight: Math.round(Layout.preferredWidth * 10 / 16)
                    Layout.alignment: Qt.AlignTop
                    radius: Looks.settings.radiusLarge
                    item: page.item
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Looks.dp(4)
                    WText {
                        Layout.fillWidth: true
                        text: page.item?.name ?? ""
                        font.pixelSize: Looks.font.pixelSize.xlarger
                        font.weight: Looks.font.weight.stronger
                        wrapMode: Text.WordWrap
                    }
                    WText {
                        Layout.fillWidth: true
                        text: Translation.tr("By %1").arg(Array.from(page.item?.authors ?? []).join(", "))
                        font.pixelSize: Looks.font.pixelSize.normal
                        color: Looks.colors.subfg
                    }
                    Stats {
                        Layout.topMargin: Looks.dp(2)
                        item: page.item
                    }
                    WText {
                        Layout.fillWidth: true
                        Layout.topMargin: Looks.dp(6)
                        text: page.item?.summary ?? ""
                        font.pixelSize: Looks.font.pixelSize.normal
                        wrapMode: Text.WordWrap
                    }
                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: Looks.dp(10)
                        spacing: Looks.dp(8)
                        ActionButton {
                            item: page.item
                        }
                        WBorderedButton {
                            visible: Boolean(page.item?.installed) && Hub.stateOf(page.item) !== "removing" && Hub.stateOf(page.item) !== "pulled"
                            text: Translation.tr("Remove")
                            onClicked: Hub.remove(page.item.id)
                        }
                        WBorderedButton {
                            visible: String(page.item?.page ?? "").length > 0
                            text: Translation.tr("See its files")
                            onClicked: Qt.openUrlExternally(page.item.page)
                        }
                        WBorderedButton {
                            visible: Hub.discussionUrl(page.item).length > 0
                            text: Translation.tr("Reviews and votes")
                            onClicked: Qt.openUrlExternally(Hub.discussionUrl(page.item))
                        }
                        WBorderlessButton {
                            visible: Hub.reportUrl(page.item).length > 0
                            implicitHeight: Looks.dp(32)
                            contentItem: WText {
                                text: Translation.tr("Report")
                                color: Looks.colors.danger
                                font.pixelSize: Looks.font.pixelSize.normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: Qt.openUrlExternally(Hub.reportUrl(page.item))
                        }
                    }
                }
            }
        }

        WText {
            Layout.fillWidth: true
            Layout.leftMargin: Looks.dp(4)
            visible: text.length > 0
            text: page.item?.description ?? ""
            font.pixelSize: Looks.font.pixelSize.normal
            color: Looks.colors.fg1
            wrapMode: Text.WordWrap
            lineHeight: 1.3
        }

        // Additional information, as the Store lays it out: label over value, three to a line.
        WSettingsCard {
            title: Translation.tr("About it")
            icon: "info"
            GridLayout {
                Layout.fillWidth: true
                Layout.margins: Looks.dp(4)
                columns: page.width >= Looks.dp(560) ? 3 : 2
                columnSpacing: Looks.dp(24)
                rowSpacing: Looks.dp(12)
                Repeater {
                    model: [
                            { icon: "desktop", label: Translation.tr("Where"), value: root.whereOf(page.item) },
                            { icon: "apps", label: Translation.tr("Works in"), value: Hub.familyNames(page.item) },
                            { icon: "arrow-sync", label: Translation.tr("Version"), value: page.item?.installed && page.item.installed !== page.item.version
                                ? Translation.tr("%1 (you have %2)").arg(page.item.version).arg(page.item.installed) : String(page.item?.version ?? "") },
                            { icon: "schedule", label: Translation.tr("Updated"), value: root.dateText(page.item?.updated ?? "") },
                            { icon: "add", label: Translation.tr("Added"), value: root.dateText(page.item?.added ?? "") },
                            { icon: "library", label: Translation.tr("License"), value: String(page.item?.license ?? "") },
                            { icon: "server", label: Translation.tr("Size"), value: page.item?.size ? Hub.sizeText(page.item.size) : "" },
                            { icon: "globe-shield", label: Translation.tr("From"), value: String(page.item?.sourceName || page.item?.source || "") }
                        ].filter(row => row.value.length > 0)
                    delegate: ColumnLayout {
                        id: fact
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: Looks.dp(1)
                        WText {
                            Layout.fillWidth: true
                            text: fact.modelData.label
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                        }
                        WText {
                            Layout.fillWidth: true
                            text: fact.modelData.value
                            font.pixelSize: Looks.font.pixelSize.normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        WSettingsCard {
            title: Array.from(page.item?.permissions ?? []).length > 0 ? Translation.tr("What it can do") : Translation.tr("Nothing beyond the shell")
            icon: "shield"
            description: Array.from(page.item?.permissions ?? []).length === 0
                ? Translation.tr("It only draws inside the shell: it runs no commands, reaches no websites and reads no files of yours.") : ""
            Repeater {
                model: Array.from(page.item?.permissions ?? [])
                delegate: WSettingsRow {
                    required property string modelData
                    enableSettingsSearch: false
                    icon: root.permissionGlyphs[modelData] ?? "shield"
                    label: Translation.tr(Hub.permissionText[modelData] ?? modelData)
                }
            }
            WSettingsRow {
                visible: Array.from(page.item?.hosts ?? []).length > 0
                enableSettingsSearch: false
                icon: "globe-shield"
                label: Translation.tr("Reaches")
                description: Array.from(page.item?.hosts ?? []).join(", ")
            }
        }
    }
}
