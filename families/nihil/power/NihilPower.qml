pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// The way out: a selector you turn. Five ways stand round a ring and the light follows the chosen one; its name is at the
// heart. The pointer, the wheel or the arrows turn it, Enter or a click goes.
FocusScope {
    id: root

    property bool flipped: false
    property bool open: false

    readonly property var ways: [
        { id: "lock", glyph: "lock", word: Translation.tr("Lock") },
        { id: "suspend", glyph: "bedtime", word: Translation.tr("Sleep") },
        { id: "logout", glyph: "logout", word: Translation.tr("Sign out") },
        { id: "reboot", glyph: "restart", word: Translation.tr("Restart") },
        { id: "poweroff", glyph: "power_settings_new", word: Translation.tr("Shut down") }
    ]
    readonly property real stride: Math.PI * 2 / root.ways.length
    property int current: 0
    // Keeps turning the short way round, past the top as well.
    property real pointer: 0
    Behavior on pointer { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

    readonly property real ringRadius: Math.min(root.height * 0.29, root.width * 0.24, NihilStyle.s(300))
    readonly property real keySide: Math.round(root.ringRadius * 0.28)
    readonly property real orbit: root.ringRadius + root.keySide / 2 + NihilStyle.s(46)

    onOpenChanged: {
        if (!root.open) return
        root.current = 0
        root.pointer = 0
        root.forceActiveFocus()
    }
    Component.onCompleted: if (root.open) root.forceActiveFocus()

    function choose(index: int): void {
        const whole = Math.PI * 2
        const off = ((index * root.stride - root.pointer) % whole + whole * 1.5) % whole - whole / 2
        root.pointer += off
        root.current = index
    }
    function step(by: int): void { root.choose((root.current + by + root.ways.length) % root.ways.length) }
    function take(id: string): void {
        GlobalStates.sessionOpen = false
        if (id === "lock") Session.lock()
        else if (id === "suspend") Session.suspend()
        else if (id === "logout") Session.logout()
        else if (id === "reboot") Session.reboot()
        else if (id === "poweroff") Session.poweroff()
    }

    Keys.onLeftPressed: root.step(-1)
    Keys.onUpPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    Keys.onDownPressed: root.step(1)
    Keys.onTabPressed: root.step(1)
    Keys.onBacktabPressed: root.step(-1)
    Keys.onReturnPressed: root.take(root.ways[root.current].id)
    Keys.onEnterPressed: root.take(root.ways[root.current].id)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)
    }

    NRing {
        id: ring
        anchors.centerIn: parent
        width: root.ringRadius * 2
        height: width
        ticks: 120
        pointer: root.pointer
        spread: root.stride * 0.42
    }

    Column {
        anchors.centerIn: ring
        width: root.ringRadius * 1.4
        spacing: NihilStyle.s(10)
        NDisplay {
            width: parent.width
            height: root.ringRadius * 0.3
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: NihilStyle.s(24)
            size: root.ringRadius * 0.26
            text: root.ways[root.current].word
        }
        NText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: DateTime.uptime ? Translation.tr("Up for %1").arg(DateTime.uptime) : ""
            font.pixelSize: NihilStyle.s(15)
            color: NihilStyle.textSecondary
        }
    }

    Repeater {
        model: root.ways
        MouseArea {
            id: way

            required property var modelData
            required property int index
            readonly property bool chosen: root.current === way.index
            readonly property real angle: way.index * root.stride

            width: Math.max(root.keySide, words.implicitWidth)
            height: root.keySide + NihilStyle.s(34)
            x: ring.x + ring.width / 2 + Math.sin(way.angle) * root.orbit - width / 2
            y: ring.y + ring.height / 2 - Math.cos(way.angle) * root.orbit - root.keySide / 2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: way.modelData.word
            onEntered: root.choose(way.index)
            onClicked: root.take(way.modelData.id)

            Rectangle {
                id: disc
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.keySide
                height: width
                radius: width / 2
                color: way.chosen ? NihilStyle.accent : NihilStyle.fillHover
                scale: way.pressed ? 0.95 : 1
                Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                Behavior on scale { NumberAnimation { duration: NihilStyle.durationShort } }
                NIcon {
                    anchors.centerIn: parent
                    text: way.modelData.glyph
                    size: root.keySide * 0.36
                    color: way.chosen ? NihilStyle.accentText : NihilStyle.text
                }
            }
            NText {
                id: words
                anchors.horizontalCenter: parent.horizontalCenter
                y: disc.height + NihilStyle.s(10)
                text: way.modelData.word
                font.pixelSize: NihilStyle.textSmall
                font.weight: way.chosen ? Font.Medium : Font.Normal
                color: way.chosen ? NihilStyle.text : NihilStyle.textSecondary
            }
        }
    }
}
