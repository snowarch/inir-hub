pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// The way out. The band has bent into the horizon of a dark planet and the five ways stand along it; the light runs to the
// chosen one. The pointer or the arrows choose, Enter or a click goes.
FocusScope {
    id: root

    property real limbAt: 0
    property real limbRadius: 2600
    property bool flipped: false
    property bool open: false

    readonly property var ways: [
        { id: "lock", glyph: "lock", word: Translation.tr("Lock") },
        { id: "suspend", glyph: "bedtime", word: Translation.tr("Sleep") },
        { id: "logout", glyph: "logout", word: Translation.tr("Sign out") },
        { id: "reboot", glyph: "restart", word: Translation.tr("Restart") },
        { id: "poweroff", glyph: "power_settings_new", word: Translation.tr("Shut down") }
    ]
    property int current: 2

    readonly property real stride: Math.min(NihilStyle.s(190), root.width / 5.4)
    function keyX(index: int): real { return root.width / 2 + (index - 2) * root.stride }
    // The height of the horizon at x, measured from the edge the sheet hangs from.
    function limbY(x: real): real {
        const off = x - root.width / 2
        return root.limbAt + root.limbRadius - Math.sqrt(root.limbRadius * root.limbRadius - off * off)
    }
    // From the edge the sheet hangs from to this window.
    function onScreen(y: real, height: real): real { return root.flipped ? root.height - y - height : y }

    readonly property real lightX: root.keyX(root.current)
    readonly property real lightY: root.limbY(root.lightX)

    onOpenChanged: {
        if (!root.open) return
        root.current = 2
        root.forceActiveFocus()
    }
    Component.onCompleted: if (root.open) root.forceActiveFocus()

    function step(by: int): void { root.current = (root.current + by + root.ways.length) % root.ways.length }
    function take(id: string): void {
        GlobalStates.sessionOpen = false
        if (id === "lock") Session.lock()
        else if (id === "suspend") Session.suspend()
        else if (id === "logout") Session.logout()
        else if (id === "reboot") Session.reboot()
        else if (id === "poweroff") Session.poweroff()
    }

    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    Keys.onTabPressed: root.step(1)
    Keys.onBacktabPressed: root.step(-1)
    Keys.onReturnPressed: root.take(root.ways[root.current].id)
    Keys.onEnterPressed: root.take(root.ways[root.current].id)

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.onScreen(root.limbAt * 0.38, height)
        spacing: NihilStyle.s(10)
        NDisplay {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ways[root.current].word
            size: NihilStyle.s(96)
            font.letterSpacing: -NihilStyle.s(3)
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text.length > 0
            text: DateTime.uptime ? Translation.tr("Up for %1").arg(DateTime.uptime) : ""
            font.pixelSize: NihilStyle.s(16)
            color: NihilStyle.inkSoft
        }
    }

    Repeater {
        model: root.ways
        MouseArea {
            id: way

            required property var modelData
            required property int index
            readonly property bool chosen: root.current === way.index
            readonly property real side: NihilStyle.s(72)

            x: root.keyX(way.index) - width / 2
            y: root.flipped ? root.height - root.limbY(root.keyX(way.index)) - way.side / 2
                : root.limbY(root.keyX(way.index)) - way.side / 2
            width: Math.min(root.stride, NihilStyle.s(150))
            height: way.side + NihilStyle.s(44)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: way.modelData.word
            onEntered: root.current = way.index
            onClicked: root.take(way.modelData.id)

            NBloom {
                anchors.centerIn: disc
                width: disc.width * 2.6
                height: width
                opacity: way.chosen ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
            }
            Rectangle {
                id: disc
                anchors.horizontalCenter: parent.horizontalCenter
                width: way.side
                height: width
                radius: width / 2
                color: way.chosen ? NihilStyle.ink : NihilStyle.void_
                border.width: way.chosen ? 0 : 1
                border.color: NihilStyle.hair
                scale: way.pressed ? 0.95 : 1
                Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                Behavior on scale { NumberAnimation { duration: NihilStyle.quick } }
                NIcon {
                    anchors.centerIn: parent
                    text: way.modelData.glyph
                    size: NihilStyle.s(28)
                    color: way.chosen ? NihilStyle.void_ : NihilStyle.ink
                }
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: disc.height + NihilStyle.s(14)
                width: Math.min(implicitWidth, parent.width)
                text: way.modelData.word
                font.pixelSize: NihilStyle.s(15)
                font.weight: way.chosen ? Font.Medium : Font.Normal
                color: way.chosen ? NihilStyle.ink : NihilStyle.inkSoft
            }
        }
    }
}
