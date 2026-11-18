pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The screen dimmed and one piece in its middle: a key in the signal, what asks and why, the password typed as dots,
// Cancel and Allow. Escape cancels; a wrong password clears the field and keeps the piece.
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

    NCard {
        anchors.centerIn: parent
        width: Math.min(NihilStyle.s(380), parent.width - NihilStyle.s(40))
        height: body.implicitHeight + pad * 2
        pad: NihilStyle.s(22)
        opacity: root.shown
        scale: 0.96 + 0.04 * root.shown

        Column {
            id: body
            width: parent.width
            spacing: NihilStyle.s(14)

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: NihilStyle.s(56)
                height: width
                radius: width / 2
                color: NihilStyle.accent
                NIcon {
                    anchors.centerIn: parent
                    text: PolkitService.batteryChargeLimitRequest ? "battery_charging_full" : "key"
                    size: NihilStyle.s(26)
                    color: NihilStyle.onAccent
                }
            }
            NText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: PolkitService.actionLabel !== Translation.tr("Authentication")
                    ? PolkitService.actionLabel : Translation.tr("Your password is needed")
                font.pixelSize: NihilStyle.textLarge
                font.weight: Font.DemiBold
            }
            NText {
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                text: PolkitService.cleanMessage
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            NField {
                id: field
                width: parent.width
                height: NihilStyle.s(46)
                glyph: "password"
                placeholder: PolkitService.cleanPrompt.length > 0 ? PolkitService.cleanPrompt : Translation.tr("Password")
                echoMode: root.hidden ? TextInput.Password : TextInput.Normal
                enabled: PolkitService.interactionAvailable
                onEntered: root.submit()
            }
            Row {
                width: parent.width
                spacing: NihilStyle.cellGap
                NKey {
                    width: (parent.width - parent.spacing) / 2
                    height: NihilStyle.s(46)
                    label: Translation.tr("Cancel")
                    onClicked: PolkitService.cancel()
                }
                NKey {
                    width: (parent.width - parent.spacing) / 2
                    height: NihilStyle.s(46)
                    lit: true
                    label: Translation.tr("Allow")
                    enabled: PolkitService.interactionAvailable
                    opacity: enabled ? 1 : 0.5
                    onClicked: root.submit()
                }
            }
        }
    }
}
