pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The wallpapers as one wide piece over the desktop: the name in dots, a search, light or dark for the colours taken
// from it, one at random; then the folder as a grid of pictures, the one in use marked in the signal.
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

    NCard {
        id: card
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        width: Math.min(NihilStyle.s(980), root.width - NihilStyle.edge * 2)
        height: Math.min(NihilStyle.s(640), room)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop
        pad: NihilStyle.s(16)

        Item {
            id: head
            width: parent.width
            height: NihilStyle.s(46)

            DotText {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                x: NihilStyle.s(6)
                text: Translation.tr("Wallpapers").toUpperCase()
                dot: NihilStyle.s(3.2)
                spacing: NihilStyle.s(1.9)
                color: NihilStyle.ink
            }
            NText {
                anchors.left: title.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: root.shown.length
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(8)
                NField {
                    id: search
                    width: NihilStyle.s(260); height: NihilStyle.s(42)
                    glyph: "search"
                    placeholder: Translation.tr("Search wallpapers")
                    clearable: true
                    onEdited: text => root.query = text
                    onStepped: by => by > 0 ? grid.moveCurrentIndexDown() : grid.moveCurrentIndexUp()
                    onEntered: root.pick(root.shown[grid.currentIndex] ?? "")
                    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                    Keys.onRightPressed: grid.moveCurrentIndexRight()
                }
                NSegmented {
                    width: NihilStyle.s(170); height: NihilStyle.s(42)
                    options: [{ value: false, label: Translation.tr("Light"), glyph: "light_mode" },
                              { value: true, label: Translation.tr("Dark"), glyph: "dark_mode" }]
                    current: root.dark
                    onPicked: value => root.dark = value
                }
                NButton {
                    width: NihilStyle.s(42); height: width
                    tone: NihilStyle.pieceRaised
                    icon: "shuffle"
                    iconSize: NihilStyle.s(20)
                    onClicked: {
                        Wallpapers.randomFromCurrentFolder(root.dark)
                        root.close()
                    }
                }
                NButton {
                    width: NihilStyle.s(42); height: width
                    tone: NihilStyle.pieceRaised
                    icon: "close"
                    iconSize: NihilStyle.s(20)
                    onClicked: root.close()
                }
            }
        }

        GridView {
            id: grid
            y: head.height + NihilStyle.s(14)
            width: parent.width
            height: parent.height - y
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            readonly property int columns: Math.max(2, Math.round(width / NihilStyle.s(230)))
            cellWidth: Math.floor(width / columns)
            cellHeight: Math.round((cellWidth - NihilStyle.s(10)) * 10 / 16) + NihilStyle.s(36)
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
            anchors.centerIn: grid
            width: Math.min(NihilStyle.s(420), grid.width - NihilStyle.s(40))
            visible: grid.count === 0
            glyph: root.query.length > 0 ? "search_off" : "wallpaper"
            title: root.query.length > 0 ? Translation.tr("Nothing by that name") : Translation.tr("No wallpapers in this folder")
            line: root.query.length > 0 ? Translation.tr("Try another word") : Wallpapers.effectiveDirectory
        }
    }
}
