pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The app grid inside the overview: pages of launchers and folders. The arrows walk the tiles, the wheel and the page
// keys turn the pages. A tile let go on the middle of another makes a folder, on its edge it takes that place.
FocusScope {
    id: root

    // False while the search field keeps the keys and this grid only shows what the words narrow it to.
    property bool takesKeys: true

    readonly property var options: Config.options?.nihil?.apps ?? ({})
    readonly property string orientation: root.options.orientation ?? "workspaces"
    readonly property bool vertical: root.orientation === "vertical"
        || (root.orientation === "workspaces"
            && ["left", "right"].includes(Config.options?.nihil?.thumbnails?.position ?? "right"))
    readonly property string animation: root.options.animation ?? "default"
    readonly property bool still: root.animation === "none" || (root.options.performance ?? false)

    readonly property real pageWidth: root.width * (root.options.pageWidth ?? 0.85)
    readonly property real pageHeight: root.height * (root.options.pageHeight ?? 0.9)
    readonly property real gap: NihilStyle.s(root.options.spacing ?? 30)
    readonly property real iconSize: (root.options.iconSize ?? -1) > 0 ? root.options.iconSize
        : NihilStyle.clamp(Math.min(root.pageWidth / 11, root.pageHeight / 7), NihilStyle.s(48), NihilStyle.s(96))
    readonly property real cellWidth: root.iconSize + NihilStyle.s(52)
    readonly property real cellHeight: root.iconSize + NihilStyle.s(56)

    property int selected: 0
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
        turn.restart()
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
            catalog.goToPage(catalog.shownPage + 1)
        else if (event.key === Qt.Key_PageUp)
            catalog.goToPage(catalog.shownPage - 1)
        else
            return
        event.accepted = true
    }

    NihilAppModel {
        id: catalog
        query: NihilState.query
        fitColumns: Math.max(1, Math.floor((root.pageWidth + root.gap) / (root.cellWidth + root.gap)))
        fitRows: Math.max(1, Math.floor((root.pageHeight + root.gap) / (root.cellHeight + root.gap)))
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
            catalog.goToPage(catalog.shownPage + (root._wheelRest < 0 ? 1 : -1))
            root._wheelRest = 0
        }
    }

    Item {
        id: pages
        anchors.centerIn: parent
        width: root.pageWidth
        height: root.pageHeight

        Grid {
            id: tiles

            property real slide: 0

            x: (root.options.center ?? false) ? Math.round((pages.width - implicitWidth) / 2) : 0
            y: Math.round((pages.height - implicitHeight) / 2)
            columns: catalog.columns
            columnSpacing: root.gap
            rowSpacing: root.gap
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
                    selected: root.selected === tile.index
                    onActivated: root.activate(tile.modelData)
                    onOpenFolder: root.openFolderId = tile.modelData.id
                    onPreviewUsed: app => root.activate(app)
                    onDropped: (sceneX, sceneY) => root.landed(tile.modelData, sceneX, sceneY)
                }
            }
        }

        NumberAnimation {
            id: turn
            target: tiles
            property: "slide"
            to: 0
            duration: NihilStyle.calm
            easing.type: Easing.OutCubic
        }

        Column {
            anchors.centerIn: parent
            visible: catalog.items.length === 0
            spacing: NihilStyle.s(6)

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "search_off"
                size: NihilStyle.s(36)
                color: NihilStyle.inkSoft
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: catalog.filtering ? Translation.tr("No apps match") : Translation.tr("No apps to show")
                font.pixelSize: NihilStyle.textLarge
                color: NihilStyle.inkSoft
            }
        }
    }

    NButton {
        visible: (root.options.pageArrows ?? true) && catalog.shownPage > 0
        anchors.left: parent.left
        anchors.leftMargin: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        icon: root.vertical ? "keyboard_arrow_up" : "chevron_left"
        onClicked: catalog.goToPage(catalog.shownPage - 1)
    }
    NButton {
        visible: (root.options.pageArrows ?? true) && catalog.shownPage < catalog.pageCount - 1
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter
        icon: root.vertical ? "expand_more" : "chevron_right"
        onClicked: catalog.goToPage(catalog.shownPage + 1)
    }

    Row {
        visible: (root.options.pageIndicators ?? true) && catalog.pageCount > 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(10)
        spacing: NihilStyle.s(4)

        Repeater {
            model: catalog.pageCount
            delegate: MouseArea {
                id: dot
                required property int index
                readonly property bool here: catalog.shownPage === dot.index

                width: NihilStyle.s(24)
                height: NihilStyle.s(24)
                cursorShape: Qt.PointingHandCursor
                onClicked: catalog.goToPage(dot.index)

                Rectangle {
                    anchors.centerIn: parent
                    width: dot.here ? NihilStyle.s(18) : NihilStyle.s(6)
                    height: NihilStyle.s(6)
                    radius: height / 2
                    color: dot.here ? NihilStyle.accent : NihilStyle.inkFaint
                    Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                }
            }
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
            }
        }
    }
}
