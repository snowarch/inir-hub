pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The wallpapers: the marked one large, with light or dark for the colours taken from it, beside the folder as pictures.
// The arrows or a click mark one; Enter, a double click or the key wears it.
Item {
    id: root

    property var screen: null
    property bool open: false


    property string query: ""
    property bool dark: NihilStyle.dark

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

    Item {
        id: sheet

        readonly property real inset: NihilStyle.s(20)

        x: sheet.inset
        y: sheet.inset
        width: root.width - sheet.inset * 2
        height: root.height - sheet.inset * 2

        // The marked wallpaper, large, with what wearing it will do.
        Item {
            id: hero

            readonly property string path: root.shown[grid.currentIndex] ?? ""
            readonly property bool video: Wallpapers.isVideoFile(hero.path)

            width: Math.round(sheet.width * 0.56)
            height: sheet.height

            ClippingRectangle {
                id: picture
                width: hero.width
                height: hero.height - foot.height - NihilStyle.s(16)
                radius: NihilStyle.r(26)
                color: NihilStyle.fill

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 1280
                    source: !root.open || hero.path.length === 0 ? ""
                        : "file://" + (hero.video ? String(Wallpapers.getVideoFirstFramePath(hero.path) ?? "") : hero.path)
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: NihilStyle.durationMedium } }
                }
            }

            Column {
                id: foot
                anchors.bottom: parent.bottom
                width: hero.width
                spacing: NihilStyle.s(14)

                NDisplay {
                    width: parent.width
                    size: NihilStyle.s(30)
                    text: FileUtils.fileNameForPath(hero.path).replace(/\.[^.]+$/, "")
                }
                Item {
                    width: parent.width
                    height: NihilStyle.s(44)

                    NSegmented {
                        anchors.verticalCenter: parent.verticalCenter
                        width: NihilStyle.s(220)
                        height: NihilStyle.s(40)
                        options: [
                            { value: true, label: Translation.tr("Dark") },
                            { value: false, label: Translation.tr("Light") }
                        ]
                        current: root.dark
                        onPicked: value => root.dark = value
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(6)

                        NButton {
                            width: NihilStyle.s(44)
                            height: NihilStyle.s(44)
                            icon: "shuffle"
                            Accessible.name: Translation.tr("Random")
                            onClicked: {
                                Wallpapers.randomFromCurrentFolder(root.dark)
                                root.close()
                            }
                        }
                        NButton {
                            height: NihilStyle.s(44)
                            icon: "check"
                            label: Translation.tr("Use this wallpaper")
                            highlighted: true
                            enabled: hero.path.length > 0
                            onClicked: root.pick(hero.path)
                        }
                    }
                }
            }
        }

        Item {
            id: shelf
            x: hero.width + NihilStyle.s(16)
            width: sheet.width - x
            height: sheet.height

            NField {
                id: search
                width: shelf.width
                height: NihilStyle.s(50)
                glyph: "search"
                placeholder: Translation.tr("Search wallpapers")
                clearable: true
                onEdited: text => {
                    root.query = text
                    grid.currentIndex = 0
                }
                onStepped: by => by > 0 ? grid.moveCurrentIndexDown() : grid.moveCurrentIndexUp()
                onWalked: by => by > 0 ? grid.moveCurrentIndexRight() : grid.moveCurrentIndexLeft()
                onEntered: root.pick(root.shown[grid.currentIndex] ?? "")
            }

            GridView {
                id: grid

                y: search.height + NihilStyle.s(10)
                width: shelf.width
                height: shelf.height - y
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.floor(width / 2)
                cellHeight: Math.round(cellWidth * 10 / 16)
                model: root.shown
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)

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
                    onMarked: grid.currentIndex = thumb.index
                    onPicked: root.pick(thumb.modelData)
                }
            }

            NEmpty {
                anchors.centerIn: grid
                width: Math.min(grid.width, NihilStyle.s(340))
                visible: grid.count === 0
                icon: root.query.length > 0 ? "search_off" : "image"
                title: root.query.length > 0 ? Translation.tr("Nothing by that name") : Translation.tr("No wallpapers in this folder")
                note: root.query.length > 0 ? Translation.tr("Try another word") : Wallpapers.effectiveDirectory
            }
        }
    }
}
