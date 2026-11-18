pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// What plays and what listens: a level and a mute key for each, and the devices to choose from.
Column {
    id: root

    component Side: Column {
        id: side
        required property string title
        required property string glyph
        required property string mutedGlyph
        required property var node
        required property real volume
        required property bool muted
        required property var devices
        property real ceiling: 1
        signal muteAsked()
        signal volumeAsked(real value)
        signal deviceAsked(var node)

        width: root.width
        spacing: NihilStyle.s(10)

        NText {
            figures: true
            text: side.title.toUpperCase()
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        NEmpty {
            visible: !side.node
            width: parent.width
            glyph: side.mutedGlyph
            title: Translation.tr("No device found")
            line: Translation.tr("Plug one in and it shows up here.")
        }
        Row {
            visible: !!side.node
            width: parent.width
            spacing: NihilStyle.s(12)
            NButton {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(42)
                height: NihilStyle.s(42)
                tone: NihilStyle.pieceRaised
                lit: side.muted
                icon: side.muted ? side.mutedGlyph : side.glyph
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Mute")
                onClicked: side.muteAsked()
            }
            NSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - NihilStyle.s(120)
                to: side.ceiling
                stepSize: 0.01
                value: side.volume
                name: side.title
                onMoved: value => side.volumeAsked(value)
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(42)
                horizontalAlignment: Text.AlignRight
                figures: true
                text: Math.round(side.volume * 100) + "%"
                font.pixelSize: NihilStyle.textSmall
            }
        }
        NChips {
            visible: side.devices.length > 1
            width: parent.width
            options: side.devices.map(device => ({ value: device, label: Audio.friendlyDeviceName(device) }))
            current: side.node
            onPicked: value => side.deviceAsked(value)
        }
    }

    spacing: NihilStyle.s(20)

    Side {
        title: Translation.tr("Output")
        glyph: "volume_up"
        mutedGlyph: "volume_off"
        node: Audio.sink
        volume: Audio.value
        muted: Audio.sink?.audio?.muted ?? false
        devices: Audio.outputDevices
        ceiling: Audio.ceiling
        onMuteAsked: Audio.toggleMute()
        onVolumeAsked: value => Audio.setSinkVolume(value)
        onDeviceAsked: node => Audio.setDefaultSink(node)
    }
    Side {
        title: Translation.tr("Input")
        glyph: "mic"
        mutedGlyph: "mic_off"
        node: Audio.source
        volume: Audio.micVolume
        muted: Audio.micMuted
        devices: Audio.inputDevices
        onMuteAsked: Audio.toggleMicMute()
        onVolumeAsked: value => Audio.setSourceVolume(value)
        onDeviceAsked: node => Audio.setDefaultSource(node)
    }
}
