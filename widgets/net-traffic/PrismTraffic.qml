pragma ComponentBehavior: Bound

// The desktop card in Prism (the widget design "Prism" of iRiS): the tab names the link, the head's fact is what goes
// out, the pane holds the rate coming in and the minute's horizon beside it, the light passing brighter the more comes
// in. Small: the rate over a short horizon on the foot. Medium: the minute's peak and what it moved on the foot.
// Large: both peaks and both amounts.
import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets
import qs.modules.iris.widgets.prism

PrismFolder {
    id: root

    readonly property var card: root.widget
    readonly property color outTint: root.nothing ? root.inkSecondary : root.accent2
    // How loud the link is now, 0..1 on the horizon's scale.
    readonly property real loud: root.card.downLevels.length > 0 ? root.card.downLevels[root.card.downLevels.length - 1] : 0

    tabGlyph: root.card.kindGlyph
    tabText: root.card.kindName
    flapText: root.card.shown ? root.card.upRate[0] : ""
    flapSuffix: root.card.shown ? root.card.upRate[1] : ""
    flapGlyph: root.card.shown ? "arrow_upward" : ""
    shelf: root.card.online ? (root.nothing ? root.signal : root.accent) : root.inkTertiary
    lightPass: root.card.shown ? 0.5 + 0.5 * root.loud : 0.4

    // ── the pane: the rate coming in, and the minute beside it ──
    Row {
        id: reading
        visible: root.card.shown
        x: root.inset
        // Centred by the figure's caps, as Vitals: a figure face with a taller line sank onto the foot.
        y: Math.round(root.paneMiddle - number.baselineOffset + number.font.pixelSize * 0.36)
        spacing: root.dp(2)
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(number.font.pixelSize * 0.1)
            text: "arrow_downward"
            fill: 1
            iconSize: root.px(root.type(18, 22, 32))
            color: root.shelf
        }
        FaceFigure {
            id: number
            rolls: false
            face: root
            text: root.card.downRate[0]
            size: root.type(42, 52, 80)
        }
        FaceText {
            face: root
            anchors.baseline: number.baseline
            text: root.card.downRate[1]
            size: root.type(13, 16, 24)
            weight: Font.DemiBold
            color: root.inkSecondary
        }
    }
    IrisHorizon {
        visible: root.card.shown && root.card.drawable
        face: root
        // Its own place, never pushed by the figure: medium at the pane's right, small and large across the foot.
        x: root.medium ? root.inset + Math.round(root.innerWidth * 0.56) : root.inset
        width: root.width - root.inset - x
        y: root.medium ? root.paneTop + root.dp(10) : root.footTop + root.pick(8, 0, 12)
        height: root.medium ? root.paneBottom - root.dp(10) - y
            : root.small ? root.height - root.inset - y : others.y - root.dp(14) - y
        downs: root.card.downLevels
        ups: root.card.upLevels
        filled: root.card.filled
        inTint: root.shelf
        outTint: root.outTint
        // A slab colours what came in by its height, as Vitals colours a load.
        inEffect: root.folded ? null : spectrum
        Component {
            id: spectrum
            PrismSpectrum { mono: root.nothing; angle: -90; from: 0.3; to: 1 }
        }
    }
    FaceText {
        visible: !root.card.shown
        face: root
        x: root.inset
        width: root.innerWidth
        y: root.paneTop
        height: root.height - root.inset - root.paneTop
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        text: root.card.emptyText
        color: root.inkSecondary
        size: root.type(12, 13, 15)
    }

    // ── the foot: the minute's peaks and what it moved ──
    Row {
        id: others
        visible: root.card.shown && !root.small
        x: root.inset
        width: root.innerWidth
        // Medium: the foot's middle. Large: its bottom, under the horizon.
        y: root.large ? root.height - root.inset - height : Math.round(root.footTop + (root.footHeight - height) / 2) - root.dp(2)
        spacing: root.pick(14, 18, 22)
        Repeater {
            // Large: four short columns, each named by its arrow and one word, so no label is ever cut.
            model: root.large ? [
                { glyph: "arrow_downward", label: Translation.tr("Peak"), value: root.card.rateText(root.card.peak) },
                { glyph: "arrow_upward", label: Translation.tr("Peak"), value: root.card.rateText(root.card.peakUp) },
                { glyph: "arrow_downward", label: Translation.tr("Minute"), value: root.card.amountText(root.card.got) },
                { glyph: "arrow_upward", label: Translation.tr("Minute"), value: root.card.amountText(root.card.sent) }
            ] : [
                { glyph: "", label: Translation.tr("Peak"), value: root.card.rateText(root.card.peak) },
                { glyph: "", label: Translation.tr("This minute"), value: root.card.amountText(root.card.got) }
            ]
            Column {
                id: other
                required property var modelData
                readonly property int count: root.large ? 4 : 2
                width: (others.width - (other.count - 1) * others.spacing) / other.count
                spacing: root.dp(3)
                Row {
                    spacing: root.dp(2)
                    MaterialSymbol {
                        visible: other.modelData.glyph.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: other.modelData.glyph
                        fill: 1
                        iconSize: root.px(12)
                        color: other.modelData.glyph === "arrow_upward" ? root.outTint : root.shelf
                    }
                    FaceText {
                        face: root
                        width: Math.min(implicitWidth, other.width - (other.modelData.glyph.length > 0 ? root.px(14) : 0))
                        text: other.modelData.label
                        color: root.inkTertiary
                        size: root.type(11, 11.5, 13)
                        weight: Font.DemiBold
                    }
                }
                Row {
                    spacing: root.dp(2)
                    FaceFigure {
                        id: otherFigure
                        rolls: false
                        face: root
                        text: other.modelData.value.split(" ")[0]
                        size: root.type(17, 18, 26)
                    }
                    FaceText {
                        face: root
                        anchors.baseline: otherFigure.baseline
                        text: other.modelData.value.split(" ")[1] ?? ""
                        size: root.type(10, 10.5, 12)
                        weight: Font.DemiBold
                        color: root.inkSecondary
                    }
                }
            }
        }
    }
}
