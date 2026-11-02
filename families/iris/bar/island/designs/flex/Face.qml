pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Flex: the time set big in a variable face, with nothing else. The hour stands in its heaviest cut; the minutes are born
// a hairline and gain ink until the hour turns, so how thick they are says how far through the hour you are.
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

    readonly property var parts: IrisFaceData.clockParts(DateTime.timeDisplay)
    readonly property real ink: Math.min(59, Number(root.parts.minutes) || 0) / 59
    readonly property real size: Math.round(root.h * 0.8)
    readonly property string family: IrisStyle.fontMain
    readonly property real contentWidth: row.implicitWidth

    component Figure: Text {
        font.family: root.family
        font.pixelSize: root.size
        font.features: ({ "tnum": 1 })
        renderType: Text.CurveRendering
        color: IrisStyle.text
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(4 * root.d)
        Figure {
            anchors.verticalCenter: parent.verticalCenter
            text: root.parts.hours
            font.variableAxes: ({ "wght": 1000, "ROND": 100, "opsz": 144 })
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(5 * root.d)
            height: width
            radius: width / 2
            color: root.mark
            // A plumb: it falls through the height of the figures as the hour goes by.
            transform: Translate {
                y: Math.round((root.ink - 0.5) * root.size * 0.56)
                Behavior on y { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(420); velocity: -1 } }
            }
        }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: heaviest.implicitWidth
            height: heaviest.implicitHeight
            Figure {
                id: heaviest
                opacity: 0
                text: "88"
                font.variableAxes: ({ "wght": 1000, "ROND": 100, "opsz": 144 })
            }
            Figure {
                anchors.left: parent.left
                text: root.parts.minutes
                font.variableAxes: ({ "wght": 40 + 960 * root.ink, "ROND": 100, "opsz": 144 })
            }
        }
    }
}
