pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The power menu (the shell's session key): one block over the Start key. The name on paper says goodbye; shutting down
// is the signal's tile, restarting beside it, and the three lighter ways out under them.
NPopup {
    id: root

    open: NihilState.powerOpen
    namespace: "nihil:power"
    onDismissed: GlobalStates.sessionOpen = false

    readonly property real g: NihilStyle.seam
    readonly property real wide: NihilStyle.s(372)
    readonly property string name: {
        const own = Config.options?.nihil?.power?.greeting ?? ""
        return own.length > 0 ? own : SystemInfo.username
    }

    function act(what: string): void {
        GlobalStates.sessionOpen = false
        if (what === "poweroff") Session.poweroff()
        else if (what === "reboot") Session.reboot()
        else if (what === "lock") Session.lock()
        else if (what === "suspend") Session.suspend()
        else if (what === "logout") Session.logout()
    }

    component Way: NButton {
        id: way
        property string glyph: ""
        property string word: ""
        property real glyphSize: NihilStyle.s(26)
        property real wordSize: NihilStyle.s(15)
        square: true
        NIcon {
            x: NihilStyle.s(14)
            y: NihilStyle.s(14)
            text: way.glyph
            size: way.glyphSize
            weight: 2.2
            color: way.ink
        }
        NText {
            x: NihilStyle.s(14)
            width: way.width - NihilStyle.s(20)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(10)
            text: way.word
            font.pixelSize: way.wordSize
            font.weight: Font.Black
            color: way.ink
        }
    }

    NRack {
        width: root.wide
        height: column.implicitHeight
        x: NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        Column {
            id: column
            spacing: root.g

            NTile {
                id: head
                width: root.wide
                height: NihilStyle.s(112)
                paper: true
                caption: Translation.tr("Goodbye,")
                NFigure {
                    x: head.pad
                    width: head.width - head.pad * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(6)
                    size: NihilStyle.s(52)
                    text: root.name
                    elide: Text.ElideRight
                    color: head.ink
                }
            }

            Row {
                spacing: root.g
                Way {
                    width: (root.wide - root.g) / 2
                    height: NihilStyle.s(136)
                    lit: true
                    glyph: "power_settings_new"
                    glyphSize: NihilStyle.s(36)
                    word: Translation.tr("Shut down")
                    wordSize: NihilStyle.textTitle
                    onClicked: root.act("poweroff")
                }
                Way {
                    width: (root.wide - root.g) / 2
                    height: NihilStyle.s(136)
                    glyph: "restart_alt"
                    glyphSize: NihilStyle.s(36)
                    word: Translation.tr("Restart")
                    wordSize: NihilStyle.textTitle
                    onClicked: root.act("reboot")
                }
            }

            Row {
                spacing: root.g
                Way {
                    width: (root.wide - root.g * 2) / 3
                    height: NihilStyle.s(96)
                    glyph: "lock"
                    word: Translation.tr("Lock")
                    onClicked: root.act("lock")
                }
                Way {
                    width: (root.wide - root.g * 2) / 3
                    height: NihilStyle.s(96)
                    glyph: "bedtime"
                    word: Translation.tr("Sleep")
                    onClicked: root.act("suspend")
                }
                Way {
                    width: (root.wide - root.g * 2) / 3
                    height: NihilStyle.s(96)
                    glyph: "logout"
                    word: Translation.tr("Sign out")
                    onClicked: root.act("logout")
                }
            }
        }
    }
}
