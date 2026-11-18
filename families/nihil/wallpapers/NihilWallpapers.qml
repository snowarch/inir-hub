pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The wallpapers on one wide pane of glass: a search, light or dark for the colours taken from the picture, one at
// random, and the folder as pictures. The arrows walk them and Enter wears the marked one.
NPopup {
    id: root

    open: NihilState.wallpapersOpen
    namespace: "nihil:wallpapers"
    blurPieces: [sheet.region]
    onDismissed: root.close()

    property string query: ""
    property bool dark: NihilStyle.dark

    readonly property bool barBottom: (Config.options?.nihil?.panel?.position ?? "top") === "bottom"
    readonly property var shown: {
        const words = root.query.trim().toLowerCase()
        const all = Wallpapers.wallpapers ?? []
        return words.length === 0 ? all : all.filter(path => FileUtils.fileNameForPath(path).toLowerCase().includes(words))
    }

    onOpenChanged: {
        if (!root.open)
            return
        root.query = ""
        root.dark = NihilStyle.dark
        search.clear()
        search.take()
        Wallpapers.generateThumbnail("large")
        grid.currentIndex = Math.max(0, root.shown.indexOf(Wallpapers.effectiveWallpaperPath))
        grid.positionViewAtIndex(grid.currentIndex, GridView.Center)
    }

    function close(): void {
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.wallpaperLauncherOpen = false
        GlobalStates.coverflowSelectorOpen = false
    }

    function pick(path: string): void {
        if (path.length === 0)
            return
        Wallpapers.select(path, root.dark)
        root.close()
    }

    NGlass {
        id: sheet

        readonly property real inset: NihilStyle.s(14)

        width: Math.min(NihilStyle.s(1040), parent.width - NihilStyle.edge * 2)
        height: Math.min(NihilStyle.s(660), parent.height - NihilStyle.barHeight - NihilStyle.edge * 3)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - NihilStyle.barHeight - NihilStyle.edge * 2
            : NihilStyle.barHeight + NihilStyle.edge * 2
        ignite: root.open ? 0.5 : 0

        MouseArea { anchors.fill: parent }

        NField {
            id: search
            x: sheet.inset
            y: sheet.inset
            width: sheet.width - sheet.inset * 2 - keys.width - NihilStyle.gap
            glyph: "search"
            placeholder: Translation.tr("Search wallpapers")
            clearable: true
            onEdited: text => root.query = text
            onStepped: by => by > 0 ? grid.moveCurrentIndexDown() : grid.moveCurrentIndexUp()
            onEntered: root.pick(root.shown[grid.currentIndex] ?? "")
            Keys.onLeftPressed: grid.moveCurrentIndexLeft()
            Keys.onRightPressed: grid.moveCurrentIndexRight()
        }

        Row {
            id: keys
            anchors.right: parent.right
            anchors.rightMargin: sheet.inset
            anchors.verticalCenter: search.verticalCenter
            spacing: NihilStyle.s(4)

            NButton {
                icon: "light_mode"
                lit: !root.dark
                onClicked: root.dark = false
            }
            NButton {
                icon: "moon"
                lit: root.dark
                onClicked: root.dark = true
            }
            NButton {
                icon: "shuffle"
                onClicked: {
                    Wallpapers.randomFromCurrentFolder(root.dark)
                    root.close()
                }
            }
            NButton {
                icon: "close"
                onClicked: root.close()
            }
        }

        GridView {
            id: grid

            readonly property int columns: Math.max(2, Math.round(width / NihilStyle.s(250)))

            x: sheet.inset
            y: search.y + search.height + NihilStyle.gap
            width: sheet.width - sheet.inset * 2
            height: sheet.height - y - sheet.inset
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: Math.floor(width / columns)
            cellHeight: Math.round(cellWidth * 10 / 16)
            model: root.shown
            keyNavigationEnabled: true
            highlightFollowsCurrentItem: false

            delegate: WallpaperThumb {
                id: thumb
                required property string modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                path: thumb.modelData
                current: thumb.modelData === Wallpapers.effectiveWallpaperPath
                focused: grid.currentIndex === thumb.index
                live: root.open
                onPicked: root.pick(thumb.modelData)
                onHoveredChanged: if (thumb.hovered) grid.currentIndex = thumb.index
            }
        }

        Column {
            anchors.centerIn: grid
            visible: grid.count === 0
            spacing: NihilStyle.s(6)

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? "search_off" : "image"
                size: NihilStyle.s(32)
                color: NihilStyle.inkSoft
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? Translation.tr("Nothing by that name") : Translation.tr("No wallpapers in this folder")
                font.pixelSize: NihilStyle.textLarge
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? Translation.tr("Try another word") : Wallpapers.effectiveDirectory
                color: NihilStyle.inkSoft
            }
        }
    }
}
