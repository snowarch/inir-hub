pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Marquee · Bulletin: beside the time, one fact of your day at a time: the next event, the weather, the sun, the date. A
// new one rolls in when the minute turns; nothing moves between, and the width holds so the Island stays still.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property int minute: Math.floor(root.now.getTime() / 60000)
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth

    readonly property var entry: IrisFaceData.nextEntry(root.minute * 60000, 180)
    readonly property bool weatherReady: Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")
    readonly property var facts: {
        const now = new Date(root.minute * 60000)
        const night = Weather.isNightNow()
        const list = []
        if (root.entry.title.length > 0) list.push({ glyph: "event", text: root.entry.title, note: root.entry.when })
        if (root.weatherReady)
            list.push({ glyph: Icons.getWeatherIcon(Weather.data?.wCode, night) ?? "cloud",
                text: (String(Weather.data?.temp ?? "").match(/-?\d+(?:[.,]\d+)?/) ?? [""])[0] + "°", note: String(Weather.data?.description ?? "") })
        const sun = IrisFaceData.dayShare(night ? Weather.data?.sunrise : Weather.data?.sunset)
        if (sun >= 0) {
            const at = new Date(now)
            at.setHours(0, Math.round(sun * 1440), 0, 0)
            list.push({ glyph: "wb_twilight", text: night ? Translation.tr("Sunrise") : Translation.tr("Sunset"), note: IrisFaceData.clockText(at) })
        }
        list.push({ glyph: "calendar_today", text: Translation.locale.toString(now, "dddd d"), note: "" })
        return list
    }
    readonly property var fact: root.facts[root.minute % root.facts.length]
    readonly property string factKey: root.fact.glyph + root.fact.text + root.fact.note
    property var leaving: null
    property var held: root.fact
    property real at: 1
    onFactKeyChanged: {
        if (IrisStyle.motionEnabled) {
            root.leaving = root.held
            roll.restart()
        }
        root.held = root.fact
    }
    SmoothedAnimation { id: roll; target: root; property: "at"; from: 0; to: 1; duration: IrisStyle.duration(420); velocity: -1 }

    component Line: Row {
        id: line
        property var fact: null
        spacing: Math.round(6 * root.d)
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: line.fact?.glyph ?? ""
            iconSize: Math.round(16 * root.d)
            fill: 1
            color: root.mark
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.round(130 * root.d))
            text: line.fact?.text ?? ""
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
            color: IrisStyle.text
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: line.fact?.note ?? ""
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.Medium)
            font.features: ({ "tnum": 1 })
            color: IrisStyle.textSecondary
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(root.h * 0.42)
            color: IrisStyle.textTertiary
        }
        Item {
            id: stage
            anchors.verticalCenter: parent.verticalCenter
            width: measure.implicitWidth
            height: Math.round(root.h - 8 * root.d)
            clip: true
            // The widest fact holds the Island's width through the day.
            Column {
                id: measure
                opacity: 0
                Repeater {
                    model: root.facts
                    Line {
                        required property var modelData
                        fact: modelData
                    }
                }
            }
            Line {
                visible: root.at < 1
                y: Math.round((stage.height - height) / 2)
                transform: Translate { y: -root.at * stage.height }
                opacity: 1 - root.at
                fact: root.leaving
            }
            Line {
                y: Math.round((stage.height - height) / 2)
                transform: Translate { y: (1 - root.at) * stage.height }
                fact: root.held
            }
        }
    }
}
