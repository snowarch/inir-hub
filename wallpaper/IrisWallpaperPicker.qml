pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// iRiS wallpaper picker. Grows out of the Island and hangs under it as a
// compact strip: two rows of wallpapers that scroll sideways, the source
// (this computer or Wallhaven) and search above, one line of selection below.
// Presentation only: local browsing, thumbnails and applying stay with the
// shared Wallpapers service (same apply semantics as the shared selector);
// online results come from the shared Wallhaven service and are downloaded
// into the wallpapers folder before they are applied the same way.
PanelWindow {
    id: root

    readonly property real d: IrisStyle.density
    readonly property bool morphOpen: GlobalStates.wallpaperSelectorOpen
    readonly property bool multiMonitor: Config.options?.background?.multiMonitor?.enable ?? false
    readonly property bool onlineEnabled: Config.options?.sidebar?.wallhaven?.enable ?? true
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barBottom: String(root.barOptions?.position ?? "top") === "bottom"
    // Captured once per open: focus may already belong to this overlay later.
    property string targetMonitor: ""
    readonly property string selectionTarget: Wallpapers.currentSelectionTarget()
    readonly property string currentPath: Wallpapers.currentWallpaperPathForTarget(root.selectionTarget, root.targetMonitor)

    // "library" or "online".
    property string source: "library"
    readonly property bool online: root.source === "online" && root.onlineEnabled
    property int selectedIndex: 0

    // Library selection.
    readonly property int libraryCount: Wallpapers.folderModelReady ? (Wallpapers.folderModel?.count ?? 0) : 0
    readonly property string libraryPath: !root.online && root.selectedIndex >= 0 && root.selectedIndex < root.libraryCount
        ? Wallpapers.folderModel.get(root.selectedIndex, "filePath") : ""
    readonly property bool selectedFolder: root.libraryPath.length > 0 && Wallpapers.folderModel.get(root.selectedIndex, "fileIsDir")

    // Online results, newest page last.
    readonly property var onlineImages: (Wallhaven.responses ?? [])
        .filter(response => response && response.provider === "wallhaven")
        .reduce((all, response) => all.concat(response.images ?? []), [])
    readonly property string onlineMessage: {
        const messages = (Wallhaven.responses ?? []).filter(response => response && response.message)
        return messages.length > 0 ? String(messages[messages.length - 1].message) : ""
    }
    readonly property int onlinePage: {
        const pages = (Wallhaven.responses ?? []).filter(response => response && response.provider === "wallhaven").map(response => Number(response.page) || 1)
        return pages.length > 0 ? Math.max(...pages) : 0
    }
    readonly property var selectedImage: root.online ? (root.onlineImages[root.selectedIndex] ?? null) : null
    readonly property var discoveries: [
        { label: Translation.tr("Top"), tags: [], category: "111" },
        { label: Translation.tr("Ricing"), tags: ["linux"], category: "111" },
        { label: Translation.tr("Minimal"), tags: ["minimal"], category: "111" },
        { label: Translation.tr("Dark"), tags: ["dark"], category: "111" },
        { label: Translation.tr("Nature"), tags: ["nature"], category: "100" },
        { label: Translation.tr("Space"), tags: ["space"], category: "100" },
        { label: Translation.tr("Abstract"), tags: ["abstract"], category: "111" },
        { label: Translation.tr("Anime"), tags: [], category: "010" }
    ]
    property int discovery: 0
    property string downloadingId: ""

    readonly property int count: root.online ? root.onlineImages.length : root.libraryCount
    readonly property string selectedName: root.online
        ? (root.selectedImage ? "wallhaven-" + root.selectedImage.id : "")
        : root.libraryPath.length > 0 ? Wallpapers.folderModel.get(root.selectedIndex, "fileName") : ""

    visible: root.morphOpen || surface.progress > 0
    screen: {
        const name = GlobalStates.wallpaperSelectorTargetMonitor
        return (name ? Quickshell.screens.find(s => s.name === name) : null) ?? GlobalStates.focusedScreen
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-wallpaper"
    WlrLayershell.keyboardFocus: root.morphOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { left: true; right: true; top: true; bottom: true }
    mask: root.morphOpen && surface.armed ? null : surfaceRegion
    Region { id: surfaceRegion; item: surface }

    function prepare(): void {
        const gsTarget = GlobalStates.wallpaperSelectorTargetMonitor ?? ""
        root.targetMonitor = !root.multiMonitor ? ""
            : gsTarget.length > 0 ? gsTarget : (GlobalStates.focusedScreen?.name ?? "")
        root.source = "library"
        Wallpapers.searchQuery = ""
        search.text = ""
        const dir = FileUtils.parentDirectory(FileUtils.trimFileProtocol(String(root.currentPath ?? "")))
        if (dir && dir.length > 0) Wallpapers.setDirectory(dir)
        Wallpapers.generateThumbnail("large")
        root.selectedIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }
    Component.onCompleted: if (root.morphOpen) root.prepare()
    onMorphOpenChanged: if (root.morphOpen) root.prepare()
    Connections {
        target: Wallpapers
        function onDirectoryChanged(): void {
            Wallpapers.generateThumbnail("large")
            if (!root.online) root.selectedIndex = 0
        }
    }

    function setSource(next: string): void {
        if (root.source === next) return
        search.text = ""
        onlineSearchDelay.stop()
        root.source = next
        root.selectedIndex = 0
        grid.contentX = 0
        if (root.online && root.onlineImages.length === 0) root.searchOnline(1, true)
    }
    function searchOnline(page: int, replace: bool): void {
        const query = search.text.trim()
        const option = root.discoveries[root.discovery]
        const tags = query.length > 0 ? query.split(/\s+/) : option.tags
        if (replace) { Wallhaven.beginSearch(); root.selectedIndex = 0; grid.contentX = 0 }
        const screen = root.screen
        Wallhaven.makeRequest(tags, false, Config.options?.sidebar?.wallhaven?.limit ?? 24, page, option.category, undefined, "wallhaven",
            { mode: "auto", width: screen?.width ?? 1920, height: screen?.height ?? 1080, ratioCode: "", aspect: (screen?.width ?? 16) / Math.max(1, screen?.height ?? 9) })
    }
    Timer { id: onlineSearchDelay; interval: 450; onTriggered: root.searchOnline(1, true) }

    function apply(filePath: string, isDir: bool): void {
        if (!filePath || filePath.length === 0) return
        if (isDir) { Wallpapers.setDirectory(filePath); return }
        Wallpapers.applySelectionTarget(FileUtils.trimFileProtocol(filePath), root.selectionTarget,
            Appearance.m3colors.darkmode, root.targetMonitor)
        root.finishSelection()
    }
    function finishSelection(): void {
        Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
        Config.setNestedValue("wallpaperSelector.targetMonitor", "")
        GlobalStates.wallpaperSelectionTarget = "main"
        GlobalStates.wallpaperSelectorTargetMonitor = ""
        GlobalStates.wallpaperSelectorOpen = false
    }
    function applyOnline(image): void {
        if (!image || !image.file_url || download.running) return
        const folder = Directories.booruDownloads
        const name = "wallhaven-" + image.id + (image.file_ext ? "." + image.file_ext : "")
        download.localPath = folder + "/" + name
        root.downloadingId = String(image.id)
        download.command = ["/usr/bin/bash", "-c", 'mkdir -p "$1" && [ -s "$2" ] || curl -fsSL "$3" -o "$2"', "_", folder, download.localPath, image.file_url]
        download.running = true
    }
    Process {
        id: download
        property string localPath: ""
        onExited: exitCode => {
            root.downloadingId = ""
            if (exitCode === 0) root.apply(download.localPath, false)
        }
    }
    function applySelected(): void {
        if (root.online) { root.applyOnline(root.selectedImage); return }
        const model = Wallpapers.folderModel
        if (!model || model.count === 0) return
        root.apply(model.get(root.selectedIndex, "filePath"), model.get(root.selectedIndex, "fileIsDir"))
    }
    function move(step: int): void {
        if (root.count === 0) return
        root.selectedIndex = Math.max(0, Math.min(root.count - 1, root.selectedIndex + step))
        grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
    }

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.wallpaperSelectorOpen = false }
    Shortcut {
        sequence: "Escape"
        enabled: root.morphOpen
        onActivated: {
            if (search.text.length > 0) search.text = ""
            else GlobalStates.wallpaperSelectorOpen = false
        }
    }

    component GlyphButton: IrisButton {
        id: glyphButton
        property string glyph: ""
        quiet: true
        implicitWidth: Math.round(34 * root.d)
        implicitHeight: implicitWidth
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
        colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.16)
        MaterialSymbol {
            anchors.centerIn: parent
            text: glyphButton.glyph
            fill: 1
            iconSize: Math.round(17 * root.d)
            color: glyphButton.enabled ? IrisStyle.text : IrisStyle.muted
        }
    }

    component KeyCap: Rectangle {
        property string label: ""
        implicitWidth: Math.max(implicitHeight, capText.implicitWidth + 10 * root.d)
        implicitHeight: Math.round(18 * root.d)
        radius: Math.round(5 * root.d)
        color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
        IrisText {
            id: capText
            anchors.centerIn: parent
            text: parent.label
            color: IrisStyle.subtext
            font.pixelSize: 10.5 * IrisStyle.typeScale
            font.weight: Font.DemiBold
        }
    }

    // A thumbnail cell shared by both sources: concentric selection ring,
    // hover lift, name melting in, and badges for the applied or downloading one.
    component Tile: MouseArea {
        id: cell
        required property int index
        property bool selected: false
        property bool current: false
        property bool busy: false
        property bool folder: false
        property string label: ""
        default property alias art: tile.data
        signal activated()
        signal committed()
        width: grid.cellWidth
        height: grid.cellHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: cell.label
        onClicked: { root.selectedIndex = cell.index; cell.activated() }
        onDoubleClicked: cell.committed()

        Item {
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.d)
            scale: cell.pressed ? 0.96 : cell.selected ? 1 : cell.containsMouse ? 0.99 : 0.97
            Behavior on scale { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

            Rectangle {
                anchors.fill: parent
                radius: Math.round(16 * root.d)
                color: "transparent"
                border.width: Math.max(2, Math.round(2.5 * root.d))
                border.color: IrisStyle.accent
                opacity: cell.selected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
            }
            ClippingRectangle {
                id: tile
                anchors.fill: parent
                anchors.margins: Math.round(5 * root.d)
                radius: Math.round(11 * root.d)
                color: IrisStyle.surfaceHigh
            }
            // Name over a melt to black while hovered or selected.
            Rectangle {
                visible: !cell.folder
                x: tile.x
                width: tile.width
                y: tile.y + tile.height - height
                height: Math.round(30 * root.d)
                radius: tile.radius
                opacity: cell.selected || cell.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                gradient: Gradient {
                    GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.surface, 0) }
                    GradientStop { position: 1; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.8) }
                }
                IrisText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Math.round(7 * root.d)
                    text: cell.label
                    font.pixelSize: 11 * IrisStyle.typeScale
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                visible: cell.current || cell.busy
                x: tile.x + tile.width - width - Math.round(6 * root.d)
                y: tile.y + Math.round(6 * root.d)
                width: Math.round(22 * root.d)
                height: width
                radius: width / 2
                color: cell.busy ? IrisStyle.surface : IrisStyle.accent
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: cell.busy ? "downloading" : "check"
                    iconSize: Math.round(14 * root.d)
                    color: cell.busy ? IrisStyle.accent : IrisStyle.onAccent
                }
            }
        }
    }

    IrisMorphSurface {
        id: surface
        open: root.morphOpen
        radius: Math.round(28 * root.d)
        readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
            + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2)) * root.d + 10 * root.d
        width: Math.min(root.width - 48, Math.round(Math.max(640, Math.min(1400, Config.options?.iris?.wallpaper?.width ?? 960)) * root.d))
        height: layout.implicitHeight + Math.round(32 * root.d)
        x: Math.round((root.width - width) / 2)
        // Hangs under the Island (or over it when the Island sits at the bottom).
        y: root.barBottom ? root.height - height - edgeGap : edgeGap
        onClosed: { Wallpapers.searchQuery = ""; search.text = "" }
        onSettledChanged: if (surface.settled && surface.open) search.forceActiveFocus()

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(16 * root.d)
            spacing: Math.round(10 * root.d)

            // Header: where the wallpapers come from, search, and the actions of
            // that source.
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                // Source switch: one sliding selection.
                Rectangle {
                    id: sourceSwitch
                    visible: root.onlineEnabled
                    Layout.preferredWidth: Math.round(208 * root.d)
                    Layout.preferredHeight: Math.round(34 * root.d)
                    radius: height / 2
                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
                    Rectangle {
                        x: 3 + (root.online ? (parent.width - 6) / 2 : 0)
                        y: 3
                        width: (parent.width - 6) / 2
                        height: parent.height - 6
                        radius: height / 2
                        color: ColorUtils.applyAlpha(IrisStyle.text, 0.16)
                        Behavior on x { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
                    }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { id: "library", label: Translation.tr("Library"), glyph: "photo_library" },
                                { id: "online", label: "Wallhaven", glyph: "travel_explore" }
                            ]
                            MouseArea {
                                id: sourceOption
                                required property var modelData
                                readonly property bool active: (sourceOption.modelData.id === "online") === root.online
                                width: sourceSwitch.width / 2
                                height: sourceSwitch.height
                                cursorShape: Qt.PointingHandCursor
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: sourceOption.modelData.label
                                Accessible.checked: sourceOption.active
                                onClicked: root.setSource(sourceOption.modelData.id)
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5 * root.d
                                    MaterialSymbol {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sourceOption.modelData.glyph
                                        fill: sourceOption.active ? 1 : 0
                                        iconSize: Math.round(15 * root.d)
                                        color: sourceOption.active ? IrisStyle.accent : IrisStyle.subtext
                                    }
                                    IrisText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sourceOption.modelData.label
                                        color: sourceOption.active ? IrisStyle.text : IrisStyle.subtext
                                        font.pixelSize: 12.5 * IrisStyle.typeScale
                                        font.weight: sourceOption.active ? Font.DemiBold : Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(34 * root.d)
                    radius: height / 2
                    color: ColorUtils.applyAlpha(IrisStyle.text, search.activeFocus ? 0.12 : 0.08)
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                    MaterialSymbol {
                        id: searchGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(12 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        iconSize: Math.round(16 * root.d)
                        color: search.text.length > 0 ? IrisStyle.accent : IrisStyle.subtext
                    }
                    TextInput {
                        id: search
                        anchors.left: searchGlyph.right
                        anchors.leftMargin: Math.round(8 * root.d)
                        anchors.right: countLabel.left
                        anchors.rightMargin: Math.round(8 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        color: IrisStyle.text
                        selectionColor: IrisStyle.accentContainer
                        selectedTextColor: IrisStyle.onAccentContainer
                        font.family: IrisStyle.fontMain
                        font.pixelSize: 13 * IrisStyle.typeScale
                        clip: true
                        focus: true
                        onTextChanged: {
                            if (root.online) { onlineSearchDelay.restart(); return }
                            Wallpapers.searchQuery = text
                            root.selectedIndex = 0
                        }
                        Keys.onPressed: event => {
                            const rows = grid.rows
                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                root.setSource(root.online ? "library" : "online")
                                search.forceActiveFocus()
                            }
                            else if (event.key === Qt.Key_Right && search.text.length === 0) root.move(rows)
                            else if (event.key === Qt.Key_Left && search.text.length === 0) root.move(-rows)
                            else if (event.key === Qt.Key_Down) root.move(1)
                            else if (event.key === Qt.Key_Up) root.move(-1)
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.applySelected()
                            else if (event.key === Qt.Key_Backspace && search.text.length === 0 && !root.online) Wallpapers.navigateUp()
                            else return
                            event.accepted = true
                        }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text.length === 0
                            text: root.online ? Translation.tr("Search Wallhaven") : Translation.tr("Search your wallpapers")
                            color: IrisStyle.muted
                            font.pixelSize: search.font.pixelSize
                        }
                    }
                    IrisText {
                        id: countLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(14 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        text: Wallhaven.runningRequests > 0 && root.online ? Translation.tr("Loading…") : String(root.count)
                        color: IrisStyle.secondaryAccent
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.Bold
                    }
                }

                GlyphButton {
                    visible: !root.online
                    glyph: "drive_folder_upload"
                    Accessible.name: Translation.tr("Parent folder")
                    onClicked: Wallpapers.navigateUp()
                }
                GlyphButton {
                    visible: !root.online
                    glyph: "shuffle"
                    enabled: root.libraryCount > 0
                    Accessible.name: Translation.tr("Random wallpaper")
                    onClicked: {
                        Wallpapers.randomFromCurrentFolder(Appearance.m3colors.darkmode, root.targetMonitor, root.selectionTarget)
                        root.finishSelection()
                    }
                }
                GlyphButton {
                    visible: root.online
                    glyph: "refresh"
                    Accessible.name: Translation.tr("Refresh")
                    onClicked: root.searchOnline(1, true)
                }
            }

            // Online: what to discover, as one scrolling row of chips.
            Flickable {
                Layout.fillWidth: true
                visible: root.online
                implicitHeight: Math.round(28 * root.d)
                contentWidth: chipRow.implicitWidth
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                Row {
                    id: chipRow
                    spacing: 6 * root.d
                Repeater {
                    model: root.discoveries
                    IrisButton {
                            required property var modelData
                            required property int index
                            text: modelData.label
                            selected: root.discovery === index && search.text.length === 0
                            quiet: !selected
                            implicitHeight: Math.round(28 * root.d)
                            buttonRadius: height / 2
                            buttonRadiusPressed: height / 2
                            onClicked: {
                                root.discovery = index
                                search.text = ""
                                onlineSearchDelay.stop()
                                root.searchOnline(1, true)
                            }
                        }
                    }
                }
            }

            // Gallery: two rows that scroll sideways (the wheel scrolls them too).
            ScriptModel {
                id: onlineResultsModel
                objectProp: "id"
                values: root.onlineImages
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                readonly property int rows: 2
                readonly property real thumbWidth: Math.round(Math.max(150, Math.min(300, (Config.options?.iris?.wallpaper?.thumbnailSize ?? 228) * 0.82)) * root.d)
                Layout.preferredHeight: cellHeight * rows
                flow: GridView.FlowTopToBottom
                cellWidth: thumbWidth
                cellHeight: Math.round(thumbWidth * 0.625)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                cacheBuffer: Math.round(cellWidth * 4)
                model: root.online ? onlineResultsModel : (Wallpapers.folderModelReady ? Wallpapers.folderModel : null)
                currentIndex: root.selectedIndex
                // Near the end of the online results, fetch the next page.
                onContentXChanged: if (root.online && Wallhaven.runningRequests === 0 && root.onlinePage > 0
                    && contentX + width > contentWidth - cellWidth * 2) root.searchOnline(root.onlinePage + 1, false)
                Behavior on contentX {
                    enabled: wheelScroll.animating
                    NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic }
                }
                WheelHandler {
                    id: wheelScroll
                    property bool animating: false
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const delta = event.pixelDelta.x || event.pixelDelta.y || (event.angleDelta.y || event.angleDelta.x) / 120 * grid.cellWidth
                        animating = event.pixelDelta.x === 0 && event.pixelDelta.y === 0
                        grid.contentX = Math.max(0, Math.min(Math.max(0, grid.contentWidth - grid.width), grid.contentX - delta))
                    }
                }

                delegate: Loader {
                    id: slot
                    required property int index
                    readonly property string filePath: !root.online && Wallpapers.folderModelReady
                        ? String(Wallpapers.folderModel.get(slot.index, "filePath") ?? "") : ""
                    readonly property string fileName: !root.online && Wallpapers.folderModelReady
                        ? String(Wallpapers.folderModel.get(slot.index, "fileName") ?? "") : ""
                    readonly property bool fileIsDir: !root.online && Wallpapers.folderModelReady
                        ? Boolean(Wallpapers.folderModel.get(slot.index, "fileIsDir") ?? false) : false
                    width: grid.cellWidth
                    height: grid.cellHeight
                    sourceComponent: root.online ? onlineTile : libraryTile

                    Component {
                        id: libraryTile
                        Tile {
                            index: slot.index
                            selected: root.selectedIndex === slot.index
                            folder: slot.fileIsDir
                            current: !slot.fileIsDir && Wallpapers.isCurrentWallpaperPath(slot.filePath, root.selectionTarget, root.targetMonitor)
                            label: slot.fileName.replace(/\.[^.]+$/, "")
                            onActivated: if (slot.fileIsDir) root.apply(slot.filePath, true)
                            onCommitted: if (!slot.fileIsDir) root.apply(slot.filePath, false)
                            ThumbnailImage {
                                anchors.fill: parent
                                visible: !slot.fileIsDir
                                generateThumbnail: true
                                sourcePath: slot.fileIsDir ? "" : slot.filePath
                                thumbnailSizeName: "large"
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: Math.round(width * 1.25)
                                sourceSize.height: Math.round(height * 1.25)
                            }
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: slot.fileIsDir
                                spacing: Math.round(3 * root.d)
                                MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "folder"; fill: 1; iconSize: Math.round(28 * root.d); color: IrisStyle.accent }
                                IrisText {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: grid.cellWidth - 30 * root.d
                                    text: slot.fileName
                                    font.pixelSize: 11.5 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    Component {
                        id: onlineTile
                        Tile {
                            id: onlineCell
                            readonly property var image: root.onlineImages[slot.index] ?? null
                            index: slot.index
                            selected: root.selectedIndex === slot.index
                            busy: root.downloadingId.length > 0 && root.downloadingId === String(image?.id ?? "")
                            label: image ? (image.width + " × " + image.height) : ""
                            onCommitted: root.applyOnline(image)
                            Image {
                                anchors.fill: parent
                                source: onlineCell.image?.preview_url ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(180) } }
                            }
                        }
                    }
                }

                IrisText {
                    anchors.centerIn: parent
                    visible: root.count === 0
                    width: parent.width - 40 * root.d
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.online
                        ? (Wallhaven.runningRequests > 0 ? Translation.tr("Looking for wallpapers…") : (root.onlineMessage || Translation.tr("Nothing found")))
                        : search.text.length > 0 ? Translation.tr("No matches") : Translation.tr("No wallpapers in this folder")
                    color: IrisStyle.muted
                }
            }

            // Selection: one line — what Apply does, where it lands, the keys.
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.d
                IrisText {
                    Layout.fillWidth: true
                    text: root.downloadingId.length > 0 ? Translation.tr("Downloading…")
                        : root.selectedName.replace(/\.[^.]+$/, "") || Translation.tr("Choose a wallpaper")
                    elide: Text.ElideMiddle
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                MaterialSymbol {
                    text: root.targetMonitor ? "desktop_windows" : "select_window"
                    iconSize: 14 * root.d
                    color: IrisStyle.muted
                }
                IrisText {
                    text: root.online ? Translation.tr("Saved to your wallpapers")
                        : Wallpapers.thumbnailGenerationRunning ? Translation.tr("Preparing previews…")
                        : (root.targetMonitor || Translation.tr("All displays"))
                    color: IrisStyle.muted
                    font.pixelSize: 11.5 * IrisStyle.typeScale
                }
                KeyCap { label: "↵"; Layout.leftMargin: 6 * root.d }
                IrisText { text: root.selectedFolder ? Translation.tr("Open") : Translation.tr("Apply"); color: IrisStyle.muted; font.pixelSize: 11.5 * IrisStyle.typeScale }
                KeyCap { label: "Esc"; Layout.leftMargin: 4 * root.d }
                IrisText { text: Translation.tr("Close"); color: IrisStyle.muted; font.pixelSize: 11.5 * IrisStyle.typeScale }
                IrisButton {
                    Layout.leftMargin: 6 * root.d
                    implicitHeight: Math.round(32 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    emphasized: !root.selectedFolder
                    text: root.selectedFolder ? Translation.tr("Open") : Translation.tr("Apply")
                    enabled: (root.online ? root.selectedImage !== null : root.libraryPath.length > 0) && root.downloadingId.length === 0
                    onClicked: root.applySelected()
                }
            }
        }
    }
}
