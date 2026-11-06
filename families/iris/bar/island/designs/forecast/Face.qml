pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Forecast · Hours: the time, then the next hours as the weather app's strip: now first, each hour its sky in colour
// and its temperature. It moves on once an hour, never each minute. Without weather the entry is the day. Short of room
// it shows fewer of the hours asked for, then lets go of their names: the Island never cuts one.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth
    // A slim strip lays each hour on one line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)

    readonly property var options: Config.options?.iris?.bar?.faces?.forecast ?? ({})
    // Hours shown, now included (iris.bar.faces.forecast.hours).
    readonly property int count: [2, 3, 4].includes(Number(root.options.hours)) ? Number(root.options.hours) : 3
    readonly property bool labels: root.options.labels !== false
    readonly property bool colour: root.options.colour !== false
    readonly property bool twelve: /ap/i.test(String(Config.options?.time?.format ?? "hh:mm"))
    readonly property int hour: Math.floor(root.now.getTime() / 3600000)
    readonly property bool sky: Weather.enabled && Weather.hasData && !String(Weather.data?.temp ?? "--").startsWith("--")
    readonly property real sunrise: IrisFaceData.dayShare(Weather.data?.sunrise)
    readonly property real sunset: IrisFaceData.dayShare(Weather.data?.sunset)

    function degrees(text: var): string {
        const figure = String(text ?? "").match(/-?\d+(?:[.,]\d+)?/)
        return figure ? Math.round(parseFloat(figure[0].replace(",", "."))) + "°" : ""
    }
    // Night by the real sun when the weather said when it rises and sets, else by the hour.
    function nightAt(at: var, fallback: bool): bool {
        if (root.sunrise < 0 || root.sunset < 0)
            return fallback
        const share = (at.getHours() * 60 + at.getMinutes()) / 1440
        return share < root.sunrise || share >= root.sunset
    }
    // Each sky in the colour it is known by: the sun yellow, rain and hail sky blue, a storm's bolt yellow; cloud, fog,
    // snow and the night stay in the text's own grey.
    function tintOf(glyph: string): color {
        if (!root.colour)
            return IrisStyle.textSecondary
        if (/clear_day|partly_cloudy_day|thunder/.test(glyph))
            return IrisStyle.identity.yellow
        if (/rain|hail/.test(glyph))
            return IrisStyle.identity.sky
        return IrisStyle.textSecondary
    }

    // The hours ahead, read against the day the weather was fetched (its slots carry only the hour).
    readonly property var cells: {
        void root.hour
        if (!root.sky)
            return []
        const now = new Date()
        const night = Weather.isNightNow()
        const glyph = Icons.getWeatherIcon(Weather.data?.wCode, night) ?? "cloud"
        const first = { label: Translation.tr("Now"), glyph: glyph, temp: root.degrees(Weather.data?.temp) }
        const base = new Date(Weather.lastUpdated)
        base.setHours(0, 0, 0, 0)
        const ahead = []
        let day = 0
        let last = -1
        for (const slot of Array.from(Weather.data?.hourly ?? [])) {
            const at = parseInt(String(slot?.label ?? "").split(":")[0])
            if (isNaN(at))
                continue
            if (at < last)
                day++
            last = at
            const when = new Date(base)
            when.setDate(base.getDate() + day)
            when.setHours(at, 0, 0, 0)
            if (when.getTime() <= now.getTime())
                continue
            const dark = root.nightAt(when, slot?.isNight ?? false)
            ahead.push({
                label: Translation.locale.toString(when, root.twelve ? "h AP" : "HH"),
                glyph: Icons.getWeatherIcon(slot?.code, dark) ?? "cloud",
                temp: root.degrees(slot?.temp)
            })
            if (ahead.length >= root.count - 1)
                break
        }
        return [first].concat(ahead)
    }

    // What the Island gives the face, and how many hours fit in it with their names or without.
    readonly property real room: root.island?.faceRoom ?? Math.round(291 * root.d)
    readonly property real glyphSize: Math.round((root.stacks ? 14 : 13) * root.d)
    FontMetrics {
        id: labelMetrics
        font.family: IrisStyle.fontMain
        font.pixelSize: IrisStyle.typeCaption
        font.weight: IrisStyle.weight(Font.Bold)
        font.features: ({ "tnum": 1 })
    }
    FontMetrics {
        id: tempMetrics
        font.family: IrisStyle.fontMain
        font.pixelSize: root.stacks ? IrisStyle.typeMeta : IrisStyle.typeFootnote
        font.weight: IrisStyle.weight(Font.DemiBold)
        font.features: ({ "tnum": 1 })
    }
    function cellWidth(cell: var, named: bool): real {
        const sky = root.glyphSize + Math.round(2 * root.d) + Math.ceil(tempMetrics.advanceWidth(String(cell.temp)))
        if (!named)
            return sky
        const label = Math.ceil(labelMetrics.advanceWidth(String(cell.label)))
        return root.stacks ? Math.max(label, sky) : label + Math.round(5 * root.d) + sky
    }
    readonly property var fitting: {
        if (labelMetrics.font.pixelSize <= 0 || tempMetrics.font.pixelSize <= 0)
            return { count: root.cells.length, named: root.labels }
        const lead = clock.implicitWidth + 2 * row.spacing + 1
        const take = named => {
            let used = lead
            let n = 0
            for (const cell of root.cells) {
                const add = (n > 0 ? strip.spacing : 0) + root.cellWidth(cell, named)
                if (n > 0 && used + add > root.room)
                    break
                used += add
                n++
            }
            return n
        }
        if (root.labels) {
            const named = take(true)
            if (named >= Math.min(2, root.cells.length))
                return { count: named, named: true }
        }
        return { count: take(false), named: false }
    }
    readonly property var shownCells: root.cells.slice(0, root.fitting.count)

    // A new hour slides the strip in; the time beside it stays put.
    onHourChanged: if (IrisStyle.motionEnabled && root.sky) comes.restart()
    ParallelAnimation {
        id: comes
        SmoothedAnimation { target: arrival; property: "y"; from: Math.round(6 * root.d); to: 0; duration: IrisStyle.duration(360); velocity: -1 }
        SmoothedAnimation { target: strip; property: "opacity"; from: 0; to: 1; duration: IrisStyle.duration(360); velocity: -1 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        IrisClock {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(root.h * 0.46)
            color: IrisStyle.hairlineStrong
        }
        Row {
            id: strip
            visible: root.cells.length > 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(12 * root.d)
            transform: Translate { id: arrival }
            Repeater {
                model: root.shownCells
                Grid {
                    id: cell
                    required property var modelData
                    required property int index
                    columns: root.stacks ? 1 : 2
                    columnSpacing: Math.round(5 * root.d)
                    rowSpacing: 0
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter
                    IrisText {
                        visible: root.fitting.named
                        text: cell.modelData.label
                        font.pixelSize: IrisStyle.typeCaption
                        font.weight: IrisStyle.weight(cell.index === 0 ? Font.Bold : Font.Medium)
                        font.features: ({ "tnum": 1 })
                        color: cell.index === 0 ? IrisStyle.text : IrisStyle.textTertiary
                    }
                    Row {
                        spacing: Math.round(2 * root.d)
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.modelData.glyph
                            fill: 1
                            iconSize: root.glyphSize
                            color: root.tintOf(cell.modelData.glyph)
                        }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.modelData.temp
                            font.pixelSize: root.stacks ? IrisStyle.typeMeta : IrisStyle.typeFootnote
                            font.weight: IrisStyle.weight(Font.DemiBold)
                            font.features: ({ "tnum": 1 })
                            color: IrisStyle.text
                        }
                    }
                }
            }
        }
        // No weather: the day, as Ledger keeps it.
        Grid {
            visible: root.cells.length === 0
            anchors.verticalCenter: parent.verticalCenter
            columns: root.stacks ? 1 : 2
            columnSpacing: Math.round(6 * root.d)
            verticalItemAlignment: Grid.AlignVCenter
            IrisText {
                text: IrisFaceData.capitalized(Translation.locale.toString(root.now, "dddd"))
                font.pixelSize: root.stacks ? IrisStyle.typeMeta : IrisStyle.typeFootnote
                font.weight: IrisStyle.weight(Font.DemiBold)
                color: IrisStyle.text
            }
            IrisText {
                text: Translation.locale.toString(root.now, "d MMMM")
                font.pixelSize: IrisStyle.typeCaption
                font.weight: IrisStyle.weight(Font.Medium)
                color: IrisStyle.textSecondary
            }
        }
    }
}
