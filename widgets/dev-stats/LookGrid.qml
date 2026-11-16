pragma ComponentBehavior: Bound

// The squares look: one column per week, Sunday on top, the week today is in last, five steps of the
// accent from quiet to busy. Hovering a day reads it out under the grid, and a click fetches again.

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

    readonly property var reading: root.card.reading
    readonly property int columns: Math.max(1, root.reading.grid.columns.length)
    readonly property int available: Math.max(0, root.card.width - root.card.pad * 2)
    // The squares grow with the card, and the gaps take what the floor leaves, so the weeks always
    // span the card instead of stopping short of its right edge.
    readonly property int cellSize: Math.max(3, Math.min(Math.round(12 * root.card.scaleFactor),
        Math.floor((root.available - root.card.baseGap * (root.columns - 1)) / root.columns)))
    readonly property int gap: root.columns > 1
        ? Math.max(root.card.baseGap, Math.floor((root.available - root.cellSize * root.columns) / (root.columns - 1)))
        : root.card.baseGap

    // A day read out under the grid, so a small square never needs its own tooltip.
    property string hoverDay: ""
    property int hoverCount: 0
    readonly property var busiest: root.reading.busiest
    readonly property string readingLine: root.hoverDay.length > 0
        ? Stats.dayWords(root.hoverDay) + " · " + Stats.number(root.hoverCount)
        : root.busiest ? Translation.tr("Busiest %1 · %2").arg(Stats.dayWords(root.busiest.key)).arg(Stats.number(root.busiest.count))
        : ""

    spacing: 0
    implicitHeight: grid.height + (root.card.showTotals ? root.card.blockGap + footer.implicitHeight : 0)

    Item {
        id: grid
        Layout.fillWidth: true
        Layout.preferredHeight: 7 * root.cellSize + 6 * root.gap

        Row {
            id: weeks
            spacing: root.gap
            Repeater {
                model: root.reading.grid.columns
                delegate: Column {
                    required property var modelData
                    spacing: root.gap
                    Repeater {
                        model: modelData
                        delegate: Rectangle {
                            required property var modelData
                            width: root.cellSize
                            height: root.cellSize
                            radius: Math.max(1, Math.round(root.cellSize * 0.3))
                            visible: !modelData.future
                            color: root.card.cellColor(modelData.level)
                        }
                    }
                }
            }
        }

        // One place to read a day out, instead of a tooltip per square.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: mouse => {
                const cell = Stats.cellAt(root.reading.grid, mouse.x, mouse.y, root.cellSize, root.gap)
                root.hoverDay = cell && !cell.future ? cell.key : ""
                root.hoverCount = cell ? cell.count : 0
            }
            onExited: root.hoverDay = ""
            onClicked: DevStatsStore.refresh(true)
        }
    }

    RowLayout {
        id: footer
        Layout.fillWidth: true
        Layout.topMargin: root.card.blockGap
        visible: root.card.showTotals
        spacing: Math.round(10 * root.card.scaleFactor)

        StyledText {
            text: Stats.number(root.reading.total)
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
                text: root.reading.current > 0
                    ? Translation.tr("%1 day streak").arg(Stats.number(root.reading.current))
                    : Translation.tr("contributions in %1 weeks").arg(root.reading.grid.weeks)
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
                font.weight: Font.Medium
                color: root.reading.current > 0 ? root.card.widgetAccentVisible : ColorUtils.applyAlpha(root.card.widgetInk, 0.66)
            }
            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.readingLine
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
                color: ColorUtils.applyAlpha(root.card.widgetInk, 0.58)
            }
        }
    }
}
