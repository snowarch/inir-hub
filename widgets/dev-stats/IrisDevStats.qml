pragma ComponentBehavior: Bound

// The iRiS face: a compact line on the Island's Desktop page. iRiS modules use IrisStyle tokens and the
// Iris* components, so they follow the theme, the density and the type ladder like the rest of the
// Island. Settings are the same keys the desktop face reads.

import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "stats.js" as Stats

Item {
    id: root

    // Given by the Island: where the module sits and which screen it is on.
    property string irisSlot: ""
    property var targetScreen

    readonly property var reading: DevStatsStore.summary
    readonly property var account: DevStatsStore.account
    readonly property var recent: {
        const cells = []
        const columns = root.reading.grid.columns
        for (let week = 0; week < columns.length; week++)
            for (let day = 0; day < columns[week].length; day++)
                cells.push(columns[week][day])
        return cells.slice(cells.length - 14)
    }
    readonly property bool drawn: DevStatsStore.hasData

    // The Island is always on screen while iRiS shows it, so this is when the numbers are asked for.
    Timer {
        interval: DevStatsStore.refreshInterval
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: DevStatsStore.refresh(false)
    }

    // iRiS has a fill for every step, so the squares never invent an alpha of their own.
    function ink(level: int): color {
        if (level >= 4)
            return IrisStyle.accent
        if (level === 3)
            return IrisStyle.fillStrong
        if (level === 2)
            return IrisStyle.fillHover
        if (level === 1)
            return IrisStyle.fill
        return IrisStyle.fillQuiet
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * IrisStyle.density)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * IrisStyle.density)

        Row {
            visible: root.drawn
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(2 * IrisStyle.density))
            Repeater {
                model: root.recent
                delegate: Rectangle {
                    required property var modelData
                    visible: !modelData.future
                    width: Math.max(3, Math.round(6 * IrisStyle.density))
                    height: width
                    radius: Math.max(1, Math.round(2 * IrisStyle.density))
                    color: root.ink(modelData.level)
                }
            }
        }

        IrisText {
            id: total
            anchors.verticalCenter: parent.verticalCenter
            visible: root.drawn
            role: IrisText.Metric
            font.pixelSize: IrisStyle.typeLabel
            color: IrisStyle.accent
            text: Stats.number(root.reading.total)
        }

        IrisText {
            anchors.baseline: total.baseline
            visible: root.drawn && root.reading.current > 0
            role: IrisText.Meta
            text: Translation.tr("%1d streak").arg(Stats.number(root.reading.current))
        }

        // With nothing drawn the line still says which state it is in, never nothing at all.
        IrisText {
            visible: !root.drawn
            role: IrisText.Meta
            text: root.account ? Translation.tr("Dev stats · fetching…")
                : DevStatsStore.error.length > 0 ? Translation.tr("Dev stats · unavailable")
                : Translation.tr("Dev stats · add an account")
        }
    }
}
