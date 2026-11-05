pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

IrisWidgetFace {
    id: root
    designFace: IrisDesign.skin("widgetWeather")

    readonly property bool ready: Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")
    readonly property string glyph: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
    readonly property color sky: IrisStyle.skyLight(root.glyph)
    // The town, not its province: "Avellaneda, Bueno…" told less than "Avellaneda". Large has the room for both.
    readonly property string city: Weather.showVisibleCity
        ? (root.large ? Weather.visibleCity : String(Weather.visibleCity).split(",")[0].trim()) : ""
    readonly property string condition: IrisFaceData.capitalized(String(Weather.data?.description ?? ""))
    readonly property string range: {
        const high = root.degrees(Weather.data?.tempMax)
        const low = root.degrees(Weather.data?.tempMin)
        return high.length > 0 && low.length > 0 ? Translation.tr("H:%1  L:%2").arg(high).arg(low) : ""
    }
    readonly property var hours: Array.from(Weather.data?.hourly ?? []).slice(0, root.small ? 5 : 6)
    readonly property var days: Array.from(Weather.data?.forecast ?? []).slice(0, 5)
    readonly property var lows: root.days.map(day => Number(day.loVal)).filter(Number.isFinite)
    readonly property var highs: root.days.map(day => Number(day.hiVal)).filter(Number.isFinite)
    readonly property real weekLow: root.lows.length > 0 ? Math.min(...root.lows) : 0
    readonly property real weekHigh: root.highs.length > 0 ? Math.max(...root.highs) : 1
    // Pointing at an hour reads it out where the conditions are ("" = the conditions).
    property string readout: ""
    readonly property real humidity: Math.max(0, Math.min(100, parseFloat(String(Weather.data?.humidity ?? "0")) || 0))
    readonly property string wind: String(Weather.data?.wind ?? "").trim()
    // Where the wind goes, clockwise from up (the reading names where it comes from).
    readonly property real windTo: (({ N: 0, NNE: 22.5, NE: 45, ENE: 67.5, E: 90, ESE: 112.5, SE: 135, SSE: 157.5, S: 180,
        SSW: 202.5, SW: 225, WSW: 247.5, W: 270, WNW: 292.5, NW: 315, NNW: 337.5 })[String(Weather.data?.windDir ?? "N").toUpperCase()] ?? 0) + 180
    readonly property real uv: Math.max(0, parseFloat(String(Weather.data?.uv ?? "0")) || 0)
    readonly property string uvWord: root.uv < 3 ? Translation.tr("Low") : root.uv < 6 ? Translation.tr("Moderate")
        : root.uv < 8 ? Translation.tr("High") : root.uv < 11 ? Translation.tr("Very high") : Translation.tr("Extreme")

    function degrees(value: var): string {
        const text = String(value ?? "").trim()
        if (text.length === 0 || text.startsWith("--"))
            return ""
        return text.replace(/°[CF]$/, "°").replace(/([0-9])$/, "$1°")
    }

    light: root.ready ? root.sky : "transparent"

    // Poster (his 11-04 reference): the forecast set as a poster sets it, one tall condensed figure, the place in spaced
    // capitals over the sky in heavy condensed capitals, and the coming hours as one capsule.
    readonly property bool poster: String(root.widget.familyOption("face", "classic")) === "poster"
    readonly property string condensed: "Google Sans Flex" // iris-literal: the poster figure needs a width axis
    readonly property string figure: {
        const value = parseFloat(String(Weather.data?.temp ?? ""))
        return Number.isFinite(value) ? String(Math.round(value)) : "--"
    }

    component Now: ColumnLayout {
        spacing: 0
        FaceText {
            face: root
            Layout.fillWidth: true
            visible: root.city.length > 0
            text: root.city
            size: 13.5
            weight: Font.DemiBold
        }
        FaceFigure {
            face: root
            Layout.fillWidth: true
            text: root.widget.temperatureText
            size: root.large ? 50 : 44
        }
    }

    component Condition: ColumnLayout {
        // medium reads it on the right, under nothing, as Apple's medium weather does
        property bool trailing: false
        spacing: root.dp(1)
        MaterialSymbol {
            Layout.alignment: parent.trailing ? Qt.AlignRight : Qt.AlignLeft
            text: root.glyph
            fill: 1
            iconSize: root.px(20)
            color: root.sky
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            horizontalAlignment: parent.trailing ? Text.AlignRight : Text.AlignLeft
            text: root.readout.length > 0 ? root.readout : root.condition
            size: 12.5
            weight: Font.DemiBold
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            horizontalAlignment: parent.trailing ? Text.AlignRight : Text.AlignLeft
            visible: root.range.length > 0 || Weather.stale
            text: !Weather.stale ? root.range
                : !Network.online ? Translation.tr("Offline · %1").arg(Weather.updatedLabel)
                : Translation.tr("Updated %1").arg(Weather.updatedLabel)
            color: Weather.stale ? root.inkTertiary : root.inkSecondary
            size: 12
        }
    }

    // The next hours drawn as the Day draws the sun: the temperature as a line with the warm fade, each hour's figure
    // above its point, and a sky mark only where it rains or snows (a glyph per hour said "cloud" six times).
    readonly property var wet: ["rainy", "thunderstorm", "weather_hail", "weather_snowy", "cloudy_snowing"]
    component Hours: Item {
        id: graph
        readonly property int n: root.hours.length
        readonly property var temps: {
            const out = []
            for (const hour of root.hours) {
                const value = parseFloat(String(hour.temp))
                out.push(Number.isFinite(value) ? value : out.length > 0 ? out[out.length - 1] : 0)
            }
            return out
        }
        readonly property real lo: graph.temps.length > 0 ? Math.min(...graph.temps) : 0
        readonly property real hi: graph.temps.length > 0 ? Math.max(...graph.temps) : 1
        // The line keeps to the lower part, so the figures above it have room.
        function level(i: int): real {
            return 0.12 + 0.5 * (graph.hi > graph.lo ? (graph.temps[i] - graph.lo) / (graph.hi - graph.lo) : 0.5)
        }
        function at(i: int): real { return (i + 0.5) / Math.max(1, graph.n) }
        readonly property var levels: graph.temps.map((value, i) => graph.level(i))
        function curve(t: real): real { return IrisFaceData.smooth(graph.levels, t) }
        implicitHeight: root.dp(root.large ? 76 : 64)

        FaceArea {
            id: line
            face: root
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: when.top
            anchors.bottomMargin: root.dp(4)
            curve: t => graph.curve(t)
            tint: root.warm
            guide: false
        }
        Repeater {
            model: root.hours
            Row {
                id: point
                required property var modelData
                required property int index
                readonly property string glyph: Icons.getWeatherIcon(point.modelData.code, point.modelData.isNight) ?? "cloud"
                x: Math.round(graph.at(point.index) * graph.width - width / 2)
                y: Math.round(line.y + line.yAt(graph.at(point.index)) - height - root.dp(3))
                spacing: root.dp(2)
                MaterialSymbol {
                    visible: root.wet.includes(point.glyph)
                    anchors.verticalCenter: parent.verticalCenter
                    text: point.glyph
                    fill: 1
                    iconSize: root.px(13)
                    color: IrisStyle.skyLight(point.glyph)
                }
                FaceText {
                    face: root
                    text: root.degrees(point.modelData.temp)
                    color: point.index === 0 ? root.ink : root.inkSecondary
                    size: 12.5
                    weight: Font.DemiBold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
        RowLayout {
            id: when
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0
            Repeater {
                model: root.hours
                FaceText {
                    id: hour
                    required property var modelData
                    required property int index
                    face: root
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignHCenter
                    text: hour.index === 0 ? Translation.tr("Now") : String(hour.modelData.label).slice(0, 5)
                    color: hour.index === 0 ? root.ink : root.inkTertiary
                    size: 10.5
                    weight: hour.index === 0 ? Font.DemiBold : Font.Medium
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
        // Pointing at an hour reads it out where the conditions are.
        Row {
            anchors.fill: parent
            Repeater {
                model: root.hours
                Item {
                    id: zone
                    required property var modelData
                    required property int index
                    width: graph.width / Math.max(1, graph.n)
                    height: graph.height
                    HoverHandler {
                        id: hourHover
                        onHoveredChanged: {
                            if (hourHover.hovered)
                                root.readout = Translation.tr("%1 · %2 · %3").arg(zone.index === 0 ? Translation.tr("Now") : String(zone.modelData.label).slice(0, 5))
                                    .arg(root.degrees(zone.modelData.temp)).arg(IrisFaceData.capitalized(Weather.describeWeather(zone.modelData.code, zone.modelData.isNight)))
                            else if (root.readout.length > 0)
                                root.readout = ""
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        visible: !root.ready
        anchors.centerIn: parent
        width: parent.width
        spacing: root.dp(6)
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "cloud_off"
            iconSize: root.px(28)
            color: root.inkTertiary
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: !Weather.enabled ? Translation.tr("Weather is off")
                : !Network.online ? Network.offlineReason
                : Translation.tr("Looking for the sky…")
            color: root.inkSecondary
            size: 12.5
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }

    ColumnLayout {
        visible: root.ready && root.small && !root.poster
        anchors.fill: parent
        spacing: 0
        Now { Layout.fillHeight: false; Layout.fillWidth: true }
        Item { Layout.fillHeight: true }
        Condition { Layout.fillHeight: false; Layout.fillWidth: true }
    }

    ColumnLayout {
        visible: root.ready && root.medium && !root.poster
        anchors.fill: parent
        spacing: 0
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(12)
            Now {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
            }
            Condition {
                trailing: true
                Layout.preferredWidth: root.contentWidth * 0.42
                Layout.alignment: Qt.AlignTop
            }
        }
        Hours { Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: root.dp(6) }
    }

    ColumnLayout {
        visible: root.ready && root.large && !root.poster
        anchors.fill: parent
        spacing: root.dp(10)

        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(12)
            Now { Layout.fillWidth: true; Layout.alignment: Qt.AlignTop }
            Condition { Layout.preferredWidth: root.contentWidth * 0.42; Layout.alignment: Qt.AlignBottom }
        }
        Hours { Layout.fillWidth: true }
        // The air as three facts: humidity, the wind with an arrow to where it goes, the UV index in a word.
        RowLayout {
            visible: Boolean(root.widget.familyOption("details", true))
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(12)
            Repeater {
                model: [
                    { glyph: "water_drop", text: Math.round(root.humidity) + "%", turn: 0 },
                    { glyph: "navigation", text: root.wind, turn: root.windTo },
                    { glyph: "wb_sunny", text: Translation.tr("UV %1 · %2").arg(Math.round(root.uv)).arg(root.uvWord), turn: 0 }
                ]
                RowLayout {
                    id: fact
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: root.dp(4)
                    MaterialSymbol {
                        text: fact.modelData.glyph
                        fill: 1
                        iconSize: root.px(13)
                        rotation: fact.modelData.turn
                        color: root.inkSecondary
                    }
                    FaceText {
                        face: root
                        Layout.fillWidth: true
                        text: fact.modelData.text
                        size: 12
                        color: root.inkSecondary
                        font.features: ({ "tnum": 1 })
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.hairline
        }
        Repeater {
            model: root.days
            RowLayout {
                id: day
                required property var modelData
                readonly property string glyph: Icons.getWeatherIcon(day.modelData.code, false) ?? "cloud"
                readonly property real span: Math.max(1, root.weekHigh - root.weekLow)
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.dp(10)
                FaceText {
                    face: root
                    Layout.preferredWidth: root.contentWidth * 0.24
                    text: IrisFaceData.capitalized(day.modelData.dayName)
                    size: 13
                    weight: Font.DemiBold
                }
                MaterialSymbol {
                    Layout.preferredWidth: root.px(22)
                    text: day.glyph
                    fill: 1
                    iconSize: root.px(18)
                    color: IrisStyle.skyLight(day.glyph)
                }
                FaceText {
                    face: root
                    Layout.preferredWidth: root.px(30)
                    horizontalAlignment: Text.AlignRight
                    text: root.degrees(day.modelData.lo)
                    color: root.inkSecondary
                    size: 13
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.dp(5)
                    radius: IrisStyle.capsule(height)
                    color: root.fill
                    Rectangle {
                        x: parent.width * (Number(day.modelData.loVal) - root.weekLow) / day.span
                        width: Math.max(parent.height, parent.width * (Number(day.modelData.hiVal) - Number(day.modelData.loVal)) / day.span)
                        height: parent.height
                        radius: IrisStyle.capsule(height)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.inked(IrisStyle.identity.sky) }
                            GradientStop { position: 1; color: root.inked(IrisStyle.identity.orange) }
                        }
                    }
                }
                FaceText {
                    face: root
                    Layout.preferredWidth: root.px(30)
                    text: root.degrees(day.modelData.hi)
                    size: 13
                    weight: Font.DemiBold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    // The hours as one capsule, as the poster's timeline: now at its start (the sun, or the moon after dark), a dark
    // seam where the day turns, the low and the high written into it where they fall, the hours under it.
    component Timeline: ColumnLayout {
        id: line
        readonly property var temps: root.hours.map(hour => parseFloat(String(hour.temp)))
        readonly property var known: line.temps.filter(Number.isFinite)
        readonly property int low: line.known.length > 1 ? line.temps.indexOf(Math.min(...line.known)) : -1
        readonly property int high: line.known.length > 1 ? line.temps.indexOf(Math.max(...line.known)) : -1
        readonly property int n: Math.max(1, root.hours.length)
        function hourOf(slot: var): int { return parseInt(String(slot?.label ?? "0").slice(0, 2), 10) }
        function at(i: int): real { return (i + 0.5) / line.n }
        function label(i: int): string {
            if (i === 0) return Translation.tr("Now").toUpperCase()
            const hour = line.hourOf(root.hours[i])
            return Translation.locale.timeFormat(Locale.ShortFormat).indexOf("AP") >= 0 || Translation.locale.timeFormat(Locale.ShortFormat).indexOf("ap") >= 0
                ? (hour % 12 === 0 ? 12 : hour % 12) + (hour === 0 ? "A" : hour === 12 ? "P" : "")
                : String(hour)
        }
        spacing: root.dp(5)
        Rectangle {
            id: track
            Layout.fillWidth: true
            implicitHeight: root.dp(root.small ? 26 : 34)
            radius: IrisStyle.capsule(height)
            color: root.fill
            clip: true
            // night hours sit a step darker, so the evening reads before any figure
            Repeater {
                model: root.hours
                Rectangle {
                    required property var modelData
                    required property int index
                    visible: Boolean(modelData.isNight)
                    x: track.width * index / line.n
                    width: Math.ceil(track.width / line.n)
                    height: track.height
                    color: root.fillQuiet
                }
            }
            Repeater {
                model: root.hours
                Rectangle {
                    required property var modelData
                    required property int index
                    visible: index > 0 && line.hourOf(modelData) < line.hourOf(root.hours[index - 1])
                    x: Math.round(track.width * index / line.n - width / 2)
                    width: root.dp(5)
                    height: track.height
                    color: root.ink
                    opacity: 0.85
                }
            }
            MaterialSymbol {
                x: Math.round(track.width * line.at(0) - width / 2)
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.isNightNow() ? "contrast" : "wb_sunny"
                fill: 1
                iconSize: Math.round(track.height * 0.52)
                color: root.ink
            }
            Repeater {
                model: [line.low, line.high].filter(i => i > 0)
                Text {
                    required property int modelData
                    x: Math.round(Math.max(track.height * 0.4, Math.min(track.width - width - track.height * 0.4, track.width * line.at(modelData) - width / 2)))
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(Math.round(line.temps[modelData]))
                    color: root.ink
                    font.family: root.condensed
                    font.variableAxes: ({ "wdth": 25, "wght": 780, "opsz": 36 })
                    font.pixelSize: Math.round(track.height * 0.78)
                    renderType: Text.QtRendering
                }
            }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: root.px(12)
            Repeater {
                model: root.hours
                Text {
                    required property int index
                    visible: !root.small || index % 2 === 0
                    x: Math.round(Math.max(0, Math.min(parent.width - width, parent.width * line.at(index) - width / 2)))
                    text: line.label(index)
                    color: root.inkTertiary
                    font.family: root.condensed
                    font.variableAxes: ({ "wdth": 62, "wght": 560, "opsz": 14 })
                    font.pixelSize: root.px(11)
                    font.letterSpacing: root.dp(0.6)
                    renderType: Text.QtRendering
                }
            }
        }
    }

    ColumnLayout {
        visible: root.ready && root.poster
        anchors.fill: parent
        spacing: root.dp(root.small ? 6 : 12)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: root.small
            spacing: root.dp(root.small ? 8 : 12)
            Text {
                id: posterFigure
                Layout.alignment: Qt.AlignTop
                text: root.figure
                color: root.ink
                font.family: root.condensed
                font.variableAxes: ({ "wdth": 25, "wght": 820, "opsz": 144 })
                font.pixelSize: Math.round(root.px(root.small ? 66 : root.large ? 96 : 84))
                lineHeight: 0.78
                renderType: Text.QtRendering
                font.features: ({ "tnum": 1 })
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: root.dp(4)
                Layout.fillWidth: true
                spacing: root.dp(2)
                FaceText {
                    face: root
                    Layout.fillWidth: true
                    visible: root.city.length > 0
                    text: root.city.split(",")[0].trim().toUpperCase()
                    color: root.inkSecondary
                    size: root.small ? 9.5 : 11
                    weight: Font.Medium
                    font.letterSpacing: root.dp(2.2)
                }
                Text {
                    Layout.fillWidth: true
                    text: (root.readout.length > 0 ? root.readout : root.condition).toUpperCase()
                    color: root.ink
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: root.condensed
                    font.variableAxes: ({ "wdth": 30, "wght": 780, "opsz": 48 })
                    font.pixelSize: root.px(root.small ? 17 : root.large ? 30 : 26)
                    lineHeight: 0.9
                    renderType: Text.QtRendering
                }
            }
            MaterialSymbol {
                visible: !root.small
                Layout.alignment: Qt.AlignTop
                text: root.glyph
                fill: 1
                iconSize: Math.round(posterFigure.height * 0.86)
                color: root.nothing ? root.ink : root.sky
            }
        }
        Timeline {
            Layout.fillWidth: true
            visible: root.hours.length > 1
        }
        // Large carries the week under it the same way: each day a condensed line, its span a capsule.
        Repeater {
            model: root.large ? root.days : []
            RowLayout {
                id: posterDay
                required property var modelData
                readonly property real span: Math.max(1, root.weekHigh - root.weekLow)
                Layout.fillWidth: true
                spacing: root.dp(10)
                Text {
                    Layout.preferredWidth: root.contentWidth * 0.22
                    text: String(posterDay.modelData.dayName ?? "").toUpperCase()
                    color: root.inkSecondary
                    font.family: root.condensed
                    font.variableAxes: ({ "wdth": 40, "wght": 700, "opsz": 24 })
                    font.pixelSize: root.px(17)
                    renderType: Text.QtRendering
                }
                MaterialSymbol {
                    text: Icons.getWeatherIcon(posterDay.modelData.code, false) ?? "cloud"
                    fill: 1
                    iconSize: root.px(17)
                    color: root.nothing ? root.ink : IrisStyle.skyLight(text)
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: root.dp(6)
                    radius: IrisStyle.capsule(height)
                    color: root.fill
                    Rectangle {
                        x: parent.width * (Number(posterDay.modelData.loVal) - root.weekLow) / posterDay.span
                        width: Math.max(parent.height, parent.width * (Number(posterDay.modelData.hiVal) - Number(posterDay.modelData.loVal)) / posterDay.span)
                        height: parent.height
                        radius: parent.radius
                        color: root.ink
                    }
                }
                Text {
                    text: Math.round(Number(posterDay.modelData.loVal)) + " " + Math.round(Number(posterDay.modelData.hiVal))
                    color: root.ink
                    font.family: root.condensed
                    font.variableAxes: ({ "wdth": 30, "wght": 760, "opsz": 24 })
                    font.pixelSize: root.px(18)
                    font.features: ({ "tnum": 1 })
                    renderType: Text.QtRendering
                }
            }
        }
        Item { Layout.fillHeight: !root.small }
    }
}
