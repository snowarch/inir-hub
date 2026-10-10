pragma ComponentBehavior: Bound

// The Waffle face: a card in Waffle's Widgets panel. Waffle draws with Looks tokens and the W*
// primitives (never Appearance), sizes with Looks.dp() and takes Fluent icons. The panel gives the
// card its body and separators; this file only lays out what is inside.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.waffle.looks
import "countdown.js" as Countdown

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    readonly property string label: String(CustomWidgets.getConfigValue("countdown", "label", "New year"))
    readonly property string dateText: String(CustomWidgets.getConfigValue("countdown", "date", ""))
    readonly property var target: Countdown.parse(root.dateText)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.visible
    }
    readonly property var reading: Countdown.describe(root.target, clock.date)

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
            RowLayout {
                spacing: Looks.dp(6)
                WText {
                    text: root.reading.valid ? root.reading.figure : "—"
                    font.pixelSize: Looks.dp(34)
                    font.weight: Font.DemiBold
                }
                WText {
                    Layout.alignment: Qt.AlignBaseline
                    visible: root.reading.valid && text.length > 0
                    text: root.reading.unit
                    font.pixelSize: Looks.font.pixelSize.large
                    color: Looks.colors.fg1
                }
            }
            WText {
                text: !root.reading.valid ? "Set a date in its settings"
                    : Countdown.dateLine(root.target, root.dateText)
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.fg1
            }
        }

        FluentIcon {
            Layout.alignment: Qt.AlignTop
            icon: "timer"
            implicitSize: Looks.dp(28)
            color: root.reading.past ? Looks.colors.fg1 : Looks.colors.accent
        }
    }
}
