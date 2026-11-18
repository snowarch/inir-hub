pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The power menu (the shell's session key): one piece at the screen's left over the bar. A raised head says goodbye
// with the name in lit dots; under it the lit power disc and the restart disc, then the lock key beside sleep and
// sign out.
NPopup {
    id: root

    open: NihilState.powerOpen
    namespace: "nihil:power"
    onDismissed: GlobalStates.sessionOpen = false

    readonly property real c: NihilStyle.cell
    readonly property real g: NihilStyle.cellGap
    readonly property string name: {
        const own = Config.options?.nihil?.power?.greeting ?? ""
        return (own.length > 0 ? own : SystemInfo.username).toUpperCase()
    }

    function act(what: string): void {
        GlobalStates.sessionOpen = false
        if (what === "poweroff") Session.poweroff()
        else if (what === "reboot") Session.reboot()
        else if (what === "lock") Session.lock()
        else if (what === "suspend") Session.suspend()
        else if (what === "logout") Session.logout()
    }

    NCard {
        id: card
        width: NihilStyle.cells(4) + NihilStyle.panelPad * 2
        height: head.height + NihilStyle.cells(2) * 2 + root.g * 2 + NihilStyle.panelPad
        x: NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        Rectangle {
            id: head
            x: -card.pad
            y: -card.pad
            width: card.width
            height: NihilStyle.s(104)
            radius: card.radius
            color: NihilStyle.pieceRaised
            Column {
                anchors.centerIn: parent
                spacing: NihilStyle.s(14)
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    figures: true
                    font.bold: true
                    font.letterSpacing: NihilStyle.s(1)
                    text: Translation.tr("Goodbye,").toUpperCase()
                    font.pixelSize: NihilStyle.textSmall
                }
                DotText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.name
                    color: NihilStyle.accent
                    dot: NihilStyle.s(4)
                    spacing: NihilStyle.s(1)
                    fitWidth: head.width - NihilStyle.s(36)
                }
            }
        }

        Grid {
            y: head.height - card.pad + root.g
            columns: 2
            spacing: root.g

            NButton {
                width: NihilStyle.cells(2); height: width
                lit: true
                icon: "power_settings_new"
                iconSize: NihilStyle.s(36)
                onClicked: root.act("poweroff")
            }
            NButton {
                width: NihilStyle.cells(2); height: width
                tone: NihilStyle.pieceRaised
                icon: "restart_alt"
                iconSize: NihilStyle.s(36)
                onClicked: root.act("reboot")
            }
            NButton {
                width: NihilStyle.cells(2); height: width
                square: true
                radius: NihilStyle.s(18)
                tone: NihilStyle.pieceRaised
                icon: "lock"
                iconSize: NihilStyle.s(36)
                onClicked: root.act("lock")
            }
            Column {
                spacing: root.g
                NButton {
                    width: NihilStyle.cells(2); height: (NihilStyle.cells(2) - root.g) / 2
                    tone: NihilStyle.pieceRaised
                    icon: "bedtime"
                    iconSize: NihilStyle.s(22)
                    onClicked: root.act("suspend")
                }
                NButton {
                    width: NihilStyle.cells(2); height: (NihilStyle.cells(2) - root.g) / 2
                    tone: NihilStyle.pieceRaised
                    icon: "logout"
                    iconSize: NihilStyle.s(22)
                    onClicked: root.act("logout")
                }
            }
        }
    }
}
