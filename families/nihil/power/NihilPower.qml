pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The way out: one bar of glass with five keys over the dimmed desktop. The pointer or the arrows move the light between
// them, Enter or a click takes that way.
NPopup {
    id: root

    open: NihilState.powerOpen
    namespace: "nihil:power"
    blurPieces: [dock.region]
    onDismissed: GlobalStates.sessionOpen = false

    readonly property var ways: [
        { id: "lock", glyph: "lock", word: Translation.tr("Lock") },
        { id: "suspend", glyph: "bedtime", word: Translation.tr("Sleep") },
        { id: "logout", glyph: "logout", word: Translation.tr("Sign out") },
        { id: "reboot", glyph: "restart", word: Translation.tr("Restart") },
        { id: "poweroff", glyph: "power_settings_new", word: Translation.tr("Shut down") }
    ]
    property int current: 0

    onOpenChanged: {
        if (!root.open)
            return
        root.current = 0
        keys.forceActiveFocus()
    }

    function step(by: int): void {
        root.current = (root.current + by + root.ways.length) % root.ways.length
    }

    function take(id: string): void {
        GlobalStates.sessionOpen = false
        if (id === "lock") Session.lock()
        else if (id === "suspend") Session.suspend()
        else if (id === "logout") Session.logout()
        else if (id === "reboot") Session.reboot()
        else if (id === "poweroff") Session.poweroff()
    }

    NGlass {
        id: dock
        anchors.centerIn: parent
        width: line.implicitWidth + NihilStyle.s(24)
        height: line.implicitHeight + NihilStyle.s(24)
        radius: NihilStyle.rPanel
        ignite: 1

        // Takes no click of its own, so a press between two keys does not close the menu.
        MouseArea { anchors.fill: parent }

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onLeftPressed: root.step(-1)
            Keys.onRightPressed: root.step(1)
            Keys.onTabPressed: root.step(1)
            Keys.onBacktabPressed: root.step(-1)
            Keys.onReturnPressed: root.take(root.ways[root.current].id)
            Keys.onEnterPressed: root.take(root.ways[root.current].id)

            Row {
                id: line
                anchors.centerIn: parent
                spacing: NihilStyle.gap

                Repeater {
                    model: root.ways
                    delegate: NButton {
                        id: way
                        required property var modelData
                        required property int index

                        width: NihilStyle.s(104)
                        height: NihilStyle.s(104)
                        radius: NihilStyle.rCard
                        lit: root.current === way.index
                        activeFocusOnTab: false
                        onEntered: root.current = way.index
                        onClicked: root.take(way.modelData.id)

                        Column {
                            anchors.centerIn: parent
                            spacing: NihilStyle.s(10)

                            NIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: way.modelData.glyph
                                size: NihilStyle.s(30)
                                color: way.ink
                            }
                            NText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: way.modelData.word
                                font.pixelSize: NihilStyle.textSmall
                                color: way.ink
                            }
                        }
                    }
                }
            }
        }
    }
}
