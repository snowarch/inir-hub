pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A page's lead (his 11-19: "cada página tratada por lo que es"): what the page is, before its groups. The thing itself
// where it has one (Sound's mixer, the charge), then the page's own switches people flip most as tiles, each said once
// here (PrismPanel takes their rows out of the groups). PrismModel.leads says what each page leads with.
Column {
    id: root
    property string page: ""
    readonly property var lead: PrismModel.leads[root.page] ?? ({})
    readonly property string live: String(root.lead.live ?? "")
    readonly property var tiles: {
        const _ = PrismModel.revision
        return Array.from(root.lead.tiles ?? []).map(([path, glyph]) => {
            if (path.startsWith("live:")) {
                const live = IrisOptions.dailySwitches.find(entry => entry.id === path.slice(5))
                return live ? { key: path, glyph: glyph, live: live, label: live.label } : null
            }
            const row = PrismModel.find(path)
            return row && PrismModel.shown(row) ? { key: path, glyph: glyph, row: row, label: row.label } : null
        }).filter(tile => tile !== null)
    }
    spacing: PrismTheme.dp(14)

    Loader {
        width: root.width
        // A machine with no battery shows no charge.
        active: root.live.length > 0 && (root.live !== "battery" || Battery.available)
        visible: active
        sourceComponent: ({ sound: soundLive, battery: batteryLive })[root.live] ?? null
    }

    Rectangle {
        visible: root.tiles.length > 0
        width: root.width
        height: grid.implicitHeight + 2 * PrismTheme.dp(14)
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
        Flow {
            id: grid
            x: PrismTheme.dp(14)
            y: PrismTheme.dp(14)
            width: parent.width - 2 * PrismTheme.dp(14)
            spacing: PrismTheme.dp(8)
            readonly property int columns: Math.max(1, Math.min(root.tiles.length, Math.floor((width + spacing) / (PrismTheme.dp(196) + spacing))))
            readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)
            // Every tile as tall as the tallest, so a two-line name never leaves a ragged row.
            property real rowHeight: PrismTheme.dp(56)
            function measure(): void {
                let tallest = PrismTheme.dp(56)
                for (const child of grid.children) if (child.need !== undefined) tallest = Math.max(tallest, child.need)
                grid.rowHeight = tallest
            }
            Repeater {
                model: ScriptModel { objectProp: "key"; values: root.tiles }
                delegate: PrismTile {
                    id: tile
                    required property var modelData
                    readonly property var value: { const _ = PrismModel.revision; return tile.modelData.live ? tile.modelData.live.state() : PrismModel.read(tile.modelData.row) }
                    readonly property bool flips: Boolean(tile.modelData.live) || String(tile.modelData.row?.kind) === "switch"
                    width: grid.tileWidth
                    height: grid.rowHeight
                    onNeedChanged: grid.measure()
                    Component.onCompleted: grid.measure()
                    on: tile.flips && Boolean(tile.value)
                    isSwitch: tile.flips
                    glyph: tile.modelData.glyph
                    label: Translation.tr(tile.modelData.label)
                    says: tile.modelData.live ? (tile.value ? Translation.tr("On") : Translation.tr("Off")) : PrismModel.sayNow(tile.modelData.row)
                    onClicked: {
                        if (tile.modelData.live) tile.modelData.live.set(!tile.value)
                        else if (tile.flips) PrismModel.write(tile.modelData.row, !Boolean(tile.value))
                    }
                }
            }
        }
    }

    // ── Sound: the mixer. Where it plays and how loud, the microphone, and every app playing now.
    component DeviceCard: Rectangle {
        id: card
        property bool isSink: true
        readonly property var node: card.isSink ? Audio.sink : Audio.source
        readonly property var devices: card.isSink ? Audio.outputDevices : Audio.inputDevices
        readonly property bool muted: card.isSink ? Boolean(Audio.sink?.audio?.muted) : Audio.micMuted
        readonly property real level: card.isSink ? Audio.value : Audio.micVolume
        radius: PrismTheme.cardRadius
        color: PrismTheme.card
        implicitHeight: body.implicitHeight + 2 * PrismTheme.dp(20)
        Column {
            id: body
            x: PrismTheme.dp(20)
            y: PrismTheme.dp(20)
            width: card.width - 2 * PrismTheme.dp(20)
            spacing: PrismTheme.dp(12)
            Column {
                width: parent.width
                spacing: PrismTheme.dp(2)
                PrismText {
                    width: parent.width
                    text: Translation.tr(card.isSink ? "Output" : "Input")
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                PrismText {
                    width: parent.width
                    text: card.node ? Audio.friendlyDeviceName(card.node)
                        : Translation.tr(card.isSink ? "No speakers or headphones found." : "No microphone found.")
                    color: card.node ? PrismTheme.ink : PrismTheme.ink2
                    font.pixelSize: card.node ? PrismTheme.head : PrismTheme.body
                    font.weight: card.node ? Font.DemiBold : Font.Normal
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
            }
            Row {
                visible: card.node !== null && card.node !== undefined
                width: parent.width
                spacing: PrismTheme.dp(10)
                PrismRound {
                    id: mute
                    anchors.verticalCenter: parent.verticalCenter
                    lit: card.muted
                    glyph: card.isSink ? (card.muted ? "volume_off" : "volume_up") : (card.muted ? "mic_off" : "mic")
                    Accessible.name: Translation.tr("Mute")
                    onClicked: card.isSink ? Audio.toggleMute() : Audio.toggleMicMute()
                }
                PrismSlider {
                    id: level
                    width: parent.width - mute.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 100
                    value: Math.round(card.level * 100)
                    label: Math.round(level.live) + "%"
                    Accessible.name: Translation.tr("Volume")
                    function apply(value: real): void {
                        if (card.isSink) { Audio.lastUserChange = Date.now(); if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                        else Audio.setSourceVolume(value / 100)
                    }
                    onMoved: value => level.apply(value)
                    onCommitted: value => level.apply(value)
                }
            }
            // Where else it can play: one press moves the sound there.
            Flow {
                visible: card.devices.length > 1
                width: parent.width
                spacing: PrismTheme.dp(6)
                Repeater {
                    model: card.devices
                    delegate: PrismPill {
                        required property var modelData
                        readonly property bool chosen: modelData === (card.isSink ? Audio.defaultSink : Audio.source)
                        tone: chosen ? "solid" : "quiet"
                        text: Audio.friendlyDeviceName(modelData)
                        onClicked: card.isSink ? Audio.setDefaultSink(modelData) : Audio.setDefaultSource(modelData)
                    }
                }
            }
        }
    }
    Component {
        id: soundLive
        Column {
            id: mixer
            readonly property bool two: mixer.width >= PrismTheme.dp(640)
            readonly property real cell: mixer.two ? Math.floor((mixer.width - PrismTheme.dp(14)) / 2) : mixer.width
            spacing: PrismTheme.dp(14)
            Grid {
                columns: mixer.two ? 2 : 1
                spacing: PrismTheme.dp(14)
                DeviceCard {
                    id: out
                    isSink: true
                    width: mixer.cell
                    height: mixer.two ? Math.max(out.implicitHeight, mic.implicitHeight) : out.implicitHeight
                }
                DeviceCard {
                    id: mic
                    isSink: false
                    width: mixer.cell
                    height: mixer.two ? Math.max(out.implicitHeight, mic.implicitHeight) : mic.implicitHeight
                }
            }
            Rectangle {
                visible: Audio.outputAppNodes.length > 0
                width: mixer.width
                height: apps.implicitHeight + 2 * PrismTheme.dp(20)
                radius: PrismTheme.cardRadius
                color: PrismTheme.card
                Column {
                    id: apps
                    x: PrismTheme.dp(20)
                    y: PrismTheme.dp(20)
                    width: parent.width - 2 * PrismTheme.dp(20)
                    spacing: PrismTheme.dp(8)
                    PrismText {
                        text: Translation.tr("Apps playing")
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                    Repeater {
                        model: Audio.outputAppNodes
                        delegate: Item {
                            id: app
                            required property var modelData
                            width: apps.width
                            height: PrismTheme.dp(40)
                            PrismText {
                                width: Math.round(parent.width * 0.3)
                                anchors.verticalCenter: parent.verticalCenter
                                text: Audio.appNodeDisplayName(app.modelData)
                                font.pixelSize: PrismTheme.row
                                font.weight: Font.Medium
                            }
                            PrismSlider {
                                id: appLevel
                                x: Math.round(parent.width * 0.32)
                                width: parent.width - x
                                anchors.verticalCenter: parent.verticalCenter
                                from: 0
                                to: 100
                                value: Math.round(Number(app.modelData?.audio?.volume ?? 0) * 100)
                                label: Math.round(appLevel.live) + "%"
                                Accessible.name: Audio.appNodeDisplayName(app.modelData)
                                onMoved: value => { if (app.modelData?.audio) app.modelData.audio.volume = value / 100 }
                                onCommitted: value => { if (app.modelData?.audio) app.modelData.audio.volume = value / 100 }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Battery: the charge itself, large, its state, and the bar it fills (the charge limit marked on it).
    Component {
        id: batteryLive
        Rectangle {
            id: charge
            readonly property real share: Math.max(0, Math.min(1, Battery.percentage))
            implicitHeight: PrismTheme.dp(168)
            radius: PrismTheme.cardRadius
            color: PrismTheme.card
            PrismText {
                id: big
                x: PrismTheme.dp(24)
                y: PrismTheme.dp(14)
                text: Math.round(charge.share * 100) + "%"
                figures: true
                font.pixelSize: PrismTheme.dp(68)
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.dp(68) * 0.03
            }
            PrismText {
                anchors.left: big.right
                anchors.leftMargin: PrismTheme.dp(14)
                anchors.baseline: big.baseline
                width: charge.width - x - PrismTheme.dp(24)
                text: Battery.isCharging ? Translation.tr("Charging") : Battery.onBattery ? Translation.tr("On battery") : Translation.tr("Plugged in")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.row
                font.weight: Font.Medium
            }
            Rectangle {
                x: PrismTheme.dp(24)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: PrismTheme.dp(26)
                width: charge.width - 2 * PrismTheme.dp(24)
                height: PrismTheme.dp(14)
                radius: height / 2
                color: PrismTheme.track
                Rectangle {
                    width: Math.max(parent.height, parent.width * charge.share)
                    height: parent.height
                    radius: height / 2
                    color: Battery.isLowAndNotCharging ? PrismTheme.tint("red") : PrismTheme.accent
                }
                // Where charging stops when the limit is on.
                Rectangle {
                    visible: Battery.chargeLimitEnabled
                    x: Math.round(parent.width * Battery.chargeLimitThreshold / 100) - 1
                    y: -PrismTheme.dp(5)
                    width: PrismTheme.dp(2)
                    height: parent.height + PrismTheme.dp(10)
                    radius: 1
                    color: PrismTheme.ink
                }
            }
        }
    }
}
