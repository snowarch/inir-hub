pragma ComponentBehavior: Bound

// The desktop card in iRiS (the widget design "iRiS"): the family's plate, glass and ink. The rate coming in leads,
// what goes out follows in the second accent, the minute's horizon beside them; the head names the link and the
// minute's peak. Small: both rates over a short horizon. Medium: the rates at the left, the horizon at the right.
// Large: the rates side by side, a tall horizon, what the minute moved at the foot.
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

IrisWidgetFace {
    id: root

    readonly property var card: root.widget
    readonly property color inTint: root.accent
    readonly property color outTint: root.nothing ? root.inkSecondary : root.accent2

    // A rate with its arrow, the figure in the family's figure face.
    component Rate: Row {
        id: rate
        property bool outgoing: false
        property real size: 40
        readonly property var value: rate.outgoing ? root.card.upRate : root.card.downRate
        spacing: root.dp(2)
        MaterialSymbol {
            anchors.verticalCenter: figure.verticalCenter
            text: rate.outgoing ? "arrow_upward" : "arrow_downward"
            fill: 1
            iconSize: root.px(rate.size * 0.5)
            color: rate.outgoing ? root.outTint : root.inTint
        }
        FaceFigure {
            id: figure
            rolls: false
            face: root
            text: rate.value[0]
            size: rate.size
            tone: rate.outgoing ? root.inkSecondary : root.ink
        }
        FaceText {
            face: root
            anchors.baseline: figure.baseline
            text: rate.value[1]
            size: Math.max(11, rate.size * 0.34)
            weight: Font.DemiBold
            color: root.inkSecondary
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.dp(8)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: root.card.kindGlyph
            text: root.card.kindName
            trailing: !root.small && root.card.shown ? Translation.tr("Peak %1").arg(root.card.rateText(root.card.peak)) : ""
            tint: root.card.online ? root.accent : root.inkTertiary
        }
        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.card.shown

            Column {
                id: rates
                y: root.medium ? Math.round((body.height - height) / 2) : 0
                spacing: root.dp(root.large ? 0 : 2)
                visible: !root.large
                Rate { size: root.small ? 30 : 40 }
                Rate { outgoing: true; size: root.small ? 15 : 18 }
            }
            Row {
                id: wide
                visible: root.large
                spacing: root.dp(18)
                Rate { size: 60 }
                Rate { outgoing: true; size: 26; anchors.bottom: parent.bottom; anchors.bottomMargin: root.dp(6) }
            }
            IrisHorizon {
                face: root
                visible: root.card.drawable
                // Its own half in medium, never pushed by the figure.
                x: root.medium ? Math.round(body.width * 0.48) : 0
                y: root.medium ? 0 : root.large ? wide.height + root.dp(14) : rates.height + root.dp(8)
                width: body.width - x
                height: body.height - y - (minute.visible ? minute.height + root.dp(10) : 0)
                downs: root.card.downLevels
                ups: root.card.upLevels
                filled: root.card.filled
                inTint: root.inTint
                outTint: root.outTint
            }
            FaceText {
                id: minute
                visible: root.large
                face: root
                width: body.width
                y: body.height - height
                text: Translation.tr("%1 in, %2 out this minute").arg(root.card.amountText(root.card.got)).arg(root.card.amountText(root.card.sent))
                color: root.inkSecondary
                size: 13
            }
        }
        FaceText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.card.shown
            face: root
            text: root.card.emptyText
            color: root.inkSecondary
            size: 13
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
