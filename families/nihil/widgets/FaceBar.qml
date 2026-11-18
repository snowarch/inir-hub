import QtQuick
import qs.modules.nihil.style

// How full something is: a hairline track with ten ticks, filled with light up to the level.
Item {
    id: root

    property real level: 0
    property color tint: NihilStyle.accent
    readonly property bool lightFill: Qt.colorEqual(root.tint, NihilStyle.accent)
    readonly property real shown: NihilStyle.clamp(root.level, 0, 1)

    implicitHeight: NihilStyle.s(6)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        color: NihilStyle.hair
    }
    Repeater {
        model: 11
        delegate: Rectangle {
            required property int index
            x: Math.round((root.width - 1) * index / 10)
            width: 1
            height: index % 5 === 0 ? root.height : root.height / 2
            y: (root.height - height) / 2
            color: NihilStyle.hair
        }
    }
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(2, root.width * root.shown)
        height: NihilStyle.s(2)
        clip: true
        Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

        NSpectrum {
            visible: root.lightFill
            width: root.width
            height: parent.height
        }
        Rectangle {
            visible: !root.lightFill
            width: root.width
            height: parent.height
            color: root.tint
        }
    }
}
