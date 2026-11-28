pragma ComponentBehavior: Bound
import qs
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.services
import qs.modules.waffle.settings

WSettingsPage {
    id: root

    // one side of the hero's light / dark pill
    component ModeSide: Item {
        id: side
        property string icon
        property string label
        property bool dark
        readonly property bool toggled: Appearance.m3colors.darkmode === side.dark
        implicitWidth: sideRow.implicitWidth + Looks.dp(22)
        implicitHeight: Looks.dp(26)
        Row {
            id: sideRow
            anchors.centerIn: parent
            spacing: Looks.dp(6)
            FluentIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: side.icon
                implicitSize: Looks.dp(14)
                color: "#FFFFFF" // literal: white over the darkened picture
            }
            WText {
                anchors.verticalCenter: parent.verticalCenter
                text: side.label
                font.pixelSize: Looks.font.pixelSize.small
                font.weight: side.toggled ? Looks.font.weight.strong : Looks.font.weight.regular
                color: "#FFFFFF" // literal: white over the darkened picture
                opacity: side.toggled || sideMa.containsMouse ? 1 : 0.78
            }
        }
        MouseArea {
            id: sideMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: MaterialThemeLoader.setDarkMode(side.dark)
        }
        Accessible.role: Accessible.RadioButton
        Accessible.name: side.label
        Accessible.checked: side.toggled
    }
    settingsPageIndex: 0
    pageTitle: Translation.tr("Quick Settings")
    pageIcon: "flash-on"
    pageDescription: Translation.tr("Fast access to the settings you tweak most")

    readonly property bool multiMonitorEnabled: Config.options?.background?.multiMonitor?.enable ?? false
    readonly property bool colorsOnlyMode: Config.options?.appearance?.wallpaperTheming?.colorsOnlyMode ?? false
    readonly property string previewWallpaperPath: Config.options?.appearance?.wallpaperTheming?.previewSourcePath ?? ""
    readonly property string currentWallpaperPath: Wallpapers.currentWallpaperPathForTarget("waffle", multiMonitorEnabled ? targetMonitor : "")
    readonly property string selectedWallpaperPath: (colorsOnlyMode && previewWallpaperPath.length > 0)
        ? previewWallpaperPath
        : currentWallpaperPath
    readonly property string displayWallpaperPath: selectedWallpaperPath.length > 0
        ? selectedWallpaperPath
        : currentWallpaperPath
    readonly property string currentWpUrl: {
        if (!displayWallpaperPath)
            return ""

        return displayWallpaperPath.startsWith("file://") ? displayWallpaperPath : "file://" + displayWallpaperPath
    }
    readonly property bool wpIsVideo: WallpaperListener.isVideoPath(displayWallpaperPath)
    readonly property bool wpIsGif: WallpaperListener.isGifPath(displayWallpaperPath)
    readonly property string wallpaperModeSummary: {
        if (root.colorsOnlyMode)
            return root.previewWallpaperPath.length > 0
                ? Translation.tr("Theme source only")
                : Translation.tr("Colors only")

        if (root.multiMonitorEnabled)
            return Translation.tr("Per-monitor background")

        return (Config.options?.waffles?.background?.useMainWallpaper ?? true)
            ? Translation.tr("Shared with Material ii")
            : Translation.tr("Waffle background")
    }
    readonly property var activeThemePreset: ThemePresets.getPreset(ThemeService.currentTheme)
    readonly property string activeThemeName: activeThemePreset?.name ?? Translation.tr("Auto")
    readonly property string activeThemeDescription: activeThemePreset?.description ?? Translation.tr("Wallpaper-reactive")
    readonly property string backgroundShortcutSummary: {
        const blur = Config.options?.waffles?.background?.effects?.enableBlur ?? false
        const transitions = Config.options?.waffles?.background?.transition?.enable ?? true
        if (blur && transitions)
            return Translation.tr("Blur + transitions enabled")
        if (blur)
            return Translation.tr("Blur enabled")
        if (transitions)
            return Translation.tr("Transitions enabled")
        return Translation.tr("Static background")
    }
    readonly property string waffleStyleSummary: {
        const palette = Looks.useMaterial
            ? Translation.tr("Material colors")
            : Translation.tr("Native Waffle colors")
        const chrome = Looks.glassActive
            ? Translation.tr("glass chrome")
            : Translation.tr("solid chrome")
        return palette + " · " + chrome
    }
    readonly property string currentScheme: Config.options?.appearance?.palette?.type ?? "auto"
    readonly property string effectiveRecordingPath: {
        const configured = Config.options?.screenRecord?.savePath ?? ""
        return configured.length > 0 ? configured : Directories.videosPath
    }
    readonly property string effectiveScreenshotPath: Directories.screenshotsPath

    property string targetMonitor: {
        if (!root.multiMonitorEnabled)
            return ""

        const primary = GlobalStates.primaryScreen
        const primaryName = primary ? (WallpaperListener.getMonitorName(primary) ?? "") : ""
        if (primaryName)
            return primaryName

        const focused = WallpaperListener.getFocusedMonitor()
        if (focused)
            return focused

        const screens = Quickshell.screens
        if (!screens || screens.length === 0)
            return ""

        return WallpaperListener.getMonitorName(screens[0]) ?? ""
    }

    // Folder navigation state
    property string rootWallpaperDir: ""

    readonly property bool isInSubfolder: {
        const current = FileUtils.trimFileProtocol(Wallpapers.effectiveDirectory)
        return root.rootWallpaperDir.length > 0 && current !== root.rootWallpaperDir
    }

    readonly property string currentFolderName: {
        const dir = FileUtils.trimFileProtocol(Wallpapers.effectiveDirectory)
        if (!dir)
            return ""

        const parts = dir.replace(/\/+$/, "").split("/")
        return parts[parts.length - 1] || ""
    }

    readonly property real _dpr: Math.max(
        1, root.QsWindow?.window?.devicePixelRatio ?? 1)

    readonly property string gridThumbnailSizeName: {
        const cell = Math.round(Math.max(1, wallpaperGrid.cellWidth) * root._dpr)
        const auto = Images.thumbnailSizeNameForDimensions(cell, cell)
        return (auto === "normal" || auto === "large") ? "x-large" : auto
    }

    // Decode at 2x the cell for headroom, capped at what the tier stores.
    readonly property int gridThumbnailDecodeWidth: {
        const tier = Images.thumbnailSizes[root.gridThumbnailSizeName] ?? 512
        const wanted = Math.round(Math.max(1, wallpaperGrid.cellWidth) * root._dpr * 2)
        return Math.max(1, Math.min(wanted, tier))
    }

    readonly property int gridThumbnailDecodeHeight: {
        const tier = Images.thumbnailSizes[root.gridThumbnailSizeName] ?? 512
        const wanted = Math.round(Math.max(1, wallpaperGrid.cellHeight) * root._dpr * 2)
        return Math.max(1, Math.min(wanted, tier))
    }

    function refreshGridThumbnails(): void {
        Wallpapers.generateThumbnail(root.gridThumbnailSizeName)
    }

    Component.onCompleted: Wallpapers.load()
    onGridThumbnailSizeNameChanged: root.refreshGridThumbnails()

    Connections {
        target: Wallpapers
        function onFolderChanged() {
            root.refreshGridThumbnails()
            if (root.rootWallpaperDir.length === 0)
                root.rootWallpaperDir = FileUtils.trimFileProtocol(Wallpapers.effectiveDirectory)
        }
    }

    function quickApplyTarget(): string {
        if (root.multiMonitorEnabled && root.targetMonitor.length > 0)
            return "main"

        return (Config.options?.waffles?.background?.useMainWallpaper ?? true) ? "main" : "waffle"
    }

    function applyQuickWallpaper(path: string): void {
        if (!path || path.length === 0)
            return

        if (root.colorsOnlyMode) {
            Wallpapers.applyColorsOnly(path, Appearance.m3colors.darkmode)
            return
        }

        const mon = root.multiMonitorEnabled ? root.targetMonitor : ""
        Wallpapers.applySelectionTarget(path, root.quickApplyTarget(), Appearance.m3colors.darkmode, mon)
    }

    function applyRandomQuickWallpaper(): void {
        const model = Wallpapers.folderModel
        const candidates = []
        const count = model?.count ?? 0

        for (let i = 0; i < count; ++i) {
            if (model.get(i, "fileIsDir"))
                continue

            const filePath = model.get(i, "filePath")
            if (filePath && filePath.length > 0)
                candidates.push(filePath)
        }

        if (candidates.length === 0)
            return

        root.applyQuickWallpaper(candidates[Math.floor(Math.random() * candidates.length)])
    }

    function openWallpaperBrowser(): void {
        const useMain = Config.options?.waffles?.background?.useMainWallpaper ?? true
        if (root.multiMonitorEnabled && root.targetMonitor) {
            Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            Config.setNestedValue("wallpaperSelector.targetMonitor", root.targetMonitor)
        } else {
            Config.setNestedValue("wallpaperSelector.selectionTarget", useMain ? "main" : "waffle")
        }

        ShellExec.ipc("wallpaperSelector", "toggle")
    }

    function navigateToParentFolder(): void {
        const dir = FileUtils.trimFileProtocol(Wallpapers.effectiveDirectory)
        if (!dir)
            return

        const clean = dir.replace(/\/+$/, "")
        const lastSlash = clean.lastIndexOf("/")
        if (lastSlash > 0)
            Wallpapers.setDirectory(clean.substring(0, lastSlash))
    }

    // ── Hero wallpaper card ────────────────────────────────────────────
    Rectangle {
        id: heroCard
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Math.max(Looks.dp(220), Math.min(Looks.dp(300), width * 0.36)))
        radius: Looks.settings.radiusXLarge
        color: Looks.colors.bg1Base
        clip: true

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: heroCard.width
                height: heroCard.height
                radius: heroCard.radius
            }
        }

        // Wallpaper image
        Image {
            id: heroImage
            visible: !root.wpIsGif && !root.wpIsVideo
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: visible ? root.currentWpUrl : ""
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            sourceSize.width: Math.round(heroCard.width * root._dpr * 2)
            sourceSize.height: Math.round(heroCard.height * root._dpr * 2)
        }

        AnimatedImage {
            visible: root.wpIsGif
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: visible ? root.currentWpUrl : ""
            asynchronous: true
            cache: false
            playing: visible
        }

        Image {
            visible: root.wpIsVideo
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: {
                const frame = Wallpapers.videoFirstFrames[root.displayWallpaperPath]
                return frame ? (frame.startsWith("file://") ? frame : "file://" + frame) : ""
            }
            asynchronous: true
            cache: false
            Component.onCompleted: Wallpapers.ensureVideoFirstFrame(root.displayWallpaperPath)
        }

        // Top gradient — fades from dark to transparent for upper controls
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.50) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Bottom gradient — heavier, for the greeting and the lower controls
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.62
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.25) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.70) }
            }
        }

        // Right-side lateral gradient — contrast for dark mode toggle
        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width * 0.40
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.20) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.50) }
            }
        }

        // ── Top-right: light / dark, one glass pill with a thumb that slides ───
        Rectangle {
            id: modePill
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Looks.dp(16)
            readonly property int pad: Looks.dp(3)
            implicitWidth: modeRow.implicitWidth + pad * 2
            implicitHeight: Looks.dp(32)
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.38)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            Rectangle {
                id: modeThumb
                readonly property Item on: Appearance.m3colors.darkmode ? modeDark : modeLight
                x: modePill.pad + on.x
                y: modePill.pad
                width: on.width
                height: modePill.height - modePill.pad * 2
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.24)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.30)
                Behavior on x {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? 260 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                }
                Behavior on width {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? 260 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                }
            }

            Row {
                id: modeRow
                x: modePill.pad
                y: modePill.pad
                ModeSide { id: modeLight; icon: "weather-sunny"; label: Translation.tr("Light mode"); dark: false }
                ModeSide { id: modeDark; icon: "weather-moon"; label: Translation.tr("Dark mode"); dark: true }
            }
        }

        // ── The person, greeted over their own picture ───
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: modeBadge.top
            anchors.leftMargin: Looks.dp(22)
            anchors.rightMargin: Looks.dp(22)
            anchors.bottomMargin: Looks.dp(10)
            spacing: 0
            WText {
                Layout.fillWidth: true
                text: {
                    const h = new Date().getHours()
                    return h < 5 || h >= 19 ? Translation.tr("Good evening") : h < 12 ? Translation.tr("Good morning") : Translation.tr("Good afternoon")
                }
                font.pixelSize: Looks.settings.body
                color: "#FFFFFF" // literal: white over the darkened picture, in light and dark
                opacity: 0.86
                elide: Text.ElideRight
            }
            WText {
                Layout.fillWidth: true
                text: SystemInfo.displayName || SystemInfo.username
                font.pixelSize: Looks.settings.title + Looks.dp(6)
                font.weight: Looks.font.weight.stronger
                color: "#FFFFFF" // literal: white over the darkened picture, in light and dark
                elide: Text.ElideRight
            }
        }

        // ── Bottom-left: mode pill badge ───
        Rectangle {
            id: modeBadge
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: Looks.dp(20)
            anchors.bottomMargin: Looks.dp(16)
            width: modeBadgeRow.implicitWidth + 16
            height: 26
            radius: height / 2
            color: root.colorsOnlyMode
                ? (modeBadgeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.22))
                : (modeBadgeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.55))
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root.colorsOnlyMode ? 0.38 : 0.12)

            Behavior on color {
                animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
            }

            Row {
                id: modeBadgeRow
                anchors.centerIn: parent
                spacing: 5

                FluentIcon {
                    icon: root.colorsOnlyMode ? "eyedropper" : (root.multiMonitorEnabled ? "desktop" : "image")
                    implicitSize: 11
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                WText {
                    text: root.wallpaperModeSummary
                    font.pixelSize: Looks.font.pixelSize.tiny
                    font.weight: Looks.font.weight.strong
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: modeBadgeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const next = !root.colorsOnlyMode
                    Config.setNestedValue("appearance.wallpaperTheming.colorsOnlyMode", next)
                    if (!next)
                        Config.setNestedValue("appearance.wallpaperTheming.previewSourcePath", "")
                }
            }

            WToolTip {
                extraVisibleCondition: modeBadgeMa.containsMouse
                text: root.colorsOnlyMode
                    ? Translation.tr("Picking a thumbnail only recolours the theme. Click to also set the wallpaper.")
                    : Translation.tr("Picking a thumbnail sets the wallpaper. Click to only take colours from it.")
            }
        }

        // ── Bottom-right: shuffle + browse buttons ───
        Row {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: Looks.dp(16)
            anchors.bottomMargin: Looks.dp(14)
            spacing: 6

            // Shuffle button
            Rectangle {
                id: shuffleBtn
                width: shuffleBtnRow.implicitWidth + 14
                height: 30
                radius: height / 2
                color: shuffleBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.45)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)

                Behavior on color {
                    animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                }

                Row {
                    id: shuffleBtnRow
                    anchors.centerIn: parent
                    spacing: 5

                    FluentIcon {
                        icon: "arrow-sync"
                        implicitSize: 13
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    WText {
                        text: Translation.tr("Shuffle")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: shuffleBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyRandomQuickWallpaper()
                }
            }

            // Browse button
            Rectangle {
                id: browseBtn
                width: browseBtnRow.implicitWidth + 14
                height: 30
                radius: height / 2
                color: browseBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.45)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)

                Behavior on color {
                    animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                }

                Row {
                    id: browseBtnRow
                    anchors.centerIn: parent
                    spacing: 5

                    FluentIcon {
                        icon: "folder"
                        implicitSize: 13
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    WText {
                        text: Translation.tr("Browse")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: browseBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openWallpaperBrowser()
                }
            }
        }

        // Video/GIF badge — top-left
        Rectangle {
            visible: root.wpIsVideo || root.wpIsGif
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            width: mediaBadgeRow.implicitWidth + 12
            height: 22
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.60)

            Row {
                id: mediaBadgeRow
                anchors.centerIn: parent
                spacing: 4

                FluentIcon {
                    icon: root.wpIsVideo ? "video" : "image"
                    implicitSize: 11
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                WText {
                    text: root.wpIsVideo ? "VIDEO" : "GIF"
                    font.pixelSize: Looks.font.pixelSize.tiny
                    font.weight: Looks.font.weight.strong
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── Wallpaper grid ─────────────────────────────────────────────────
    Rectangle {
        id: gridCard
        // Cells come from the column's width, not the card's: a short folder (the three pictures a new install has)
        // hugs its pictures, where a full-width plate left two thirds of it empty (10-29).
        readonly property int itemCount: Wallpapers.folderModel?.count ?? 0
        readonly property int cols: Math.max(1, Math.floor(((parent?.width ?? 0) - 12) / 140))
        readonly property real cell: ((parent?.width ?? 0) - 12) / cols
        readonly property bool hugs: itemCount > 0 && itemCount < cols && !root.isInSubfolder
        Layout.fillWidth: !hugs
        Layout.preferredWidth: hugs ? Math.ceil(itemCount * cell + 12) : -1
        Layout.preferredHeight: {
            const navH = root.isInSubfolder ? 36 : 0
            if (itemCount === 0)
                return Math.max(160, navH + 80)

            // ends at its last row: a short folder left a plate of air under its pictures (10-29)
            return Math.min(380, Math.ceil(itemCount / cols) * cell * 0.625 + 12 + navH)
        }
        radius: Looks.settings.radiusLarge
        color: Looks.settings.card
        border.width: 1
        border.color: Looks.settings.cardStroke
        clip: true

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: gridCard.width
                height: gridCard.height
                radius: gridCard.radius
            }
        }

        // Folder navigation header — visible only inside subfolders
        Item {
            id: folderNavHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.isInSubfolder ? 36 : 0
            visible: root.isInSubfolder

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 4

                Rectangle {
                    width: 28; height: 28
                    radius: Looks.radius.medium
                    color: folderBackMa.containsMouse ? Looks.colors.bg1Hover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                    }

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: "chevron-left"
                        implicitSize: 14
                        color: folderBackMa.containsMouse ? Looks.colors.accent : Looks.colors.subfg

                        Behavior on color {
                            animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                        }
                    }

                    MouseArea {
                        id: folderBackMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateToParentFolder()
                    }
                }

                WText {
                    text: root.currentFolderName
                    font.pixelSize: Looks.font.pixelSize.normal
                    font.weight: Looks.font.weight.strong
                    color: Looks.colors.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Subtle bottom separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 1
                color: Looks.colors.bg1Border
            }
        }

        GridView {
            id: wallpaperGrid
            clip: true
            anchors.top: folderNavHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.bottomMargin: 6
            anchors.topMargin: root.isInSubfolder ? 2 : 6
            model: Wallpapers.folderModelReady ? Wallpapers.folderModel : null
            Component.onCompleted: root.refreshGridThumbnails()

            cellWidth: gridCard.cell
            cellHeight: cellWidth * 0.625

            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: cellHeight * 2
            property int currentHoverIndex: -1

            ScrollBar.vertical: ScrollBar {
                policy: wallpaperGrid.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            delegate: Item {
                id: wpDelegateItem
                required property int index
                required property bool fileIsDir
                required property string filePath
                required property string fileName
                required property url fileUrl

                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    id: wpThumb
                    anchors.fill: parent
                    anchors.margins: Looks.dp(4)
                    radius: Looks.settings.radiusSmall
                    // a picture under the pointer comes forward a little
                    scale: wpDelegateItem.index === wallpaperGrid.currentHoverIndex ? 1.04 : 1
                    z: scale > 1 ? 1 : 0
                    Behavior on scale {
                        animation: NumberAnimation { duration: Looks.transition.enabled ? 200 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                    }
                    color: Looks.colors.bg2Base
                    clip: true
                    border.width: wpThumbSelected ? 2 : (wpDelegateItem.index === wallpaperGrid.currentHoverIndex ? 1 : 0)
                    border.color: wpThumbSelected ? Looks.colors.accent : Looks.colors.bg2Border

                    Behavior on border.width {
                        animation: NumberAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                    }
                    Behavior on border.color {
                        animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0 }
                    }

                    readonly property bool wpThumbSelected: {
                        if (wpDelegateItem.fileIsDir) return false
                        if (root.colorsOnlyMode) {
                            return wpDelegateItem.filePath === root.previewWallpaperPath
                        }
                        return wpDelegateItem.filePath === root.displayWallpaperPath
                    }

                    ThumbnailImage {
                        visible: !WallpaperListener.isVideoPath(wpDelegateItem.filePath) && !WallpaperListener.isGifPath(wpDelegateItem.filePath) && !wpDelegateItem.fileIsDir
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        fillMode: Image.PreserveAspectCrop
                        sourcePath: visible ? wpDelegateItem.filePath : ""
                        cache: true
                        thumbnailSizeName: root.gridThumbnailSizeName
                        smooth: true
                        mipmap: true
                        sourceSize.width: root.gridThumbnailDecodeWidth
                        sourceSize.height: root.gridThumbnailDecodeHeight
                    }

                    AnimatedImage {
                        visible: WallpaperListener.isGifPath(wpDelegateItem.filePath)
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        fillMode: Image.PreserveAspectCrop
                        source: visible ? (wpDelegateItem.filePath.startsWith("file://") ? wpDelegateItem.filePath : "file://" + wpDelegateItem.filePath) : ""
                        asynchronous: true
                        cache: true
                        playing: false
                    }

                    Image {
                        visible: WallpaperListener.isVideoPath(wpDelegateItem.filePath)
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            const ff = Wallpapers.videoFirstFrames[wpDelegateItem.filePath]
                            return ff ? (ff.startsWith("file://") ? ff : "file://" + ff) : ""
                        }
                        asynchronous: true
                        cache: true
                        Component.onCompleted: Wallpapers.ensureVideoFirstFrame(wpDelegateItem.filePath)
                    }

                    // Folder overlay
                    Rectangle {
                        visible: wpDelegateItem.fileIsDir
                        anchors.fill: parent
                        color: Looks.colors.bg2Base
                        radius: parent.radius

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3

                            FluentIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: "folder"
                                implicitSize: 28
                                color: Looks.colors.accent
                            }

                            WText {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: wpThumb.width - 12
                                text: wpDelegateItem.fileName
                                font.pixelSize: Looks.font.pixelSize.small
                                color: Looks.colors.subfg
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Selected checkmark
                    Rectangle {
                        visible: wpThumb.wpThumbSelected
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 5
                        width: 20; height: 20
                        radius: 10
                        color: Looks.colors.accent

                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "checkmark"
                            implicitSize: 12
                            color: Looks.colors.accentFg
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: wallpaperGrid.currentHoverIndex = wpDelegateItem.index
                        onExited: if (wallpaperGrid.currentHoverIndex === wpDelegateItem.index) wallpaperGrid.currentHoverIndex = -1
                        onClicked: {
                            if (wpDelegateItem.fileIsDir) {
                                Wallpapers.setDirectory(wpDelegateItem.filePath)
                            } else if (root.colorsOnlyMode) {
                                Wallpapers.applyColorsOnly(wpDelegateItem.filePath, Appearance.m3colors.darkmode)
                            } else {
                                root.applyQuickWallpaper(wpDelegateItem.filePath)
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        ColumnLayout {
            anchors.centerIn: parent
            visible: (Wallpapers.folderModel?.count ?? 0) === 0
            spacing: 6

            FluentIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "image"
                implicitSize: 32
                color: Looks.colors.accent
                opacity: 0.4
            }

            WText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No images found")
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.subfg
                opacity: 0.7
            }
        }
    }

    // Home is the picture, its folder and the ways out (his 10-29: no card of options on arrival); palette,
    // strength and transparency are Themes', per-monitor and colours-only Background's, reload toasts General's.
    // ── Related settings ───────────────────────────────────────────────
    WSettingsSection {
        title: Translation.tr("Related settings")
        icon: "open"
    }

    WSettingsCard {
        WSettingsRow {
            label: Translation.tr("Themes")
            icon: "dark-theme"
            description: root.activeThemeName + " · " + root.activeThemeDescription
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(4)
        }

        WSettingsRow {
            label: Translation.tr("Background")
            icon: "image"
            description: root.backgroundShortcutSummary
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(3)
        }

        WSettingsRow {
            label: Translation.tr("Taskbar")
            icon: "panel-left-expand"
            description: Translation.tr("Layout, tray, clock, and peek options")
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(2)
        }

        WSettingsRow {
            label: Translation.tr("Waffle Style")
            icon: "wand"
            description: root.waffleStyleSummary
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(8)
        }
    }



    WSettingsSection {
        title: Translation.tr("Capture locations")
        icon: "folder"
    }

    WSettingsCard {
        WSettingsRow {
            label: Translation.tr("Recordings folder")
            icon: "record"
            description: Directories.shortHomePath(root.effectiveRecordingPath)
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(6)
        }

        WSettingsRow {
            label: Translation.tr("Screenshots folder")
            icon: "image"
            description: Directories.shortHomePath(root.effectiveScreenshotPath)
            clickable: true
            showChevron: true
            onClicked: root.navigateRequested(6)
        }
    }
}
