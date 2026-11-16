pragma ComponentBehavior: Bound

// The bars look: the last twelve weeks as columns, so the rhythm of the work reads at a glance — which
// weeks were heavy, which were quiet, and where the run the streak is made of sits.

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import "stats.js" as Stats

ColumnLayout {
    id: root

    required property var card

    readonly property var weekly: Stats.weeks(root.card.days, 12, root.card.today)
    readonly property var bars: root.weekly.weeks
    readonly property int available: Math.max(0, root.card.width - root.card.pad * 2)
    readonly property int gap: Math.max(2, Math.round(3 * root.card.scaleFactor))
    readonly property int barWidth: root.bars.length > 0
        ? Math.max(3, Math.floor((root.available - root.gap * (root.bars.length - 1)) / root.bars.length))
        : 0
    readonly property int total: root.bars.reduce((sum, week) => sum + week.count, 0)
    readonly property var heaviest: root.bars.reduce((best, week) => !best || week.count > best.count ? week : best, null)

    spacing: 0
    implicitHeight: barsArea.height + root.card.blockGap + footer.implicitHeight

    Item {
        id: barsArea
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(84 * root.card.scaleFactor)

        // The floor every bar stands on, faint enough to be a guide and never a line of its own.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(1, Math.round(root.card.scaleFactor))
            color: ColorUtils.applyAlpha(root.card.widgetInk, 0.12)
        }

        Row {
            spacing: root.gap
            Repeater {
                model: root.bars
                delegate: Item {
                    required property var modelData
                    width: root.barWidth
                    height: barsArea.height
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: modelData.count > 0
                            ? Math.max(Math.round(3 * root.card.scaleFactor),
                                Math.round(parent.height * modelData.count / Math.max(1, root.weekly.max)))
                            : Math.max(1, Math.round(root.card.scaleFactor))
                        radius: Math.max(1, Math.round(Math.min(parent.width, width) * 0.25))
                        color: modelData.count > 0 ? root.card.cellColor(modelData.level) : root.card.quietCell
                    }
                }
            }
        }
    }

    RowLayout {
        id: footer
        Layout.fillWidth: true
        Layout.topMargin: root.card.blockGap
        spacing: Math.round(10 * root.card.scaleFactor)

        StyledText {
            text: Stats.number(root.total)
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.huge * root.card.scaleFactor)
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
            color: root.card.widgetInk
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                text: root.card.showTotals && root.heaviest
                    ? Translation.tr("Busiest week · %1").arg(Stats.number(root.heaviest.count))
                    : Translation.tr("contributions in %1 weeks").arg(root.bars.length)
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
                font.weight: Font.Medium
                color: ColorUtils.applyAlpha(root.card.widgetInk, 0.66)
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.card.showTotals
                text: root.card.reading.current > 0
                    ? Translation.tr("%1 day streak").arg(Stats.number(root.card.reading.current))
                    : Translation.tr("%1 days worked").arg(Stats.number(root.card.reading.active))
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
                color: root.card.reading.current > 0 ? root.card.widgetAccentVisible : ColorUtils.applyAlpha(root.card.widgetInk, 0.58)
            }
        }
    }
}
