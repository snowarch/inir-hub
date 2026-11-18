pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// One choice of a few, side by side: a lit plate slides to the one chosen. The shell's own segmented control too
// (part control.segmented): `options` is [{ value, label, glyph }], `picked` asks for the change.
Rectangle {
    id: root

    property var options: []
    property var current
    property string accessibleName: ""
    signal picked(var value)

    readonly property int at: root.options.findIndex(option => option.value === root.current)
    readonly property real inset: NihilStyle.s(3)
    readonly property real slot: (root.width - root.inset * 2) / Math.max(1, root.options.length)
    function shownLabel(option: var): string { return Translation.tr(String(option?.label ?? "")).toUpperCase() }
    readonly property real widest: {
        let most = 0
        for (const option of root.options) {
            const glyph = String(option?.glyph ?? "").length > 0 ? NihilStyle.s(22) : 0
            most = Math.max(most, metrics.advanceWidth(root.shownLabel(option)) + glyph)
        }
        return most
    }

    FontMetrics { id: metrics; font.family: NihilStyle.grotesk; font.pixelSize: NihilStyle.textSmall }

    implicitWidth: (root.widest + NihilStyle.s(22)) * root.options.length + root.inset * 2
    implicitHeight: NihilStyle.s(36)
    radius: NihilStyle.keyRadius(width, height, false)
    color: NihilStyle.pieceRaised

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
        color: NihilStyle.accent
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
                Accessible.name: root.shownLabel(segment.modelData)
                Accessible.checked: segment.chosen
                onClicked: root.picked(segment.modelData.value)
                Row {
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(5)
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: segment.glyph.length > 0
                        text: segment.glyph
                        size: NihilStyle.s(16)
                        color: word.color
                    }
                    NText {
                        id: word
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, segment.width - NihilStyle.s(segment.glyph.length > 0 ? 30 : 8))
                        figures: true
                        text: root.shownLabel(segment.modelData)
                        font.pixelSize: NihilStyle.textSmall
                        color: segment.chosen ? NihilStyle.onAccent : segment.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
                        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                    }
                }
            }
        }
    }

    NFocus { shown: root.activeFocus }
}
