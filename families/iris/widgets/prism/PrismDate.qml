pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// The date in Prism: the month on the tab, the weekday on the flap, the day's number in the pane, the week and the
// year's run on the foot.
PrismFolder {
    id: root

    readonly property var today: root.widget.today
    readonly property int dayOfYear: root.widget.dayOfYear
    readonly property int daysInYear: root.widget.daysInYear
    readonly property int week: {
        const t = new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate())
        t.setDate(t.getDate() + 3 - (t.getDay() + 6) % 7)
        const first = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t.getTime() - first.getTime()) / 86400000 - 3 + (first.getDay() + 6) % 7) / 7)
    }
    readonly property int daysLeft: root.daysInYear - root.dayOfYear

    tabGlyph: "calendar_today"
    tabText: IrisFaceData.capitalized(Translation.locale.toString(root.today, root.widget.showYear && !root.small ? "MMMM yyyy" : "MMMM"))
    flapText: root.widget.showWeekday ? IrisFaceData.capitalized(Translation.locale.toString(root.today, "ddd")) : String(root.today.getFullYear())

    // ── the pane: the day ──
    FaceFigure {
        id: number
        face: root
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        text: root.today.getDate()
        size: root.type(50, 58, 92)
        rolls: false
    }
    Column {
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.dp(2)
        FaceText {
            anchors.right: parent.right
            face: root
            text: Translation.tr("Week %1").arg(root.week)
            color: root.inkSecondary
            size: root.type(12, 13, 15)
            weight: Font.DemiBold
        }
        FaceText {
            anchors.right: parent.right
            face: root
            text: Translation.tr("Day %1").arg(root.dayOfYear)
            color: root.inkTertiary
            size: root.type(11, 12, 14)
        }
    }

    // ── the foot: the week (medium, large) and how much of the year is left (small, large) ──
    PrismWeek {
        id: weekStrip
        visible: !root.small
        face: root
        today: root.today
        dates: true
        x: root.inset
        width: root.innerWidth
        height: implicitHeight
        y: root.large ? root.footTop + root.dp(24) : Math.round(root.footTop + (root.footHeight - height) / 2)
    }
    // The year as its twelve months: the ones gone dim, this one filling in the widget's colour, the rest to come.
    Row {
        id: year
        visible: !root.medium
        readonly property int month: root.today.getMonth()
        readonly property real monthShare: (root.today.getDate() - 1) / new Date(root.today.getFullYear(), year.month + 1, 0).getDate()
        x: root.inset
        width: root.innerWidth
        height: root.dp(root.large ? 6 : 5)
        y: root.small ? root.footTop + root.dp(22) : root.height - root.dp(56)
        spacing: root.dp(root.large ? 4 : 3)
        // A slab spends the year through the spectrum: January violet to December red, the months to come faint.
        layer.enabled: !root.folded
        layer.smooth: true
        layer.effect: PrismSpectrum { mono: root.nothing }
        Repeater {
            model: 12
            Rectangle {
                id: month
                required property int index
                width: (year.width - 11 * year.spacing) / 12
                height: year.height
                radius: height / 2
                color: month.index < year.month ? (root.folded ? root.fillActive : root.ink) : root.fill
                Rectangle {
                    visible: month.index === year.month
                    width: Math.max(height, parent.width * year.monthShare)
                    height: parent.height
                    radius: height / 2
                    color: root.folded ? root.shelf : root.ink
                }
            }
        }
    }
    FaceText {
        visible: year.visible
        face: root
        x: root.inset
        width: root.innerWidth
        y: year.y + year.height + root.dp(root.large ? 12 : 9)
        text: root.daysLeft === 1 ? Translation.tr("1 day left in %1").arg(root.today.getFullYear())
            : Translation.tr("%1 days left in %2").arg(root.daysLeft).arg(root.today.getFullYear())
        color: root.inkSecondary
        size: root.type(11.5, 12, 14)
    }
}
