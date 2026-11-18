pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The wallpapers as one wide block over the bar: the name on paper, a search, light or dark for the colours taken from
// the picture, one at random; then the folder as pictures packed a seam apart, the one in use marked in the signal.
NPopup {
    id: root

    open: NihilState.wallpapersOpen
    namespace: "nihil:wallpapers"
    onDismissed: root.close()

    property string query: ""
    property bool dark: NihilStyle.dark
    readonly property var shown: {
        const words = root.query.trim().toLowerCase()
        const all = Wallpapers.wallpapers ?? []
        return words.length === 0 ? all : all.filter(path => FileUtils.fileNameForPath(path).toLowerCase().includes(words))
    }

    onOpenChanged: {
        if (!root.open) return
        root.query = ""
        root.dark = NihilStyle.dark
        search.clear()
        search.take()
        Wallpapers.generateThumbnail("large")
        const at = root.shown.indexOf(Wallpapers.effectiveWallpaperPath)
        grid.currentIndex = Math.max(0, at)
        grid.positionViewAtIndex(grid.currentIndex, GridView.Center)
    }

    function close(): void {
        GlobalStates.wallpaperSelectorOpen = false
        GlobalStates.wallpaperLauncherOpen = false
        GlobalStates.coverflowSelectorOpen = false
    }

    function pick(path: string): void {
        if (path.length === 0) return
        Wallpapers.select(path, root.dark)
        root.close()
    }

    NRack {
        id: rack
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        readonly property real g: NihilStyle.seam
        width: Math.min(NihilStyle.s(1040), root.width - NihilStyle.edge * 2)
        height: Math.min(NihilStyle.s(660), room)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        Row {
            id: head
            height: NihilStyle.s(72)
            spacing: rack.g

            NTile {
                id: title
                width: NihilStyle.s(264)
                height: head.height
                paper: true
                caption: root.shown.length + " " + Translation.tr("Pictures")
                NText {
                    x: title.pad
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(6)
                    text: Translation.tr("Wallpapers")
                    font.pixelSize: NihilStyle.textTitle
                    font.weight: Font.Black
                    color: title.ink
                }
            }
            NField {
                id: search
                width: rack.width - title.width - modes.width - shuffle.width - closeKey.width - rack.g * 4
                height: head.height
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
                id: modes
                spacing: rack.g
                NButton {
                    width: head.height; height: head.height
                    square: true
                    paper: !root.dark
                    icon: "light_mode"
                    iconSize: NihilStyle.s(26)
                    onClicked: root.dark = false
                }
                NButton {
                    width: head.height; height: head.height
                    square: true
                    paper: root.dark
                    icon: "dark_mode"
                    iconSize: NihilStyle.s(26)
                    onClicked: root.dark = true
                }
            }
            NButton {
                id: shuffle
                width: head.height; height: head.height
                square: true
                icon: "shuffle"
                iconSize: NihilStyle.s(26)
                onClicked: {
                    Wallpapers.randomFromCurrentFolder(root.dark)
                    root.close()
                }
            }
            NButton {
                id: closeKey
                width: head.height; height: head.height
                square: true
                icon: "close"
                iconSize: NihilStyle.s(26)
                onClicked: root.close()
            }
        }

        NTile {
            id: sheet
            y: head.height + rack.g
            width: rack.width
            height: rack.height - y

            GridView {
                id: grid
                x: NihilStyle.s(6)
                y: NihilStyle.s(6)
                width: sheet.width - NihilStyle.s(12)
                height: sheet.height - NihilStyle.s(12)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                readonly property int columns: Math.max(2, Math.round(width / NihilStyle.s(250)))
                cellWidth: Math.floor(width / columns)
                cellHeight: Math.round((cellWidth - NihilStyle.seam) * 10 / 16) + NihilStyle.seam
                model: root.shown
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: false
                delegate: WallpaperThumb {
                    required property string modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    path: modelData
                    current: modelData === Wallpapers.effectiveWallpaperPath
                    focused: grid.currentIndex === index
                    live: root.open
                    onPicked: root.pick(modelData)
                    onHoveredChanged: if (hovered) grid.currentIndex = index
                }
            }

            NEmpty {
                anchors.centerIn: parent
                width: Math.min(NihilStyle.s(420), sheet.width - NihilStyle.s(40))
                visible: grid.count === 0
                glyph: root.query.length > 0 ? "search_off" : "wallpaper"
                title: root.query.length > 0 ? Translation.tr("Nothing by that name") : Translation.tr("No wallpapers in this folder")
                line: root.query.length > 0 ? Translation.tr("Try another word") : Wallpapers.effectiveDirectory
            }
        }
    }
}
