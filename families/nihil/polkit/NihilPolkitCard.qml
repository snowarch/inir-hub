pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The screen dimmed and one block in its middle: a key on the signal's tile, what asks and why, the password typed as
// dots, Cancel and Allow. Escape cancels; a wrong password clears the field and keeps the block.
Item {
    id: root
    focus: true

    readonly property bool hidden: !(PolkitService.flow?.responseVisible ?? false)
    property real shown: 0
    Behavior on shown { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    Component.onCompleted: {
        root.shown = 1
        field.take()
    }

    function submit(): void {
        if (!PolkitService.interactionAvailable || field.text.length === 0) return
        PolkitService.submit(field.text)
    }

    Keys.onEscapePressed: PolkitService.cancel()

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged(): void {
            if (!PolkitService.interactionAvailable) return
            field.clear()
            field.take()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: NihilStyle.scrim
        opacity: root.shown
    }

    NRack {
        id: rack
        anchors.centerIn: parent
        width: Math.min(NihilStyle.s(420), parent.width - NihilStyle.s(40))
        height: body.implicitHeight
        opacity: root.shown
        scale: 0.96 + 0.04 * root.shown

        Column {
            id: body
            width: rack.width
            spacing: NihilStyle.seam

            Row {
                spacing: NihilStyle.seam
                NButton {
                    id: mark
                    width: NihilStyle.s(92); height: asks.height
                    square: true
                    interactive: false
                    lit: true
                    icon: PolkitService.batteryChargeLimitRequest ? "battery_charging_full" : "key"
                    iconSize: NihilStyle.s(38)
                }
                NTile {
                    id: asks
                    width: rack.width - mark.width - NihilStyle.seam
                    height: Math.max(NihilStyle.s(92), title.implicitHeight + NihilStyle.s(44))
                    paper: true
                    caption: Translation.tr("Permission")
                    NText {
                        id: title
                        x: asks.pad
                        y: NihilStyle.s(32)
                        width: asks.width - asks.pad * 2
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                        text: PolkitService.actionLabel !== Translation.tr("Authentication")
                            ? PolkitService.actionLabel : Translation.tr("Your password is needed")
                        font.pixelSize: NihilStyle.textLarge
                        font.weight: Font.Black
                        color: asks.ink
                    }
                }
            }
            NTile {
                id: why
                visible: PolkitService.cleanMessage.length > 0
                width: rack.width
                height: reason.implicitHeight + why.pad * 2
                NText {
                    id: reason
                    x: why.pad
                    y: why.pad
                    width: why.width - why.pad * 2
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    text: PolkitService.cleanMessage
                    font.pixelSize: NihilStyle.textSmall
                    color: why.inkSoft
                }
            }
            NField {
                id: field
                width: rack.width
                height: NihilStyle.s(56)
                glyph: "password"
                placeholder: PolkitService.cleanPrompt.length > 0 ? PolkitService.cleanPrompt : Translation.tr("Password")
                echoMode: root.hidden ? TextInput.Password : TextInput.Normal
                enabled: PolkitService.interactionAvailable
                onEntered: root.submit()
            }
            Row {
                spacing: NihilStyle.seam
                component Answer: NButton {
                    id: answer
                    property string word: ""
                    width: (rack.width - NihilStyle.seam) / 2
                    height: NihilStyle.s(56)
                    square: true
                    NText {
                        anchors.centerIn: parent
                        text: answer.word
                        font.pixelSize: NihilStyle.s(16)
                        font.weight: Font.Black
                        color: answer.ink
                    }
                }
                Answer {
                    word: Translation.tr("Cancel")
                    onClicked: PolkitService.cancel()
                }
                Answer {
                    word: Translation.tr("Allow")
                    paper: PolkitService.interactionAvailable
                    interactive: PolkitService.interactionAvailable
                    onClicked: root.submit()
                }
            }
        }
    }
}
