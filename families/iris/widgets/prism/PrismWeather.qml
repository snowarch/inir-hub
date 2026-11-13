pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// The weather in Prism: the sky's mark and the town on the tab, the day's high and low on the flap lit in the sky's
// colour, the temperature in the pane, the coming hours on the foot (large adds the days).
PrismFolder {
    id: root

    readonly property bool ready: Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")
    readonly property string glyph: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
    readonly property color sky: root.skyOf(root.glyph)
    readonly property string city: Weather.showVisibleCity ? String(Weather.visibleCity).split(",")[0].trim() : ""
    readonly property string condition: IrisFaceData.capitalized(String(Weather.data?.description ?? ""))
    readonly property string high: root.degrees(Weather.data?.tempMax)
    readonly property string low: root.degrees(Weather.data?.tempMin)
    readonly property var hours: Array.from(Weather.data?.hourly ?? []).slice(0, root.small ? 0 : 6)
    readonly property var days: Array.from(Weather.data?.forecast ?? []).slice(0, root.large ? 3 : 0)
    readonly property var lows: root.days.map(day => Number(day.loVal)).filter(Number.isFinite)
    readonly property var highs: root.days.map(day => Number(day.hiVal)).filter(Number.isFinite)
    readonly property real weekLow: root.lows.length > 0 ? Math.min(...root.lows) : 0
    readonly property real weekHigh: root.highs.length > 0 ? Math.max(...root.highs) : 1
    readonly property string figure: {
        const value = parseFloat(String(Weather.data?.temp ?? ""))
        return Number.isFinite(value) ? String(Math.round(value)) : "--"
    }
    readonly property string feels: root.degrees(Weather.data?.tempFeelsLike)
    function degrees(value: var): string {
        const text = String(value ?? "").trim()
        if (text.length === 0 || text.startsWith("--"))
            return ""
        return text.replace(/°[CF]$/, "°").replace(/([0-9])$/, "$1°")
    }

    tabGlyph: root.ready ? root.glyph : "cloud"
    tabText: root.city.length > 0 ? root.city : Translation.tr("Weather")
    flapText: !root.ready || root.high.length === 0 ? "" : root.small ? root.high + " / " + root.low
        : Translation.tr("H:%1  L:%2").arg(root.high).arg(root.low)
    shelf: root.nothing ? root.signal : root.ready ? root.sky : root.accent
    lightPass: root.ready ? 1 : 0.5

    // ── the pane: the temperature, and the sky beside it ──
    Row {
        id: now
        visible: root.ready
        x: root.inset
        y: Math.round(root.paneMiddle - number.height / 2)
        spacing: root.dp(1)
        FaceFigure {
            id: number
            face: root
            text: root.figure
            size: root.type(46, 56, 86)
        }
        FaceText {
            face: root
            y: Math.round(number.height * 0.12)
            text: "°"
            size: root.type(26, 32, 48)
            weight: Font.DemiBold
            color: root.inkSecondary
        }
    }
    Column {
        visible: root.ready
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        width: Math.min(root.pick(70, 160, 170), root.width - root.inset - now.x - now.width - root.dp(12))
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.dp(2)
        MaterialSymbol {
            anchors.right: parent.right
            text: root.glyph
            fill: 1
            iconSize: root.px(root.type(24, 26, 34))
            color: root.sky
        }
        FaceText {
            visible: !root.small
            anchors.right: parent.right
            width: Math.min(implicitWidth, parent.width)
            horizontalAlignment: Text.AlignRight
            face: root
            text: root.condition
            size: root.type(12, 13, 15)
            weight: Font.DemiBold
        }
        FaceText {
            visible: !root.small && root.feels.length > 0
            anchors.right: parent.right
            face: root
            text: Translation.tr("Feels like %1").arg(root.feels)
            color: root.inkSecondary
            size: root.type(11, 12, 13)
        }
    }
    FaceText {
        visible: !root.ready
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        text: !Weather.enabled ? Translation.tr("Weather is off")
            : !Network.online ? Network.offlineReason
            : Translation.tr("Looking for the sky…")
        color: root.inkSecondary
        size: root.type(12, 13, 15)
    }

    // ── the foot: small says the sky in words, medium and large the coming hours, large the days ──
    Column {
        visible: root.ready && root.small
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2)
        spacing: root.dp(1)
        FaceText {
            face: root
            width: parent.width
            text: root.condition
            size: 12.5
            weight: Font.DemiBold
        }
        FaceText {
            face: root
            width: parent.width
            visible: text.length > 0
            text: Weather.stale ? (!Network.online ? Translation.tr("Offline · %1").arg(Weather.updatedLabel)
                : Translation.tr("Updated %1").arg(Weather.updatedLabel))
                : root.feels.length > 0 ? Translation.tr("Feels like %1").arg(root.feels) : ""
            color: root.inkTertiary
            size: 11
        }
    }
    Row {
        id: coming
        visible: root.ready && root.hours.length > 0
        x: root.inset
        width: root.innerWidth
        y: root.large ? root.footTop + root.dp(18) : Math.round(root.footTop + (root.footHeight - height) / 2)
        Repeater {
            model: root.hours
            Column {
                id: hour
                required property var modelData
                required property int index
                readonly property string glyph: Icons.getWeatherIcon(hour.modelData.code, hour.modelData.isNight) ?? "cloud"
                width: coming.width / Math.max(1, root.hours.length)
                spacing: root.dp(3)
                FaceText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    face: root
                    text: hour.index === 0 ? Translation.tr("Now") : String(hour.modelData.label).slice(0, 5)
                    color: hour.index === 0 ? root.ink : root.inkTertiary
                    size: root.type(10.5, 10.5, 11.5)
                    weight: hour.index === 0 ? Font.DemiBold : Font.Medium
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: hour.glyph
                    fill: 1
                    iconSize: root.px(root.type(14, 15, 18))
                    color: root.skyOf(hour.glyph)
                }
                FaceText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    face: root
                    text: root.degrees(hour.modelData.temp)
                    color: hour.index === 0 ? root.ink : root.inkSecondary
                    size: root.type(12, 12.5, 14)
                    weight: Font.DemiBold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
    Repeater {
        model: root.ready ? root.days : []
        Item {
            id: day
            required property var modelData
            required property int index
            readonly property real span: Math.max(1, root.weekHigh - root.weekLow)
            readonly property string glyph: Icons.getWeatherIcon(day.modelData.code, false) ?? "cloud"
            x: root.inset
            width: root.innerWidth
            height: root.dp(28)
            y: coming.y + coming.height + root.dp(12) + day.index * height
            FaceText {
                id: dayName
                anchors.verticalCenter: parent.verticalCenter
                width: root.dp(56)
                face: root
                text: IrisFaceData.capitalized(day.modelData.dayName)
                size: 14
                weight: Font.DemiBold
            }
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                x: dayName.width
                text: day.glyph
                fill: 1
                iconSize: root.px(17)
                color: root.skyOf(day.glyph)
            }
            FaceText {
                id: dayLow
                anchors.verticalCenter: parent.verticalCenter
                x: dayName.width + root.dp(30)
                width: root.dp(34)
                horizontalAlignment: Text.AlignRight
                face: root
                text: root.degrees(day.modelData.lo)
                color: root.inkSecondary
                size: 13
                font.family: root.fontNumbers
                font.features: ({ "tnum": 1 })
            }
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                x: dayLow.x + dayLow.width + root.dp(10)
                width: parent.width - x - root.dp(44)
                height: root.dp(5)
                radius: height / 2
                color: root.fill
                Rectangle {
                    x: track.width * (Number(day.modelData.loVal) - root.weekLow) / day.span
                    width: Math.max(track.height, track.width * (Number(day.modelData.hiVal) - Number(day.modelData.loVal)) / day.span)
                    height: track.height
                    radius: height / 2
                    color: root.shelf
                }
            }
            FaceText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                face: root
                text: root.degrees(day.modelData.hi)
                size: 13
                weight: Font.DemiBold
                font.family: root.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
    }
}
