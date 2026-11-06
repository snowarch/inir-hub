pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Tiles · Pair: hour and minutes as two halves of one bar, the hour lit, a hair between them; a figure rolls over when it
// changes. The day sits beside them as a small date stamp. Which tile is lit and the stamp are the person's
// (iris.bar.faces.tiles).
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

    readonly property var parts: IrisFaceData.clockParts(DateTime.timeDisplay)
    // A slim strip gives the tiles the height and the day one line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)
    readonly property real tileH: Math.round(root.h - (root.stacks ? 12 : 6) * root.d)
    readonly property real tileW: Math.round(root.figure * 1.7)
    readonly property color lit: root.island?.nothingLook ? IrisStyle.text : root.mark
    readonly property var options: Config.options?.iris?.bar?.faces?.tiles ?? ({})
    readonly property string lights: ["hour", "minutes", "both"].includes(String(root.options.lit)) ? String(root.options.lit) : "hour"
    readonly property bool hourLit: root.lights !== "minutes"
    readonly property bool minutesLit: root.lights !== "hour"
    readonly property int outer: Math.min(IrisStyle.radiusTile, Math.round(root.tileH * 0.42))

    // The figure on a tile: the new one rolls up as the old one leaves.
    component Roller: Item {
        id: roller
        property string value
        property color ink
        property string shown: value
        property string leaving: ""
        property real at: 1
        implicitWidth: incoming.implicitWidth
        implicitHeight: incoming.implicitHeight
        clip: true
        onValueChanged: {
            if (!IrisStyle.motionEnabled) { shown = value; at = 1; return }
            leaving = shown
            shown = value
            turn.restart()
        }
        SmoothedAnimation { id: turn; target: roller; property: "at"; from: 0; to: 1; duration: IrisStyle.duration(360); velocity: -1 }
        IrisText {
            visible: roller.at < 1
            transform: Translate { y: -roller.at * roller.height }
            text: roller.leaving
            font: incoming.font
            color: roller.ink
        }
        IrisText {
            id: incoming
            transform: Translate { y: (1 - roller.at) * roller.height }
            text: roller.shown
            font.pixelSize: root.figure
            font.family: root.face
            font.weight: IrisStyle.weight(Font.Bold)
            font.features: ({ "tnum": 1 })
            color: roller.ink
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(2 * root.d))
            Rectangle {
                width: root.tileW
                height: root.tileH
                color: root.hourLit ? root.lit : IrisStyle.fillQuiet
                topLeftRadius: root.outer
                bottomLeftRadius: root.outer
                topRightRadius: IrisStyle.radiusMicro
                bottomRightRadius: IrisStyle.radiusMicro
                Roller {
                    anchors.centerIn: parent
                    value: root.parts.hours
                    ink: root.hourLit ? IrisStyle.onTintFor(root.lit) : IrisStyle.text
                }
            }
            Rectangle {
                width: Math.max(root.tileW, minutes.width + Math.round(16 * root.d))
                height: root.tileH
                color: root.minutesLit ? root.lit : IrisStyle.fillQuiet
                topLeftRadius: IrisStyle.radiusMicro
                bottomLeftRadius: IrisStyle.radiusMicro
                topRightRadius: root.outer
                bottomRightRadius: root.outer
                Row {
                    id: minutes
                    anchors.centerIn: parent
                    spacing: Math.round(2 * root.d)
                    Roller {
                        anchors.verticalCenter: parent.verticalCenter
                        value: root.parts.minutes
                        ink: root.minutesLit ? IrisStyle.onTintFor(root.lit) : IrisStyle.text
                    }
                    IrisText {
                        visible: root.parts.period.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.parts.period
                        font.pixelSize: IrisStyle.typeCaption
                        font.weight: IrisStyle.weight(Font.Bold)
                        color: root.minutesLit ? IrisStyle.onTintFor(root.lit) : IrisStyle.textSecondary
                    }
                }
            }
        }
        Grid {
            visible: root.options.day !== false
            anchors.verticalCenter: parent.verticalCenter
            columns: root.stacks ? 1 : 2
            columnSpacing: Math.round(4 * root.d)
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            IrisText {
                text: Translation.locale.toString(root.now, "ddd").replace(/\./g, "")
                font.pixelSize: IrisStyle.typeCaption
                font.weight: IrisStyle.weight(Font.DemiBold)
                color: IrisStyle.textSecondary
            }
            IrisText {
                text: Translation.locale.toString(root.now, "d")
                font.pixelSize: IrisStyle.typeLabel
                font.family: root.face
                font.weight: IrisStyle.weight(Font.Bold)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.text
            }
        }
    }
}
