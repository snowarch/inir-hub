pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// Uptime in Prism: the name on the tab, the hour it started on the flap, how long it has run in the pane, the session
// drawn over the last day on the foot.
PrismFolder {
    id: root

    readonly property int total: root.widget.sessionSeconds
    readonly property int days: Math.floor(root.total / 86400)
    readonly property int hours: Math.floor(root.total % 86400 / 3600)
    readonly property int minutes: Math.floor(root.total % 3600 / 60)
    readonly property var parts: root.days > 0
        ? [{ value: root.days, unit: Translation.tr("d") }, { value: root.hours, unit: Translation.tr("h") }]
        : [{ value: root.hours, unit: Translation.tr("h") }, { value: root.minutes, unit: Translation.tr("min") }]
    readonly property var now: DateTime.clock.date
    readonly property real nowAt: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property bool sinceYesterday: root.total / 86400 >= root.nowAt
    readonly property real bootAt: root.sinceYesterday ? 0 : root.nowAt - root.total / 86400
    readonly property var boot: root.widget.bootDate
    readonly property var bootParts: IrisFaceData.timeParts(IrisFaceData.clockText(root.boot))

    tabGlyph: "power_settings_new"
    tabText: Translation.tr("Uptime")
    flapText: root.bootParts.main
    flapSuffix: root.bootParts.suffix

    // ── the pane: how long ──
    Row {
        id: lead
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
        visible: root.medium
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        text: root.sinceYesterday ? IrisFaceData.capitalized(Translation.locale.toString(root.boot, "dddd")) : Translation.tr("Today")
        color: root.inkTertiary
        size: 13
        face: root
    }

    // ── the foot: the session over the day, from midnight to now ──
    FaceArea {
        id: session
        face: root
        x: root.inset
        width: root.innerWidth
        y: root.footTop + root.pick(14, 10, 30)
        height: root.pick(22, 22, 72)
        from: root.bootAt
        to: root.nowAt
        tint: root.shelf
        curve: t => 0.8
    }
    Repeater {
        model: [0, 6, 12, 18, 24]
        FaceText {
            id: mark
            required property var modelData
            required property int index
            face: root
            x: Math.round(session.x + session.width * mark.index / 4 - (mark.index === 0 ? 0 : mark.index === 4 ? width : width / 2))
            y: session.y + session.height + root.dp(4)
            text: String(mark.modelData)
            color: root.inkTertiary
            size: root.type(10, 10.5, 12)
            font.family: root.fontNumbers
            font.features: ({ "tnum": 1 })
        }
    }
}
