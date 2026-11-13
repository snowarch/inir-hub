pragma ComponentBehavior: Bound

// The Material sidebar face: a card in the left sidebar's Widgets column and, when the person turns it on, a tab of
// the right sidebar (iiSlot says which). SidebarStyle (qs.modules.ii.kit) holds the ink, plates and radii of the
// built-in cards beside it under every global style; the sidebar gives the card its width and side margins.

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit

Item {
    id: root

    // Given by the sidebar: "sidebar.left" (a card) or "sidebar.right" (a tab, which fills the space it is given).
    property string iiSlot: ""
    readonly property bool tab: root.iiSlot === "sidebar.right"

    readonly property string label: String(CustomWidgets.getConfigValue("__ID__", "label", "Now"))

    implicitHeight: content.implicitHeight + SidebarStyle.padding * 2

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: SidebarStyle.padding
        y: root.tab ? Math.max(SidebarStyle.padding, Math.round((root.height - implicitHeight) / 2)) : SidebarStyle.padding
        spacing: 6

        // The header the built-in cards carry: a glyph and what it is.
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            MaterialSymbol {
                text: "widgets"
                iconSize: 16
                color: SidebarStyle.text
            }
            StyledText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: SidebarStyle.text
            }
        }

        StyledText {
            text: DateTime.time
            font.pixelSize: root.tab ? Appearance.font.pixelSize.hugeass * 2 : Appearance.font.pixelSize.huge
            font.weight: Font.DemiBold
            color: SidebarStyle.accent
        }
    }
}
