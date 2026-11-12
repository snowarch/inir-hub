pragma ComponentBehavior: Bound

// The Material sidebar face: a card in the left sidebar's Widgets column, or a tab of the right sidebar
// (iiSlot says which). It draws with SidebarStyle from qs.modules.ii.kit, the ink, plates and radii of the
// built-in cards beside it under every global style; the sidebar gives it its width and side margins.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.modules.ii.kit
import "countdown.js" as Countdown

Item {
    id: root

    // Given by the sidebar: "sidebar.left" (a card in the Widgets column) or "sidebar.right" (a tab).
    property string iiSlot: ""
    readonly property bool tab: root.iiSlot === "sidebar.right"

    readonly property string label: String(CustomWidgets.getConfigValue("countdown", "label", "New year"))
    readonly property string dateText: String(CustomWidgets.getConfigValue("countdown", "date", ""))
    readonly property string shapeName: String(CustomWidgets.getConfigValue("countdown", "shape", "Cookie9Sided"))
    readonly property bool showProgress: Boolean(CustomWidgets.getConfigValue("countdown", "showProgress", true))
    readonly property var target: Countdown.parse(root.dateText)

    // Minutes, and only while the card or its tab is on screen.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.visible
    }
    readonly property var reading: Countdown.describe(root.target, clock.date)
    readonly property bool arrived: root.reading.valid && root.reading.past && root.reading.unit.length === 0
    readonly property real waited: Countdown.progress(Countdown.parse(String(CustomWidgets.getConfigValue("countdown", "since", ""))), root.target, clock.date)
    readonly property bool barShown: root.showProgress && root.waited >= 0 && root.reading.valid && !root.reading.past

    // The bar measures the wait from the day the date was set, stamped once per date (the desktop face keeps
    // its own per screen).
    readonly property bool _needsSince: Config.ready && root.target !== null
        && String(CustomWidgets.getConfigValue("countdown", "sinceFor", "")) !== root.dateText
    on_NeedsSinceChanged: if (root._needsSince) stampSince.restart()
    Component.onCompleted: if (root._needsSince) stampSince.restart()
    Timer {
        id: stampSince
        interval: 0
        onTriggered: {
            if (!root._needsSince)
                return
            CustomWidgets.setConfigValue("countdown", "since", Countdown.isoDay(new Date()))
            CustomWidgets.setConfigValue("countdown", "sinceFor", root.dateText)
        }
    }

    readonly property int shapeSize: root.tab ? 112 : 68
    readonly property color shapeFill: root.reading.valid && !root.reading.past || root.arrived
        ? SidebarStyle.accent : SidebarStyle.plate
    readonly property color shapeInk: root.reading.valid && !root.reading.past || root.arrived
        ? SidebarStyle.accentInk : SidebarStyle.text

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
            visible: !root.tab
            spacing: 6
            MaterialSymbol {
                text: "hourglass_bottom"
                iconSize: 16
                color: SidebarStyle.text
            }
            StyledText {
                Layout.fillWidth: true
                text: root.label
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
            spacing: 14

            Item {
                implicitWidth: root.shapeSize
                implicitHeight: root.shapeSize

                // Changing the shape morphs it, as on the desktop.
                MaterialShape {
                    anchors.fill: parent
                    implicitSize: root.shapeSize
                    shape: DesktopWidgetShapes.shapeForName(root.arrived ? "SoftBurst" : root.reading.valid ? root.shapeName : "Cookie4Sided")
                    color: root.shapeFill
                }
                StyledText {
                    anchors.centerIn: parent
                    width: Math.round(root.shapeSize * 0.7)
                    height: Math.round(root.shapeSize * 0.5)
                    visible: root.reading.valid && !root.arrived
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 11
                    text: root.reading.figure
                    color: root.shapeInk
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Math.round(root.shapeSize * 0.42)
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: !root.reading.valid || root.arrived
                    text: root.arrived ? "celebration" : "edit_calendar"
                    fill: 1
                    iconSize: Math.round(root.shapeSize * 0.4)
                    color: root.shapeInk
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    visible: root.tab
                    text: root.label
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: SidebarStyle.subtext
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Countdown.caption(root.reading)
                    elide: Text.ElideRight
                    font.pixelSize: root.tab ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: SidebarStyle.text
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.reading.valid ? Countdown.dateLine(root.target, root.dateText) : "Choose one in its settings"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: SidebarStyle.subtext
                }
            }
        }

        // How much of the wait has gone by.
        RowLayout {
            Layout.fillWidth: true
            visible: root.barShown
            spacing: 8

            StyledProgressBar {
                Layout.fillWidth: true
                valueBarHeight: 4
                valueBarGap: 4
                wavy: true
                animateWave: false
                waveFrequency: 4
                value: Math.max(0.02, root.waited)
                highlightColor: SidebarStyle.accent
                trackColor: ColorUtils.applyAlpha(SidebarStyle.text, 0.14)
            }
            StyledText {
                text: Math.round(root.waited * 100) + "%"
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
                color: SidebarStyle.subtext
            }
        }
    }
}
