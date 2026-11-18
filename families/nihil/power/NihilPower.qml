pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style
import qs.modules.nihil.state

// The way out as a poster: the chosen way set large over the dimmed desktop, five numbered keys under it. The pointer or the arrows move the light between
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

    // The chosen way set as the poster's title, over the dimmed desktop. It changes as the light moves.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(NihilStyle.void_, 0.62)
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
    }

    Item {
        id: stage
        anchors.fill: parent

        NDisplay {
            id: title
            anchors.horizontalCenter: parent.horizontalCenter
            y: dock.y - height - NihilStyle.s(28)
            text: root.ways[root.current].word
            size: Math.min(parent.height * 0.26, parent.width * 0.7 / Math.max(3, text.length * 0.46))
            bloom: 0.9
        }
        NSpark {
            x: title.x + title.width - size * 0.4
            y: title.y - size * 0.1
            size: NihilStyle.s(44)
        }
        NLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: title.top
            anchors.bottomMargin: NihilStyle.s(6)
            text: String(root.current + 1).padStart(2, "0") + "  /  " + String(root.ways.length).padStart(2, "0")
        }
    }

    NGlass {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.12
        width: line.implicitWidth + NihilStyle.s(12)
        height: line.implicitHeight + NihilStyle.s(12)
        radius: NihilStyle.rCard

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

                Repeater {
                    model: root.ways
                    delegate: MouseArea {
                        id: way
                        required property var modelData
                        required property int index
                        readonly property bool lit: root.current === way.index

                        width: NihilStyle.s(112)
                        height: NihilStyle.s(86)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = way.index
                        onClicked: root.take(way.modelData.id)

                        Rectangle {
                            anchors.fill: parent
                            radius: NihilStyle.r(8)
                            color: NihilStyle.ink
                            opacity: way.lit ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
                        }
                        Rectangle {
                            visible: way.index > 0 && !way.lit && root.current !== way.index - 1
                            width: 1
                            height: parent.height * 0.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: NihilStyle.hair
                        }
                        NLabel {
                            x: NihilStyle.s(10)
                            y: NihilStyle.s(9)
                            text: String(way.index + 1).padStart(2, "0")
                            color: way.lit ? NihilStyle.void_ : NihilStyle.inkFaint
                        }
                        NIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: NihilStyle.s(24)
                            text: way.modelData.glyph
                            size: NihilStyle.s(24)
                            color: way.lit ? NihilStyle.void_ : NihilStyle.ink
                        }
                        NLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: NihilStyle.s(12)
                            text: way.modelData.word
                            color: way.lit ? NihilStyle.void_ : NihilStyle.inkSoft
                        }
                    }
                }
            }
        }
    }

    NRule {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: dock.bottom
        anchors.topMargin: NihilStyle.s(18)
        width: dock.width
        start: Translation.tr("Arrows move, Enter takes")
        middle: "⋈"
        end: DateTime.time
    }
}
