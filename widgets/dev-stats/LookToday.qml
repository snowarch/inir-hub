pragma ComponentBehavior: Bound

// The today look: the shape grammar the built-in widgets wear. Today's count sits in a Material shape,
// and beside it the week so far, the streak and the busiest day — what today is part of, not the year.

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.services
import "stats.js" as Stats

RowLayout {
    id: root

    required property var card

    readonly property var today: Stats.todayReading(root.card.days, root.card.today)
    readonly property var busiest: root.card.reading.busiest
    readonly property int shapeSize: Math.round(104 * root.card.scaleFactor)
    readonly property color shapeFill: root.card.widgetSemanticContainer(root.card.widgetPrimaryRole)
    readonly property color shapeInk: root.card.widgetSemanticOnContainer(root.card.widgetPrimaryRole)

    spacing: Math.round(18 * root.card.scaleFactor)
    implicitHeight: Math.max(root.shapeSize, info.implicitHeight)

    Item {
        Layout.preferredWidth: root.shapeSize
        Layout.preferredHeight: root.shapeSize

        MaterialShape {
            anchors.fill: parent
            implicitSize: root.shapeSize
            shape: DesktopWidgetShapes.shapeForName("Cookie9Sided")
            color: root.shapeFill
        }
        StyledText {
            anchors.centerIn: parent
            width: Math.round(root.shapeSize * 0.72)
            height: Math.round(root.shapeSize * 0.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPixelSize: Math.round(12 * root.card.scaleFactor)
            text: Stats.number(root.today.count)
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(root.shapeSize * 0.42)
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
            color: root.shapeInk
        }
    }

    ColumnLayout {
        id: info
        Layout.fillWidth: true
        spacing: Math.round(3 * root.card.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.card.scaleFactor)
            MaterialSymbol {
                text: "today"
                fill: 1
                iconSize: Math.round(Appearance.font.pixelSize.small * root.card.scaleFactor)
                color: root.card.widgetAccentVisible
            }
            StyledText {
                Layout.fillWidth: true
                text: root.today.day
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
                font.weight: Font.DemiBold
                font.letterSpacing: Math.round(1 * root.card.scaleFactor)
                color: ColorUtils.applyAlpha(root.card.widgetInk, 0.66)
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.card.reading.current > 0
                ? Translation.tr("%1 day streak").arg(Stats.number(root.card.reading.current))
                : Translation.tr("No streak right now")
            elide: Text.ElideRight
            font.family: root.card.widgetNumbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.large * root.card.scaleFactor)
            font.weight: Font.DemiBold
            color: root.card.reading.current > 0 ? root.card.widgetAccentVisible : root.card.widgetInk
        }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("This week · %1").arg(Stats.number(root.today.week))
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
            color: ColorUtils.applyAlpha(root.card.widgetInk, 0.66)
        }

        StyledText {
            Layout.fillWidth: true
            text: root.busiest
                ? Translation.tr("Busiest %1 · %2").arg(Stats.dayWords(root.busiest.key)).arg(Stats.number(root.busiest.count))
                : ""
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.card.scaleFactor)
            color: ColorUtils.applyAlpha(root.card.widgetInk, 0.58)
        }
    }
}
