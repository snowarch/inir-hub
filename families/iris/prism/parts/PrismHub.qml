pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The community hub in Prism (`.claude/ref/language`): a shelf of sleeves. One line says what the hub holds; search is
// a well, the order folds out in place under it, kinds are keys with their counts; the featured band is pictures with
// their words on frosted glass, then the catalogue as cards or as rows in one card. An item opens as its own page
// (`PrismHubItem`). Hub owns the catalogue, the order and the installs; widgets go to the Island when they have a
// module for it, iRiS themes apply through IrisThemes.
Flickable {
    id: root
    IrisScrollFeel {}
    clip: true
    contentHeight: column.implicitHeight + PrismTheme.dp(40)
    boundsBehavior: Flickable.StopAtBounds

    property string kind: ""
    property string filter: "" // "", "installed" or "updates"
    property string query: ""
    property string openId: ""
    property int shownCount: 40
    property bool sorting: false

    readonly property string sort: Config.options?.hub?.sort ?? "popular"
    readonly property bool grid: (Config.options?.hub?.view ?? "list") === "grid"
    readonly property bool browsing: root.kind === "" && root.query === "" && root.filter === ""
    readonly property var shown: Hub.sorted(Hub.items.filter(item => Hub.matches(item, root.kind, root.query, root.filter === "installed")
        && (root.filter !== "updates" || Hub.stateOf(item) === "update")), root.sort)
    readonly property var listed: root.shown.slice(0, root.shownCount)
    readonly property var opened: root.openId.length > 0 ? Hub.find(root.openId) : null
    readonly property bool hasStats: Hub.items.some(item => item.downloads !== undefined || Hub.votes(item) > 0)
    readonly property int installed: Hub.items.filter(item => Hub.owned(item)).length

    readonly property real gap: PrismTheme.dp(10)
    readonly property int bandColumns: column.width >= PrismTheme.dp(720) ? 3 : 2
    // A band of one only repeats the shelf's first item: it shows once it holds two.
    readonly property var featured: {
        const picks = root.browsing ? Hub.sorted(Hub.items.filter(item => item.featured === true && Hub.fits(item, "iris")
            && item.compatible !== false && !item.blocked), "popular").slice(0, root.bandColumns) : []
        return picks.length >= 2 ? picks : []
    }
    readonly property int columns: Math.max(2, Math.floor((column.width + root.gap) / (PrismTheme.dp(210) + root.gap)))
    readonly property real cardWidth: Math.floor((column.width - (root.columns - 1) * root.gap) / root.columns)

    Component.onCompleted: {
        Hub.ensureLoaded()
        if (Hub.requestedKind.length > 0) root.kind = Hub.takeKind()
        if (Hub.requestedId.length > 0) root.openId = Hub.takeRequest()
    }
    Connections {
        target: Hub
        function onRequestedIdChanged(): void {
            if (Hub.requestedId.length > 0) root.openId = Hub.takeRequest()
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
        if (item?.kind === "iris-theme") {
            if (IrisThemes.activeId === item.id) return { text: Translation.tr("In use") }
            return { text: Translation.tr("Use"), run: () => root.applyTheme(item.id) }
        }
        if (item?.kind === "widget" && Hub.fits(item, "iris")) {
            if (Hub.widgetInUse(item.id, "iris")) return { text: Translation.tr("In use") }
            return { text: Translation.tr("Use"), run: () => Hub.useWidget(item.id, "iris") }
        }
        return { text: Translation.tr("Installed") }
    }
    function applyTheme(id: string): void {
        const theme = IrisThemes.find(id)
        if (theme) IrisThemes.choose(theme)
    }
    function bylineOf(item: var): string {
        return [Translation.tr(Hub.kindName(item?.kind ?? "")), Array.from(item?.authors ?? []).join(", ")]
            .filter(part => part.length > 0).join(" · ")
    }
    function dateText(date: string): string {
        if (!date) return ""
        const day = new Date(date + "T12:00:00")
        return Translation.locale.toString(day, day.getFullYear() === new Date().getFullYear() ? "d MMM" : "MMM yyyy")
    }
    function likedText(item: var): string {
        return `${Math.round(Hub.liked(item) * 100)} %`
    }

    Column {
        id: column
        x: PrismTheme.dp(32)
        width: root.width - PrismTheme.dp(64)
        spacing: PrismTheme.dp(16)

        // ── What the hub holds, and what to do about it ─────────────────
        Item {
            width: parent.width
            height: PrismTheme.dp(34)
            visible: root.opened === null
            PrismText {
                anchors.left: parent.left
                anchors.right: tools.left
                anchors.rightMargin: PrismTheme.dp(12)
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                mono: true
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.caption - 1
                font.letterSpacing: 0.8
                text: (!Hub.loaded ? Translation.tr("Reading the hub…")
                    : !Hub.online ? Translation.tr("Offline · the list from the last time the hub answered")
                    : Hub.error.length > 0 ? Translation.tr("The hub didn't answer · the list from the last time it did")
                    : Translation.tr("%1 in the hub · %2 installed").arg(Hub.items.length).arg(root.installed)).toUpperCase()
            }
            Row {
                id: tools
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(8)
                PrismPill {
                    visible: Hub.updates > 0
                    glyph: "update"
                    text: Translation.tr("Update all (%1)").arg(Hub.updates)
                    onClicked: Hub.updateAll()
                }
                PrismRound {
                    implicitWidth: PrismTheme.dp(34)
                    glyph: "refresh"
                    glyphSize: PrismTheme.dp(17)
                    enabled_: !Hub.loading
                    Accessible.name: Translation.tr("Refresh")
                    onClicked: Hub.refresh(true)
                }
            }
        }

        // ── Search, order, view ─────────────────────────────────────────
        Row {
            width: parent.width
            visible: root.opened === null
            spacing: PrismTheme.dp(8)
            PrismField {
                id: search
                width: parent.width - order.width - view.width - parent.spacing * 2
                height: PrismTheme.dp(38)
                glyph: "search"
                commitOnEdit: true
                placeholder: Hub.items.length > 0 ? Translation.tr("Search %1 items").arg(Hub.items.length) : Translation.tr("Search the hub")
                onEdited: text => searchDelay.restart()
                Timer { id: searchDelay; interval: 140; onTriggered: root.query = search.input.text }
            }
            // The order says itself and folds its choices out under this line, never a menu.
            Item {
                id: order
                width: orderLine.implicitWidth + PrismTheme.dp(30)
                height: PrismTheme.dp(38)
                readonly property var current: Hub.sorts.find(entry => entry.id === root.sort) ?? Hub.sorts[0]
                PrismKey {
                    anchors.fill: parent
                    radius: height / 2
                    face: root.sorting ? PrismTheme.solid : PrismTheme.keyQuiet
                    hovered: orderArea.containsMouse
                    down: orderArea.pressed
                    Row {
                        id: orderLine
                        anchors.centerIn: parent
                        spacing: PrismTheme.dp(6)
                        PrismGlyph {
                            anchors.verticalCenter: parent.verticalCenter
                            text: order.current.icon
                            filled: true
                            iconSize: PrismTheme.dp(16)
                            color: root.sorting ? PrismTheme.inkSolid : PrismTheme.ink
                        }
                        PrismText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(order.current.label)
                            font.pixelSize: PrismTheme.small
                            font.weight: Font.DemiBold
                            color: root.sorting ? PrismTheme.inkSolid : PrismTheme.ink
                        }
                        PrismGlyph {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sorting ? "expand_less" : "expand_more"
                            iconSize: PrismTheme.dp(16)
                            color: root.sorting ? PrismTheme.inkSolid : PrismTheme.ink3
                        }
                    }
                }
                MouseArea {
                    id: orderArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Order")
                    onClicked: root.sorting = !root.sorting
                }
            }
            // List or grid: two keys in one well, the chosen one up.
            Item {
                id: view
                width: PrismTheme.dp(80)
                height: PrismTheme.dp(38)
                PrismWell { anchors.fill: parent }
                Repeater {
                    model: [{ value: "list", glyph: "view_agenda", label: "List" }, { value: "grid", glyph: "grid_view", label: "Grid" }]
                    delegate: Item {
                        id: slot
                        required property var modelData
                        required property int index
                        readonly property bool chosen: (root.grid ? "grid" : "list") === slot.modelData.value
                        x: PrismTheme.dp(3) + slot.index * width
                        y: PrismTheme.dp(3)
                        width: (view.width - PrismTheme.dp(6)) / 2
                        height: view.height - PrismTheme.dp(6)
                        PrismKey {
                            anchors.fill: parent
                            visible: slot.chosen
                            radius: height / 2
                            face: PrismTheme.paper
                        }
                        PrismGlyph {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: slot.chosen ? -PrismTheme.keyLip / 2 : 0
                            text: slot.modelData.glyph
                            filled: slot.chosen
                            iconSize: PrismTheme.dp(16)
                            color: slot.chosen ? PrismTheme.night : slotArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                        }
                        MouseArea {
                            id: slotArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: Translation.tr(slot.modelData.label)
                            onClicked: Config.setNestedValue("hub.view", slot.modelData.value)
                        }
                    }
                }
            }
        }
        PrismChips {
            width: parent.width
            visible: root.opened === null && root.sorting
            choices: Hub.sorts.map(entry => ({ value: entry.id, label: entry.label }))
            current: root.sort
            onPicked: value => {
                Config.setNestedValue("hub.sort", String(value))
                root.sorting = false
            }
        }

        // ── Kinds, each with its count ──────────────────────────────────
        Flow {
            width: parent.width
            visible: root.opened === null && Hub.items.length > 0
            spacing: PrismTheme.dp(6)
            PrismHubKey {
                label: Translation.tr("Everything")
                count: String(Hub.items.length)
                chosen: root.kind === "" && root.filter === ""
                onPress: { root.kind = ""; root.filter = "" }
            }
            Repeater {
                model: Hub.kinds.map(entry => Object.assign({ count: Hub.items.filter(item => item.kind === entry.id).length }, entry)).filter(entry => entry.count > 0)
                delegate: PrismHubKey {
                    required property var modelData
                    label: Translation.tr(modelData.label)
                    count: String(modelData.count)
                    chosen: root.kind === modelData.id
                    onPress: root.kind = root.kind === modelData.id ? "" : modelData.id
                }
            }
            PrismHubKey {
                visible: root.installed > 0
                glyph: "download_done"
                label: Translation.tr("Installed")
                count: String(root.installed)
                chosen: root.filter === "installed"
                onPress: root.filter = root.filter === "installed" ? "" : "installed"
            }
            PrismHubKey {
                visible: Hub.updates > 0
                glyph: "update"
                label: Translation.tr("Updates")
                count: String(Hub.updates)
                chosen: root.filter === "updates"
                onPress: root.filter = root.filter === "updates" ? "" : "updates"
            }
        }

        // ── Empty and unreachable ───────────────────────────────────────
        Column {
            width: parent.width
            visible: Hub.loaded && root.opened === null && root.shown.length === 0
            topPadding: PrismTheme.dp(32)
            bottomPadding: PrismTheme.dp(16)
            spacing: PrismTheme.dp(10)
            PrismGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? "search_off" : Hub.items.length === 0 ? "cloud_off" : "download_done"
                iconSize: PrismTheme.dp(34)
                color: PrismTheme.ink3
            }
            PrismText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 40
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.body
                text: root.query.length > 0 ? Voice.miss(Translation.tr("Nothing matches “%1”").arg(root.query), root.query)
                    : Hub.cliMissing ? Translation.tr("The hub comes with the inir command: run inir update once to get it")
                    : Hub.items.length === 0 ? Translation.tr("The hub didn't answer. Check your connection and try again")
                    : root.filter === "installed" ? Translation.tr("Nothing installed from the hub yet")
                    : Translation.tr("Nothing here yet")
            }
            PrismPill {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Hub.items.length === 0
                tone: "quiet"
                text: Translation.tr("Try again")
                onClicked: Hub.refresh(true)
            }
        }

        // ── Featured: a band of pictures, never a banner ────────────────
        PrismHeading {
            width: parent.width
            visible: root.opened === null && root.featured.length > 0
            title: Translation.tr("Featured")
            titleSize: PrismTheme.head
        }
        Row {
            width: parent.width
            visible: root.opened === null && root.featured.length > 0
            spacing: root.gap
            Repeater {
                model: root.opened === null ? root.featured : []
                delegate: PrismHubCard {
                    required property var modelData
                    width: Math.floor((column.width - (root.bandColumns - 1) * root.gap) / root.bandColumns)
                    height: implicitHeight
                    form: "poster"
                    hub: root
                    item: modelData
                    onOpen: root.openId = modelData.id
                }
            }
        }

        // ── The shelf ───────────────────────────────────────────────────
        PrismHeading {
            width: parent.width
            visible: root.opened === null && root.shown.length > 0
            title: Translation.tr(Hub.sorts.find(entry => entry.id === root.sort)?.label ?? "Popular")
            titleSize: PrismTheme.head
            note: String(root.shown.length)
        }
        Rectangle {
            width: parent.width
            visible: root.opened === null && !root.grid && root.listed.length > 0
            height: rows.implicitHeight + PrismTheme.dp(12)
            radius: PrismTheme.dp(24)
            color: PrismTheme.card
            Column {
                id: rows
                x: PrismTheme.dp(6)
                y: PrismTheme.dp(6)
                width: parent.width - PrismTheme.dp(12)
                Repeater {
                    model: root.opened === null && !root.grid ? root.listed : []
                    delegate: PrismHubCard {
                        required property var modelData
                        required property int index
                        width: rows.width
                        height: implicitHeight
                        form: "row"
                        hub: root
                        item: modelData
                        last: index === root.listed.length - 1
                        onOpen: root.openId = modelData.id
                    }
                }
            }
        }
        Flow {
            width: parent.width
            visible: root.opened === null && root.grid
            spacing: root.gap
            Repeater {
                model: root.opened === null && root.grid ? root.listed : []
                delegate: PrismHubCard {
                    required property var modelData
                    width: root.cardWidth
                    height: implicitHeight
                    form: "card"
                    hub: root
                    item: modelData
                    onOpen: root.openId = modelData.id
                }
            }
        }
        PrismPill {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.opened === null && root.shown.length > root.listed.length
            tone: "quiet"
            text: Translation.tr("Show %1 more").arg(Math.min(40, root.shown.length - root.listed.length))
            onClicked: root.shownCount += 40
        }

        // ── One item ────────────────────────────────────────────────────
        Loader {
            width: parent.width
            active: root.opened !== null
            visible: active
            sourceComponent: PrismHubItem {
                width: column.width
                hub: root
                item: root.opened
                onBack: root.openId = ""
            }
        }

        // ── Where the shelf comes from ──────────────────────────────────
        PrismHubSources {
            width: parent.width
            visible: root.opened === null && Hub.loaded
        }
    }
}
