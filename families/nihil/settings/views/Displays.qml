pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// Each screen's resolution, refresh and scale. A change holds for a few seconds and goes back by itself unless it is
// kept, so a screen that goes dark comes back with no one touching anything.
Column {
    id: root

    readonly property var rows: [
        { key: "resolution", label: Translation.tr("Resolution") },
        { key: "rate", label: Translation.tr("Refresh rate") },
        { key: "scale", label: Translation.tr("Scale") }
    ]
    readonly property bool ready: CompositorConfig.outputs.length > 0

    spacing: NihilStyle.s(14)
    Component.onCompleted: CompositorConfig.ensure()

    NEmpty {
        visible: !root.ready
        width: root.width
        busy: true
        title: Translation.tr("Reading your screens")
    }

    Rectangle {
        visible: !!CompositorConfig.pending
        width: root.width
        height: NihilStyle.s(58)
        radius: NihilStyle.sectionRowRadius
        color: NihilStyle.accent
        NText {
            anchors.left: parent.left
            anchors.leftMargin: NihilStyle.s(16)
            anchors.right: keep.left
            anchors.rightMargin: NihilStyle.s(10)
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Keep this? Going back in %1 s").arg(CompositorConfig.secondsLeft)
            font.weight: Font.Medium
            color: NihilStyle.onAccent
        }
        NKey {
            id: keep
            anchors.right: back.left
            anchors.rightMargin: NihilStyle.s(6)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(78)
            height: NihilStyle.s(40)
            label: Translation.tr("Keep")
            onClicked: CompositorConfig.keepDisplay()
        }
        NKey {
            id: back
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(9)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(92)
            height: NihilStyle.s(40)
            label: Translation.tr("Go back")
            onClicked: CompositorConfig.revertDisplay()
        }
    }

    NChips {
        visible: CompositorConfig.outputs.length > 1
        width: root.width
        options: CompositorConfig.displayChoices("screen")
        current: CompositorConfig.displayValue("screen")
        onPicked: value => CompositorConfig.applyDisplay("screen", value)
    }

    Repeater {
        model: root.ready ? root.rows : []
        Column {
            id: line
            required property var modelData
            width: root.width
            spacing: NihilStyle.s(7)
            NText {
                mono: true
                text: line.modelData.label.toUpperCase()
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            NChips {
                width: parent.width
                options: CompositorConfig.displayChoices(line.modelData.key)
                current: CompositorConfig.displayValue(line.modelData.key)
                onPicked: value => CompositorConfig.applyDisplay(line.modelData.key, value)
            }
        }
    }
}
