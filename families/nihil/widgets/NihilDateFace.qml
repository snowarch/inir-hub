import QtQuick
import qs.services
import qs.modules.nihil.style

// The day of the month as the poster's figure, its names beside it and, with room, how far the year has gone.
NihilWidgetFace {
    id: root

    readonly property date today: root.widget.today
    readonly property real yearGone: root.widget.dayOfYear / Math.max(1, root.widget.daysInYear)

    NDisplay {
        id: day
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.small ? 0 : -root.dp(8)
        text: String(root.today.getDate()).padStart(2, "0")
        bloom: 0.7
        size: Math.min(root.contentHeight * 0.78, root.contentWidth * 0.5)
    }

    Column {
        anchors.left: day.right
        anchors.leftMargin: root.dp(12)
        anchors.right: parent.right
        anchors.verticalCenter: day.verticalCenter
        spacing: root.dp(4)

        NDisplay {
            width: parent.width
            visible: root.widget.showWeekday
            text: Translation.locale.toString(root.today, "dddd")
            elide: Text.ElideRight
            bloom: 0
            size: root.dp(root.small ? 18 : 24)
        }
        NLabel {
            width: parent.width
            text: Translation.locale.toString(root.today, root.widget.showYear ? "MMMM yyyy" : "MMMM")
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !root.small
        spacing: root.dp(6)

        Item {
            width: parent.width
            height: gone.implicitHeight
            NLabel {
                id: gone
                text: Translation.tr("Day %1 of %2").arg(root.widget.dayOfYear).arg(root.widget.daysInYear)
            }
            NLabel {
                anchors.right: parent.right
                strong: true
                text: Math.round(root.yearGone * 100) + "%"
            }
        }
        FaceBar {
            width: parent.width
            level: root.yearGone
        }
    }
}
