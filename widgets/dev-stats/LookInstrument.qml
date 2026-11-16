pragma ComponentBehavior: Bound

// The iNstrument look: the grammar the built-in widgets wear when the person's design is iNstrument or
// Readout. An eyebrow, the total as the reading, the last two weeks as measured bars and three labelled
// fields, so a card among built-in instruments never sticks out.

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.shared.background.widgets.instrument
import qs.services
import "stats.js" as Stats

ColumnLayout {
    id: root

    required property var card

    readonly property var reading: root.card.reading
    readonly property var busiest: root.reading.busiest
    // The two weeks the bars measure, flattened into one row of days.
    readonly property var recent: {
        const columns = root.reading.grid.columns
        const recentWeeks = columns.slice(Math.max(0, columns.length - 2))
        if (recentWeeks.length > 1)
            return recentWeeks[0].concat(recentWeeks[1])
        return recentWeeks.length === 1 ? recentWeeks[0] : []
    }

    spacing: Math.round(5 * root.card.scaleFactor)
    implicitHeight: eyebrow.height + readingLine.implicitHeight + bars.implicitHeight + fields.implicitHeight
        + 3 * root.spacing

    InstrumentLabel {
        id: eyebrow
        Layout.fillWidth: true
        text: "Dev / " + (root.card.account ? Stats.platformName(root.card.account) + " — " + root.card.account.user : Translation.tr("No account"))
        color: root.card.widgetAccentVisible
        scaleFactor: root.card.scaleFactor
        strong: true
    }

    RowLayout {
        id: readingLine
        Layout.fillWidth: true
        spacing: Math.round(8 * root.card.scaleFactor)
        StyledText {
            Layout.maximumWidth: root.card.width * 0.5
            text: Stats.number(root.reading.total)
            elide: Text.ElideRight
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(44 * root.card.scaleFactor)
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
            font.letterSpacing: -1
            color: root.card.widgetInk
        }
        InstrumentLabel {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBaseline
            text: Translation.tr("contributions")
            color: root.card.widgetInkMuted
            scaleFactor: root.card.scaleFactor
            size: 11
            strong: true
        }
    }

    // Quiet days stay visible as a hairline, so the row never reads as a broken line.
    Row {
        id: bars
        Layout.fillWidth: true
        Layout.topMargin: Math.round(4 * root.card.scaleFactor)
        Layout.preferredHeight: Math.round(24 * root.card.scaleFactor)
        spacing: Math.max(1, Math.round(2 * root.card.scaleFactor))
        Repeater {
            model: root.recent
            delegate: Item {
                required property var modelData
                width: Math.max(2, Math.floor((root.card.width - root.card.pad * 2) / 14) - 2)
                height: bars.height
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: modelData.count > 0
                        ? Math.max(Math.round(3 * root.card.scaleFactor),
                            Math.round(parent.height * Math.sqrt(modelData.count / Math.max(1, root.reading.max))))
                        : Math.max(1, Math.round(root.card.scaleFactor))
                    radius: Math.max(1, Math.round(width * 0.3))
                    color: modelData.count > 0 ? root.card.widgetAccentVisible : root.card.quietCell
                }
            }
        }
    }

    RowLayout {
        id: fields
        Layout.fillWidth: true
        Layout.topMargin: Math.round(2 * root.card.scaleFactor)
        spacing: Math.round(14 * root.card.scaleFactor)
        InstrumentField {
            Layout.fillWidth: true
            label: Translation.tr("Streak")
            value: root.reading.current > 0 ? Translation.tr("%1 days").arg(Stats.number(root.reading.current)) : "—"
            ink: root.card.widgetInk
            muted: root.card.widgetInkMuted
            family: root.card.widgetNumbersFamily
            scaleFactor: root.card.scaleFactor
        }
        InstrumentField {
            Layout.fillWidth: true
            label: Translation.tr("Longest")
            value: root.reading.longest > 0 ? Translation.tr("%1 days").arg(Stats.number(root.reading.longest)) : "—"
            ink: root.card.widgetInk
            muted: root.card.widgetInkMuted
            family: root.card.widgetNumbersFamily
            scaleFactor: root.card.scaleFactor
        }
        InstrumentField {
            Layout.fillWidth: true
            label: Translation.tr("Busiest")
            value: root.busiest ? Stats.number(root.busiest.count) : "—"
            ink: root.card.widgetInk
            muted: root.card.widgetInkMuted
            family: root.card.widgetNumbersFamily
            scaleFactor: root.card.scaleFactor
        }
    }
}
