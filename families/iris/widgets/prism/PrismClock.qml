pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.widgets

// The clock in Prism: the weekday on the tab, the date on the flap, the hour in the pane, the week on the foot.
PrismFolder {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.live
    }
    readonly property var now: clock.date
    readonly property string timePattern: {
        const format = String(root.widget.timeFormat ?? "system")
        if (format === "24h") return "HH:mm"
        if (format === "12h") return "h:mm AP"
        return String(Config.options?.time?.format ?? "hh:mm").replace(/:ss/, "")
    }
    readonly property var time: IrisFaceData.timeParts(Translation.locale.toString(root.now, root.timePattern))
    readonly property int week: {
        const t = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        t.setDate(t.getDate() + 3 - (t.getDay() + 6) % 7)
        const first = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t.getTime() - first.getTime()) / 86400000 - 3 + (first.getDay() + 6) % 7) / 7)
    }
    readonly property int dayOfYear: Math.round((new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        - new Date(root.now.getFullYear(), 0, 1)) / 86400000) + 1

    tabGlyph: "schedule"
    tabText: IrisFaceData.capitalized(Translation.locale.toString(root.now, root.small ? "ddd" : "dddd"))
    flapText: Translation.locale.toString(root.now, root.small ? "d" : "d MMM")

    // ── the pane: the hour ──
    Row {
        id: figure
        x: root.inset
        y: Math.round(root.paneMiddle - hour.height / 2)
        spacing: root.dp(4)
        FaceFigure {
            id: hour
            face: root
            text: root.time.main
            size: root.type(42, 54, 82)
        }
        FaceText {
            visible: text.length > 0
            face: root
            anchors.baseline: hour.baseline
            text: root.time.suffix
            color: root.inkSecondary
            size: root.type(13, 15, 20)
            weight: Font.Bold
        }
    }
    Column {
        visible: root.medium
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.dp(2)
        FaceText {
            anchors.right: parent.right
            face: root
            text: Translation.tr("Week %1").arg(root.week)
            color: root.inkSecondary
            size: 13
            weight: Font.DemiBold
        }
        FaceText {
            anchors.right: parent.right
            face: root
            text: Translation.tr("Day %1").arg(root.dayOfYear)
            color: root.inkTertiary
            size: 12
        }
    }

    // ── the foot: the week ──
    PrismWeek {
        face: root
        today: root.now
        dates: root.large
        x: root.inset
        width: root.innerWidth
        height: implicitHeight
        y: root.large ? root.footTop + root.dp(26) : Math.round(root.footTop + (root.footHeight - height) / 2)
    }
    FaceText {
        visible: root.large
        face: root
        x: root.inset
        width: root.innerWidth
        y: root.height - root.dp(30) - height / 2
        horizontalAlignment: Text.AlignHCenter
        text: Translation.tr("Week %1").arg(root.week) + "  ·  " + Translation.tr("Day %1").arg(root.dayOfYear)
        color: root.inkTertiary
        size: 13
    }
}
