pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The app grid: pages of launchers and folders, filling the room it is given. The arrows walk the tiles, the wheel and the
// page keys turn the pages. A tile let go on the middle of another makes a folder, on its edge it takes that place.
FocusScope {
    id: root

    // False while the search field keeps the keys and this grid only shows what the words narrow it to.
    property bool takesKeys: true
    // The kind of app on show.
    property string kind: "all"
    readonly property int columns: catalog.columns
    readonly property var kindsHeld: catalog.kindsHeld
    signal folderClosed()

    readonly property var options: Config.options?.nihil?.apps ?? ({})
    readonly property string orientation: root.options.orientation ?? "workspaces"
    readonly property bool vertical: root.orientation === "vertical"
        || (root.orientation === "workspaces"
            && ["left", "right"].includes(Config.options?.nihil?.thumbnails?.position ?? "right"))
    readonly property string animation: root.options.animation ?? "default"
    readonly property bool still: root.animation === "none" || (root.options.performance ?? false)

    readonly property real pagerRoom: NihilStyle.s(36)
    readonly property real pageWidth: root.width
    readonly property real pageHeight: root.height - root.pagerRoom
    readonly property real gap: NihilStyle.s(root.options.spacing ?? 20)
    readonly property real rowGap: Math.round(root.gap * 0.53)
    readonly property real iconSize: (root.options.iconSize ?? -1) > 0 ? root.options.iconSize
        : NihilStyle.clamp(root.pageWidth / 19, NihilStyle.s(48), NihilStyle.s(96))
    readonly property real cellWidth: root.iconSize + NihilStyle.s(48)
    readonly property real cellHeight: root.iconSize + NihilStyle.s(56)
    // The columns spread over the whole width, so the grid ends where the search field does.
    readonly property real columnGap: catalog.columns > 1
        ? Math.max(root.gap, (root.pageWidth - catalog.columns * root.cellWidth) / (catalog.columns - 1)) : 0

    property int selected: 0
    // The tile under the pointer; while one is, the keys' choice steps back.
    property var hovered: null
    property string openFolderId: ""
    readonly property var openFolder: catalog.folders.find(folder => folder.id === root.openFolderId) ?? null

    property int _pageBefore: -1
    property real _wheelRest: 0

    // The search field's arrows and Enter land here too.
    function step(by: int): void {
        const next = root.selected + by
        if (next < 0 && catalog.shownPage > 0) {
            catalog.goToPage(catalog.shownPage - 1)
            root.selected = catalog.pageItems.length - 1
        } else if (next >= catalog.pageItems.length && catalog.shownPage < catalog.pageCount - 1) {
            catalog.goToPage(catalog.shownPage + 1)
            root.selected = 0
        } else {
            root.selected = NihilStyle.clamp(next, 0, Math.max(0, catalog.pageItems.length - 1))
        }
    }

    function turn(by: int): void {
        catalog.goToPage(catalog.shownPage + by)
    }

    function activateFirst(): void {
        root.activate(catalog.pageItems[root.selected])
    }

    function activate(item: var): void {
        if (!item || item.kind === "gap")
            return
        if (item.kind === "folder") {
            root.openFolderId = item.id
            return
        }
        catalog.launch(item)
        NihilState.closeOverview()
    }

    function landed(dragged: var, sceneX: real, sceneY: real): void {
        const at = tiles.mapFromItem(null, sceneX, sceneY)
        const under = tiles.childAt(at.x, at.y)
        const target = under?.item
        if (!target || target.id === dragged.id)
            return
        if (target.kind === "folder") {
            catalog.addToFolder(target.id, dragged.id)
            return
        }
        const inside = under.mapFromItem(tiles, at.x, at.y)
        const onMiddle = Math.abs(inside.x - under.width / 2) < under.width / 4
            && Math.abs(inside.y - under.height / 2) < under.height / 4
        if (target.kind === "app" && onMiddle)
            catalog.createFolder(Translation.tr("New folder"), [target.id, dragged.id])
        else if (catalog.order === "custom")
            catalog.moveApp(dragged.id, target.id)
    }

    function _turned(page: int): void {
        const before = root._pageBefore
        root._pageBefore = page
        root.selected = 0
        if (root.options.rememberPage ?? false)
            Config.setNestedValue("nihil.apps.lastPage", page)
        if (before < 0 || root.still)
            return
        const fixed = root.animation === "left" || root.animation === "up" ? -1
            : root.animation === "right" || root.animation === "down" ? 1 : 0
        tiles.slide = NihilStyle.s(48) * (fixed !== 0 ? fixed : page > before ? 1 : -1)
        slideBack.restart()
    }

    focus: root.takesKeys
    Component.onCompleted: {
        if (root.options.rememberPage ?? false)
            catalog.goToPage(root.options.lastPage ?? 0)
        root._pageBefore = catalog.shownPage
        if (root.takesKeys)
            root.forceActiveFocus()
    }

    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    Keys.onUpPressed: root.step(-catalog.columns)
    Keys.onDownPressed: root.step(catalog.columns)
    Keys.onReturnPressed: root.activateFirst()
    Keys.onEnterPressed: root.activateFirst()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_PageDown)
            root.turn(1)
        else if (event.key === Qt.Key_PageUp)
            root.turn(-1)
        else
            return
        event.accepted = true
    }

    NihilAppModel {
        id: catalog
        query: NihilState.query
        kind: root.kind
        fitColumns: Math.max(1, Math.floor((root.pageWidth + root.gap) / (root.cellWidth + root.gap)))
        fitRows: Math.max(1, Math.floor((root.pageHeight + root.rowGap) / (root.cellHeight + root.rowGap)))
        onShownPageChanged: root._turned(catalog.shownPage)
    }

    // One notch turns one page; a touchpad's small steps add up to a notch first.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            root._wheelRest += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
            if (Math.abs(root._wheelRest) < 120)
                return
            root.turn(root._wheelRest < 0 ? 1 : -1)
            root._wheelRest = 0
        }
    }

    Item {
        id: pages
        width: root.pageWidth
        height: root.pageHeight

        Grid {
            id: tiles

            property real slide: 0

            x: (root.options.center ?? false) ? Math.round((pages.width - implicitWidth) / 2) : 0
            columns: catalog.columns
            columnSpacing: root.columnGap
            rowSpacing: root.rowGap
            opacity: 1 - Math.abs(tiles.slide) / NihilStyle.s(96)
            transform: Translate {
                x: root.vertical ? 0 : tiles.slide
                y: root.vertical ? tiles.slide : 0
            }

            Repeater {
                model: catalog.pageItems
                delegate: AppTile {
                    id: tile
                    required property var modelData
                    required property int index
                    item: tile.modelData
                    width: root.cellWidth
                    height: root.cellHeight
                    iconSize: root.iconSize
                    selected: root.selected === tile.index && root.hovered === null
                    onActivated: root.activate(tile.modelData)
                    onOpenFolder: root.openFolderId = tile.modelData.id
                    onPreviewUsed: app => root.activate(app)
                    onDropped: (sceneX, sceneY) => root.landed(tile.modelData, sceneX, sceneY)
                    onContainsMouseChanged: {
                        if (tile.containsMouse) root.hovered = tile.modelData
                        else if (root.hovered === tile.modelData) root.hovered = null
                    }
                }
            }
        }

        NumberAnimation {
            id: slideBack
            target: tiles
            property: "slide"
            to: 0
            duration: NihilStyle.durationMedium
            easing.type: Easing.OutCubic
        }

        Column {
            anchors.centerIn: parent
            visible: catalog.items.length === 0
            spacing: NihilStyle.s(6)

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: catalog.filtering ? "search_off" : "apps"
                size: NihilStyle.s(30)
                color: NihilStyle.textTertiary
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: catalog.filtering ? Translation.tr("No apps match") : Translation.tr("No apps to show")
                font.weight: Font.Medium
                color: NihilStyle.textSecondary
            }
        }
    }

    // The pages, under the grid: a key each way and a mark for each page.
    Row {
        visible: catalog.pageCount > 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: root.pagerRoom
        spacing: NihilStyle.s(8)

        NButton {
            visible: root.options.pageArrows ?? true
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            tone: "transparent"
            enabled: catalog.shownPage > 0
            opacity: enabled ? 1 : 0.3
            icon: root.vertical ? "expand_less" : "chevron_left"
            iconSize: NihilStyle.s(16)
            Accessible.name: Translation.tr("Previous")
            onClicked: root.turn(-1)
        }

        Row {
            visible: root.options.pageIndicators ?? true
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(2)

            Repeater {
                model: catalog.pageCount
                delegate: MouseArea {
                    id: dot
                    required property int index
                    readonly property bool here: catalog.shownPage === dot.index

                    width: mark.width + NihilStyle.s(10)
                    height: NihilStyle.s(20)
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Page %1").arg(dot.index + 1)
                    onClicked: catalog.goToPage(dot.index)

                    Rectangle {
                        id: mark
                        anchors.centerIn: parent
                        width: dot.here ? NihilStyle.s(22) : NihilStyle.s(6)
                        height: NihilStyle.s(6)
                        radius: height / 2
                        color: dot.here ? NihilStyle.text : Qt.alpha(NihilStyle.text, dot.containsMouse ? 0.5 : 0.22)
                        Behavior on width { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        NButton {
            visible: root.options.pageArrows ?? true
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            tone: "transparent"
            enabled: catalog.shownPage < catalog.pageCount - 1
            opacity: enabled ? 1 : 0.3
            icon: root.vertical ? "expand_more" : "chevron_right"
            iconSize: NihilStyle.s(16)
            Accessible.name: Translation.tr("Next")
            onClicked: root.turn(1)
        }
    }

    Loader {
        anchors.fill: parent
        active: root.openFolder !== null
        focus: active
        sourceComponent: FolderView {
            folder: root.openFolder
            catalog: catalog
            onClosed: {
                root.openFolderId = ""
                if (root.takesKeys)
                    root.forceActiveFocus()
                root.folderClosed()
            }
        }
    }
}
