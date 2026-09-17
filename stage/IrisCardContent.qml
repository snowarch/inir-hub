pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar
import qs.modules.iris.sidebar

Item {
    id: root

    property string kind: ""
    property bool contentActive: true
    readonly property real d: IrisStyle.density
    readonly property bool bleeds: root.kind === "weather" || root.kind === "notifications"
        || root.kind === "media"
    readonly property real contentHeight: body.item?.implicitHeight ?? 0
    readonly property color light: {
        switch (root.kind) {
        case "weather": return IrisStyle.skyLight(Icons.getWeatherIcon(Weather.data.wCode, Weather.isNightNow()) ?? "")
        case "sound": return IrisStyle.identity.indigo
        case "mic": return IrisStyle.identity.orange
        case "tools": return IrisStyle.secondaryAccent
        case "tray": return IrisStyle.identity.teal
        case "media": return "transparent"
        default: return IrisStyle.wallpaperLight
        }
    }
    signal navigate()
    function close(): void { root.navigate() }

    implicitHeight: root.contentHeight

    Loader {
        id: body
        width: root.width
        active: root.kind.length > 0
        sourceComponent: {
            switch (root.kind) {
            case "weather": return weatherCard
            case "notifications": return notificationsCard
            case "sound": return soundCard
            case "mic": return micCard
            case "tools": return toolsCard
            case "tray": return trayCard
            case "media": return mediaCard
            default: return null
            }
        }
    }

    component SectionCard: IrisSidebarSection {
        bare: true
        expanded: true
        contentActive: root.contentActive
        onNavigate: root.close()
    }

    component CardHeader: RowLayout {
        id: header
        property string glyph: ""
        property string title: ""
        property string detail: ""
        property color tint: IrisStyle.accent
        default property alias actions: actionRow.data
        Layout.fillWidth: true
        spacing: 8 * root.d
        Rectangle {
            implicitWidth: Math.round(24 * root.d)
            implicitHeight: implicitWidth
            radius: IrisStyle.iconRadius(width)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(header.tint, 1.2) }
                GradientStop { position: 1; color: header.tint }
            }
            MaterialSymbol { anchors.centerIn: parent; text: header.glyph; fill: 1; iconSize: Math.round(15 * root.d); color: IrisStyle.onTint }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            IrisText {
                Layout.fillWidth: true
                text: header.title
                font.weight: Font.DemiBold
                font.pixelSize: 14 * IrisStyle.typeScale
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: header.detail
                role: IrisText.Meta
                elide: Text.ElideRight
            }
        }
        RowLayout { id: actionRow; spacing: 0 }
    }

    readonly property var cardOptions: Config.options?.iris?.appearance?.surfaces?.cards ?? ({})
    component LevelCard: ColumnLayout {
        id: level
        property bool input: false
        readonly property bool muted: level.input ? Audio.micMuted : (Audio.sink?.audio?.muted ?? false)
        readonly property real value: Math.min(1, (level.input ? Audio.micVolume : Audio.value) ?? 0)
        spacing: 12 * root.d
        CardHeader {
            visible: root.cardOptions?.header ?? true
            glyph: level.input ? "mic" : "volume_up"
            tint: level.input ? IrisStyle.identity.orange : IrisStyle.identity.indigo
            title: level.input ? Translation.tr("Microphone") : Translation.tr("Sound")
            detail: Audio.friendlyDeviceName(level.input ? Audio.source : Audio.defaultSink)
            IrisNumber {
                text: Math.round(level.value * 100) + "%"
                color: IrisStyle.subtext
                pixelSize: 13 * IrisStyle.typeScale
                weight: Font.DemiBold
            }
        }
        IrisCapsuleSlider {
            Layout.fillWidth: true
            implicitHeight: Math.round(48 * root.d)
            muted: level.muted
            icon: level.input ? (level.muted ? "mic_off" : "mic")
                : level.muted ? "volume_off" : level.value < 0.34 ? "volume_mute" : level.value < 0.67 ? "volume_down" : "volume_up"
            value: level.value
            Accessible.name: level.input ? Translation.tr("Microphone") : Translation.tr("Volume")
            onMoved: next => level.input ? Audio.setSourceVolume(next) : Audio.setSinkVolume(next)
            onIconClicked: level.input ? Audio.toggleMicMute() : Audio.toggleMute()
        }
        IrisDeviceList {
            visible: root.cardOptions?.devices ?? true
            Layout.fillWidth: true
            Layout.leftMargin: -6 * root.d
            Layout.rightMargin: -6 * root.d
            outputs: !level.input
            inputs: level.input
        }
    }

    Component {
        id: weatherCard
        SectionCard { kind: "weather" }
    }
    Component {
        id: notificationsCard
        SectionCard { kind: "notifications" }
    }
    Component {
        id: soundCard
        ColumnLayout {
            spacing: 6 * root.d
            LevelCard { Layout.fillWidth: true }
            SectionCard {
                visible: root.cardOptions?.mixer ?? true
                Layout.fillWidth: true
                Layout.leftMargin: -14 * root.d
                Layout.rightMargin: -14 * root.d
                kind: "mixer"
            }
        }
    }
    Component {
        id: micCard
        LevelCard { input: true }
    }
    Component {
        id: toolsCard
        ColumnLayout {
            spacing: 14 * root.d
            CardHeader {
                glyph: "timer"
                tint: IrisStyle.identity.orange
                title: Translation.tr("Timers")
                detail: TimerService.countdownRunning || TimerService.pomodoroRunning || TimerService.stopwatchRunning
                    ? Translation.tr("Running") : Translation.tr("Tap a dial to start, scroll to adjust")
            }
            IrisTools {
                Layout.fillWidth: true
                onActivityRequested: { root.close(); GlobalStates.irisIslandPageRequest = "activity" }
            }
        }
    }
    Component {
        id: trayCard
        ColumnLayout {
            id: tray
            readonly property var items: SystemTray.items.values.filter(item => item && item.id
                && (!(Config.options?.iris?.tray?.hidePassive ?? false) || item.status !== Status.Passive))
            spacing: 12 * root.d
            CardHeader {
                glyph: "apps"
                tint: IrisStyle.identity.teal
                title: Translation.tr("Tray")
                detail: tray.items.length > 0 ? Translation.tr("%1 background apps").arg(tray.items.length) : Translation.tr("Background apps")
            }
            IrisTray { Layout.fillWidth: true; showHeader: false; items: tray.items }
        }
    }

    Component {
        id: mediaCard
        Item {
            id: player
            ColorQuantizer {
                id: tintQuantizer
                source: MediaArtwork.displaySource
                depth: 2
                rescaleSize: 48
            }
            readonly property color tint: {
                const colors = tintQuantizer.colors ?? []
                let best = null
                let bestScore = -1
                for (let i = 0; i < colors.length; i++) {
                    const c = colors[i]
                    const score = Math.max(0, c.hslSaturation) * (1 - Math.abs(c.hslLightness - 0.5))
                    if (score > bestScore) { bestScore = score; best = c }
                }
                if (!best || best.hslSaturation < 0.14 || best.hslHue < 0) return IrisStyle.text
                return Qt.hsla(best.hslHue, Math.max(0.5, best.hslSaturation),
                    Math.max(0.64, Math.min(0.76, best.hslLightness + 0.22)), 1)
            }
            implicitHeight: card.implicitHeight
            Loader {
                anchors.fill: parent
                active: (Config.options?.iris?.player?.artworkBackground ?? true)
                    && MediaArtwork.displaySource.length > 0
                sourceComponent: Item {
                    IrisMediaBackdrop { anchors.fill: parent; source: MediaArtwork.displaySource; strength: 0.9 }
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: IrisStyle.tintFill(player.tint) }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }
                }
            }
            IrisMediaCard {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                showBackground: false
                active: root.contentActive
                tint: player.tint
            }
        }
    }
}
