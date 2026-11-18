pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The way out: a glass card over the dimmed desktop, five round keys under the name of the chosen one. The pointer or
// the arrows move the choice, Enter or a click takes that way.
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

    Rectangle {
        anchors.fill: parent
        color: NihilStyle.scrim
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
    }

    NGlass {
        id: dock
        anchors.centerIn: parent
        width: line.implicitWidth + NihilStyle.s(48)
        height: line.implicitHeight + head.implicitHeight + NihilStyle.s(78)
        radius: NihilStyle.rPanel
        ignite: root.open ? 0.45 : 0

        // Takes no click of its own, so a press between two keys does not close the menu.
        MouseArea { anchors.fill: parent }

        Column {
            id: head
            anchors.horizontalCenter: parent.horizontalCenter
            y: NihilStyle.s(26)
            spacing: NihilStyle.s(2)
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.ways[root.current].word
                font.pixelSize: NihilStyle.textLarge
                font.weight: Font.DemiBold
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: DateTime.uptime ? Translation.tr("Up for %1").arg(DateTime.uptime) : ""
                visible: text.length > 0
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }

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
                anchors.horizontalCenter: parent.horizontalCenter
                y: head.y + head.implicitHeight + NihilStyle.s(22)
                spacing: NihilStyle.s(14)

                Repeater {
                    model: root.ways
                    delegate: MouseArea {
                        id: way
                        required property var modelData
                        required property int index
                        readonly property bool lit: root.current === way.index

                        width: NihilStyle.s(64)
                        height: NihilStyle.s(64)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: way.modelData.word
                        onEntered: root.current = way.index
                        onClicked: root.take(way.modelData.id)

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: way.lit ? (way.modelData.id === "poweroff" ? NihilStyle.danger : NihilStyle.accent) : NihilStyle.piece
                            border.width: way.lit ? 0 : 1
                            border.color: NihilStyle.line
                            scale: way.pressed ? 0.94 : 1
                            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                            Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
                        }
                        NIcon {
                            anchors.centerIn: parent
                            text: way.modelData.glyph
                            size: NihilStyle.s(24)
                            color: way.lit ? NihilStyle.accentInk : NihilStyle.ink
                        }
                    }
                }
            }
        }
    }
}
