pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The screen dimmed and one pane of glass in its middle: what asks, why, the password, Cancel and Allow. Escape cancels;
// a wrong password clears the field and keeps the pane.
Item {
    id: root

    focus: true

    readonly property alias glassRegion: pane.region
    readonly property bool hidden: !(PolkitService.flow?.responseVisible ?? false)
    readonly property string title: PolkitService.actionLabel !== Translation.tr("Authentication")
        ? PolkitService.actionLabel : Translation.tr("Your password is needed")

    property real shown: 0
    Behavior on shown { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

    Component.onCompleted: {
        root.shown = 1
        field.take()
    }

    function submit(): void {
        if (PolkitService.interactionAvailable && field.text.length > 0)
            PolkitService.submit(field.text)
    }

    Keys.onEscapePressed: PolkitService.cancel()

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged(): void {
            if (!PolkitService.interactionAvailable)
                return
            field.clear()
            field.take()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: NihilStyle.scrim
        opacity: root.shown
    }

    NGlass {
        id: pane
        anchors.centerIn: parent
        width: Math.min(NihilStyle.s(420), parent.width - NihilStyle.s(40))
        height: body.implicitHeight + NihilStyle.s(56)
        radius: NihilStyle.radiusWindow
        tint: NihilStyle.menuBackground
        opacity: root.shown
        scale: 0.96 + 0.04 * root.shown

        Column {
            id: body
            anchors.centerIn: parent
            width: pane.width - NihilStyle.s(56)
            spacing: NihilStyle.s(18)

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: PolkitService.batteryChargeLimitRequest ? "battery_charging_full" : "key"
                size: NihilStyle.s(34)
                color: NihilStyle.accent
            }
            NText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.title
                font.pixelSize: NihilStyle.textTitle
                color: NihilStyle.text
            }
            NText {
                width: parent.width
                visible: PolkitService.cleanMessage.length > 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                text: PolkitService.cleanMessage
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.textSecondary
            }
            NField {
                id: field
                width: parent.width
                glyph: "password"
                placeholder: PolkitService.cleanPrompt.length > 0 ? PolkitService.cleanPrompt : Translation.tr("Password")
                echoMode: root.hidden ? TextInput.Password : TextInput.Normal
                enabled: PolkitService.interactionAvailable
                onEntered: root.submit()
            }
            Row {
                anchors.right: parent.right
                spacing: NihilStyle.spacing

                NButton {
                    label: Translation.tr("Cancel")
                    onClicked: PolkitService.cancel()
                }
                NButton {
                    label: Translation.tr("Allow")
                    highlighted: true
                    enabled: PolkitService.interactionAvailable
                    onClicked: root.submit()
                }
            }
        }
    }
}
