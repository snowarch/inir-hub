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

    // Target monitor for wallpaper operations
    property string targetMonitor: {
        if (!multiMonitorEnabled) return ""
        const screens = Quickshell.screens
        if (!screens || screens.length === 0) return ""
        return WallpaperListener.getMonitorName(screens[0]) ?? ""
    }

    // Wallpaper section
    WSettingsCard {
        title: Translation.tr("Wallpaper & Colors")
        icon: "image-filled"

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
                    if (globalPath) Wallpapers.apply(globalPath, Appearance.m3colors.darkmode)
                }
            }
        }

        // Monitor selector strip (visible when per-monitor is ON)
        Item {
            visible: root.multiMonitorEnabled
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            implicitHeight: 78

            Rectangle {
                anchors.fill: parent
                radius: Looks.radius.large
                color: Looks.colors.bg1
                border.width: 1
                border.color: Looks.colors.bg2Border

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    height: parent.height - 10

                    Repeater {
                        model: Quickshell.screens

                        Rectangle {
                            id: qkMonCard
                            required property var modelData
                            required property int index

                            readonly property string monName: WallpaperListener.getMonitorName(modelData) ?? ""
                            readonly property var wpData: WallpaperListener.effectivePerMonitor[monName] ?? { path: "" }
                            readonly property string wpPath: wpData.path || (Config.options?.background?.wallpaperPath ?? "")
                            readonly property bool isSelected: monName === root.targetMonitor
                            readonly property real aspectRatio: modelData.width / Math.max(1, modelData.height)
                            readonly property string wpUrl: {
                                if (!wpPath) return ""
                                return wpPath.startsWith("file://") ? wpPath : "file://" + wpPath
                            }

                            onWpPathChanged: if (WallpaperListener.isVideoPath(wpPath)) Wallpapers.ensureVideoFirstFrame(wpPath)

                            width: parent.height * aspectRatio
                            height: parent.height
                            radius: Looks.radius.medium
                            color: "transparent"
                            border.width: isSelected ? 2 : 1
                            border.color: isSelected ? Looks.colors.accent : Looks.colors.bg2Border
                            clip: true

                            scale: isSelected ? 1.0 : (qkMonMa.containsMouse ? 0.97 : 0.93)
                            opacity: isSelected ? 1.0 : (qkMonMa.containsMouse ? 0.95 : 0.8)
                            Behavior on scale { animation: Looks.transition.hover.createObject(this) }
                            Behavior on opacity { animation: Looks.transition.hover.createObject(this) }
                            Behavior on border.color { animation: Looks.transition.color.createObject(this) }

                            MouseArea {
                                id: qkMonMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: root.targetMonitor = qkMonCard.monName
                            }

                            // Wallpaper thumbnail
                            Image {
                                visible: !WallpaperListener.isVideoPath(qkMonCard.wpPath) && !WallpaperListener.isGifPath(qkMonCard.wpPath)
                                anchors.fill: parent
                                anchors.margins: qkMonCard.border.width
                                fillMode: Image.PreserveAspectCrop
                                source: visible ? qkMonCard.wpUrl : ""
                                sourceSize.width: 160
                                sourceSize.height: 160
                                cache: true
                                asynchronous: true
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
                            AnimatedImage {
                                visible: WallpaperListener.isGifPath(qkMonCard.wpPath)
                                anchors.fill: parent
                                anchors.margins: qkMonCard.border.width
                                fillMode: Image.PreserveAspectCrop
                                source: visible ? qkMonCard.wpUrl : ""
                                asynchronous: true
                                cache: true
                                playing: false
                            }

                            // Label overlay
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: qkMonLabel.implicitHeight + 6
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.7) }
                                }
                                WText {
                                    id: qkMonLabel
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
                                    text: qkMonCard.monName || ("Monitor " + (qkMonCard.index + 1))
                                    font.pixelSize: Looks.font.pixelSize.tiny
                                    font.weight: Font.Medium
                                    color: "white"
                                }
                            }

                            // Selected check badge
                            Rectangle {
                                visible: qkMonCard.isSelected
                                anchors { top: parent.top; right: parent.right; margins: 3 }
                                width: 14; height: 14; radius: 7
                                color: Looks.colors.accent
                                FluentIcon {
                                    anchors.centerIn: parent
                                    icon: "checkmark"
                                    implicitSize: 8
                                    color: Looks.colors.accentFg
                                }
                            }
                        }
                    }
                }
            }
        }

        // Inline wallpaper browser strip
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            spacing: 4

            // Folder label
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                FluentIcon {
                    icon: "folder"
                    implicitSize: 12
                    color: Looks.colors.subfg
                    opacity: 0.6
                }
                WText {
                    Layout.fillWidth: true
                    text: {
                        const dir = Wallpapers.effectiveDirectory
                        if (!dir) return Translation.tr("Wallpapers")
                        const parts = dir.split("/")
                        return parts[parts.length - 1] || parts[parts.length - 2] || Translation.tr("Wallpapers")
                    }
                    font.pixelSize: Looks.font.pixelSize.tiny
                    color: Looks.colors.subfg
                    opacity: 0.6
                    elide: Text.ElideMiddle
                }
                WText {
                    text: Wallpapers.folderModel.count + " " + Translation.tr("items")
                    font.pixelSize: Looks.font.pixelSize.tiny
                    color: Looks.colors.subfg
                    opacity: 0.5
                }
            }

            // Thumbnail strip
            ListView {
                id: qkWpStrip
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                orientation: ListView.Horizontal
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Wallpapers.folderModel

                delegate: Rectangle {
                    id: qkWpThumb
                    required property int index
                    required property string filePath
                    required property string fileName
                    required property bool fileIsDir
                    required property url fileUrl

                    readonly property string currentWp: {
                        if (root.multiMonitorEnabled && root.targetMonitor) {
                            const data = WallpaperListener.effectivePerMonitor[root.targetMonitor] ?? {}
                            return data.path || (Config.options?.background?.wallpaperPath ?? "")
                        }
                        return Config.options?.background?.wallpaperPath ?? ""
                    }
                    readonly property bool isCurrent: filePath === currentWp
                    readonly property string thumbSource: {
                        if (fileIsDir) return ""
                        const thumb = Wallpapers.getExpectedThumbnailPath(filePath, "large")
                        if (thumb) return thumb.startsWith("file://") ? thumb : "file://" + thumb
                        return filePath.startsWith("file://") ? filePath : "file://" + filePath
                    }

                    width: fileIsDir ? 64 : 80
                    height: qkWpStrip.height
                    radius: Looks.radius.medium
                    color: fileIsDir ? Looks.colors.bg2Base : "transparent"
                    border.width: isCurrent ? 2 : 0
                    border.color: isCurrent ? Looks.colors.accent : "transparent"
                    clip: true

                    scale: qkThumbMa.containsMouse ? 0.95 : 1.0
                    Behavior on scale { animation: Looks.transition.hover.createObject(this) }

                    // Folder icon
                    FluentIcon {
                        visible: qkWpThumb.fileIsDir
                        anchors.centerIn: parent
                        icon: "folder"
                        implicitSize: 24
                        color: Looks.colors.subfg
                    }
                    WText {
                        visible: qkWpThumb.fileIsDir
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
                        text: qkWpThumb.fileName
                        font.pixelSize: Looks.font.pixelSize.tiny
                        color: Looks.colors.subfg
                        width: parent.width - 6
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Image thumbnail
                    Image {
                        visible: !qkWpThumb.fileIsDir && !WallpaperListener.isVideoPath(qkWpThumb.filePath)
                        anchors.fill: parent
                        anchors.margins: qkWpThumb.border.width
                        fillMode: Image.PreserveAspectCrop
                        source: visible ? qkWpThumb.thumbSource : ""
                        sourceSize.width: 160
                        sourceSize.height: 160
                        cache: true
                        asynchronous: true
                    }
                    // Video first frame
                    Image {
                        visible: !qkWpThumb.fileIsDir && WallpaperListener.isVideoPath(qkWpThumb.filePath)
                        anchors.fill: parent
                        anchors.margins: qkWpThumb.border.width
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            if (!visible) return ""
                            const ff = Wallpapers.videoFirstFrames[qkWpThumb.filePath]
                            return ff ? (ff.startsWith("file://") ? ff : "file://" + ff) : ""
                        }
                        cache: true
                        asynchronous: true
                        Component.onCompleted: {
                            if (WallpaperListener.isVideoPath(qkWpThumb.filePath))
                                Wallpapers.ensureVideoFirstFrame(qkWpThumb.filePath)
                        }
                    }

                    // Current indicator
                    Rectangle {
                        visible: qkWpThumb.isCurrent && !qkWpThumb.fileIsDir
                        anchors { top: parent.top; right: parent.right; margins: 3 }
                        width: 12; height: 12; radius: 6
                        color: Looks.colors.accent
                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "checkmark"
                            implicitSize: 7
                            color: Looks.colors.accentFg
                        }
                    }

                    MouseArea {
                        id: qkThumbMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (qkWpThumb.fileIsDir) {
                                Wallpapers.setDirectory(qkWpThumb.filePath)
                                return
                            }
                            const mon = root.multiMonitorEnabled ? root.targetMonitor : ""
                            Wallpapers.select(qkWpThumb.filePath, Appearance.m3colors.darkmode, mon)
                        }
                    }

                    WToolTip {
                        visible: qkThumbMa.containsMouse
                        text: qkWpThumb.fileName
                    }
                }
            }
        }

        // Action row
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 8
            spacing: 6

            WButton {
                Layout.fillWidth: true
                text: Translation.tr("Open selector")
                icon.name: "image"
                colBackground: Looks.colors.accent
                colBackgroundHover: Looks.colors.accentHover
                colBackgroundActive: Looks.colors.accentActive
                colForeground: Looks.colors.accentFg
                onClicked: {
                    const useMain = Config.options?.waffles?.background?.useMainWallpaper ?? true
                    if (root.multiMonitorEnabled && root.targetMonitor) {
                        Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
                        Config.setNestedValue("wallpaperSelector.targetMonitor", root.targetMonitor)
                    } else {
                        Config.setNestedValue("wallpaperSelector.selectionTarget", useMain ? "main" : "waffle")
                    }
                    Quickshell.execDetached(["/usr/bin/qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "toggle"])
                }
            }
            WButton {
                text: Translation.tr("Random")
                icon.name: "arrow-shuffle"
                onClicked: {
                    const mon = root.multiMonitorEnabled ? root.targetMonitor : ""
                    Wallpapers.randomFromCurrentFolder(Appearance.m3colors.darkmode, mon)
                }
            }
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
