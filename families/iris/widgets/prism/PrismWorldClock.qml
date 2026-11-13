pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.widgets

// The world clock in Prism: the first city on the tab, how far it is on the flap, its hour in the pane, the other
// cities on the foot.
PrismFolder {
    id: root

    readonly property var cities: Array.from(root.widget.cities ?? []).slice(0, 4)
    readonly property var first: root.cities[0] ?? null
    readonly property var others: root.cities.slice(1, root.small ? 3 : 4)
    readonly property int localOffset: -WorldClock.now.getTimezoneOffset()

    function hoursAway(index: int): string {
        const delta = ((WorldClock.offsetsMinutes[index] ?? 0) - root.localOffset) / 60
        const hours = Math.abs(delta) % 1 === 0 ? Math.abs(delta) : Math.abs(delta).toFixed(1)
        return delta === 0 ? "" : (delta > 0 ? "+" : "−") + hours + " h"
    }
    function dayWord(index: int): string {
        const day = root.widget.cityDayDelta(index)
        return day > 0 ? Translation.tr("Tomorrow") : day < 0 ? Translation.tr("Yesterday") : Translation.tr("Today")
    }
    function shift(index: int): string {
        const away = root.hoursAway(index)
        return away.length === 0 ? root.dayWord(index) : root.small ? away : root.dayWord(index) + ", " + away
    }
    readonly property var time: IrisFaceData.timeParts(root.first?.time ?? "")

    tabGlyph: "public"
    readonly property bool names: root.widget.showNames
    readonly property bool offsets: root.widget.showOffsets

    tabText: root.names ? root.first?.name ?? Translation.tr("World clock") : Translation.tr("World clock")
    flapText: root.first && root.offsets ? root.shift(0) : ""

    // ── the pane: the first city's hour ──
    Row {
        id: figure
        visible: root.first !== null
        x: root.inset
        y: Math.round(root.paneMiddle - hour.height / 2)
        spacing: root.dp(4)
        FaceFigure {
            id: hour
            face: root
            text: root.time.main
            size: root.type(42, 54, 82)
            tone: root.first?.isDay ?? true ? root.ink : root.inkSecondary
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
    MaterialSymbol {
        visible: root.first !== null && !root.small
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        text: root.first?.isDay ?? true ? "light_mode" : "dark_mode"
        fill: 1
        iconSize: root.px(root.type(20, 26, 34))
        color: root.first?.isDay ?? true ? root.warm : root.inkTertiary
    }
    FaceText {
        visible: root.first === null
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        horizontalAlignment: Text.AlignHCenter
        text: Translation.tr("Add a city")
        color: root.inkTertiary
        size: root.type(12, 13, 15)
    }

    // ── the foot: the other cities, a row each (small, large) or side by side (medium) ──
    Repeater {
        model: root.medium ? [] : root.others
        Item {
            id: row
            required property var modelData
            required property int index
            readonly property real pitch: root.pick(24, 0, 50)
            x: root.inset
            width: root.innerWidth
            height: row.pitch
            y: root.footTop + root.pick(8, 0, 14) + row.index * row.pitch
            Rectangle {
                visible: root.large && row.index > 0
                width: parent.width
                height: 1
                color: root.hairline
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - when.width - root.dp(8)
                FaceText {
                    visible: root.names
                    face: root
                    width: Math.min(implicitWidth, parent.width)
                    text: row.modelData.name
                    color: row.modelData.isDay ? root.ink : root.inkSecondary
                    size: root.type(12, 13, 15)
                    weight: Font.DemiBold
                }
                FaceText {
                    visible: root.large && root.offsets
                    face: root
                    text: root.shift(row.index + 1)
                    color: root.inkTertiary
                    size: 12
                }
            }
            FaceText {
                id: when
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.time
                color: row.modelData.isDay ? root.ink : root.inkSecondary
                size: root.type(13, 14, 24)
                weight: Font.Bold
                font.family: root.fontNumbers
                font.features: ({ "tnum": 1 })
                face: root
            }
        }
    }
    Row {
        visible: root.medium
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2)
        spacing: root.dp(18)
        Repeater {
            model: root.medium ? root.others : []
            Column {
                id: column
                required property var modelData
                width: (parent.width - 2 * parent.spacing) / 3
                FaceText {
                    visible: root.names
                    face: root
                    width: Math.min(implicitWidth, column.width)
                    text: column.modelData.name
                    color: root.inkTertiary
                    size: 11.5
                    weight: Font.DemiBold
                }
                FaceText {
                    face: root
                    text: column.modelData.time
                    color: column.modelData.isDay ? root.ink : root.inkSecondary
                    size: 17
                    weight: Font.Bold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
    FaceText {
        visible: root.first !== null && root.others.length === 0 && root.offsets
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2)
        text: root.dayWord(0) + " · " + (root.first?.offset ?? "")
        color: root.inkTertiary
        size: root.type(11.5, 12.5, 14)
    }
}
