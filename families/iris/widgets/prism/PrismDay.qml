pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// The Day in Prism: what comes next on the tab (sunset, sunrise), its hour on the flap, the sun's path across the pane
// with the sun on it where the beam breaks, the other turn of the day and its daylight on the foot.
PrismFolder {
    id: root

    readonly property real fraction: root.widget.dayFraction
    readonly property real sunriseAt: IrisFaceData.dayShare(Weather.data?.sunrise)
    readonly property real sunsetAt: IrisFaceData.dayShare(Weather.data?.sunset)
    readonly property bool sunKnown: root.sunriseAt >= 0 && root.sunsetAt > root.sunriseAt
    readonly property real sunrise: root.sunKnown ? root.sunriseAt : 6 / 24
    readonly property real sunset: root.sunKnown ? root.sunsetAt : 19 / 24
    readonly property bool daytime: root.fraction >= root.sunrise && root.fraction < root.sunset
    readonly property var sunriseFact: ({ name: Translation.tr("Sunrise"), time: String(Weather.data?.sunrise ?? "") })
    readonly property var sunsetFact: ({ name: Translation.tr("Sunset"), time: String(Weather.data?.sunset ?? "") })
    readonly property var next: root.daytime ? root.sunsetFact : root.sunriseFact
    readonly property var other: root.daytime ? root.sunriseFact : root.sunsetFact
    function span(minutes: int): string {
        const hours = Math.floor(minutes / 60)
        return hours > 0 ? Translation.tr("%1 h %2 min").arg(hours).arg(minutes % 60) : Translation.tr("%1 min").arg(minutes)
    }
    readonly property string daylight: root.span(Math.round((root.sunset - root.sunrise) * 1440))
    readonly property var figure: IrisFaceData.timeParts(root.sunKnown ? root.next.time
        : root.span(Math.max(0, Math.round((1 - root.fraction) * 1440))))
    readonly property var otherParts: IrisFaceData.timeParts(root.other.time)

    tabGlyph: root.daytime ? "light_mode" : "dark_mode"
    tabText: root.sunKnown ? root.next.name : Translation.tr("Until midnight")
    flapText: root.figure.main
    flapSuffix: root.figure.suffix
    shelf: root.nothing ? root.signal : root.warm
    prism: Qt.point(sky.x + sun.x + sun.width / 2, sky.y + sun.y + sun.height / 2)

    // ── the pane: the sun's path, and the sun ──
    FaceSunPath {
        id: sky
        face: root
        x: root.inset
        y: root.paneTop + root.pick(6, 6, 10)
        width: root.innerWidth
        height: root.paneBottom - root.pick(6, 6, 10) - y
        Rectangle {
            id: sun
            readonly property real side: root.pick(10, 12, 16)
            x: Math.round(root.fraction * sky.width - width / 2)
            y: Math.round(sky.yAt(root.fraction) - height / 2)
            width: sun.side
            height: sun.side
            radius: width / 2
            color: root.daytime ? root.shelf : root.ink
            border.width: root.dp(2)
            border.color: root.plateColor
        }
    }

    // ── the foot: the day's other turn, and how long the light lasts ──
    component Fact: Column {
        id: fact
        property string name: ""
        property var parts: ({ main: "", suffix: "" })
        property bool trailing: false
        spacing: root.dp(1)
        FaceText {
            anchors.right: fact.trailing ? parent.right : undefined
            face: root
            text: fact.name
            color: root.inkTertiary
            size: root.type(11, 12, 13)
            weight: Font.DemiBold
        }
        Row {
            anchors.right: fact.trailing ? parent.right : undefined
            spacing: root.dp(3)
            FaceFigure {
                id: factFigure
                face: root
                text: fact.parts.main
                size: root.type(17, 19, 30)
                rolls: false
            }
            FaceText {
                visible: text.length > 0
                face: root
                anchors.baseline: factFigure.baseline
                text: fact.parts.suffix
                color: root.inkSecondary
                size: root.type(9, 10, 13)
                weight: Font.Bold
            }
        }
    }
    Item {
        visible: root.sunKnown
        x: root.inset
        width: root.innerWidth
        y: root.footTop + root.pick(10, 8, 34)
        height: root.footHeight - root.pick(10, 8, 34)
        Fact {
            name: root.other.name
            parts: root.otherParts
        }
        Fact {
            anchors.right: parent.right
            trailing: true
            name: Translation.tr("Daylight")
            parts: ({ main: root.daylight, suffix: "" })
        }
    }
    FaceText {
        visible: !root.sunKnown
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        text: Translation.tr("Sunrise and sunset come with the weather")
        color: root.inkTertiary
        size: root.type(11, 12, 13)
    }
}
