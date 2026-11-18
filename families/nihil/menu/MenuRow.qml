pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One setting in NiHiL's menu: a tile with its name, and its value as a chip at the right end (on paper while on).
// A tap moves the value to the next of `choices` ([{ value, label }]), or flips a yes/no key; `action` instead runs it.
NButton {
    id: root

    property string label: ""
    property string key: ""
    property var choices: []
    property var fallback: false
    property var action: null
    readonly property var value: root.key.length > 0 ? Config.getNestedValue(root.key, root.fallback) : undefined
    readonly property bool isSwitch: root.choices.length === 0 && root.action === null
    readonly property int at: Math.max(0, root.choices.findIndex(choice => choice.value === root.value))
    // An action's own state, when it has one (light or dark).
    property string actionValue: ""
    property bool actionOn: false
    readonly property string shown: root.action !== null ? (root.actionValue.length > 0 ? root.actionValue : "›")
        : root.isSwitch ? (root.value ? Translation.tr("On") : Translation.tr("Off"))
        : String(root.choices[root.at]?.label ?? "")
    readonly property bool on: root.action !== null ? root.actionOn : root.isSwitch ? Boolean(root.value) : root.at > 0

    height: NihilStyle.s(56)
    square: true
    onClicked: {
        if (root.action !== null) { root.action(); return }
        if (root.isSwitch) { Config.setNestedValue(root.key, !root.value); return }
        Config.setNestedValue(root.key, root.choices[(root.at + 1) % root.choices.length].value)
    }

    NText {
        anchors.left: parent.left
        anchors.leftMargin: NihilStyle.s(14)
        anchors.right: chip.left
        anchors.rightMargin: NihilStyle.s(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: NihilStyle.textBody
        font.weight: Font.Bold
    }
    Rectangle {
        id: chip
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(8)
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - NihilStyle.s(16)
        width: Math.max(height, value.implicitWidth + NihilStyle.s(22))
        radius: NihilStyle.rowRadius
        color: root.on ? NihilStyle.plate : NihilStyle.pieceRaised
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        NText {
            id: value
            anchors.centerIn: parent
            figures: true
            text: root.shown.toUpperCase()
            font.pixelSize: NihilStyle.textMicro
            font.weight: Font.Bold
            color: root.on ? NihilStyle.onPlate : NihilStyle.ink
        }
    }
}
