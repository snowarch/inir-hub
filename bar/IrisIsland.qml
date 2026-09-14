pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

IrisSurface {
    id: root
    property var targetScreen
    property real availableWidth: 800
    property real compactHeight: 42
    property bool expanded: false
    property bool showModules: false
    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: root.player !== null && root.player !== undefined
        && String(root.player.trackTitle ?? "").length > 0
    readonly property bool ytMusic: root.hasMedia && MprisController._isYtMusicMpv(root.player)
    readonly property string title: root.ytMusic ? YtMusic.currentTitle : String(root.player?.trackTitle ?? "")
    readonly property string artist: root.ytMusic ? YtMusic.currentArtist : String(root.player?.trackArtist ?? "")
    readonly property string artwork: root.hasMedia ? MprisController.effectiveArtUrl(root.player) : ""
    readonly property var options: Config.options?.iris?.bar ?? ({})
    readonly property bool feedback: feedbackTimer.running
    property string feedbackKind: "volume"
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(root.targetScreen)
    readonly property real feedbackValue: root.feedbackKind === "brightness"
        ? (root.brightnessMonitor?.brightness ?? 0)
        : root.feedbackKind === "mic" ? (Audio.micVolume ?? 0) : (Audio.value ?? 0)
    readonly property string feedbackIcon: root.feedbackKind === "brightness" ? "brightness_6"
        : root.feedbackKind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
        : Audio.sink?.audio?.muted ? "volume_off" : "volume_up"

    implicitWidth: Math.min(root.availableWidth, (root.expanded ? 440 : root.hasMedia || root.feedback ? 300 : 232) * IrisStyle.density)
    implicitHeight: root.expanded ? (details.item?.implicitHeight ?? 0) + root.compactHeight + 28 * IrisStyle.density : root.compactHeight
    radius: root.expanded ? IrisStyle.radius : root.compactHeight / 2
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: IrisStyle.duration(240); easing.type: Easing.OutQuint } }
    Behavior on implicitHeight { NumberAnimation { duration: IrisStyle.duration(240); easing.type: Easing.OutQuint } }
    Behavior on radius { NumberAnimation { duration: IrisStyle.duration(240); easing.type: Easing.OutQuint } }

    function showFeedback(kind: string): void {
        if (!(Config.options?.iris?.modules?.osd ?? true)
            || root.targetScreen?.name !== GlobalStates.focusedScreen?.name) return
        root.feedbackKind = kind
        feedbackTimer.restart()
    }

    Timer {
        id: feedbackTimer
        interval: 1800
        onTriggered: {
            GlobalStates.osdVolumeOpen = false
            GlobalStates.osdBrightnessOpen = false
            GlobalStates.osdMicOpen = false
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.expanded && !root.showModules && (root.player?.isPlaying ?? false)
        onTriggered: root.player?.positionChanged()
    }
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged(): void { root.showFeedback("volume") }
        function onMutedChanged(): void { root.showFeedback("volume") }
    }
    Connections {
        target: Audio
        function onMicVolumeChanged(): void { root.showFeedback("mic") }
        function onMicMutedChanged(): void { root.showFeedback("mic") }
    }
    Connections {
        target: Brightness
        function onBrightnessChanged(): void { root.showFeedback("brightness") }
    }
    Connections {
        target: Notifications
        function onPopupListChanged(): void {
            if ((Notifications.popupList?.length ?? 0) > 0) root.expanded = false
        }
    }
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged(): void { if (GlobalStates.osdVolumeOpen) root.showFeedback("volume") }
        function onOsdBrightnessOpenChanged(): void { if (GlobalStates.osdBrightnessOpen) root.showFeedback("brightness") }
        function onOsdMicOpenChanged(): void { if (GlobalStates.osdMicOpen) root.showFeedback("mic") }
        function onSearchOpenChanged(): void { if (GlobalStates.searchOpen) root.expanded = false }
        function onControlPanelOpenChanged(): void { if (GlobalStates.controlPanelOpen) root.expanded = false }
    }

    IrisButton {
        id: compact
        width: parent.width
        height: root.compactHeight
        quiet: true
        buttonRadius: height / 2
        Accessible.name: root.expanded ? Translation.tr("Collapse island") : Translation.tr("Expand island")
        Accessible.checkable: true
        Accessible.checked: root.expanded
        onClicked: root.expanded = !root.expanded

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15 * IrisStyle.density
            anchors.rightMargin: 15 * IrisStyle.density
            spacing: 10 * IrisStyle.density
            Image {
                visible: root.hasMedia && !root.feedback && status === Image.Ready
                source: root.artwork
                asynchronous: true
                sourceSize: Qt.size(64, 64)
                Layout.preferredWidth: 24 * IrisStyle.density
                Layout.preferredHeight: 24 * IrisStyle.density
                fillMode: Image.PreserveAspectCrop
            }
            MaterialSymbol {
                visible: root.feedback || !root.hasMedia || root.artwork.length === 0
                text: root.feedback ? root.feedbackIcon : root.hasMedia ? "music_note" : "blur_on"
                iconSize: 22 * IrisStyle.density
                color: root.feedback ? IrisStyle.accent : root.hasMedia ? IrisStyle.secondaryAccent : IrisStyle.text
            }
            IrisText {
                Layout.fillWidth: true
                text: root.feedback ? (root.feedbackKind === "brightness" ? Translation.tr("Brightness")
                    : root.feedbackKind === "mic" ? Translation.tr("Microphone") : Translation.tr("Volume"))
                    : root.expanded ? (root.showModules || !root.hasMedia ? Translation.tr("Desktop") : Translation.tr("Now playing"))
                    : root.hasMedia ? root.title : "iRiS"
                font.pixelSize: 12 * IrisStyle.typeScale
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            IrisText {
                text: root.feedback ? Math.round(root.feedbackValue * 100) + "%" : DateTime.timeDisplay
                font.pixelSize: 12 * IrisStyle.typeScale
                font.weight: Font.DemiBold
                color: root.feedback ? IrisStyle.accent : IrisStyle.text
            }
            MaterialSymbol {
                visible: root.hasMedia && !root.feedback
                text: root.player?.isPlaying ? "graphic_eq" : "pause"
                iconSize: 20 * IrisStyle.density
                color: IrisStyle.secondaryAccent
            }
        }
    }

    Loader {
        id: details
        x: 24 * IrisStyle.density
        y: root.compactHeight + 8 * IrisStyle.density
        width: Math.max(0, root.width - 48 * IrisStyle.density)
        active: root.expanded || opacity > 0
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        enabled: root.expanded
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(100) } }
        sourceComponent: ColumnLayout {
            id: expandedContent
            spacing: 14 * IrisStyle.density

            RowLayout {
                Layout.fillWidth: true
                visible: root.hasMedia && !root.showModules
                spacing: 14 * IrisStyle.density
                Image {
                    source: root.artwork
                    asynchronous: true
                    sourceSize: Qt.size(144, 144)
                    Layout.preferredWidth: 58 * IrisStyle.density
                    Layout.preferredHeight: 58 * IrisStyle.density
                    fillMode: Image.PreserveAspectCrop
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: parent.status !== Image.Ready
                        text: "music_note"
                        color: IrisStyle.secondaryAccent
                        iconSize: 36
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    IrisText { Layout.fillWidth: true; text: root.title; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    IrisText { Layout.fillWidth: true; text: root.artist; role: IrisText.Meta; elide: Text.ElideRight }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: root.hasMedia && !root.showModules
                spacing: 22 * IrisStyle.density
                IrisIconButton {
                    materialIcon: "skip_previous"
                    iconSize: 26
                    Accessible.name: Translation.tr("Previous track")
                    enabled: MprisController.canGoPreviousForPlayer(root.player)
                    onClicked: MprisController.previousForPlayer(root.player)
                }
                IrisIconButton {
                    materialIcon: root.player?.isPlaying ? "pause" : "play_arrow"
                    implicitWidth: 48 * IrisStyle.density
                    implicitHeight: implicitWidth
                    iconSize: 34
                    Accessible.name: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                    enabled: root.player?.canControl ?? false
                    onClicked: {
                        if (root.ytMusic) YtMusic.togglePlaying()
                        else root.player?.togglePlaying()
                    }
                }
                IrisIconButton {
                    materialIcon: "skip_next"
                    iconSize: 26
                    Accessible.name: Translation.tr("Next track")
                    enabled: MprisController.canGoNextForPlayer(root.player)
                    onClicked: MprisController.nextForPlayer(root.player)
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.hasMedia && !root.showModules && (root.player?.length ?? 0) > 0
                spacing: 0
                StyledSlider {
                    Layout.fillWidth: true
                    implicitHeight: 22 * IrisStyle.density
                    enableSettingsSearch: false
                    trackWidth: 4 * IrisStyle.density
                    trackRadius: 2 * IrisStyle.density
                    handleHeight: pressed || hovered ? 12 * IrisStyle.density : 0
                    handleDefaultWidth: 12 * IrisStyle.density
                    handlePressedWidth: handleDefaultWidth
                    handleColor: IrisStyle.text
                    handleMargins: 0
                    stopIndicatorValues: []
                    enabled: root.player?.canSeek ?? false
                    value: (root.player?.length ?? 0) > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0
                    highlightColor: IrisStyle.text
                    trackColor: IrisStyle.surfaceHighest
                    tooltipContent: StringUtils.friendlyTimeForSeconds(value * (root.player?.length ?? 0))
                    onMoved: { if (root.player) root.player.position = value * root.player.length }
                }
                RowLayout {
                    Layout.fillWidth: true
                    IrisText { role: IrisText.Meta; text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0) }
                    Item { Layout.fillWidth: true }
                    IrisText { role: IrisText.Meta; text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0) }
                }
            }
            Repeater {
                model: ["left", "center", "right"]
                Flickable {
                    id: slotRow
                    required property string modelData
                    readonly property var modules: root.options?.[modelData + "Modules"] ?? []
                    Layout.fillWidth: true
                    Layout.preferredHeight: row.implicitHeight
                    visible: modules.length > 0 && (root.showModules || !root.hasMedia)
                    contentWidth: row.implicitWidth
                    contentHeight: row.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    Row {
                        id: row
                        x: Math.max(0, (slotRow.width - implicitWidth) / 2)
                        spacing: 4 * IrisStyle.density
                        Repeater {
                            model: slotRow.modules
                            IrisBarModule {
                                required property string modelData
                                moduleId: modelData
                                targetScreen: root.targetScreen
                                slot: "bar." + slotRow.modelData
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density
                IrisButton {
                    Layout.fillWidth: true
                    visible: root.hasMedia
                    quiet: true
                    text: root.showModules ? Translation.tr("Now playing") : Translation.tr("Desktop")
                    onClicked: root.showModules = !root.showModules
                }
                IrisButton {
                    Layout.fillWidth: true
                    quiet: true
                    text: Translation.tr("Quick controls")
                    onClicked: { root.expanded = false; GlobalStates.controlPanelOpen = true }
                }
            }
        }
    }
}
