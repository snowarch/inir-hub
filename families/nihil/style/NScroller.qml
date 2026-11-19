import QtQuick

// A column that scrolls, a thin pill showing where it stands while it moves or the pointer is over it. `reveal` brings
// a row into view.
Item {
    id: root

    default property alias content: holder.data
    property real spacing: 0
    property real topPad: 0
    property real bottomPad: 0
    property real sidePad: 0
    readonly property alias contentY: flick.contentY
    readonly property real innerWidth: holder.width

    function toTop(): void { jump.stop(); flick.contentY = 0 }
    function reveal(item: Item): void {
        if (!item) return
        const y = item.mapToItem(holder, 0, 0).y + root.topPad - NihilStyle.s(24)
        jump.to = NihilStyle.clamp(y, 0, Math.max(0, flick.contentHeight - flick.height))
        jump.restart()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: holder.implicitHeight + root.topPad + root.bottomPad
        boundsBehavior: Flickable.StopAtBounds
        NumberAnimation { id: jump; target: flick; property: "contentY"; duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic }
        Column {
            id: holder
            x: root.sidePad
            y: root.topPad
            width: flick.width - root.sidePad * 2
            spacing: root.spacing
        }
    }

    HoverHandler { id: pointer }

    Rectangle {
        visible: flick.contentHeight > flick.height
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(3)
        y: flick.visibleArea.yPosition * flick.height
        width: NihilStyle.s(3)
        height: Math.max(NihilStyle.s(28), flick.visibleArea.heightRatio * flick.height)
        radius: width / 2
        color: NihilStyle.textSecondary
        opacity: flick.moving || pointer.hovered ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: NihilStyle.durationMedium } }
    }
}
