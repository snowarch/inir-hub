pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// The community hub in iRiS Settings, laid out like a store built for hundreds: one line of search, order and view,
// kinds with their counts, a small featured band, then the catalogue as rows in one reading card (or a grid of
// pictures). One item opens as a page with the store's fact strip. Hub owns the catalogue, the order and the
// installs; widgets go to the Island when they have a module for it, iRiS themes apply through IrisThemes.
Flickable {
    IrisScrollFeel {}
    id: root

    readonly property real d: IrisStyle.settingsDensity
    property string kind: ""
    property string filter: "" // "", "installed" or "updates"
    property string query: ""
    property string openId: ""
    property int shownCount: 40

    readonly property string sort: Config.options?.hub?.sort ?? "popular"
    readonly property bool grid: (Config.options?.hub?.view ?? "list") === "grid"
    readonly property bool browsing: root.kind === "" && root.query === "" && root.filter === ""
    readonly property var shown: Hub.sorted(Hub.items.filter(item => Hub.matches(item, root.kind, root.query, root.filter === "installed")
        && (root.filter !== "updates" || Hub.stateOf(item) === "update")), root.sort)
    readonly property var listed: root.shown.slice(0, root.shownCount)
    readonly property var opened: root.openId.length > 0 ? Hub.find(root.openId) : null
    readonly property bool hasStats: Hub.items.some(item => item.downloads !== undefined || Hub.votes(item) > 0)

    readonly property real columnWidth: Math.min(root.width - Math.round(32 * root.d), Math.round(900 * root.d))
    readonly property bool wide: root.columnWidth >= Math.round(600 * root.d)
    readonly property int gap: Math.round(10 * root.d)
    readonly property int bandColumns: root.columnWidth >= Math.round(720 * root.d) ? 3 : 2
    // A band of one only repeats the list's first row: it shows once it holds two.
    readonly property var featured: {
        const picks = root.browsing ? Hub.sorted(Hub.items.filter(item => item.featured === true && Hub.fits(item, "iris")
            && item.compatible !== false && !item.blocked), "popular").slice(0, root.bandColumns) : []
        return picks.length >= 2 ? picks : []
    }
    readonly property int columns: Math.max(2, Math.floor((root.columnWidth + root.gap) / (Math.round(200 * root.d) + root.gap)))
    readonly property real tileWidth: Math.floor((root.columnWidth - (root.columns - 1) * root.gap) / root.columns)
    readonly property int listInset: Math.round(4 * root.d)
    readonly property int rowRadius: IrisStyle.concentric(IrisStyle.radiusTile, root.listInset, Math.round(4 * root.d))

    readonly property var permissionGlyphs: ({ process: "terminal", network: "public", files: "folder_open", inject: "code" })
    readonly property var kindGlyphs: ({ widget: "widgets", theme: "palette", "iris-theme": "style", webapp: "language", component: "extension", design: "brush", family: "dashboard" })

    clip: true
    contentHeight: pageColumn.implicitHeight + Math.round(40 * root.d)
    ScrollBar.vertical: IrisScrollBar {}

    Component.onCompleted: {
        Hub.ensureLoaded()
        if (Hub.requestedKind.length > 0)
            root.kind = Hub.takeKind()
        if (Hub.requestedId.length > 0)
            root.openId = Hub.takeRequest()
    }
    Connections {
        target: Hub
        function onRequestedIdChanged(): void {
            if (Hub.requestedId.length > 0)
                root.openId = Hub.takeRequest()
        }
        function onRequestedKindChanged(): void {
            if (Hub.requestedKind.length > 0) {
                root.openId = ""
                root.kind = Hub.takeKind()
            }
        }
    }
    onOpenIdChanged: root.contentY = 0
    onKindChanged: root.shownCount = 40
    onFilterChanged: root.shownCount = 40
    onQueryChanged: root.shownCount = 40

    function actionOf(item: var): var {
        switch (Hub.stateOf(item)) {
        case "installing": return { text: Translation.tr("Installing…"), busy: true }
        case "updating": return { text: Translation.tr("Updating…"), busy: true }
        case "removing": return { text: Translation.tr("Removing…"), busy: true }
        case "failed": return { text: Translation.tr("Try again"), danger: true, run: () => item.installed ? Hub.update(item.id) : Hub.install(item.id) }
        case "pulled": return { text: Translation.tr("Remove"), danger: true, run: () => Hub.remove(item.id) }
        case "blocked": return { text: Translation.tr("Pulled") }
        case "update": return { text: Translation.tr("Update"), strong: true, run: () => Hub.update(item.id) }
        case "conflict": return { text: Translation.tr("Name taken") }
        case "incompatible": return { text: Translation.tr("Needs iNiR %1").arg(item.minInir) }
        case "get": return { text: Translation.tr("Get"), strong: true, run: () => Hub.install(item.id) }
        case "active": return { text: Translation.tr("In use") }
        case "present": return { text: Translation.tr("Use"), run: () => Hub.useFamily(item.id) }
        }
        if (item.kind === "iris-theme") {
            if (IrisThemes.activeId === item.id)
                return { text: Translation.tr("In use") }
            return { text: Translation.tr("Use"), run: () => root.applyTheme(item.id) }
        }
        if (item.kind === "widget" && Hub.fits(item, "iris")) {
            if (Hub.widgetInUse(item.id, "iris"))
                return { text: Translation.tr("In use") }
            return { text: Translation.tr("Use"), run: () => Hub.useWidget(item.id, "iris") }
        }
        return { text: Translation.tr("Installed") }
    }
    function whereOf(item: var): string {
        return Hub.whereOf(item, "iris")
    }
    function applyTheme(id: string): void {
        const theme = IrisThemes.find(id)
        if (theme)
            IrisThemes.choose(theme)
    }
    function bylineOf(item: var): string {
        return [Translation.tr(Hub.kindName(item?.kind ?? "")), Array.from(item?.authors ?? []).join(", ")]
            .filter(part => part.length > 0).join(" · ")
    }
    function dateText(date: string): string {
        if (!date)
            return ""
        const day = new Date(date + "T12:00:00")
        return Translation.locale.toString(day, day.getFullYear() === new Date().getFullYear() ? "d MMM" : "MMM yyyy")
    }
    function likedText(item: var): string {
        return `${Math.round(Hub.liked(item) * 100)} %`
    }

    ColumnLayout {
        id: pageColumn
        width: root.columnWidth
        x: Math.round((root.width - width) / 2)
        y: Math.round(18 * root.d)
        spacing: Math.round(14 * root.d)

        // ── Identity ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: root.opened === null
            spacing: Math.round(12 * root.d)
            Rectangle {
                implicitWidth: Math.round(40 * root.d)
                implicitHeight: implicitWidth
                radius: IrisStyle.iconRadius(width)
                gradient: Gradient {
                    GradientStop { position: 0; color: IrisStyle.tileTop(IrisStyle.identity.pink) }
                    GradientStop { position: 1; color: IrisStyle.identity.pink }
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "storefront"
                    fill: 1
                    iconSize: Math.round(22 * root.d)
                    color: IrisStyle.onTint
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                    text: Translation.tr("Made by people who use iNiR")
                }
                IrisText {
                    Layout.fillWidth: true
                    role: IrisText.Meta
                    elide: Text.ElideRight
                    text: !Hub.loaded ? Translation.tr("Reading the hub…")
                        : !Hub.online ? Translation.tr("Offline · the list from the last time the hub answered")
                        : Hub.error.length > 0 ? Translation.tr("The hub didn't answer · the list from the last time it did")
                        : Translation.tr("%1 in the hub · %2 installed").arg(Hub.items.length).arg(Hub.items.filter(item => Hub.owned(item)).length)
                }
            }
            IrisButton {
                visible: Hub.updates > 0
                emphasized: true
                text: Translation.tr("Update all (%1)").arg(Hub.updates)
                onClicked: Hub.updateAll()
            }
            IrisIconButton {
                materialIcon: "refresh"
                enabled: !Hub.loading
                onClicked: Hub.refresh(true)
            }
        }

        // ── Search, order, view ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: root.opened === null
            spacing: Math.round(8 * root.d)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(34 * root.d)
                radius: IrisStyle.capsule(height)
                color: searchField.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                border.width: searchField.activeFocus ? 1 : 0
                border.color: IrisStyle.tintBorder(IrisStyle.accent)
                MaterialSymbol {
                    id: searchGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(12 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    iconSize: Math.round(16 * root.d)
                    color: IrisStyle.muted
                }
                TextInput {
                    cursorDelegate: TextCursor { accent: IrisStyle.accent }
                    id: searchField
                    anchors.left: searchGlyph.right
                    anchors.leftMargin: Math.round(6 * root.d)
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(12 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    color: IrisStyle.text
                    selectionColor: IrisStyle.accentContainer
                    selectedTextColor: IrisStyle.inkOnAccentContainer
                    font.family: IrisStyle.fontMain
                    font.pixelSize: IrisStyle.typeLabel
                    clip: true
                    onTextChanged: searchDelay.restart()
                    Timer { id: searchDelay; interval: 140; onTriggered: root.query = searchField.text }
                    IrisText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text.length === 0
                        text: Hub.items.length > 0 ? Translation.tr("Search %1 items").arg(Hub.items.length) : Translation.tr("Search the hub")
                        color: IrisStyle.muted
                        font.pixelSize: searchField.font.pixelSize
                    }
                }
            }
            IrisPopupButton {
                Layout.preferredHeight: Math.round(34 * root.d)
                accessibleName: Translation.tr("Order")
                options: Hub.sorts.map(entry => ({ value: entry.id, label: Translation.tr(entry.label), glyph: entry.icon }))
                current: root.sort
                onPicked: value => Config.setNestedValue("hub.sort", String(value))
            }
            IrisSegmented {
                glyphOnly: true
                accessibleName: Translation.tr("View")
                current: root.grid ? "grid" : "list"
                options: [
                    { value: "list", glyph: "view_agenda", label: Translation.tr("List") },
                    { value: "grid", glyph: "grid_view", label: Translation.tr("Grid") }
                ]
                onPicked: value => Config.setNestedValue("hub.view", String(value))
            }
        }

        // ── Kinds, each with its count ────────────────────────────────
        Flow {
            Layout.fillWidth: true
            visible: root.opened === null
            spacing: Math.round(6 * root.d)
            IrisChip {
                label: `${Translation.tr("Everything")}  ${Hub.items.length}`
                selected: root.kind === "" && root.filter === ""
                onClicked: {
                    root.kind = ""
                    root.filter = ""
                }
            }
            Repeater {
                model: Hub.kinds.map(entry => Object.assign({ count: Hub.items.filter(item => item.kind === entry.id).length }, entry))
                    .filter(entry => entry.count > 0)
                delegate: IrisChip {
                    required property var modelData
                    label: `${Translation.tr(modelData.label)}  ${modelData.count}`
                    selected: root.kind === modelData.id
                    onClicked: root.kind = root.kind === modelData.id ? "" : modelData.id
                }
            }
            IrisChip {
                readonly property int count: Hub.items.filter(item => Hub.owned(item)).length
                visible: count > 0
                glyph: "download_done"
                label: `${Translation.tr("Installed")}  ${count}`
                selected: root.filter === "installed"
                onClicked: root.filter = root.filter === "installed" ? "" : "installed"
            }
            IrisChip {
                visible: Hub.updates > 0
                glyph: "update"
                label: `${Translation.tr("Updates")}  ${Hub.updates}`
                selected: root.filter === "updates"
                onClicked: root.filter = root.filter === "updates" ? "" : "updates"
            }
        }

        // ── Empty and unreachable states ──────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(28 * root.d)
            visible: Hub.loaded && root.opened === null && root.shown.length === 0
            spacing: Math.round(6 * root.d)
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: root.query.length > 0 ? "search_off" : Hub.items.length === 0 ? "cloud_off" : "download_done"
                iconSize: Math.round(36 * root.d)
                color: IrisStyle.textTertiary
            }
            IrisText {
                Layout.alignment: Qt.AlignHCenter
                text: root.query.length > 0 ? Translation.tr("Nothing matches “%1”").arg(root.query)
                    : Hub.cliMissing ? Translation.tr("The hub comes with the inir command: run inir update once to get it")
                    : Hub.items.length === 0 ? Translation.tr("The hub didn't answer. Check your connection and try again")
                    : root.filter === "installed" ? Translation.tr("Nothing installed from the hub yet")
                    : Translation.tr("Nothing here yet")
            }
            IrisButton {
                Layout.alignment: Qt.AlignHCenter
                visible: Hub.items.length === 0
                text: Translation.tr("Try again")
                onClicked: Hub.refresh(true)
            }
        }

        // ── Featured: a band, never a banner ──────────────────────────
        Heading {
            visible: root.opened === null && root.featured.length > 0
            text: Translation.tr("Featured")
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.opened === null && root.featured.length > 0
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

        // ── The catalogue ─────────────────────────────────────────────
        Heading {
            visible: root.opened === null && root.featured.length > 0 && root.shown.length > 0
            text: Translation.tr(Hub.sorts.find(entry => entry.id === root.sort)?.label ?? "Popular")
        }
        Rectangle {
            Layout.fillWidth: true
            visible: root.opened === null && !root.grid && root.listed.length > 0
            implicitHeight: listColumn.implicitHeight + 2 * root.listInset
            radius: IrisStyle.radiusTile
            color: IrisStyle.readingCard
            Column {
                id: listColumn
                x: root.listInset
                y: root.listInset
                width: parent.width - 2 * root.listInset
                Repeater {
                    model: root.grid ? [] : root.listed
                    delegate: ItemRow {}
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            visible: root.opened === null && root.grid
            spacing: root.gap
            Repeater {
                model: root.grid ? root.listed : []
                delegate: ItemCard {}
            }
        }
        IrisButton {
            Layout.alignment: Qt.AlignHCenter
            visible: root.opened === null && root.shown.length > root.listed.length
            quiet: true
            text: Translation.tr("Show %1 more").arg(Math.min(40, root.shown.length - root.listed.length))
            onClicked: root.shownCount += 40
        }

        // ── One item ──────────────────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            active: root.opened !== null
            visible: active
            sourceComponent: ItemPage {
                item: root.opened
            }
        }

        // ── Sources ───────────────────────────────────────────────────
        Heading {
            visible: root.opened === null && Hub.loaded
            text: Translation.tr("Sources")
        }
        Rectangle {
            Layout.fillWidth: true
            visible: root.opened === null && Hub.loaded
            implicitHeight: sourceColumn.implicitHeight + Math.round(16 * root.d)
            radius: IrisStyle.radiusTile
            color: IrisStyle.readingCard
            ColumnLayout {
                id: sourceColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(8 * root.d)
                spacing: Math.round(2 * root.d)
                Repeater {
                    model: Hub.sources
                    delegate: RowLayout {
                        id: sourceRow
                        required property var modelData
                        readonly property bool extra: Hub.extraSources.includes(modelData.source)
                        Layout.fillWidth: true
                        Layout.leftMargin: Math.round(8 * root.d)
                        Layout.minimumHeight: Math.round(40 * root.d)
                        spacing: Math.round(10 * root.d)
                        MaterialSymbol {
                            text: sourceRow.modelData.error ? "error" : sourceRow.extra ? "folder_special" : "verified"
                            fill: 1
                            iconSize: Math.round(18 * root.d)
                            color: sourceRow.modelData.error ? IrisStyle.danger : IrisStyle.accent
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            IrisText {
                                Layout.fillWidth: true
                                text: sourceRow.modelData.name || sourceRow.modelData.source
                                font.pixelSize: IrisStyle.typeLabel
                                elide: Text.ElideMiddle
                            }
                            IrisText {
                                Layout.fillWidth: true
                                role: IrisText.Meta
                                text: sourceRow.modelData.error && sourceRow.modelData.count === 0 ? Translation.tr("Didn't answer")
                                    : Translation.tr("%1 items · %2").arg(sourceRow.modelData.count).arg(sourceRow.modelData.source)
                                elide: Text.ElideMiddle
                            }
                        }
                        IrisIconButton {
                            visible: sourceRow.extra
                            materialIcon: "delete"
                            onClicked: Hub.removeSource(sourceRow.modelData.source)
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(4 * root.d)
                    implicitHeight: Math.round(34 * root.d)
                    radius: IrisStyle.radiusRow
                    color: sourceInput.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                    TextInput {
                        cursorDelegate: TextCursor { accent: IrisStyle.accent }
                        id: sourceInput
                        anchors.left: parent.left
                        anchors.right: addSource.left
                        anchors.leftMargin: Math.round(12 * root.d)
                        anchors.rightMargin: Math.round(8 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        color: IrisStyle.text
                        selectionColor: IrisStyle.accentContainer
                        selectedTextColor: IrisStyle.inkOnAccentContainer
                        font.family: IrisStyle.fontMain
                        font.pixelSize: IrisStyle.typeLabel
                        clip: true
                        onAccepted: addSource.clicked()
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: sourceInput.text.length === 0
                            text: Translation.tr("Address of an index.json, or a folder")
                            color: IrisStyle.muted
                            font.pixelSize: sourceInput.font.pixelSize
                        }
                    }
                    IrisButton {
                        id: addSource
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(2 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        quiet: true
                        text: Translation.tr("Add")
                        enabled: sourceInput.text.trim().length > 0
                        onClicked: {
                            Hub.addSource(sourceInput.text)
                            sourceInput.text = ""
                        }
                    }
                }
            }
        }
        IrisText {
            Layout.fillWidth: true
            Layout.leftMargin: Math.round(16 * root.d)
            Layout.rightMargin: Math.round(16 * root.d)
            Layout.topMargin: Math.round(-8 * root.d)
            visible: root.opened === null && Hub.loaded
            role: IrisText.Meta
            wrapMode: Text.WordWrap
            text: Translation.tr("Everything in the official hub is reviewed before it is published. Other sources are not: add only the ones you trust.")
        }
    }

    // ── Pieces ────────────────────────────────────────────────────────

    component Heading: IrisText {
        Layout.leftMargin: Math.round(16 * root.d)
        Layout.bottomMargin: Math.round(-8 * root.d)
        color: IrisStyle.muted
        font.family: IrisStyle.fontTitle
        font.pixelSize: IrisStyle.typeMeta
        font.weight: IrisStyle.weight(Font.DemiBold)
    }

    component Preview: ClippingRectangle {
        id: preview
        property var item
        color: IrisStyle.fillQuiet
        IrisImage {
            id: previewImage
            anchors.fill: parent
            source: preview.item?.previewUrl ?? ""
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity {
                enabled: IrisStyle.motionEnabled
                NumberAnimation { duration: IrisStyle.duration(180) }
            }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            visible: previewImage.status !== Image.Ready
            text: root.kindGlyphs[preview.item?.kind] ?? "extension"
            fill: 1
            iconSize: Math.round(preview.height * 0.36)
            color: IrisStyle.textTertiary
        }
    }

    // Liked share, downloads and (unless brief) the last update, as small tabular figures.
    component Stats: Row {
        id: stats
        property var item
        property bool brief: false
        spacing: Math.round(10 * root.d)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Hub.liked(stats.item) >= 0
            spacing: Math.round(2 * root.d)
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "thumb_up"
                fill: 1
                iconSize: Math.round(12 * root.d)
                color: IrisStyle.textTertiary
            }
            IrisText {
                role: IrisText.Meta
                font.pixelSize: IrisStyle.typeFootnote
                font.features: { "tnum": 1 }
                text: root.likedText(stats.item)
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: stats.item?.downloads !== undefined
            spacing: Math.round(2 * root.d)
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "download"
                iconSize: Math.round(13 * root.d)
                color: IrisStyle.textTertiary
            }
            IrisText {
                role: IrisText.Meta
                font.pixelSize: IrisStyle.typeFootnote
                font.features: { "tnum": 1 }
                text: Hub.countText(stats.item?.downloads ?? 0)
            }
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !stats.brief && text.length > 0
            role: IrisText.Meta
            font.pixelSize: IrisStyle.typeFootnote
            font.features: { "tnum": 1 }
            text: root.dateText(stats.item?.updated ?? "")
        }
    }

    component ActionButton: IrisButton {
        id: action
        property var item
        readonly property var plan: root.actionOf(action.item)
        text: action.plan.text
        emphasized: Boolean(action.plan.strong)
        danger: Boolean(action.plan.danger)
        quiet: typeof action.plan.run !== "function"
        enabled: typeof action.plan.run === "function"
        onClicked: action.plan.run()
    }

    // The action in a slot every row shares, so names, figures and buttons line up down the list.
    component ActionSlot: Item {
        id: slot
        property var item
        Layout.preferredWidth: Math.max(Math.round(88 * root.d), slotButton.implicitWidth)
        implicitHeight: slotButton.implicitHeight
        ActionButton {
            id: slotButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            item: slot.item
        }
    }

    component ItemRow: Item {
        id: row
        required property var modelData
        required property int index
        readonly property bool last: row.index === root.listed.length - 1
        width: listColumn.width
        height: Math.max(Math.round(64 * root.d), rowLine.implicitHeight + Math.round(16 * root.d))

        Rectangle {
            anchors.fill: parent
            radius: root.rowRadius
            color: rowHover.hovered ? IrisStyle.fillQuiet : "transparent"
            Behavior on color {
                enabled: IrisStyle.motionEnabled
                ColorAnimation { duration: IrisStyle.duration(110) }
            }
        }
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.openId = row.modelData.id }

        RowLayout {
            id: rowLine
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Math.round(10 * root.d)
            anchors.rightMargin: Math.round(10 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(12 * root.d)
            Preview {
                id: rowThumb
                Layout.preferredWidth: Math.round(72 * root.d)
                Layout.preferredHeight: Math.round(45 * root.d)
                radius: IrisStyle.radiusRow
                item: row.modelData
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: row.modelData.summary ?? ""
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    elide: Text.ElideRight
                }
                // Plain anchors: a layout sizing the byline by its own width rearranges forever.
                Item {
                    id: metaLine
                    Layout.fillWidth: true
                    implicitHeight: Math.max(byline.implicitHeight, rowStats.implicitHeight)
                    IrisText {
                        id: byline
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, Math.max(0, metaLine.width
                            - (rowStats.visible ? rowStats.implicitWidth + Math.round(10 * root.d) : 0)))
                        role: IrisText.Meta
                        font.pixelSize: IrisStyle.typeFootnote
                        text: Hub.stateOf(row.modelData) === "pulled" || Hub.stateOf(row.modelData) === "blocked"
                            ? Translation.tr("Pulled from the hub") : root.bylineOf(row.modelData)
                        color: Hub.stateOf(row.modelData) === "pulled" ? IrisStyle.danger : IrisStyle.subtext
                        elide: Text.ElideRight
                    }
                    Stats {
                        id: rowStats
                        anchors.left: byline.right
                        anchors.leftMargin: Math.round(10 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.hasStats
                        item: row.modelData
                    }
                }
            }
            MaterialSymbol {
                visible: root.wide
                opacity: Array.from(row.modelData.permissions ?? []).length > 0 ? 1 : 0
                text: "shield"
                fill: 1
                iconSize: Math.round(16 * root.d)
                color: IrisStyle.secondaryAccent
            }
            ActionSlot {
                item: row.modelData
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Math.round(10 * root.d) + rowThumb.width + Math.round(12 * root.d)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(10 * root.d)
            anchors.bottom: parent.bottom
            height: 1
            visible: !row.last && !rowHover.hovered
            color: IrisStyle.hairline
        }
    }

    component ItemCard: ClippingRectangle {
        id: card
        required property var modelData
        width: root.tileWidth
        height: cardColumn.implicitHeight
        radius: IrisStyle.radiusTile
        color: cardHover.hovered ? IrisStyle.fillHover : IrisStyle.readingCard

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
                Layout.margins: Math.round(10 * root.d)
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: card.modelData.name
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    role: IrisText.Meta
                    font.pixelSize: IrisStyle.typeFootnote
                    text: root.bylineOf(card.modelData)
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(6 * root.d)
                    spacing: Math.round(6 * root.d)
                    // A long state ("Needs iNiR 2.40.0") takes the line; the figures step aside, never under it.
                    Stats {
                        id: cardStats
                        visible: root.hasStats && cardAction.implicitWidth + implicitWidth + Math.round(6 * root.d) <= card.width - Math.round(20 * root.d)
                        brief: true
                        item: card.modelData
                    }
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        id: cardAction
                        Layout.maximumWidth: card.width - Math.round(20 * root.d)
                        item: card.modelData
                    }
                }
            }
        }
    }

    // A featured item: its picture beside its name and what it does, small enough that the list stays in view.
    component FeaturedTile: Rectangle {
        id: tile
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: tileLine.implicitHeight + Math.round(16 * root.d)
        radius: IrisStyle.radiusTile
        color: tileHover.hovered ? IrisStyle.fillHover : IrisStyle.readingCard

        HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.openId = tile.modelData.id }

        RowLayout {
            id: tileLine
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Math.round(8 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(10 * root.d)
            Preview {
                Layout.preferredWidth: Math.round(80 * root.d)
                Layout.preferredHeight: Math.round(50 * root.d)
                radius: IrisStyle.concentric(IrisStyle.radiusTile, Math.round(8 * root.d), Math.round(4 * root.d))
                item: tile.modelData
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: tile.modelData.name
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    text: tile.modelData.summary ?? ""
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeFootnote
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ItemPage: ColumnLayout {
        id: page
        property var item
        readonly property var permissions: Array.from(page.item?.permissions ?? [])
        readonly property var hosts: Array.from(page.item?.hosts ?? [])
        readonly property string pulledWhy: String(page.item?.installedBlocked || page.item?.blocked || "")
        spacing: Math.round(14 * root.d)

        IrisButton {
            quiet: true
            text: Translation.tr("‹ Hub")
            onClicked: root.openId = ""
        }

        Rectangle {
            Layout.fillWidth: true
            visible: page.pulledWhy.length > 0
            implicitHeight: pulledLine.implicitHeight + Math.round(20 * root.d)
            radius: IrisStyle.radiusTile
            color: IrisStyle.tintFill(IrisStyle.danger)
            RowLayout {
                id: pulledLine
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Math.round(14 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(10 * root.d)
                MaterialSymbol {
                    text: "gpp_bad"
                    fill: 1
                    iconSize: Math.round(18 * root.d)
                    color: IrisStyle.danger
                }
                IrisText {
                    Layout.fillWidth: true
                    font.pixelSize: IrisStyle.typeLabel
                    wrapMode: Text.WordWrap
                    text: Translation.tr("Pulled from the hub: %1").arg(page.pulledWhy)
                }
            }
        }

        // The head: picture, name, author and the one action.
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(16 * root.d)
            Preview {
                Layout.preferredWidth: Math.round(Math.min(300 * root.d, page.width * 0.42))
                Layout.preferredHeight: Math.round(Layout.preferredWidth * 10 / 16)
                Layout.alignment: Qt.AlignTop
                radius: IrisStyle.radiusTile
                item: page.item
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Math.round(2 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: page.item?.name ?? ""
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.Bold)
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    Layout.fillWidth: true
                    role: IrisText.Meta
                    elide: Text.ElideRight
                    visible: Array.from(page.item?.authors ?? []).length > 0
                    text: Translation.tr("By %1").arg(Array.from(page.item?.authors ?? []).join(", "))
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(6 * root.d)
                    text: page.item?.summary ?? ""
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    wrapMode: Text.WordWrap
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(10 * root.d)
                    spacing: Math.round(6 * root.d)
                    ActionButton {
                        item: page.item
                    }
                    IrisButton {
                        visible: Boolean(page.item?.installed) && !["removing", "pulled"].includes(Hub.stateOf(page.item))
                        danger: true
                        quiet: true
                        text: Translation.tr("Remove")
                        onClicked: Hub.remove(page.item.id)
                    }
                }
                // A plugin's own choices (plugin.json `choices`), read as its page opens; a chip flips one.
                IrisText {
                    readonly property string plugin: Hub.choicesTitle(page.item).length > 0 ? page.item.id : ""
                    visible: plugin.length > 0
                    Layout.topMargin: Math.round(16 * root.d)
                    text: Hub.choicesTitle(page.item)
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    onPluginChanged: if (plugin.length > 0) Hub.readChoices(plugin)
                    Component.onCompleted: if (plugin.length > 0) Hub.readChoices(plugin)
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(6 * root.d)
                    visible: Hub.choicesTitle(page.item).length > 0
                    spacing: Math.round(6 * root.d)
                    Repeater {
                        model: Hub.choices[page.item?.id ?? ""] ?? []
                        delegate: IrisChip {
                            required property var modelData
                            label: modelData.label
                            selected: modelData.on
                            onClicked: Hub.toggleChoice(page.item.id, modelData.id)
                        }
                    }
                }
            }
        }

        // The store's fact strip: a figure over what it counts, split by hairlines.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: factLine.implicitHeight + Math.round(20 * root.d)
            radius: IrisStyle.radiusTile
            color: IrisStyle.readingCard
            RowLayout {
                id: factLine
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Repeater {
                    model: [
                        { figure: Hub.liked(page.item) >= 0 ? root.likedText(page.item) : "–", caption: Hub.votes(page.item) > 0
                            ? Translation.tr("%1 of %2 people liked it").arg(page.item?.votesUp ?? 0).arg(Hub.votes(page.item)) : Translation.tr("No votes yet") },
                        { figure: page.item?.downloads !== undefined ? Hub.countText(page.item.downloads) : "", caption: Translation.tr("Downloads") },
                        { figure: String(page.item?.version ?? ""), caption: page.item?.installed && page.item.installed !== page.item.version
                            ? Translation.tr("You have %1").arg(page.item.installed) : Translation.tr("Version") },
                        { figure: root.dateText(page.item?.updated ?? ""), caption: Translation.tr("Updated") },
                        { figure: page.item?.size ? Hub.sizeText(page.item.size) : "", caption: Translation.tr("Size") }
                    ].filter(fact => fact.figure.length > 0)
                    delegate: Item {
                        id: fact
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: factColumn.implicitHeight
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: parent.height * 0.7
                            visible: fact.index > 0
                            color: IrisStyle.hairline
                        }
                        ColumnLayout {
                            id: factColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Math.round(8 * root.d)
                            anchors.rightMargin: Math.round(8 * root.d)
                            spacing: 0
                            IrisText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: fact.modelData.figure
                                font.pixelSize: IrisStyle.typeHeadline
                                font.weight: IrisStyle.weight(IrisStyle.figureWeight)
                                font.features: { "tnum": 1 }
                                elide: Text.ElideRight
                            }
                            IrisText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                role: IrisText.Meta
                                font.pixelSize: IrisStyle.typeFootnote
                                text: fact.modelData.caption
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        IrisText {
            Layout.fillWidth: true
            Layout.leftMargin: Math.round(4 * root.d)
            // Many listings repeat the summary as the description: say it once.
            visible: text.length > 0 && text.replace(/\.$/, "") !== String(page.item?.summary ?? "").replace(/\.$/, "")
            text: page.item?.description ?? ""
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeLabel
            wrapMode: Text.WordWrap
            lineHeight: 1.2
        }

        Heading { text: Hub.reachTitle(page.item) }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: permissionColumn.implicitHeight + Math.round(16 * root.d)
            radius: IrisStyle.radiusTile
            color: IrisStyle.readingCard
            ColumnLayout {
                id: permissionColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(8 * root.d)
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    Layout.margins: Math.round(8 * root.d)
                    visible: page.permissions.length === 0
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    wrapMode: Text.WordWrap
                    text: Hub.reachText(page.item)
                }
                Repeater {
                    model: page.permissions
                    delegate: PermissionLine {
                        required property string modelData
                        glyph: root.permissionGlyphs[modelData] ?? "shield"
                        label: Translation.tr(Hub.permissionText[modelData] ?? modelData)
                    }
                }
                PermissionLine {
                    visible: page.hosts.length > 0
                    glyph: "dns"
                    label: Translation.tr("Reaches")
                    detail: page.hosts.join(", ")
                }
            }
        }

        Heading { text: Translation.tr("About it") }
        InfoCard {
            rows: [
                { label: Translation.tr("Where"), value: root.whereOf(page.item) },
                { label: Translation.tr("Works in"), value: Hub.familyNames(page.item) },
                { label: Translation.tr("Added"), value: root.dateText(page.item?.added ?? "") },
                { label: Translation.tr("License"), value: String(page.item?.license ?? "") },
                { label: Translation.tr("From"), value: String(page.item?.sourceName || page.item?.source || "") }
            ].filter(row => row.value.length > 0)
        }

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.d)
            IrisButton {
                visible: Hub.discussionUrl(page.item).length > 0
                quiet: true
                text: Translation.tr("Reviews and votes")
                onClicked: Qt.openUrlExternally(Hub.discussionUrl(page.item))
            }
            IrisButton {
                visible: String(page.item?.page ?? "").length > 0
                quiet: true
                text: Translation.tr("See its files")
                onClicked: Qt.openUrlExternally(page.item.page)
            }
            IrisButton {
                visible: Hub.reportUrl(page.item).length > 0
                quiet: true
                danger: true
                text: Translation.tr("Report")
                onClicked: Qt.openUrlExternally(Hub.reportUrl(page.item))
            }
        }
    }

    component PermissionLine: RowLayout {
        id: line
        property string glyph
        property string label
        property string detail: ""
        Layout.fillWidth: true
        Layout.minimumHeight: Math.round(36 * root.d)
        Layout.leftMargin: Math.round(8 * root.d)
        spacing: Math.round(10 * root.d)
        MaterialSymbol {
            text: line.glyph
            fill: 1
            iconSize: Math.round(18 * root.d)
            color: IrisStyle.secondaryAccent
        }
        IrisText {
            font.pixelSize: IrisStyle.typeLabel
            text: line.label
        }
        IrisText {
            Layout.fillWidth: true
            Layout.rightMargin: Math.round(8 * root.d)
            visible: line.detail.length > 0
            horizontalAlignment: Text.AlignRight
            role: IrisText.Meta
            text: line.detail
            elide: Text.ElideMiddle
        }
    }

    component InfoCard: Rectangle {
        id: infoCard
        property var rows: []
        Layout.fillWidth: true
        implicitHeight: infoColumn.implicitHeight
        radius: IrisStyle.radiusTile
        color: IrisStyle.readingCard
        Column {
            id: infoColumn
            width: parent.width
            Repeater {
                model: infoCard.rows
                Item {
                    id: infoRow
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: Math.round(40 * root.d)
                    IrisText {
                        id: infoLabel
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(16 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        text: infoRow.modelData.label
                        font.pixelSize: IrisStyle.typeLabel
                    }
                    IrisText {
                        anchors.left: infoLabel.right
                        anchors.leftMargin: Math.round(16 * root.d)
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(16 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: infoRow.modelData.value
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeLabel
                        elide: Text.ElideMiddle
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(16 * root.d)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        visible: infoRow.index < infoCard.rows.length - 1
                        color: IrisStyle.hairline
                    }
                }
            }
        }
    }
}
