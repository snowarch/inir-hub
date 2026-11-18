pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// One choice of many: chips that wrap to the width they are given, the chosen one lit.
Flow {
    id: root

    property var options: []
    property var current
    signal picked(var value)

    spacing: NihilStyle.s(6)

    Repeater {
        model: root.options
        NButton {
            id: chip
            required property var modelData
            readonly property bool chosen: chip.modelData.value === root.current
            width: word.implicitWidth + NihilStyle.s(26)
            height: NihilStyle.s(34)
            lit: chip.chosen
            tone: NihilStyle.pieceRaised
            Accessible.role: Accessible.RadioButton
            Accessible.name: word.text
            Accessible.checked: chip.chosen
            onClicked: root.picked(chip.modelData.value)
            NText {
                id: word
                anchors.centerIn: parent
                figures: true
                text: Translation.tr(String(chip.modelData.label ?? ""))
                font.pixelSize: NihilStyle.textSmall
                color: chip.ink
            }
        }
    }
}
