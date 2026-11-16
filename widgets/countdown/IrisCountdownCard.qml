pragma ComponentBehavior: Bound

// The desktop card in iRiS (the widget design "iRiS"): the family's plate, glass and ink. The head names what it
// counts to and the day; the days left lead as the figure; the wait is the ruler at the foot, today's tick in the
// accent. Small: the figure and its words. Medium: the share gone beside the figure. Large: the date in full.
import QtQuick
import qs.modules.iris.style
import qs.modules.iris.widgets

IrisWidgetFace {
    id: root

    readonly property var card: root.widget
    readonly property var reading: root.card.reading
    readonly property color live: root.nothing ? root.signal : root.accent

    FaceHeader {
        id: head
        face: root
        width: parent.width
        glyph: "hourglass_bottom"
        text: root.card.label
        trailing: root.small || !root.reading.valid ? "" : root.card.shortDate
        tint: root.live
    }

    CountdownRuler {
        id: ruler
        visible: root.card.barShown
        y: parent.height - height
        width: parent.width
        height: root.dp(root.large ? 30 : root.small ? 14 : 18)
        d: root.k
        ticks: root.large ? 32 : root.small ? 14 : 28
        fraction: root.card.waited
        feedback: IrisStyle.feedbackDuration
        ink: root.ink
        track: IrisStyle.trackOf(root.ink)
        lit: root.live
    }

    FaceText {
        id: dateWords
        face: root
        visible: root.large && root.reading.valid
        y: Math.round((ruler.visible ? ruler.y - root.dp(14) : parent.height) - height)
        width: parent.width
        text: root.card.barShown ? root.card.dateLine + "  ·  " + root.card.waitedLine : root.card.dateLine
        color: root.inkSecondary
        size: 13
    }

    Item {
        id: lead
        visible: root.reading.valid
        readonly property real roomTop: head.height + root.dp(4)
        readonly property real roomBottom: dateWords.visible ? dateWords.y - root.dp(6)
            : ruler.visible ? ruler.y - root.dp(8) : parent.height
        y: Math.round(lead.roomTop + (lead.roomBottom - lead.roomTop - height) / 2)
        width: parent.width
        height: root.small ? figure.height + words.height : figure.height

        FaceFigure {
            id: figure
            face: root
            width: Math.min(implicitWidth, lead.width - (root.small ? 0 : words.implicitWidth + root.dp(8)))
            text: root.reading.figure
            size: root.large ? 120 : root.small ? 40 : 52
            tone: root.card.arrived ? root.live : root.ink
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: root.px(20)
        }
        FaceText {
            id: words
            face: root
            visible: text.length > 0
            x: root.small ? 0 : figure.x + figure.width + root.dp(8)
            y: root.small ? figure.height : Math.round(figure.y + figure.baselineOffset - baselineOffset)
            width: root.small ? lead.width : Math.min(implicitWidth, lead.width - x)
            text: root.card.arrived ? "" : root.card.caption
            color: root.inkSecondary
            size: root.large ? 18 : root.small ? 12 : 14
            weight: Font.DemiBold
        }
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

    FaceText {
        visible: !root.reading.valid
        face: root
        y: head.height
        width: parent.width
        height: parent.height - head.height
        text: "No date yet. Set one in its settings"
        color: root.inkSecondary
        size: 13
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
