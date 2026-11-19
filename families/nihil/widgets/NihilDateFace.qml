import QtQuick
import qs.services
import qs.modules.nihil.style

// The month in the accent, the day of the month large, its weekday beside it and, with room, how far the year has gone.
NihilWidgetFace {
    id: root

    readonly property date today: root.widget.today
    readonly property real yearGone: root.widget.dayOfYear / Math.max(1, root.widget.daysInYear)

    NText {
        anchors.left: parent.left
        anchors.top: parent.top
        text: Translation.locale.toString(root.today, root.widget.showYear ? "MMMM yyyy" : "MMMM")
        font.pixelSize: root.dp(13)
        font.weight: Font.DemiBold
        color: root.accent
    }

    NDisplay {
        color: root.foreground
        id: day
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.small ? root.dp(6) : -root.dp(2)
        text: root.today.getDate()
        size: Math.min(root.contentHeight * (root.small ? 0.5 : 0.48), root.contentWidth * 0.42)
    }
    NText {
        anchors.left: day.right
        anchors.leftMargin: root.dp(10)
        anchors.right: parent.right
        anchors.baseline: day.baseline
        visible: root.widget.showWeekday
        text: Translation.locale.toString(root.today, "dddd")
        font.pixelSize: root.dp(root.small ? 14 : 17)
        font.weight: Font.DemiBold
        color: root.foregroundSecondary
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !root.small
        spacing: root.dp(7)

        Item {
            width: parent.width
            height: gone.implicitHeight
            NText {
                id: gone
                text: Translation.tr("Day %1 of %2").arg(root.widget.dayOfYear).arg(root.widget.daysInYear)
                font.pixelSize: root.dp(12)
                color: root.foregroundSecondary
            }
            NText {
                color: root.foreground
                anchors.right: parent.right
                text: Math.round(root.yearGone * 100) + "%"
                figures: true
                font.pixelSize: root.dp(12)
                font.weight: Font.DemiBold
            }
        }
        FaceBar {
            foreground: root.foreground
            width: parent.width
            level: root.yearGone
        }
    }
}
