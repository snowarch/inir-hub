pragma ComponentBehavior: Bound

// The Waffle face: a card in Waffle's Widgets panel. Looks tokens, the W* parts and Fluent icons
// (never Appearance). The panel draws the card and the separators; this file lays out what is inside.

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.waffle.looks

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    readonly property string label: String(CustomWidgets.getConfigValue("__ID__", "label", "Now"))

    implicitHeight: content.implicitHeight + Looks.dp(32)

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Looks.dp(16)
        spacing: Looks.dp(16)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(2)

            WText {
                text: root.label
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Font.Medium
                color: Looks.colors.subfg
            }
            WText {
                text: DateTime.time
                font.pixelSize: Looks.dp(30)
                font.weight: Font.DemiBold
            }
        }

        FluentIcon {
            Layout.alignment: Qt.AlignTop
            icon: "apps"
            implicitSize: Looks.dp(24)
            color: Looks.colors.accent
        }
    }
}
