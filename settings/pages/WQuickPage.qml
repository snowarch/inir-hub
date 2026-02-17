pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 0
    pageTitle: Translation.tr("Quick Settings")
    pageIcon: "flash-on"
    pageDescription: Translation.tr("Frequently used settings and quick actions")
    
    // Multi-monitor state
    readonly property bool multiMonitorEnabled: Config.options?.background?.multiMonitor?.enable ?? false

    // Wallpaper section
    WSettingsCard {
        title: Translation.tr("Wallpaper & Colors")
        icon: "image-filled"
        
        // Single wallpaper preview (visible when multi-monitor is OFF)
        Item {
            visible: !root.multiMonitorEnabled
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 12

            Rectangle {
                anchors.fill: parent
                radius: Looks.radius.large
                color: Looks.colors.bg2
                clip: true

                readonly property string wallpaperPath: {
                    const useMain = Config.options?.waffles?.background?.useMainWallpaper ?? true
                    if (useMain) return Config.options?.background?.wallpaperPath ?? ""
                    return Config.options?.waffles?.background?.wallpaperPath ?? Config.options?.background?.wallpaperPath ?? ""
                }

                readonly property bool wallpaperIsVideo: {
                    const lowerPath = wallpaperPath.toLowerCase();
                    return lowerPath.endsWith(".mp4") || lowerPath.endsWith(".webm") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".avi") || lowerPath.endsWith(".mov");
                }

                readonly property bool wallpaperIsGif: wallpaperPath.toLowerCase().endsWith(".gif")

                readonly property string wallpaperUrl: {
                    if (!wallpaperPath) return "";
                    if (wallpaperPath.startsWith("file://")) return wallpaperPath;
                    return "file://" + wallpaperPath;
                }

                // Static image
                Image {
                    id: wallpaperPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: parent.wallpaperUrl && !parent.wallpaperIsGif && !parent.wallpaperIsVideo ? parent.wallpaperUrl : ""
                    asynchronous: true
                    cache: false
                    visible: !parent.wallpaperIsGif && !parent.wallpaperIsVideo

                    layer.enabled: Appearance.effectsEnabled
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: wallpaperPreview.width
                            height: wallpaperPreview.height
                            radius: Looks.radius.large
                        }
                    }
                }

                // Animated GIF
                AnimatedImage {
                    id: gifPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: parent.wallpaperIsGif ? parent.wallpaperUrl : ""
                    asynchronous: true
                    cache: false
                    visible: parent.wallpaperIsGif
                    playing: visible

                    layer.enabled: Appearance.effectsEnabled
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: gifPreview.width
                            height: gifPreview.height
                            radius: Looks.radius.large
                        }
                    }
                }

                // Video
                Video {
                    id: videoPreview
                    anchors.fill: parent
                    source: parent.wallpaperIsVideo ? parent.wallpaperUrl : ""
                    fillMode: VideoOutput.PreserveAspectCrop
                    visible: parent.wallpaperIsVideo
                    loops: MediaPlayer.Infinite
                    muted: true
                    autoPlay: true

                    onPlaybackStateChanged: {
                        if (playbackState === MediaPlayer.StoppedState && visible) {
                            play()
                        }
                    }

                    onVisibleChanged: {
                        if (visible) {
                            play()
                        } else {
                            pause()
                        }
                    }

                    layer.enabled: Appearance.effectsEnabled
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: videoPreview.width
                            height: videoPreview.height
                            radius: Looks.radius.large
                        }
                    }
                }
                
                // Overlay buttons
                RowLayout {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8
                    
                    WButton {
                        text: Translation.tr("Change wallpaper")
                        icon.name: "image"
                        onClicked: {
                            // Use waffle target if not sharing wallpaper with Material ii
                            const useMain = Config.options?.waffles?.background?.useMainWallpaper ?? true
                            Config.setNestedValue("wallpaperSelector.selectionTarget", useMain ? "main" : "waffle")
                            Quickshell.execDetached(["/usr/bin/qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "toggle"])
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    WBorderlessButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Looks.radius.medium
                            color: Appearance.m3colors.darkmode ? Looks.colors.bg2 : Looks.colors.bg1
                            opacity: 0.9
                        }
                        
                        contentItem: FluentIcon {
                            anchors.centerIn: parent
                            icon: Appearance.m3colors.darkmode ? "weather-moon" : "weather-sunny"
                            implicitSize: 18
                            color: Looks.colors.fg
                        }
                        
                        onClicked: {
                            const dark = !Appearance.m3colors.darkmode
                            ShellExec.execCmd(`${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`)
                        }
                        
                        WToolTip {
                            visible: parent.hovered
                            text: Appearance.m3colors.darkmode ? Translation.tr("Switch to light mode") : Translation.tr("Switch to dark mode")
                        }
                    }
                }
            }
        }

        // Per-monitor toggle
        WSettingsSwitch {
            label: Translation.tr("Per-monitor wallpapers")
            icon: "monitor"
            description: Translation.tr("Set different wallpapers for each monitor")
            checked: root.multiMonitorEnabled
            onCheckedChanged: {
                Config.setNestedValue("background.multiMonitor.enable", checked)
                if (!checked) {
                    const globalPath = Config.options?.background?.wallpaperPath ?? ""
                    if (globalPath) {
                        Wallpapers.apply(globalPath, Appearance.m3colors.darkmode)
                    }
                }
            }
        }

        // Multi-monitor management panel (visible when per-monitor is ON)
        ColumnLayout {
            id: qkMultiMonPanel
            visible: root.multiMonitorEnabled
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 8
            spacing: Looks.spacing.small

            property string selectedMonitor: {
                const screens = Quickshell.screens
                if (!screens || screens.length === 0) return ""
                return WallpaperListener.getMonitorName(screens[0]) ?? ""
            }

            readonly property var selMonData: WallpaperListener.effectivePerMonitor[selectedMonitor] ?? { path: "", isVideo: false, isGif: false, isAnimated: false, hasCustomWallpaper: false }
            readonly property string selMonPath: selMonData.path || (Config.options?.background?.wallpaperPath ?? "")

            // Visual monitor layout
            Item {
                Layout.fillWidth: true
                implicitHeight: 130

                Rectangle {
                    anchors.fill: parent
                    radius: Looks.radius.large
                    color: Looks.colors.bg1
                    border.width: 1
                    border.color: Looks.colors.bg2Border

                    Row {
                        anchors.centerIn: parent
                        spacing: Looks.spacing.small
                        height: parent.height - Looks.spacing.normal

                        Repeater {
                            model: Quickshell.screens

                            Rectangle {
                                id: qkMonCard
                                required property var modelData
                                required property int index

                                readonly property string monName: WallpaperListener.getMonitorName(modelData) ?? ""
                                readonly property var wpData: WallpaperListener.effectivePerMonitor[monName] ?? { path: "" }
                                readonly property string wpPath: wpData.path || (Config.options?.background?.wallpaperPath ?? "")
                                readonly property bool isSelected: monName === qkMultiMonPanel.selectedMonitor
                                readonly property real aspectRatio: modelData.width / Math.max(1, modelData.height)

                                onWpPathChanged: if (WallpaperListener.isVideoPath(wpPath)) Wallpapers.ensureVideoFirstFrame(wpPath)

                                width: (parent.height) * aspectRatio
                                height: parent.height
                                radius: Looks.radius.small
                                color: "transparent"
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Looks.colors.accent : Looks.colors.bg2Border
                                clip: true

                                scale: isSelected ? 1.0 : (qkMonMa.containsMouse ? 0.97 : 0.93)
                                opacity: isSelected ? 1.0 : (qkMonMa.containsMouse ? 0.95 : 0.8)
                                Behavior on scale {
                                    animation: Looks.transition.number.createObject(this)
                                }
                                Behavior on opacity {
                                    animation: Looks.transition.number.createObject(this)
                                }
                                Behavior on border.color {
                                    animation: Looks.transition.color.createObject(this)
                                }

                                MouseArea {
                                    id: qkMonMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: qkMultiMonPanel.selectedMonitor = qkMonCard.monName
                                }

                                Image {
                                    visible: !WallpaperListener.isVideoPath(qkMonCard.wpPath) && !WallpaperListener.isGifPath(qkMonCard.wpPath)
                                    anchors.fill: parent
                                    anchors.margins: qkMonCard.border.width
                                    fillMode: Image.PreserveAspectCrop
                                    source: (!WallpaperListener.isVideoPath(qkMonCard.wpPath) && !WallpaperListener.isGifPath(qkMonCard.wpPath)) ? (qkMonCard.wpPath || "") : ""
                                    sourceSize.width: 200
                                    sourceSize.height: 200
                                    cache: true
                                    asynchronous: true
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: qkMonCard.width - qkMonCard.border.width * 2
                                            height: qkMonCard.height - qkMonCard.border.width * 2
                                            radius: Math.max(0, Looks.radius.small - qkMonCard.border.width)
                                        }
                                    }
                                }
                                AnimatedImage {
                                    visible: WallpaperListener.isGifPath(qkMonCard.wpPath)
                                    anchors.fill: parent
                                    anchors.margins: qkMonCard.border.width
                                    fillMode: Image.PreserveAspectCrop
                                    source: {
                                        if (!WallpaperListener.isGifPath(qkMonCard.wpPath)) return ""
                                        const p = qkMonCard.wpPath
                                        return p.startsWith("file://") ? p : "file://" + p
                                    }
                                    asynchronous: true
                                    cache: true
                                    playing: false
                                }
                                Image {
                                    visible: WallpaperListener.isVideoPath(qkMonCard.wpPath)
                                    anchors.fill: parent
                                    anchors.margins: qkMonCard.border.width
                                    fillMode: Image.PreserveAspectCrop
                                    source: {
                                        const ff = Wallpapers.videoFirstFrames[qkMonCard.wpPath]
                                        return ff ? (ff.startsWith("file://") ? ff : "file://" + ff) : ""
                                    }
                                    cache: true
                                    asynchronous: true
                                    Component.onCompleted: Wallpapers.ensureVideoFirstFrame(qkMonCard.wpPath)
                                }

                                // Media type badge
                                Rectangle {
                                    visible: WallpaperListener.isAnimatedPath(qkMonCard.wpPath)
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: Looks.spacing.small
                                    width: qkBadgeRow.implicitWidth + Looks.spacing.small * 2
                                    height: qkBadgeRow.implicitHeight + 4
                                    radius: height / 2
                                    color: Qt.rgba(0, 0, 0, 0.65)
                                    Row {
                                        id: qkBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 3
                                        FluentIcon {
                                            icon: WallpaperListener.isVideoPath(qkMonCard.wpPath) ? "video" : "gif"
                                            implicitSize: Looks.font.pixelSize.small - 2
                                            color: "white"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        WText {
                                            text: WallpaperListener.mediaTypeLabel(qkMonCard.wpPath)
                                            font.pixelSize: Looks.font.pixelSize.small
                                            color: "white"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // Bottom label gradient
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: Math.max(qkMonLabelCol.implicitHeight + 10, parent.height * 0.4)
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.35) }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                                    }
                                    ColumnLayout {
                                        id: qkMonLabelCol
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottomMargin: Looks.spacing.small
                                        spacing: 0
                                        WText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: qkMonCard.monName || ("Monitor " + (qkMonCard.index + 1))
                                            font.pixelSize: Looks.font.pixelSize.small
                                            font.weight: Font.Medium
                                            color: "white"
                                        }
                                        WText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: qkMonCard.modelData.width + "×" + qkMonCard.modelData.height
                                            font.pixelSize: Looks.font.pixelSize.small
                                            color: Qt.rgba(1, 1, 1, 0.6)
                                        }
                                    }
                                }

                                // Selected check badge
                                Rectangle {
                                    visible: qkMonCard.isSelected
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 16; height: 16
                                    radius: 8
                                    color: Looks.colors.accent
                                    FluentIcon {
                                        anchors.centerIn: parent
                                        icon: "checkmark"
                                        implicitSize: 10
                                        color: Looks.colors.accentFg
                                    }
                                }

                                // Custom wallpaper indicator dot
                                Rectangle {
                                    visible: (qkMonCard.wpData.hasCustomWallpaper ?? false) && !qkMonCard.isSelected
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    width: 7; height: 7
                                    radius: 4
                                    color: Looks.colors.accent
                                    opacity: 0.8
                                }
                            }
                        }
                    }
                }
            }

            // Hero preview + controls card
            Item {
                Layout.fillWidth: true
                implicitHeight: qkPreviewCard.implicitHeight

                Rectangle {
                    id: qkPreviewCard
                    anchors.fill: parent
                    implicitHeight: qkPreviewCol.implicitHeight
                    radius: Looks.radius.large
                    color: Looks.colors.bg2Base
                    border.width: 1
                    border.color: Looks.colors.bg2Border
                    clip: true

                    readonly property string wpUrl: {
                        const path = qkMultiMonPanel.selMonPath
                        if (!path) return ""
                        return path.startsWith("file://") ? path : "file://" + path
                    }
                    readonly property bool isVideo: WallpaperListener.isVideoPath(qkMultiMonPanel.selMonPath)
                    readonly property bool isGif: WallpaperListener.isGifPath(qkMultiMonPanel.selMonPath)

                    Connections {
                        target: qkMultiMonPanel
                        function onSelMonPathChanged() {
                            if (qkPreviewCard.isVideo) Wallpapers.ensureVideoFirstFrame(qkMultiMonPanel.selMonPath)
                        }
                    }

                    ColumnLayout {
                        id: qkPreviewCol
                        anchors { left: parent.left; right: parent.right }
                        spacing: 0

                        // Hero preview
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                            clip: true

                            Image {
                                visible: !qkPreviewCard.isGif && !qkPreviewCard.isVideo
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: visible ? qkPreviewCard.wpUrl : ""
                                asynchronous: true
                                cache: false
                            }
                            AnimatedImage {
                                visible: qkPreviewCard.isGif
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: visible ? qkPreviewCard.wpUrl : ""
                                asynchronous: true
                                cache: false
                                playing: false
                            }
                            Image {
                                visible: qkPreviewCard.isVideo
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: {
                                    const ff = Wallpapers.videoFirstFrames[qkMultiMonPanel.selMonPath]
                                    return ff ? (ff.startsWith("file://") ? ff : "file://" + ff) : ""
                                }
                                asynchronous: true
                                cache: false
                                Component.onCompleted: Wallpapers.ensureVideoFirstFrame(qkMultiMonPanel.selMonPath)
                            }

                            // Gradient overlay with monitor info
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * 0.55
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.4) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                                }

                                RowLayout {
                                    anchors {
                                        bottom: parent.bottom; left: parent.left; right: parent.right
                                        margins: 10; bottomMargin: 8
                                    }
                                    spacing: 6

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        WText {
                                            text: qkMultiMonPanel.selectedMonitor || Translation.tr("No monitor")
                                            font.pixelSize: Looks.font.pixelSize.larger
                                            font.weight: Font.DemiBold
                                            color: "#ffffff"
                                        }
                                        WText {
                                            text: {
                                                const custom = qkMultiMonPanel.selMonData.hasCustomWallpaper ?? false
                                                const animated = qkMultiMonPanel.selMonData.isAnimated ?? false
                                                let label = custom ? Translation.tr("Custom wallpaper") : Translation.tr("Global wallpaper")
                                                if (animated) label += " · " + WallpaperListener.mediaTypeLabel(qkMultiMonPanel.selMonPath)
                                                return label
                                            }
                                            font.pixelSize: Looks.font.pixelSize.small - 1
                                            color: Qt.rgba(1, 1, 1, 0.7)
                                        }
                                    }

                                    // Media type badge
                                    Rectangle {
                                        visible: qkPreviewCard.isVideo || qkPreviewCard.isGif
                                        width: qkPreviewBadge.implicitWidth + 8
                                        height: 18
                                        radius: 9
                                        color: Qt.rgba(1, 1, 1, 0.15)
                                        Row {
                                            id: qkPreviewBadge
                                            anchors.centerIn: parent
                                            spacing: 3
                                            FluentIcon {
                                                icon: qkPreviewCard.isVideo ? "video" : "gif"
                                                implicitSize: 8
                                                color: "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            WText {
                                                text: WallpaperListener.mediaTypeLabel(qkMultiMonPanel.selMonPath)
                                                font.pixelSize: Looks.font.pixelSize.small - 2
                                                color: "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Looks.colors.bg2Border
                            opacity: 0.5
                        }

                        // Controls section
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.margins: 12
                            Layout.topMargin: 10
                            Layout.bottomMargin: 12
                            spacing: 8

                            // Wallpaper path
                            WText {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                font.pixelSize: Looks.font.pixelSize.small
                                color: Looks.colors.subfg
                                opacity: 0.7
                                text: qkMultiMonPanel.selMonPath ? String(qkMultiMonPanel.selMonPath).replace(/^file:\/\//, "") : Translation.tr("No wallpaper set")
                            }

                            // Primary actions: Change + Random
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                WButton {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Change")
                                    icon.name: "image"
                                    colBackground: Looks.colors.accent
                                    colBackgroundHover: Looks.colors.accentHover
                                    colBackgroundActive: Looks.colors.accentActive
                                    colForeground: Looks.colors.accentFg
                                    onClicked: {
                                        const mon = qkMultiMonPanel.selectedMonitor
                                        if (mon) {
                                            Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
                                            Config.setNestedValue("wallpaperSelector.targetMonitor", mon)
                                            Quickshell.execDetached(["/usr/bin/qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "toggle"])
                                        }
                                    }
                                }
                                WButton {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Random")
                                    icon.name: "arrow-shuffle"
                                    onClicked: {
                                        const mon = qkMultiMonPanel.selectedMonitor
                                        if (mon) {
                                            Wallpapers.randomFromCurrentFolder(Appearance.m3colors.darkmode, mon)
                                        }
                                    }
                                }
                            }

                            // Secondary actions: Reset + Apply all
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                WButton {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Reset to global")
                                    icon.name: "arrow-reset"
                                    onClicked: {
                                        const mon = qkMultiMonPanel.selectedMonitor
                                        if (!mon) return
                                        const globalPath = Config.options?.background?.wallpaperPath ?? ""
                                        if (globalPath) {
                                            Wallpapers.select(globalPath, Appearance.m3colors.darkmode, mon)
                                        }
                                    }
                                }
                                WButton {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Apply to all")
                                    icon.name: "select-all-on"
                                    onClicked: {
                                        const globalPath = Config.options?.background?.wallpaperPath ?? ""
                                        if (globalPath) {
                                            Wallpapers.apply(globalPath, Appearance.m3colors.darkmode)
                                        }
                                    }
                                }
                            }

                            // Info bar
                            WText {
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                font.pixelSize: Looks.font.pixelSize.small - 2
                                color: Looks.colors.subfg
                                opacity: 0.6
                                text: Translation.tr("%1 monitors detected").arg(WallpaperListener.screenCount) + "  ·  " + Translation.tr("Ctrl+Alt+T targets focused output")
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // Dark mode toggle (keep accessible in multi-monitor mode)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                WButton {
                    Layout.fillWidth: true
                    text: Appearance.m3colors.darkmode ? Translation.tr("Switch to light") : Translation.tr("Switch to dark")
                    icon.name: Appearance.m3colors.darkmode ? "weather-moon" : "weather-sunny"
                    onClicked: {
                        const dark = !Appearance.m3colors.darkmode
                        ShellExec.execCmd(`${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`)
                    }
                }
            }
        }
        
        WSettingsDropdown {
            label: Translation.tr("Color scheme")
            icon: "dark-theme"
            description: Translation.tr("How colors are generated from wallpaper")
            currentValue: Config.options?.appearance?.palette?.type ?? "auto"
            options: [
                { value: "auto", displayName: Translation.tr("Auto") },
                { value: "scheme-content", displayName: Translation.tr("Content") },
                { value: "scheme-expressive", displayName: Translation.tr("Expressive") },
                { value: "scheme-fidelity", displayName: Translation.tr("Fidelity") },
                { value: "scheme-fruit-salad", displayName: Translation.tr("Fruit Salad") },
                { value: "scheme-monochrome", displayName: Translation.tr("Monochrome") },
                { value: "scheme-neutral", displayName: Translation.tr("Neutral") },
                { value: "scheme-rainbow", displayName: Translation.tr("Rainbow") },
                { value: "scheme-tonal-spot", displayName: Translation.tr("Tonal Spot") }
            ]
            onSelected: newValue => {
                Config.setNestedValue("appearance.palette.type", newValue)
                ShellExec.execCmd(`${Directories.wallpaperSwitchScriptPath} --noswitch`)
            }
        }
        
        WSettingsSwitch {
            label: Translation.tr("Transparency")
            icon: "auto"
            description: Translation.tr("Enable transparent UI elements")
            checked: Config.options?.appearance?.transparency?.enable ?? false
            onCheckedChanged: Config.setNestedValue("appearance.transparency.enable", checked)
        }
    }
    
    // Taskbar section (waffle-specific)
    WSettingsCard {
        title: Translation.tr("Taskbar")
        icon: "desktop"
        
        WSettingsSwitch {
            label: Translation.tr("Left-align apps")
            icon: "chevron-left"
            description: Translation.tr("Align taskbar apps to the left instead of center")
            checked: Config.options?.waffles?.bar?.leftAlignApps ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.leftAlignApps", checked)
        }
        
        WSettingsSwitch {
            label: Translation.tr("Tint app icons")
            icon: "dark-theme"
            description: Translation.tr("Apply accent color to taskbar icons")
            checked: Config.options?.waffles?.bar?.monochromeIcons ?? false
            onCheckedChanged: Config.setNestedValue("waffles.bar.monochromeIcons", checked)
        }
        
        WSettingsDropdown {
            label: Translation.tr("Screen rounding")
            icon: "desktop"
            description: Translation.tr("Fake rounded corners for flat screens")
            currentValue: Config.options?.appearance?.fakeScreenRounding ?? 0
            options: [
                { value: 0, displayName: Translation.tr("None") },
                { value: 1, displayName: Translation.tr("Always") },
                { value: 2, displayName: Translation.tr("When not fullscreen") }
            ]
            onSelected: newValue => Config.setNestedValue("appearance.fakeScreenRounding", newValue)
        }
    }
    
    // Quick Actions section
    WSettingsCard {
        title: Translation.tr("Quick Actions")
        icon: "flash-on"
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            WButton {
                Layout.fillWidth: true
                text: Translation.tr("Reload shell")
                icon.name: "arrow-sync"
                onClicked: Quickshell.execDetached(["/usr/bin/setsid", "/usr/bin/fish", "-c", "qs kill -c ii; sleep 0.3; qs -c ii"])
            }
            
            WButton {
                Layout.fillWidth: true
                text: Translation.tr("Open config")
                icon.name: "settings"
                onClicked: Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`)
            }
            
            WButton {
                Layout.fillWidth: true
                text: Translation.tr("Shortcuts")
                icon.name: "keyboard"
                onClicked: Quickshell.execDetached(["/usr/bin/qs", "-c", "ii", "ipc", "call", "cheatsheet", "toggle"])
            }
        }
        
        WSettingsSwitch {
            label: Translation.tr("Show reload notifications")
            icon: "alert"
            description: Translation.tr("Toast when Quickshell or Niri config reloads")
            checked: Config.options?.reloadToasts?.enable ?? true
            onCheckedChanged: Config.setNestedValue("reloadToasts.enable", checked)
        }
    }
}
