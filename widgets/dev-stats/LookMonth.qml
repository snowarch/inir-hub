pragma ComponentBehavior: Bound

// The month look: this calendar month as a sheet, every day shaded by what it holds, today outlined.
// It answers the question the grid cannot at a glance — how this month is going, not the whole year.

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

    readonly property var sheet: Stats.month(root.card.days, root.card.today)
    readonly property int available: Math.max(0, root.card.width - root.card.pad * 2)
    readonly property int gap: Math.max(1, Math.round(2 * root.card.scaleFactor))
    readonly property int cellSize: Math.max(14, Math.min(Math.round(34 * root.card.scaleFactor),
        Math.floor((root.available - root.gap * 6) / 7)))

    spacing: 0
    implicitHeight: titleRow.implicitHeight + root.card.blockGap + sheetBody.height
        + root.card.blockGap + footer.implicitHeight

    RowLayout {
        id: titleRow
        Layout.fillWidth: true
        spacing: Math.round(6 * root.card.scaleFactor)

        StyledText {
            Layout.fillWidth: true
            text: root.sheet.name + " " + root.sheet.year
            elide: Text.ElideRight
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.large * root.card.scaleFactor)
            font.weight: Font.DemiBold
            color: root.card.widgetInk
        }
        // How many days of the month were worked, beside its name.
        StyledText {
            text: Translation.tr("%1 days worked").arg(Stats.number(root.sheet.active))
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
            color: ColorUtils.applyAlpha(root.card.widgetInk, 0.58)
        }
    }

    Item {
        id: sheetBody
        Layout.fillWidth: true
        Layout.preferredHeight: root.sheet.rows * root.cellSize + (root.sheet.rows - 1) * root.gap

        Column {
            spacing: root.gap
            Repeater {
                model: root.sheet.rows
                delegate: Row {
                    id: weekRow
                    required property int index
                    spacing: root.gap
                    Repeater {
                        model: 7
                        delegate: Item {
                            id: dayCell
                            required property int index
                            readonly property var day: root.sheet.cells[weekRow.index * 7 + index] ?? null
                            width: root.cellSize
                            height: root.cellSize

                            Rectangle {
                                anchors.fill: parent
                                visible: dayCell.day !== null
                                radius: Math.max(2, Math.round(root.cellSize * 0.22))
                                color: dayCell.day ? root.card.cellColor(dayCell.day.level) : "transparent"
                                border.width: dayCell.day && dayCell.day.today ? Math.max(1, Math.round(root.card.scaleFactor)) : 0
                                border.color: root.card.widgetAccentVisible
                            }
                            StyledText {
                                anchors.centerIn: parent
                                visible: dayCell.day !== null
                                text: dayCell.day ? String(dayCell.day.day) : ""
                                font.family: root.card.widgetNumbersFamily
                                font.pixelSize: Math.round(Math.min(root.cellSize * 0.42, Appearance.font.pixelSize.smaller * root.card.scaleFactor))
                                color: dayCell.day
                                    ? ColorUtils.ensureReadable(root.card.widgetInk, root.card.cellColor(dayCell.day.level), 4.5)
                                    : "transparent"
                            }
                        }
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
            text: Stats.number(root.sheet.total)
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.huge * root.card.scaleFactor)
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
            color: root.card.widgetInk
        }
        StyledText {
            Layout.fillWidth: true
            text: root.card.reading.current > 0
                ? Translation.tr("%1 day streak").arg(Stats.number(root.card.reading.current))
                : Translation.tr("This month")
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
            color: root.card.reading.current > 0 ? root.card.widgetAccentVisible : ColorUtils.applyAlpha(root.card.widgetInk, 0.66)
        }
    }
}
