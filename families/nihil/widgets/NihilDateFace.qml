import QtQuick
import qs.services
import qs.modules.nihil.style

// The day of the month as the one large thing, its names beside it and, with room, how far the year has gone.
NihilWidgetFace {
    id: root

    readonly property date today: root.widget.today
    readonly property real yearGone: root.widget.dayOfYear / Math.max(1, root.widget.daysInYear)

    NText {
        id: day
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.small ? 0 : -root.dp(10)
        figures: true
        text: root.today.getDate()
        font.weight: Font.Light
        font.pixelSize: Math.min(root.contentHeight * 0.72, root.contentWidth * 0.46)
    }

    Column {
        anchors.left: day.right
        anchors.leftMargin: root.dp(12)
        anchors.right: parent.right
        anchors.verticalCenter: day.verticalCenter
        spacing: root.dp(2)

        NText {
            width: parent.width
            visible: root.widget.showWeekday
            text: Translation.locale.toString(root.today, "dddd")
            elide: Text.ElideRight
            font.pixelSize: root.dp(root.small ? 14 : 18)
        }
        NText {
            width: parent.width
            text: Translation.locale.toString(root.today, root.widget.showYear ? "MMMM yyyy" : "MMMM")
            elide: Text.ElideRight
            font.pixelSize: root.dp(root.small ? 12 : 14)
            color: NihilStyle.inkSoft
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !root.small
        spacing: root.dp(5)

        NText {
            figures: true
            text: Translation.tr("Day %1 of %2").arg(root.widget.dayOfYear).arg(root.widget.daysInYear)
            font.pixelSize: root.dp(12)
            color: NihilStyle.inkSoft
        }
        FaceBar {
            width: parent.width
            level: root.yearGone
        }
    }
}
