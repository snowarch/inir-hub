pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.pieces
import qs.modules.iris.widgets

// Screen time in Prism: the name on the tab, the app the day went to on the flap, today's total in the pane, the day's
// hours on the foot (large adds the apps that lead).
PrismFolder {
    id: root

    property int revision: 0
    readonly property bool counting: ScreenTime.enabled
    readonly property var today: { void root.revision; return ScreenTime.getToday() }
    readonly property int total: Number(root.today?.totalSeconds ?? 0)
    readonly property var hourly: Array.from(root.today?.hourly ?? []).concat(new Array(24).fill(0)).slice(0, 24)
    readonly property real hourPeak: Math.max(900, ...root.hourly)
    readonly property int hourNow: { void root.revision; return new Date().getHours() }
    readonly property var apps: { void root.revision; return root.counting ? ScreenTime.getAppList(3) : [] }
    readonly property var leader: root.apps[0] ?? null
    readonly property bool idle: root.total < 60
    readonly property var parts: {
        const hours = Math.floor(root.total / 3600)
        const minutes = Math.floor(root.total % 3600 / 60)
        return hours > 0 ? [{ value: hours, unit: Translation.tr("h") }, { value: minutes, unit: Translation.tr("min") }]
            : [{ value: minutes, unit: Translation.tr("min") }]
    }
    function shortDuration(seconds: int): string {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor(seconds % 3600 / 60)
        return hours > 0 ? hours + Translation.tr("h") + " " + minutes + Translation.tr("m") : minutes + Translation.tr("m")
    }

    // Ticks only while seen; uncovered, it catches up with what was counted behind the windows.
    Connections {
        target: ScreenTime
        enabled: root.moving
        function onDataChanged(): void { root.revision++ }
    }
    onMovingChanged: if (root.moving) root.revision++

    tabGlyph: "hourglass_top"
    tabText: root.small ? Translation.tr("Today") : Translation.tr("Screen Time")
    shelf: root.nothing ? root.signal : root.accent

    // ── the flap: the app the day went to ──
    Row {
        visible: root.counting && root.leader !== null && !root.idle
        readonly property real middle: root.folded ? Math.round((root.flapTop + root.paneTop) / 2) : root.headY
        x: root.folded ? Math.round((root.flapLeft + root.flapRight) / 2 + root.dp(3) - width / 2) : root.width - root.inset - width
        y: Math.round(middle - height / 2)
        spacing: root.dp(4)
        SmartAppIcon {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: root.pick(14, 16, 22)
            icon: IrisPieces.appIcon(String(root.leader?.originalId ?? root.leader?.id ?? ""))
        }
        FaceText {
            anchors.verticalCenter: parent.verticalCenter
            face: root
            text: root.shortDuration(root.leader?.seconds ?? 0)
            color: root.folded ? root.inkOnShelf : root.shelf
            size: root.folded ? root.type(12, 13, 17) : root.type(12, 13, 15)
            weight: Font.Bold
            font.family: root.fontNumbers
            font.features: ({ "tnum": 1 })
        }
    }

    // ── the pane: today ──
    Row {
        id: lead
        visible: root.counting && !root.idle
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.pick(6, 8, 12)
        Repeater {
            model: root.parts
            Row {
                id: part
                required property var modelData
                spacing: root.dp(2)
                FaceFigure {
                    id: figure
                    face: root
                    text: part.modelData.value
                    size: root.type(36, 50, 72)
                }
                FaceText {
                    face: root
                    anchors.baseline: figure.baseline
                    text: part.modelData.unit
                    color: root.inkSecondary
                    size: root.type(14, 18, 26)
                    weight: Font.DemiBold
                }
            }
        }
    }
    FaceText {
        visible: !root.counting || root.idle
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        text: !root.counting ? Translation.tr("See where your day goes") : Translation.tr("Nothing yet today")
        color: root.inkSecondary
        size: root.type(12, 13, 15)
    }

    // ── the foot: the day's hours, a bar each, the one running on the widget's colour ──
    Item {
        id: hours
        visible: root.counting
        x: root.inset
        width: root.innerWidth
        y: root.footTop + root.pick(12, 10, 18)
        height: root.pick(26, 24, 44)
        readonly property real pitch: hours.width / 24
        // A slab runs the day through the spectrum, midnight violet to the next midnight red; hours to come stay faint.
        layer.enabled: !root.folded
        layer.smooth: true
        layer.effect: PrismSpectrum { mono: root.nothing }
        Repeater {
            model: hours.visible ? 24 : 0
            Rectangle {
                id: bar
                required property int index
                readonly property real level: root.hourly[bar.index] / root.hourPeak
                x: Math.round(bar.index * hours.pitch + hours.pitch * 0.18)
                width: Math.max(2, Math.round(hours.pitch * 0.64))
                height: Math.max(width, Math.round(hours.height * bar.level))
                y: hours.height - height
                radius: Math.min(width / 2, root.dp(2))
                color: !root.folded ? (bar.index > root.hourNow ? root.fill : root.ink)
                    : bar.index === root.hourNow ? root.shelf : bar.index > root.hourNow ? root.fill : root.fillActive
            }
        }
    }
    Repeater {
        model: hours.visible ? [0, 6, 12, 18] : []
        FaceText {
            id: mark
            required property var modelData
            face: root
            x: Math.round(hours.x + mark.modelData * hours.pitch)
            y: hours.y + hours.height + root.dp(4)
            text: String(mark.modelData)
            color: root.inkTertiary
            size: root.type(10, 10.5, 12)
            font.family: root.fontNumbers
            font.features: ({ "tnum": 1 })
        }
    }
    Repeater {
        model: root.large && root.counting ? root.apps.slice(0, 2) : []
        Item {
            id: app
            required property var modelData
            required property int index
            x: root.inset
            width: root.innerWidth
            height: root.dp(30)
            y: root.footTop + root.dp(90) + app.index * root.dp(32)
            SmartAppIcon {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: root.dp(20)
                icon: IrisPieces.appIcon(String(app.modelData?.originalId ?? app.modelData?.id ?? ""))
            }
            FaceText {
                anchors.verticalCenter: parent.verticalCenter
                x: root.dp(30)
                width: parent.width - x - spent.width - root.dp(10)
                face: root
                text: app.modelData?.name ?? ""
                size: 14
                weight: Font.DemiBold
            }
            FaceText {
                id: spent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                face: root
                text: root.shortDuration(app.modelData?.seconds ?? 0)
                color: root.inkSecondary
                size: 13
                font.family: root.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
    }
}
