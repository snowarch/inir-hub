pragma ComponentBehavior: Bound

// The Waffle face: a card in Waffle's Widgets panel. Waffle draws with Looks tokens and the W*
// primitives (never Appearance), sizes with Looks.dp() and takes Fluent icons. The panel gives the
// card its body and separators; this file only lays out what is inside.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.functions
import qs.services
import qs.modules.waffle.looks
import "stats.js" as Stats

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    readonly property var reading: DevStatsStore.summary
    readonly property var account: DevStatsStore.account
    readonly property bool drawn: DevStatsStore.hasData

    // The last ten weeks, the weeks of the window the numbers are about.
    readonly property var columns: {
        const all = root.reading.grid.columns
        return all.slice(Math.max(0, all.length - 10))
    }

    Timer {
        interval: DevStatsStore.refreshInterval
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: DevStatsStore.refresh(false)
    }

    function ink(level: int): color {
        if (level >= 4)
            return Looks.colors.accent
        if (level === 3)
            return ColorUtils.applyAlpha(Looks.colors.accent, 0.66)
        if (level === 2)
            return ColorUtils.applyAlpha(Looks.colors.accent, 0.42)
        if (level === 1)
            return ColorUtils.applyAlpha(Looks.colors.accent, 0.24)
        return Looks.colors.bg2Base
    }

    implicitHeight: content.implicitHeight + Looks.dp(32)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Looks.dp(16)
        spacing: Looks.dp(8)

        RowLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(8)

            FluentIcon {
                icon: "code"
                implicitSize: Looks.dp(20)
                color: Looks.colors.accent
            }
            WText {
                Layout.fillWidth: true
                text: root.account
                    ? Stats.platformName(root.account) + " · " + root.account.user
                    : Translation.tr("Contributions")
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Font.Medium
                color: Looks.colors.subfg
            }
            WText {
                text: root.drawn ? Stats.number(root.reading.total) : "—"
                font.pixelSize: Looks.dp(26)
                font.weight: Font.DemiBold
            }
        }

        // Ten weeks as a grid, quiet days in the panel's own fill and busy ones in the accent.
        Row {
            Layout.fillWidth: true
            Layout.topMargin: Looks.dp(2)
            visible: root.drawn
            spacing: Looks.dp(3)
            Repeater {
                model: root.columns
                delegate: Column {
                    required property var modelData
                    spacing: Looks.dp(3)
                    Repeater {
                        model: modelData
                        delegate: Rectangle {
                            required property var modelData
                            visible: !modelData.future
                            width: Looks.dp(9)
                            height: Looks.dp(9)
                            radius: Looks.radius.small
                            color: root.ink(modelData.level)
                        }
                    }
                }
            }
        }

        WText {
            Layout.fillWidth: true
            visible: !root.drawn
            text: DevStatsStore.emptyWords
            wrapMode: Text.WordWrap
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
        }

        WText {
            Layout.fillWidth: true
            visible: root.drawn
            text: root.reading.current > 0
                ? Translation.tr("%1 day streak · %2 days worked").arg(Stats.number(root.reading.current)).arg(Stats.number(root.reading.active))
                : Translation.tr("%1 contributions in %2 weeks").arg(Stats.number(root.reading.total)).arg(root.reading.grid.weeks)
            elide: Text.ElideRight
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.fg1
        }
    }
}
