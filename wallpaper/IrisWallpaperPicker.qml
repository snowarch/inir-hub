pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root

    readonly property real d: IrisStyle.density
    readonly property bool morphOpen: GlobalStates.wallpaperSelectorOpen
    readonly property bool multiMonitor: Config.options?.background?.multiMonitor?.enable ?? false
    readonly property bool onlineEnabled: Config.options?.sidebar?.wallhaven?.enable ?? true
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barBottom: String(root.barOptions?.position ?? "top") === "bottom"
    property string targetMonitor: ""
    readonly property string selectionTarget: Wallpapers.currentSelectionTarget()
    readonly property string currentPath: Wallpapers.currentWallpaperPathForTarget(root.selectionTarget, root.targetMonitor)

    property string source: "library"
    readonly property bool online: root.source === "online" && root.onlineEnabled
    property int selectedIndex: 0

    property var libraryFolders: []
    property var libraryFiles: []
    function readFolder(): void {
        const model = Wallpapers.folderModel
        const folders = []
        const files = []
        if (Wallpapers.folderModelReady && model) {
            for (let i = 0; i < model.count; i++) {
                const entry = { path: String(model.get(i, "filePath") ?? ""), name: String(model.get(i, "fileName") ?? "") }
                if (entry.path.length === 0) continue
                if (model.get(i, "fileIsDir")) folders.push(entry)
                else files.push(entry)
            }
        }
        folders.sort((a, b) => a.name.localeCompare(b.name))
        const same = (a, b) => a.length === b.length && a.every((entry, i) => entry.path === b[i].path)
        if (!same(folders, root.libraryFolders)) root.libraryFolders = folders
        if (!same(files, root.libraryFiles)) root.libraryFiles = files
        if (root.selectedIndex >= files.length) root.selectedIndex = Math.max(0, files.length - 1)
    }
    Connections {
        target: Wallpapers.folderModel
        function onCountChanged(): void { folderRead.restart() }
        function onStatusChanged(): void { folderRead.restart() }
    }
    Connections {
        target: Wallpapers
        function onFolderModelReadyChanged(): void { folderRead.restart() }
    }
    Timer { id: folderRead; interval: 40; onTriggered: root.readFolder() }
    readonly property int libraryCount: root.libraryFiles.length
    readonly property string libraryPath: !root.online ? String(root.libraryFiles[root.selectedIndex]?.path ?? "") : ""

    readonly property string folderPath: Wallpapers.effectiveDirectory.replace(/\/+$/, "") || "/"
    readonly property string homePath: String(Quickshell.env("HOME") ?? "").replace(/\/+$/, "")
    readonly property string wallpapersHome: FileUtils.trimFileProtocol(String(Wallpapers.defaultFolder ?? "")).replace(/\/+$/, "")
    readonly property var crumbs: {
        const path = root.folderPath
        const underHome = root.homePath.length > 0 && (path === root.homePath || path.startsWith(root.homePath + "/"))
        const base = underHome ? root.homePath : ""
        const rest = path.slice(base.length).split("/").filter(part => part.length > 0)
        const list = [{ label: underHome ? Translation.tr("Home") : "/", path: underHome ? root.homePath : "/", home: true }]
        let walked = base
        for (const part of rest) {
            walked += "/" + part
            list.push({ label: part, path: walked, home: false })
        }
        return list.length > 5 ? [list[0], { label: "…", path: list[list.length - 4].path, home: false }].concat(list.slice(-3)) : list
    }
    readonly property bool canGoBack: (Wallpapers.folderModel?.currentFolderHistoryIndex ?? 0) > 0
    readonly property bool canGoForward: (Wallpapers.folderModel?.currentFolderHistoryIndex ?? 0) < (Wallpapers.folderModel?.folderHistory?.length ?? 0) - 1
    readonly property bool atWallpapersHome: root.folderPath === root.wallpapersHome
    function openFolder(path: string): void {
        if (!path || path === root.folderPath) return
        root.selectedIndex = 0
        grid.contentX = 0
        Wallpapers.setDirectory(path)
    }

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
        : String(root.libraryFiles[root.selectedIndex]?.name ?? "")

    visible: root.morphOpen || surface.progress > 0
    IrisOutputHold {
        id: outputHold
        wanted: {
            const name = GlobalStates.wallpaperSelectorTargetMonitor
            return (name ? Quickshell.screens.find(s => s.name === name) : null) ?? GlobalStates.focusedScreen
        }
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-wallpaper"
    WlrLayershell.keyboardFocus: root.morphOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { left: true; right: true; top: true; bottom: true }
    margins {
        left: IrisFrame.band
        right: IrisFrame.band
        top: IrisFrame.band
        bottom: IrisFrame.band
    }
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
        root.previewArmed = false
        root.readFolder()
        root.selectCurrent()
        Qt.callLater(() => search.forceActiveFocus())
    }
    function selectCurrent(): void {
        const current = FileUtils.trimFileProtocol(String(root.currentPath ?? ""))
        const index = root.libraryFiles.findIndex(entry => entry.path === current)
        if (index >= 0) {
            root.selectedIndex = index
            Qt.callLater(() => grid.positionViewAtIndex(index, GridView.Contain))
        }
    }
    Component.onCompleted: if (root.morphOpen) root.prepare()
    Connections {
        target: Wallpapers
        function onDirectoryChanged(): void {
            Wallpapers.generateThumbnail("large")
            if (!root.online) { root.selectedIndex = 0; grid.contentX = 0 }
            folderRead.restart()
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
        if (isDir) { root.openFolder(filePath); return }
        const target = root.selectionTarget
        root.committing = true
        Wallpapers.applySelectionTarget(FileUtils.trimFileProtocol(filePath), target,
            Appearance.m3colors.darkmode, root.targetMonitor)
        if (target === "backdrop" || target === "waffle-backdrop") Wallpapers.cancelWallpaperPreview()
        else Wallpapers.clearWallpaperPreview()
        root.finishSelection()
        Qt.callLater(() => root.committing = false)
    }

    readonly property bool livePreview: Config.options?.iris?.wallpaper?.livePreview ?? true
    property bool previewArmed: false
    property bool committing: false
    onSelectedIndexChanged: if (root.morphOpen && !root.online) previewDelay.restart()
    Timer {
        id: previewDelay
        interval: 180
        onTriggered: {
            if (!root.morphOpen || root.online || !root.livePreview || !root.previewArmed) return
            const path = root.libraryPath
            if (!path || path === FileUtils.trimFileProtocol(String(root.currentPath ?? ""))) Wallpapers.cancelWallpaperPreview()
            else Wallpapers.previewWallpaper(path, root.targetMonitor)
        }
    }
    function select(index: int): void {
        root.previewArmed = true
        root.selectedIndex = index
    }
    onMorphOpenChanged: {
        if (root.morphOpen) root.prepare()
        else if (!root.committing) Wallpapers.cancelWallpaperPreview()
    }
    onLivePreviewChanged: if (!root.livePreview) Wallpapers.cancelWallpaperPreview()
    onOnlineChanged: if (root.online) Wallpapers.cancelWallpaperPreview()
    Component.onDestruction: if (!root.committing) Wallpapers.cancelWallpaperPreview()
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
        if (root.libraryPath.length > 0) root.apply(root.libraryPath, false)
    }
    function move(step: int): void {
        if (root.count === 0) return
        root.select(Math.max(0, Math.min(root.count - 1, root.selectedIndex + step)))
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
    Shortcut { sequence: "Alt+Left"; enabled: root.morphOpen && !root.online && root.canGoBack; onActivated: Wallpapers.navigateBack() }
    Shortcut { sequence: "Alt+Right"; enabled: root.morphOpen && !root.online && root.canGoForward; onActivated: Wallpapers.navigateForward() }
    Shortcut { sequence: "Alt+Up"; enabled: root.morphOpen && !root.online; onActivated: Wallpapers.navigateUp() }

    component GlyphButton: IrisButton {
        id: glyphButton
        property string glyph: ""
        quiet: true
        implicitWidth: Math.round(34 * root.d)
        implicitHeight: implicitWidth
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        colBackground: IrisStyle.fillQuiet
        colBackgroundHover: IrisStyle.fillHover
        MaterialSymbol {
            anchors.centerIn: parent
            text: glyphButton.glyph
            fill: 1
            iconSize: Math.round(17 * root.d)
            color: !glyphButton.enabled ? IrisStyle.muted : glyphButton.selected ? IrisStyle.accent : IrisStyle.text
        }
    }

    component KeyCap: Rectangle {
        property string label: ""
        implicitWidth: Math.max(implicitHeight, capText.implicitWidth + 10 * root.d)
        implicitHeight: Math.round(18 * root.d)
        radius: IrisStyle.radiusChip
        color: IrisStyle.fill
        IrisText {
            id: capText
            anchors.centerIn: parent
            text: parent.label
            color: IrisStyle.subtext
            font.pixelSize: 10.5 * IrisStyle.typeScale
            font.weight: Font.DemiBold
        }
    }

    component Tile: MouseArea {
        id: cell
        required property int index
        property bool selected: false
        property bool current: false
        property bool busy: false
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
        onClicked: { root.select(cell.index); cell.activated() }
        onDoubleClicked: cell.committed()

        Item {
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.d)
            scale: cell.pressed ? IrisStyle.pressScale(0.97) : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

            Rectangle {
                anchors.fill: parent
                radius: IrisStyle.radiusCard
                color: "transparent"
                border.width: Math.max(2, Math.round(2.5 * root.d))
                border.color: IrisStyle.accent
                opacity: cell.selected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
            }
            ClippingRectangle {
                id: tile
                anchors.fill: parent
                anchors.margins: Math.round(4 * root.d)
                radius: IrisStyle.radiusTile
                color: IrisStyle.surfaceHigh
            }
            Rectangle {
                x: tile.x
                width: tile.width
                y: tile.y + tile.height - height
                height: Math.round(44 * root.d)
                radius: tile.radius
                opacity: cell.selected || cell.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                gradient: Gradient {
                    GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.surface, 0) }
                    GradientStop { position: 1; color: IrisStyle.veilHeavy }
                }
                IrisText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Math.round(7 * root.d)
                    text: cell.label
                    font.pixelSize: 12 * IrisStyle.typeScale
                    color: IrisStyle.onMedia
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

    RectangularShadow {
        x: surface.x + surface.lerp(surface.from.x, 0)
        y: surface.y + surface.lerp(surface.from.y, 0) + 8 * root.d * surface.progress
        width: surface.lerp(surface.from.width, surface.width)
        height: surface.lerp(surface.from.height, surface.height)
        radius: Math.min(width / 2, height / 2, surface.lerp(surface.fromRadius, surface.radius))
        blur: 32 * root.d
        spread: -6 * root.d
        color: IrisStyle.shadow
        opacity: IrisStyle.shadowAt(surface.progress)
    }

    IrisMorphSurface {
        motionSurface: "gallery"
        windowOffset: Qt.point(IrisFrame.band, IrisFrame.band)
        id: surface
        open: root.morphOpen
        radius: IrisStyle.surfaceRadius("gallery", IrisStyle.radiusPanel)
        light: IrisStyle.surfaceLight("gallery", IrisStyle.wallpaperLight)
        lightFrom: (Config.options?.iris?.bar?.position ?? "top") === "bottom" ? "bottom" : "top"
        readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
            + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2)) * root.d + 10 * root.d
        width: Math.min(root.width - 48, Math.round(Math.max(640, Math.min(1400, Config.options?.iris?.wallpaper?.width ?? 960)) * root.d))
        height: layout.implicitHeight + Math.round(40 * root.d)
        x: Math.round((root.width - width) / 2)
        y: root.barBottom ? root.height - height - edgeGap : edgeGap
        onClosed: { Wallpapers.searchQuery = ""; search.text = "" }
        onSettledChanged: if (surface.settled && surface.open) search.forceActiveFocus()

        Rectangle {
            z: 100
            opacity: Math.max(0, (surface.progress - 0.85) / 0.15)
            anchors.fill: parent
            radius: surface.radius
            color: "transparent"
            border.width: 1
            border.color: IrisStyle.border
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(20 * root.d)
            spacing: Math.round(12 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)

                GlyphButton {
                    visible: !root.online
                    glyph: "chevron_left"
                    enabled: root.canGoBack
                    Accessible.name: Translation.tr("Back")
                    onClicked: Wallpapers.navigateBack()
                }
                GlyphButton {
                    visible: !root.online
                    glyph: "chevron_right"
                    enabled: root.canGoForward
                    Accessible.name: Translation.tr("Forward")
                    onClicked: Wallpapers.navigateForward()
                }

                Flickable {
                    id: crumbFlick
                    visible: !root.online
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(34 * root.d)
                    contentWidth: crumbRow.implicitWidth
                    contentX: Math.max(0, crumbRow.implicitWidth - width)
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: crumbRow.implicitWidth > width
                    clip: true
                    Row {
                        id: crumbRow
                        height: parent.height
                        spacing: Math.round(2 * root.d)
                        Repeater {
                            model: root.crumbs
                            Row {
                                id: crumb
                                required property var modelData
                                required property int index
                                readonly property bool last: crumb.index === root.crumbs.length - 1
                                height: crumbRow.height
                                spacing: Math.round(2 * root.d)
                                MaterialSymbol {
                                    visible: crumb.index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "chevron_right"
                                    iconSize: Math.round(15 * root.d)
                                    color: IrisStyle.muted
                                }
                                MouseArea {
                                    id: crumbArea
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: crumbContent.implicitWidth + Math.round(18 * root.d)
                                    height: Math.round(28 * root.d)
                                    hoverEnabled: true
                                    cursorShape: crumb.last ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    Accessible.role: Accessible.Button
                                    Accessible.name: crumb.modelData.label
                                    onClicked: root.openFolder(crumb.modelData.path)
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: (crumb.last ? IrisStyle.fill : crumbArea.containsMouse ? IrisStyle.fillQuiet : ColorUtils.applyAlpha(IrisStyle.text, 0))
                                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                                    }
                                    Row {
                                        id: crumbContent
                                        anchors.centerIn: parent
                                        spacing: Math.round(5 * root.d)
                                        MaterialSymbol {
                                            visible: crumb.modelData.home || (crumb.last && root.atWallpapersHome)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: crumb.modelData.home ? "home" : "wallpaper"
                                            fill: 1
                                            iconSize: Math.round(15 * root.d)
                                            color: crumb.last ? IrisStyle.accent : IrisStyle.subtext
                                        }
                                        IrisText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: crumb.modelData.label
                                            color: crumb.last ? IrisStyle.text : IrisStyle.subtext
                                            font.pixelSize: (crumb.last ? 13.5 : 12.5) * IrisStyle.typeScale
                                            font.weight: crumb.last ? Font.DemiBold : Font.Medium
                                        }
                                        IrisText {
                                            visible: crumb.last
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: String(root.libraryCount)
                                            color: IrisStyle.secondaryAccent
                                            font.family: IrisStyle.fontNumbers
                                            font.features: ({ "tnum": 1 })
                                            font.pixelSize: 12 * IrisStyle.typeScale
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                IrisText {
                    visible: root.online
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(4 * root.d)
                    text: Translation.tr("Discover on Wallhaven")
                    font.pixelSize: 13.5 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                GlyphButton {
                    visible: !root.online && !root.atWallpapersHome
                    glyph: "wallpaper"
                    Accessible.name: Translation.tr("Wallpapers folder")
                    onClicked: root.openFolder(root.wallpapersHome)
                }

                Rectangle {
                    id: sourceSwitch
                    visible: root.onlineEnabled
                    Layout.preferredWidth: Math.round(208 * root.d)
                    Layout.preferredHeight: Math.round(34 * root.d)
                    radius: height / 2
                    color: IrisStyle.fillQuiet
                    Rectangle {
                        x: 3 + (root.online ? (parent.width - 6) / 2 : 0)
                        y: 3
                        width: (parent.width - 6) / 2
                        height: parent.height - 6
                        radius: height / 2
                        color: IrisStyle.fillHover
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
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(34 * root.d)
                    radius: height / 2
                    color: (search.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet)
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
                            else if (event.modifiers & Qt.AltModifier) return
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
                            text: root.online ? Translation.tr("Search Wallhaven")
                                : Translation.tr("Search in %1").arg(root.crumbs[root.crumbs.length - 1]?.label ?? "")
                            color: IrisStyle.muted
                            font.pixelSize: search.font.pixelSize
                        }
                    }
                    IrisText {
                        id: countLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(14 * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.online || search.text.length > 0
                        text: Wallhaven.runningRequests > 0 && root.online ? Translation.tr("Loading…") : String(root.count)
                        color: IrisStyle.secondaryAccent
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: 12.5 * IrisStyle.typeScale
                        font.weight: Font.Bold
                    }
                }

                GlyphButton {
                    visible: !root.online
                    glyph: root.livePreview ? "visibility" : "visibility_off"
                    selected: root.livePreview
                    Accessible.name: Translation.tr("Preview on the desktop")
                    onClicked: Config.setNestedValue("iris.wallpaper.livePreview", !root.livePreview)
                }
                GlyphButton {
                    visible: !root.online
                    glyph: "shuffle"
                    enabled: root.libraryCount > 0
                    Accessible.name: Translation.tr("Random wallpaper")
                    onClicked: {
                        const pick = root.libraryFiles[Math.floor(Math.random() * root.libraryFiles.length)]
                        if (pick) root.apply(pick.path, false)
                    }
                }
                GlyphButton {
                    visible: root.online
                    glyph: "refresh"
                    Accessible.name: Translation.tr("Refresh")
                    onClicked: root.searchOnline(1, true)
                }
            }

            Flickable {
                id: folderStrip
                Layout.fillWidth: true
                visible: !root.online && search.text.length === 0 && root.libraryFolders.length > 0
                implicitHeight: Math.round(32 * root.d)
                contentWidth: folderRow.implicitWidth
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const delta = event.pixelDelta.x || event.pixelDelta.y || (event.angleDelta.y || event.angleDelta.x) / 2
                        folderStrip.contentX = Math.max(0, Math.min(Math.max(0, folderStrip.contentWidth - folderStrip.width), folderStrip.contentX - delta))
                    }
                }
                Row {
                    id: folderRow
                    spacing: Math.round(6 * root.d)
                    Repeater {
                        model: root.libraryFolders
                        MouseArea {
                            id: folderChip
                            required property var modelData
                            width: chipContent.implicitWidth + Math.round(24 * root.d)
                            height: folderStrip.height
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: folderChip.modelData.name
                            onClicked: root.openFolder(folderChip.modelData.path)
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: (folderChip.pressed ? IrisStyle.fillActive : folderChip.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet)
                                scale: folderChip.pressed ? IrisStyle.pressScale(0.96) : 1
                                Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                                Behavior on scale { NumberAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                            }
                            Row {
                                id: chipContent
                                anchors.centerIn: parent
                                spacing: Math.round(6 * root.d)
                                MaterialSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "folder"
                                    fill: 1
                                    iconSize: Math.round(16 * root.d)
                                    color: IrisStyle.accent
                                }
                                IrisText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: folderChip.modelData.name
                                    font.pixelSize: 12.5 * IrisStyle.typeScale
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }

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

            ScriptModel {
                id: onlineResultsModel
                objectProp: "id"
                values: root.onlineImages
            }
            ScriptModel {
                id: libraryModel
                objectProp: "path"
                values: root.libraryFiles
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                readonly property int rows: 2
                readonly property real thumbWidth: Math.round(Math.max(150, Math.min(300, (Config.options?.iris?.wallpaper?.thumbnailSize ?? 228))) * root.d)
                Layout.preferredHeight: cellHeight * rows
                flow: GridView.FlowTopToBottom
                cellWidth: thumbWidth
                cellHeight: Math.round(thumbWidth * 0.625)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                cacheBuffer: Math.round(cellWidth * 4)
                model: root.online ? onlineResultsModel : libraryModel
                currentIndex: root.selectedIndex
                onContentXChanged: if (root.online && Wallhaven.runningRequests === 0 && root.onlinePage > 0
                    && contentX + width > contentWidth - cellWidth * 2) root.searchOnline(root.onlinePage + 1, false)
                Behavior on contentX {
                    enabled: wheelScroll.animating
                    NumberAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing }
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
                    required property var modelData
                    readonly property string filePath: !root.online ? String(slot.modelData?.path ?? "") : ""
                    readonly property string fileName: !root.online ? String(slot.modelData?.name ?? "") : ""
                    width: grid.cellWidth
                    height: grid.cellHeight
                    sourceComponent: root.online ? onlineTile : libraryTile

                    Component {
                        id: libraryTile
                        Tile {
                            index: slot.index
                            selected: root.selectedIndex === slot.index
                            current: Wallpapers.isCurrentWallpaperPath(slot.filePath, root.selectionTarget, root.targetMonitor)
                            label: slot.fileName.replace(/\.[^.]+$/, "")
                            onCommitted: root.apply(slot.filePath, false)
                            ThumbnailImage {
                                anchors.fill: parent
                                generateThumbnail: true
                                sourcePath: slot.filePath
                                thumbnailSizeName: "large"
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: Math.round(width * 1.25)
                                sourceSize.height: Math.round(height * 1.25)
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

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.count === 0
                    width: parent.width - 40 * root.d
                    spacing: Math.round(6 * root.d)
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.online ? "travel_explore"
                            : search.text.length > 0 ? "search_off"
                            : root.libraryFolders.length > 0 ? "folder_open" : "hide_image"
                        fill: 1
                        iconSize: Math.round(30 * root.d)
                        color: IrisStyle.muted
                    }
                    IrisText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.online
                            ? (Wallhaven.runningRequests > 0 ? Translation.tr("Looking for wallpapers…") : (root.onlineMessage || Translation.tr("Nothing found")))
                            : search.text.length > 0 ? Translation.tr("No matches")
                            : root.libraryFolders.length > 0 ? Translation.tr("Wallpapers live in the folders above")
                            : Translation.tr("No wallpapers in this folder")
                        color: IrisStyle.muted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: IrisStyle.hairline
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.d
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    IrisText {
                        Layout.fillWidth: true
                        text: root.downloadingId.length > 0 ? Translation.tr("Downloading…")
                            : root.selectedName.replace(/\.[^.]+$/, "") || Translation.tr("Choose a wallpaper")
                        elide: Text.ElideMiddle
                        font.pixelSize: 15 * IrisStyle.typeScale
                        font.weight: Font.DemiBold
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: root.online ? (root.selectedImage ? root.selectedImage.width + " × " + root.selectedImage.height + " · " + Translation.tr("saved to your wallpapers") : "")
                            : Wallpapers.thumbnailGenerationRunning ? Translation.tr("Preparing previews…")
                            : root.livePreview && root.previewArmed ? Translation.tr("Previewing on the desktop")
                            : Translation.tr("Double-click or press Enter to apply")
                        color: IrisStyle.muted
                        font.pixelSize: 11 * IrisStyle.typeScale
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    implicitHeight: Math.round(28 * root.d)
                    implicitWidth: targetRow.implicitWidth + Math.round(20 * root.d)
                    radius: height / 2
                    color: "transparent"
                    Row {
                        id: targetRow
                        anchors.centerIn: parent
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.targetMonitor ? "desktop_windows" : "select_window"
                            iconSize: Math.round(14 * root.d)
                            color: IrisStyle.subtext
                        }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.targetMonitor || Translation.tr("All displays")
                            color: IrisStyle.subtext
                            font.pixelSize: 11.5 * IrisStyle.typeScale
                        }
                    }
                }
                KeyCap { label: "Esc"; Layout.leftMargin: 2 * root.d }
                IrisButton {
                    implicitHeight: Math.round(36 * root.d)
                    implicitWidth: Math.round(88 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    emphasized: true
                    text: Translation.tr("Apply")
                    enabled: (root.online ? root.selectedImage !== null : root.libraryPath.length > 0) && root.downloadingId.length === 0
                    onClicked: root.applySelected()
                }
            }
        }
    }
}
