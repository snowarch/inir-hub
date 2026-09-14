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
    property bool outputsOpen: false
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
                color: toggle.checked ? "#ffffff" : IrisStyle.text
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

    component ShortcutTile: IrisButton {
        id: tile
        property string glyph: ""
        property string label: ""
        property bool lit: false
        Layout.fillWidth: true
        implicitHeight: Math.round(62 * root.d)
        buttonRadius: Math.round(18 * root.d)
        buttonRadiusPressed: buttonRadius
        colBackground: tile.lit ? IrisStyle.text : root.blockColor
        colBackgroundHover: tile.lit ? ColorUtils.applyAlpha(IrisStyle.text, 0.88) : ColorUtils.applyAlpha(IrisStyle.text, 0.13)
        Accessible.name: tile.label
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 3 * root.d
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: tile.glyph
                fill: tile.lit ? 1 : 0
                iconSize: Math.round(21 * root.d)
                color: tile.lit ? IrisStyle.surface : IrisStyle.text
            }
            IrisText {
                Layout.alignment: Qt.AlignHCenter
                text: tile.label
                color: tile.lit ? IrisStyle.surface : IrisStyle.subtext
                font.pixelSize: 10 * IrisStyle.typeScale
                font.weight: Font.Medium
            }
        }
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
                text: DateTime.date
                role: IrisText.Meta
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

    // ── Levels ───────────────────────────────────────────────────────────
    IrisCapsuleSlider {
        Layout.fillWidth: true
        enabled: root.monitor !== null
        icon: "light_mode"
        value: root.monitor?.brightness ?? 0
        onMoved: next => root.monitor?.setBrightness(next)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8 * root.d
        IrisCapsuleSlider {
            Layout.fillWidth: true
            muted: Audio.sink?.audio?.muted ?? false
            icon: muted ? "volume_off" : (Audio.value ?? 0) < 0.34 ? "volume_mute" : (Audio.value ?? 0) < 0.67 ? "volume_down" : "volume_up"
            value: Math.min(1, Audio.value ?? 0)
            onMoved: next => Audio.setSinkVolume(next)
            onIconClicked: Audio.toggleMute()
        }
        IrisButton {
            implicitWidth: Math.round(44 * root.d)
            implicitHeight: implicitWidth
            buttonRadius: height / 2
            buttonRadiusPressed: height / 2
            selected: root.outputsOpen
            colBackground: root.blockColor
            colBackgroundToggled: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
            Accessible.name: Translation.tr("Sound output")
            onClicked: root.outputsOpen = !root.outputsOpen
            MaterialSymbol {
                anchors.centerIn: parent
                text: /head|bluez|airpod|buds/i.test(String(Audio.defaultSink?.name ?? "") + String(Audio.defaultSink?.description ?? ""))
                    ? "headphones" : "speaker"
                iconSize: Math.round(20 * root.d)
                color: IrisStyle.text
            }
        }
    }

    // Output picker unfolds in place, so the panel grows instead of stacking
    // another popup.
    Block {
        Layout.fillWidth: true
        visible: implicitHeight > 1
        clip: true
        implicitHeight: root.outputsOpen ? outputList.implicitHeight + 12 * root.d : 0
        Behavior on implicitHeight { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        ColumnLayout {
            id: outputList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6 * root.d
            spacing: 2 * root.d
            Repeater {
                model: Audio.outputDevices
                IrisButton {
                    id: outputRow
                    required property var modelData
                    readonly property bool current: Audio.defaultSink?.id === modelData.id
                    Layout.fillWidth: true
                    quiet: true
                    implicitHeight: Math.round(38 * root.d)
                    buttonRadius: Math.round(14 * root.d)
                    onClicked: { Audio.setDefaultSink(outputRow.modelData); root.outputsOpen = false }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10 * root.d
                        anchors.rightMargin: 10 * root.d
                        spacing: 10 * root.d
                        MaterialSymbol {
                            text: /head|bluez|airpod|buds/i.test(String(outputRow.modelData.name ?? "") + String(outputRow.modelData.description ?? "")) ? "headphones" : "speaker"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.subtext
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(outputRow.modelData)
                            elide: Text.ElideRight
                            font.pixelSize: 12.5 * IrisStyle.typeScale
                        }
                        MaterialSymbol {
                            visible: outputRow.current
                            text: "check"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.accent
                        }
                    }
                }
            }
        }
    }

    // ── Quick toggles ────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8 * root.d
        ShortcutTile {
            glyph: "dark_mode"
            label: Translation.tr("Dark")
            lit: Appearance.m3colors.darkmode
            onClicked: Appearance.toggleDarkMode()
        }
        ShortcutTile {
            glyph: "nightlight"
            label: Translation.tr("Night")
            lit: Hyprsunset.active
            onClicked: Hyprsunset.toggle()
        }
        ShortcutTile {
            glyph: "coffee"
            label: Translation.tr("Awake")
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
            label: RecorderStatus.isRecording ? Translation.tr("Stop") : Translation.tr("Record")
            lit: RecorderStatus.isRecording
            onClicked: {
                const args = ["/usr/bin/bash", Directories.recordScriptPath]
                args.push(...(RecorderStatus.isRecording ? ["--stop"] : ["--fullscreen", "--sound"]))
                Quickshell.execDetached(args)
                RecorderStatus.scheduleQuickCheck()
                if (!RecorderStatus.isRecording) GlobalStates.controlPanelOpen = false
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
                    SmartAppIcon {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 2 * root.d
                        icon: groupRow.group?.appIcon || groupRow.modelData
                        fallback: "dialog-information"
                        iconSize: Math.round(28 * root.d)
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
