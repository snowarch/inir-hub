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

    // A slab worn small is a lens: a disc of glass with the hour in its middle, the day above and the date under it.
    readonly property bool lens: root.small && !root.folded
    slabRadius: root.lens ? Math.min(root.width, root.height) / 2 : root.radius
    prism: root.lens ? Qt.point(root.width * 0.82, root.height * 0.12)
        : root.folded ? Qt.point(Math.round(root.inset * 0.5), root.paneBottom - root.pick(10, 10, 16))
        : Qt.point(root.width - root.pick(28, 40, 48), root.pick(2, 2, 4))

    tabGlyph: root.lens ? "" : "schedule"
    tabText: root.lens ? "" : IrisFaceData.capitalized(Translation.locale.toString(root.now, root.small ? "ddd" : "dddd"))
    flapText: root.lens ? "" : Translation.locale.toString(root.now, root.small ? "d" : "d MMM")

    FaceText {
        visible: root.lens
        face: root
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.24 - height / 2)
        text: root.label ? Translation.locale.toString(root.now, "ddd").toUpperCase() : IrisFaceData.capitalized(Translation.locale.toString(root.now, "dddd"))
        color: root.label ? root.ink : root.shelf
        size: root.label ? 10.5 : 13
        weight: Font.Bold
        font.family: root.label ? root.fontLabel : root.fontMain
    }
    FaceText {
        visible: root.lens
        face: root
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.75 - height / 2)
        text: Translation.locale.toString(root.now, "d MMM")
        color: root.inkSecondary
        size: 12
        weight: Font.DemiBold
    }

    // ── the pane: the hour ──
    Row {
        id: figure
        x: root.lens ? Math.round((root.width - width) / 2) : root.inset
        y: root.lens ? Math.round(root.height / 2 - hour.height / 2) : Math.round(root.paneMiddle - hour.height / 2)
        spacing: root.dp(4)
        FaceFigure {
            id: hour
            face: root
            text: root.time.main
            size: root.lens ? 38 : root.type(42, 54, 82)
        }
        FaceText {
            visible: text.length > 0
            face: root
            anchors.baseline: hour.baseline
            text: root.lens ? "" : root.time.suffix
            color: root.inkSecondary
            size: root.type(13, 15, 20)
            weight: Font.Bold
        }
    }
    // The hour passing, as a thread of the light split under the figure: white where the hour began, the colours as it
    // goes; the rest of the hour a faint line.
    Item {
        id: thread
        visible: !root.folded
        readonly property real share: root.now.getMinutes() / 60
        x: root.lens ? Math.round(root.width * 0.3) : root.inset
        width: root.lens ? Math.round(root.width * 0.4) : figure.width
        y: root.lens ? Math.round(root.height * 0.64) : figure.y + figure.height + root.pick(4, 4, 8)
        height: root.dp(root.large ? 3 : 2)
        Rectangle { anchors.fill: parent; radius: height / 2; color: root.fill }
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.effect: PrismSpectrum { mono: root.nothing; white: 0.12 }
            Rectangle {
                width: Math.max(parent.height, parent.width * thread.share)
                height: parent.height
                radius: height / 2
                color: root.ink
            }
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
        visible: !root.lens
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
