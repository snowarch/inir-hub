pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.mediaControls.components
import qs.modules.iris.components
import qs.modules.iris.style

// Island Control Center. Grouped modules on one black chassis: connectivity and
// now-playing blocks, capsule levels, quick toggles, grouped notifications and
// session actions. Every control drives the shared iNiR service it names.
ColumnLayout {
    id: root
    property var targetScreen
    readonly property real d: IrisStyle.density
    readonly property var monitor: Brightness.getMonitorForScreen(root.targetScreen)
    readonly property real blockRadius: Math.round(22 * root.d)
    readonly property color blockColor: ColorUtils.applyAlpha(IrisStyle.text, 0.07)
    // Which device list unfolds under the levels: "output", "input" or none.
    property string picker: ""
    // Name of the tile under the pointer, shown in place of the date.
    property string hint: ""
    spacing: 10 * root.d

    component Block: Rectangle {
        radius: root.blockRadius
        color: root.blockColor
    }

    component RoundToggle: ColumnLayout {
        id: toggle
        property string glyph: ""
        property string label: ""
        property bool checked: false
        property color tint: IrisStyle.accent
        signal toggled()
        spacing: 4 * root.d
        IrisButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(46 * root.d)
            implicitHeight: implicitWidth
            buttonRadius: height / 2
            buttonRadiusPressed: height / 2
            colBackground: toggle.checked ? toggle.tint : ColorUtils.applyAlpha(IrisStyle.text, 0.12)
            colBackgroundHover: toggle.checked ? ColorUtils.mix(toggle.tint, IrisStyle.text, 0.85) : ColorUtils.applyAlpha(IrisStyle.text, 0.2)
            Accessible.name: toggle.label
            Accessible.checkable: true
            Accessible.checked: toggle.checked
            onClicked: toggle.toggled()
            MaterialSymbol {
                anchors.centerIn: parent
                text: toggle.glyph
                fill: toggle.checked ? 1 : 0
                iconSize: Math.round(21 * root.d)
                // Text on the accent stays dark; saturated tints keep white.
                color: !toggle.checked ? IrisStyle.text : toggle.tint.hslLightness > 0.6 ? IrisStyle.onAccent : "#ffffff"
            }
        }
        IrisText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: Math.round(72 * root.d)
            text: toggle.label
            elide: Text.ElideRight
            color: IrisStyle.subtext
            font.pixelSize: 10.5 * IrisStyle.typeScale
            font.weight: Font.Medium
        }
    }

    // Square glyph tile; its name shows in the header while hovered instead of
    // under the glyph, to keep the grid compact. Lit tiles wear the accent (or
    // their own tint).
    component ShortcutTile: IrisButton {
        id: tile
        property string glyph: ""
        property string label: ""
        property bool lit: false
        property color tint: IrisStyle.accent
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(50 * root.d)
        buttonRadius: Math.round(16 * root.d)
        buttonRadiusPressed: buttonRadius
        colBackground: tile.lit ? tile.tint : root.blockColor
        colBackgroundHover: tile.lit ? ColorUtils.mix(tile.tint, IrisStyle.text, 0.85) : ColorUtils.applyAlpha(IrisStyle.text, 0.13)
        Accessible.name: tile.label
        MaterialSymbol {
            anchors.centerIn: parent
            text: tile.glyph
            fill: tile.lit ? 1 : 0
            iconSize: Math.round(21 * root.d)
            color: !tile.lit ? IrisStyle.text : tile.tint.hslLightness > 0.6 ? IrisStyle.onAccent : "#ffffff"
        }
        HoverHandler { onHoveredChanged: root.hint = hovered ? tile.label : (root.hint === tile.label ? "" : root.hint) }
    }

    // ── Header ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4 * root.d
        Layout.rightMargin: 2 * root.d
        spacing: 8 * root.d
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            IrisText {
                text: Translation.tr("Control Center")
                font.pixelSize: 16 * IrisStyle.typeScale
                font.weight: Font.DemiBold
            }
            IrisText {
                text: root.hint || DateTime.date
                role: IrisText.Meta
                color: root.hint ? IrisStyle.text : IrisStyle.subtext
                font.pixelSize: 11.5 * IrisStyle.typeScale
            }
        }
        IrisIconButton {
            materialIcon: "lock"
            Accessible.name: Translation.tr("Lock")
            onClicked: {
                GlobalStates.controlPanelOpen = false
                Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "lock", "activate"])
            }
        }
        IrisIconButton {
            materialIcon: "settings"
            Accessible.name: Translation.tr("Settings")
            onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.openSettings() }
        }
        IrisIconButton {
            materialIcon: "power_settings_new"
            Accessible.name: Translation.tr("Session")
            onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.sessionOpen = true }
        }
    }

    // ── Connectivity + Now playing ───────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10 * root.d

        Block {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: connectivity.implicitHeight + 24 * root.d
            GridLayout {
                id: connectivity
                anchors.centerIn: parent
                columns: 2
                columnSpacing: 14 * root.d
                rowSpacing: 8 * root.d
                RoundToggle {
                    glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                    label: Network.ethernet ? Translation.tr("Ethernet") : (Network.networkName || Translation.tr("Wi-Fi"))
                    checked: Network.ethernet || Network.wifiEnabled
                    onToggled: Network.toggleWifi()
                }
                RoundToggle {
                    glyph: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    label: BluetoothStatus.activeDeviceSummary() || Translation.tr("Bluetooth")
                    checked: BluetoothStatus.enabled
                    enabled: BluetoothStatus.available
                    onToggled: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
                }
                RoundToggle {
                    glyph: Notifications.manualDndActive ? "do_not_disturb_on" : "do_not_disturb_off"
                    label: Translation.tr("Focus")
                    checked: Notifications.manualDndActive
                    tint: "#5e5ce6"
                    onToggled: Notifications.toggleSilent()
                }
                RoundToggle {
                    glyph: Audio.micMuted ? "mic_off" : "mic"
                    label: Audio.micMuted ? Translation.tr("Muted") : Translation.tr("Mic")
                    checked: !Audio.micMuted
                    tint: IrisStyle.secondaryAccent
                    onToggled: Audio.toggleMicMute()
                }
            }
        }

        Block {
            id: nowPlaying
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            clip: true
            readonly property bool hasPlayer: MprisController.activePlayer !== null && MprisController.activePlayer !== undefined
            PlayerBase { id: media; player: MprisController.activePlayer; positionUpdatesActive: nowPlaying.visible }
            Loader {
                anchors.fill: parent
                active: nowPlaying.hasPlayer && (Config.options?.iris?.player?.artworkBackground ?? true)
                    && MediaArtwork.displaySource.length > 0
                sourceComponent: IrisMediaBackdrop { source: MediaArtwork.displaySource; radius: root.blockRadius }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * root.d
                spacing: 4 * root.d
                IrisArtwork {
                    Layout.preferredWidth: 40 * root.d
                    Layout.preferredHeight: 40 * root.d
                    source: MediaArtwork.displaySource
                    circular: Config.options?.iris?.player?.roundCover ?? true
                    radius: circular ? width / 2 : 10 * root.d
                }
                Item { Layout.fillHeight: true }
                IrisText {
                    Layout.fillWidth: true
                    text: nowPlaying.hasPlayer ? media.effectiveTitle : Translation.tr("Not playing")
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: nowPlaying.hasPlayer
                    text: media.effectiveArtist
                    color: ColorUtils.applyAlpha(IrisStyle.text, 0.6)
                    font.pixelSize: 11.5 * IrisStyle.typeScale
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: nowPlaying.hasPlayer
                    spacing: 0
                    Repeater {
                        model: [
                            { glyph: "fast_rewind", action: "previous" },
                            { glyph: media.effectiveIsPlaying ? "pause" : "play_arrow", action: "toggle" },
                            { glyph: "fast_forward", action: "next" }
                        ]
                        IrisButton {
                            id: transportButton
                            required property var modelData
                            Layout.fillWidth: true
                            quiet: true
                            implicitHeight: Math.round(30 * root.d)
                            buttonRadius: height / 2
                            Accessible.name: modelData.action
                            onClicked: modelData.action === "previous" ? media.previous()
                                : modelData.action === "next" ? media.next() : media.togglePlaying()
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: transportButton.modelData.glyph
                                fill: 1
                                iconSize: Math.round((transportButton.modelData.action === "toggle" ? 26 : 20) * root.d)
                                color: IrisStyle.text
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Toggles + levels ─────────────────────────────────────────────────
    // Compact like a phone's control center: a grid of glyph tiles beside
    // three tall levels (brightness, volume, microphone) of the same height.
    RowLayout {
        id: controlsRow
        Layout.fillWidth: true
        spacing: 10 * root.d
        readonly property real levelWidth: Math.round(46 * root.d)

        GridLayout {
            id: tileGrid
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8 * root.d
            columnSpacing: 8 * root.d
            ShortcutTile {
                glyph: "dark_mode"
                label: Translation.tr("Dark")
                lit: Appearance.m3colors.darkmode
                onClicked: Appearance.toggleDarkMode()
            }
            ShortcutTile {
                glyph: "nightlight"
                label: Translation.tr("Night light")
                lit: Hyprsunset.active
                onClicked: Hyprsunset.toggle()
            }
            ShortcutTile {
                glyph: "coffee"
                label: Translation.tr("Stay awake")
                lit: Idle.inhibit
                onClicked: Idle.toggleInhibit()
            }
            ShortcutTile {
                glyph: "screenshot_region"
                label: Translation.tr("Capture")
                onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.openRegionScreenshot() }
            }
            ShortcutTile {
                glyph: RecorderStatus.isRecording ? "stop_circle" : "radio_button_checked"
                label: RecorderStatus.isRecording ? Translation.tr("Stop recording") : Translation.tr("Record screen")
                lit: RecorderStatus.isRecording
                tint: IrisStyle.danger
                onClicked: {
                    const args = ["/usr/bin/bash", Directories.recordScriptPath]
                    args.push(...(RecorderStatus.isRecording ? ["--stop"] : ["--fullscreen", "--sound"]))
                    Quickshell.execDetached(args)
                    RecorderStatus.scheduleQuickCheck()
                    if (!RecorderStatus.isRecording) GlobalStates.controlPanelOpen = false
                }
            }
            ShortcutTile {
                glyph: /head|bluez|airpod|buds/i.test(String(Audio.defaultSink?.name ?? "") + String(Audio.defaultSink?.description ?? ""))
                    ? "headphones" : "speaker"
                label: Translation.tr("Sound devices")
                lit: root.picker !== ""
                onClicked: root.picker = root.picker === "" ? "devices" : ""
            }
        }

        IrisCapsuleSlider {
            vertical: true
            Layout.preferredWidth: controlsRow.levelWidth
            Layout.fillHeight: true
            enabled: root.monitor !== null
            icon: "light_mode"
            value: root.monitor?.brightness ?? 0
            Accessible.name: Translation.tr("Brightness")
            onMoved: next => root.monitor?.setBrightness(next)
        }
        IrisCapsuleSlider {
            vertical: true
            Layout.preferredWidth: controlsRow.levelWidth
            Layout.fillHeight: true
            muted: Audio.sink?.audio?.muted ?? false
            icon: muted ? "volume_off" : (Audio.value ?? 0) < 0.34 ? "volume_mute" : (Audio.value ?? 0) < 0.67 ? "volume_down" : "volume_up"
            value: Math.min(1, Audio.value ?? 0)
            Accessible.name: Translation.tr("Volume")
            onMoved: next => Audio.setSinkVolume(next)
            onIconClicked: Audio.toggleMute()
        }
        IrisCapsuleSlider {
            vertical: true
            visible: Audio.source !== null
            Layout.preferredWidth: controlsRow.levelWidth
            Layout.fillHeight: true
            muted: Audio.micMuted
            icon: muted ? "mic_off" : "mic"
            value: Math.min(1, Audio.micVolume ?? 0)
            Accessible.name: Translation.tr("Microphone")
            onMoved: next => Audio.setSourceVolume(next)
            onIconClicked: Audio.toggleMicMute()
        }
    }

    // Sound devices unfold in place, so the panel grows instead of stacking
    // another popup: outputs, then inputs.
    Block {
        Layout.fillWidth: true
        visible: implicitHeight > 1
        clip: true
        implicitHeight: root.picker !== "" ? deviceList.implicitHeight + 12 * root.d : 0
        Behavior on implicitHeight { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        ColumnLayout {
            id: deviceList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6 * root.d
            spacing: 2 * root.d
            Repeater {
                model: [
                    { input: false, title: Translation.tr("Output"), devices: Audio.outputDevices },
                    { input: true, title: Translation.tr("Input"), devices: Audio.inputDevices }
                ]
                ColumnLayout {
                    id: deviceGroup
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2 * root.d
                    IrisText {
                        Layout.leftMargin: 10 * root.d
                        Layout.topMargin: 4 * root.d
                        text: deviceGroup.modelData.title
                        role: IrisText.Meta
                        font.weight: Font.DemiBold
                    }
                    Repeater {
                        model: deviceGroup.modelData.devices
                        IrisButton {
                            id: deviceRow
                            required property var modelData
                            readonly property bool input: deviceGroup.modelData.input
                            readonly property bool current: (deviceRow.input ? Audio.source?.id : Audio.defaultSink?.id) === modelData.id
                            Layout.fillWidth: true
                            quiet: true
                            implicitHeight: Math.round(36 * root.d)
                            buttonRadius: Math.round(14 * root.d)
                            onClicked: {
                                if (deviceRow.input) Audio.setDefaultSource(deviceRow.modelData)
                                else Audio.setDefaultSink(deviceRow.modelData)
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10 * root.d
                                anchors.rightMargin: 10 * root.d
                                spacing: 10 * root.d
                                MaterialSymbol {
                                    text: deviceRow.input ? "mic"
                                        : /head|bluez|airpod|buds/i.test(String(deviceRow.modelData.name ?? "") + String(deviceRow.modelData.description ?? "")) ? "headphones" : "speaker"
                                    iconSize: Math.round(18 * root.d)
                                    color: deviceRow.current ? IrisStyle.accent : IrisStyle.subtext
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    text: Audio.friendlyDeviceName(deviceRow.modelData)
                                    elide: Text.ElideRight
                                    font.pixelSize: 12.5 * IrisStyle.typeScale
                                }
                                MaterialSymbol {
                                    visible: deviceRow.current
                                    text: "check"
                                    iconSize: Math.round(18 * root.d)
                                    color: IrisStyle.accent
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Notifications, grouped by app ────────────────────────────────────
    Block {
        Layout.fillWidth: true
        implicitHeight: notificationColumn.implicitHeight + 20 * root.d
        ColumnLayout {
            id: notificationColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10 * root.d
            anchors.leftMargin: 14 * root.d
            spacing: 6 * root.d
            RowLayout {
                Layout.fillWidth: true
                IrisText {
                    Layout.fillWidth: true
                    text: Notifications.list.length > 0
                        ? Translation.tr("Notifications") + "  ·  " + Notifications.list.length
                        : Translation.tr("Notifications")
                    font.pixelSize: 12.5 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                IrisButton {
                    visible: Notifications.list.length > 0
                    quiet: true
                    text: Translation.tr("Clear")
                    implicitHeight: Math.round(26 * root.d)
                    buttonRadius: height / 2
                    onClicked: Notifications.discardAllNotifications()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4 * root.d
                Layout.bottomMargin: 8 * root.d
                visible: Notifications.list.length === 0
                spacing: 8 * root.d
                MaterialSymbol { text: "notifications_none"; iconSize: Math.round(18 * root.d); color: IrisStyle.muted }
                IrisText { text: Translation.tr("You're all caught up"); role: IrisText.Meta }
            }
            Repeater {
                model: Notifications.appNameList.slice(0, 3)
                RowLayout {
                    id: groupRow
                    required property string modelData
                    readonly property var group: Notifications.groupsByAppName[modelData]
                    readonly property var latest: groupRow.group?.notifications?.[groupRow.group.notifications.length - 1]
                    Layout.fillWidth: true
                    spacing: 10 * root.d
                    IrisNotificationIcon {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 2 * root.d
                        size: Math.round(28 * root.d)
                        showImage: false
                        appName: groupRow.modelData
                        appIcon: String(groupRow.group?.appIcon ?? "")
                        summary: String(groupRow.latest?.summary ?? "")
                        critical: String(groupRow.latest?.urgency ?? "") === "critical"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        RowLayout {
                            Layout.fillWidth: true
                            IrisText {
                                Layout.fillWidth: true
                                text: groupRow.latest?.summary || groupRow.modelData
                                font.pixelSize: 12.5 * IrisStyle.typeScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                visible: (groupRow.group?.notifications?.length ?? 0) > 1
                                implicitWidth: countLabel.implicitWidth + 10 * root.d
                                implicitHeight: 16 * root.d
                                radius: height / 2
                                color: ColorUtils.applyAlpha(IrisStyle.text, 0.14)
                                IrisText {
                                    id: countLabel
                                    anchors.centerIn: parent
                                    text: groupRow.group?.notifications?.length ?? 0
                                    font.pixelSize: 10 * IrisStyle.typeScale
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: groupRow.latest?.body ?? ""
                            textFormat: Text.PlainText
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            role: IrisText.Meta
                        }
                    }
                    IrisIconButton {
                        Layout.alignment: Qt.AlignTop
                        materialIcon: "close"
                        iconSize: Math.round(15 * root.d)
                        implicitWidth: Math.round(26 * root.d)
                        Accessible.name: Translation.tr("Dismiss")
                        onClicked: (groupRow.group?.notifications ?? []).slice().forEach(n => Notifications.discardNotification(n.notificationId))
                    }
                }
            }
        }
    }
}
