pragma ComponentBehavior: Bound

// The Material sidebar face: a card in the left sidebar's Widgets column, or a tab of the right
// sidebar (iiSlot says which). It draws with SidebarStyle from qs.modules.ii.kit, the ink, plates and
// radii of the built-in cards beside it under every global style; the sidebar gives it its width and
// side margins.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.kit
import "stats.js" as Stats

Item {
    id: root

    // Given by the sidebar: "sidebar.left" (a card in the Widgets column) or "sidebar.right" (a tab).
    property string iiSlot: ""
    readonly property bool tab: root.iiSlot === "sidebar.right"

    readonly property var reading: DevStatsStore.summary
    readonly property var account: DevStatsStore.account
    readonly property bool drawn: DevStatsStore.hasData

    // A card shows six weeks, a tab has the room for twelve.
    readonly property var columns: {
        const all = root.reading.grid.columns
        return all.slice(Math.max(0, all.length - (root.tab ? 12 : 6)))
    }
    readonly property int cell: root.tab ? 12 : 7

    Timer {
        interval: DevStatsStore.refreshInterval
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: DevStatsStore.refresh(false)
    }

    function ink(level: int): color {
        if (level >= 4)
            return SidebarStyle.accent
        if (level === 3)
            return ColorUtils.applyAlpha(SidebarStyle.accent, 0.66)
        if (level === 2)
            return ColorUtils.applyAlpha(SidebarStyle.accent, 0.42)
        if (level === 1)
            return ColorUtils.applyAlpha(SidebarStyle.accent, 0.24)
        return SidebarStyle.plate
    }

    implicitHeight: body.implicitHeight + SidebarStyle.padding * 2

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: SidebarStyle.padding
        // A card sits at the top of its column; a tab centres in the space the right sidebar gives it.
        y: root.tab ? Math.max(SidebarStyle.padding, Math.round((root.height - implicitHeight) / 2)) : SidebarStyle.padding
        spacing: 10

        // The header every sidebar card carries: a glyph and what it is.
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2
                text: Stats.platformGlyph(root.account)
                iconSize: 16
                color: SidebarStyle.text
            }
            StyledText {
                Layout.fillWidth: true
                text: root.account
                    ? Stats.platformName(root.account) + " · " + root.account.user
                    : Translation.tr("Contributions")
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: SidebarStyle.text
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            StyledText {
                text: root.drawn ? Stats.number(root.reading.total) : "—"
                font.family: Appearance.font.family.numbers
                font.pixelSize: root.tab ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: SidebarStyle.accent
            }
            StyledText {
                Layout.fillWidth: true
                text: root.reading.current > 0
                    ? Translation.tr("%1 day streak").arg(Stats.number(root.reading.current))
                    : Translation.tr("%1 contributions").arg(Stats.number(root.reading.total))
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: SidebarStyle.subtext
            }
        }

        Row {
            Layout.fillWidth: true
            visible: root.drawn
            spacing: 3
            Repeater {
                model: root.columns
                delegate: Column {
                    required property var modelData
                    spacing: 3
                    Repeater {
                        model: modelData
                        delegate: Rectangle {
                            required property var modelData
                            visible: !modelData.future
                            width: root.cell
                            height: root.cell
                            radius: SidebarStyle.radiusSmall
                            color: root.ink(modelData.level)
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.drawn
            text: DevStatsStore.emptyWords
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: SidebarStyle.subtext
        }
    }
}
