pragma ComponentBehavior: Bound

// The desktop card in Prism (the widget design "Prism" of iRiS): what it counts to on the tab, the day on the flap,
// the days left as the pane's figure, and the wait as a ruler at the foot whose tick for today is the one thing the
// light breaks on. Small: the figure and its words. Medium: the figure, the share gone and the ruler. Large: the date
// in full over a longer ruler. On the day the light passes whole; after it, the days since, no ruler.
import QtQuick
import qs.modules.iris.style
import qs.modules.iris.widgets
import qs.modules.iris.widgets.prism

PrismFolder {
    id: root

    readonly property var card: root.widget
    readonly property var reading: root.card.reading
    readonly property bool counting: root.reading.valid && !root.card.arrived

    tabGlyph: "hourglass_bottom"
    tabText: root.card.label
    flapText: root.reading.valid ? root.card.shortDate : ""
    lightPass: root.card.arrived ? 1 : root.counting && !root.reading.past ? 0.55 : 0.3
    // The light falls on today's tick, from the slab's top edge.
    prism: ruler.visible ? Qt.point(ruler.x + ruler.todayX, 0) : Qt.point(root.width - root.pick(28, 40, 48), root.pick(2, 2, 4))

    // The slab gives its whole body under the head.
    readonly property real areaTop: root.paneTop + root.pick(2, 2, 6)
    readonly property real areaBottom: root.footBottom - root.pick(6, 6, 10)
    readonly property real rulerHeight: root.pick(14, 18, 30)
    readonly property real wordsBottom: ruler.visible ? ruler.y - root.pick(8, 10, 18) : root.areaBottom

    CountdownRuler {
        id: ruler
        visible: root.card.barShown
        x: root.inset
        y: root.areaBottom - height
        width: root.innerWidth
        height: root.rulerHeight
        d: root.k
        ticks: root.pick(14, 28, 32)
        fraction: root.card.waited
        feedback: IrisStyle.feedbackDuration
        ink: root.ink
        track: IrisStyle.trackOf(root.ink)
        lit: root.shelf
    }

    // Large: the date in full and the share gone, over the ruler.
    FaceText {
        id: dateWords
        face: root
        visible: root.large && root.reading.valid
        x: root.inset
        y: Math.round(root.wordsBottom - height)
        width: root.innerWidth
        text: root.card.barShown ? root.card.dateLine + "  ·  " + root.card.waitedLine : root.card.dateLine
        color: root.inkSecondary
        size: 14
    }

    // The figure and its words, in the room left above.
    Item {
        id: lead
        visible: root.reading.valid
        readonly property real roomTop: root.areaTop
        readonly property real roomBottom: dateWords.visible ? dateWords.y - root.dp(8) : root.wordsBottom
        x: root.inset
        y: Math.round(lead.roomTop + (lead.roomBottom - lead.roomTop - height) / 2)
        width: root.innerWidth
        height: root.small ? figure.height + words.height : figure.height

        FaceFigure {
            id: figure
            face: root
            width: Math.min(implicitWidth, lead.width - (root.small ? 0 : words.implicitWidth + root.dp(10)))
            text: root.reading.figure
            size: root.type(44, 56, 128)
            tone: root.card.arrived ? root.shelf : root.ink
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: root.px(20)
        }
        FaceText {
            id: words
            face: root
            visible: text.length > 0
            x: root.small ? 0 : figure.x + figure.width + root.dp(10)
            y: root.small ? figure.height : Math.round(figure.y + figure.baselineOffset - baselineOffset)
            width: root.small ? lead.width : Math.min(implicitWidth, lead.width - x)
            text: root.card.arrived ? "" : root.card.caption
            color: root.inkSecondary
            size: root.type(12, 15, 20)
            weight: Font.DemiBold
        }
        // Medium: the share gone, at the row's end.
        FaceText {
            face: root
            // Only where it stands clear of the words ("18h 52m left today" leaves it no room).
            visible: root.medium && root.card.barShown && words.x + words.width + root.dp(12) + width <= lead.width
            x: lead.width - width
            y: Math.round(figure.y + figure.baselineOffset - baselineOffset)
            text: Math.round(root.card.waited * 100) + "%"
            color: root.inkTertiary
            size: 13
            weight: Font.DemiBold
        }
    }

    // No date yet: what to do, where the figure would stand.
    FaceText {
        visible: !root.reading.valid
        face: root
        x: root.inset
        y: root.areaTop
        width: root.innerWidth
        height: root.areaBottom - root.areaTop
        text: "No date yet. Set one in its settings"
        color: root.inkSecondary
        size: root.type(12, 13, 14)
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
