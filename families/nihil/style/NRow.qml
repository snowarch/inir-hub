import QtQuick

// One line of a section: what it is, one short line on what it does, its control at the far end. `stacked` puts the
// control under the words, full width. `tappable` makes the whole row answer the hand; `flash` shows where a search
// landed.
Item {
    id: root

    property string label: ""
    property string desc: ""
    property bool stacked: false
    property bool tappable: false
    default property alias control: slot.data
    signal tapped()

    readonly property real pad: NihilStyle.s(12)
    readonly property bool worded: root.label.length > 0
    readonly property real wordsHeight: words.height
    // Room a stacked row keeps at the end of its words line for a small key of its own.
    property real wordsEndRoom: 0
    readonly property real slotWide: root.stacked ? root.width - root.pad * 2
        : Math.min(root.width * 0.6, slot.children.length > 0 ? slot.children[0].implicitWidth : 0)

    function flash(): void { glow.restart() }

    implicitHeight: root.stacked
        ? (root.worded ? words.implicitHeight + NihilStyle.s(10) : 0) + slot.height + root.pad * 2
        : Math.max(NihilStyle.rowHeight, Math.max(words.implicitHeight, slot.height) + root.pad * 2)

    Rectangle {
        id: veil
        anchors.fill: parent
        radius: NihilStyle.sectionRowRadius
        color: NihilStyle.hoverVeil
        opacity: root.tappable && tap.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
    }
    Rectangle {
        id: lamp
        anchors.fill: parent
        radius: NihilStyle.sectionRowRadius
        color: NihilStyle.accent
        opacity: 0
        SequentialAnimation {
            id: glow
            NumberAnimation { target: lamp; property: "opacity"; to: 0.26; duration: 180 }
            PauseAnimation { duration: 700 }
            NumberAnimation { target: lamp; property: "opacity"; to: 0; duration: 620 }
        }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        enabled: root.tappable
        hoverEnabled: root.tappable
        cursorShape: root.tappable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.tapped()
    }

    Column {
        id: words
        visible: root.worded
        x: root.pad
        y: root.stacked ? root.pad : (root.height - height) / 2
        width: root.stacked ? root.width - root.pad * 2 - root.wordsEndRoom : root.width - root.pad * 2 - root.slotWide - NihilStyle.s(14)
        spacing: NihilStyle.s(2)
        NText {
            width: parent.width
            text: root.label
            font.pixelSize: NihilStyle.textBody
            font.weight: Font.Medium
        }
        NText {
            visible: root.desc.length > 0
            width: parent.width
            text: root.desc
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
    }

    Item {
        id: slot
        x: root.stacked ? root.pad : root.width - root.pad - width
        y: root.stacked ? (root.worded ? words.y + words.height + NihilStyle.s(10) : root.pad) : (root.height - height) / 2
        width: root.slotWide
        height: slot.children.length > 0 ? slot.children[0].implicitHeight : 0
    }
}
