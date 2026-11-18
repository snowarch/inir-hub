pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// One choice of a few. Also the shell's segmented control (part control.segmented): `options` is
// [{ value, label, glyph }], `picked` asks for the change.
Rectangle {
    id: root

    property var options: []
    property var current
    property string accessibleName: ""
    signal picked(var value)

    readonly property int at: root.options.findIndex(option => option.value === root.current)
    readonly property real inset: NihilStyle.s(3)
    readonly property real slot: (root.width - root.inset * 2) / Math.max(1, root.options.length)

    implicitWidth: NihilStyle.s(92) * root.options.length + root.inset * 2
    implicitHeight: NihilStyle.s(34)
    radius: NihilStyle.rKey
    color: NihilStyle.piece

    activeFocusOnTab: true
    Accessible.role: Accessible.List
    Accessible.name: root.accessibleName
    function step(by: int): void {
        const next = NihilStyle.clamp(root.at + by, 0, root.options.length - 1)
        if (next !== root.at) root.picked(root.options[next].value)
    }
    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)

    Rectangle {
        visible: root.at >= 0
        x: root.inset + root.slot * Math.max(0, root.at)
        y: root.inset
        width: root.slot
        height: root.height - root.inset * 2
        radius: Math.max(0, root.radius - root.inset)
        color: NihilStyle.chosen
        border.width: 1
        border.color: NihilStyle.hair
        Behavior on x { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    }

    Row {
        x: root.inset
        y: root.inset
        Repeater {
            model: root.options
            MouseArea {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: root.at === segment.index
                readonly property string glyph: String(segment.modelData?.glyph ?? "")
                width: root.slot
                height: root.height - root.inset * 2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.RadioButton
                Accessible.name: word.text
                Accessible.checked: segment.chosen
                onClicked: root.picked(segment.modelData.value)
                Row {
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(5)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: segment.glyph.length > 0
                        text: segment.glyph
                        size: NihilStyle.s(15)
                        color: word.color
                    }
                    NText {
                        id: word
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, segment.width - NihilStyle.s(segment.glyph.length > 0 ? 28 : 8))
                        text: Translation.tr(String(segment.modelData?.label ?? ""))
                        font.pixelSize: NihilStyle.textSmall
                        color: segment.chosen || segment.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
                        font.weight: segment.chosen ? Font.DemiBold : Font.Medium
                    }
                }
            }
        }
    }
}
