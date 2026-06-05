pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root

    property int selectedRange: 0
    readonly property var rangeOptions: [
        { label: Translation.tr("Today"), days: 1 },
        { label: Translation.tr("3 days"), days: 3 },
        { label: Translation.tr("14 days"), days: 14 }
    ]
    readonly property int currentDays: rangeOptions[selectedRange].days
    property var _displayData: null
    property var _appList: []

    readonly property real maxAppSeconds: {
        let m = 0
        for (let i = 0; i < _appList.length; i++) {
            if (_appList[i].seconds > m) m = _appList[i].seconds
        }
        return m > 0 ? m : 1
    }

    Connections {
        target: ScreenTime
        function onDataChanged() { root._refreshData() }
        function onRangeLoaded(days: int, data: var) { root._refreshData() }
    }

    function _refreshData(): void {
        if (root.currentDays <= 1) {
            root._displayData = ScreenTime.getToday()
        } else {
            const cached = ScreenTime.getCachedDays(root.currentDays)
            if (cached) {
                root._displayData = cached
            } else {
                ScreenTime.requestDays(root.currentDays)
                return
            }
        }
        root._appList = ScreenTime.getAppList(root.currentDays)
    }

    Component.onCompleted: root._refreshData()
    onSelectedRangeChanged: root._refreshData()

    WPanelPageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                HeaderRow {
                    Layout.fillWidth: true
                    title: Translation.tr("Screen Time")
                }

                StyledFlickable {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true

                    ColumnLayout {
                        id: contentLayout
                        width: parent.width
                        spacing: Looks.dp(4)

                        // Range tabs
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Looks.dp(12)
                            Layout.rightMargin: Looks.dp(12)
                            Layout.topMargin: Looks.dp(4)
                            spacing: Looks.dp(4)

                            Repeater {
                                model: root.rangeOptions
                                delegate: WBorderlessButton {
                                    required property int index
                                    required property var modelData
                                    Layout.fillWidth: true
                                    property bool isSelected: root.selectedRange === index

                                    onClicked: root.selectedRange = index

                                    contentItem: WText {
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.label
                                        font.pixelSize: Looks.font.pixelSize.small
                                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                                        color: isSelected ? Looks.colors.fg : Looks.colors.subfg

                                        Behavior on color {
                                            enabled: Looks.transition.enabled
                                            animation: NumberAnimation {
                                                duration: Looks.transition.duration.normal
                                                easing.type: Easing.BezierSpline
                                                easing.bezierCurve: Looks.transition.easing.bezierCurve.standard
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Total time
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Looks.dp(16)
                            Layout.rightMargin: Looks.dp(16)
                            Layout.topMargin: Looks.dp(8)
                            spacing: 0

                            WText {
                                text: root._displayData
                                    ? ScreenTime.formatDuration(root._displayData.totalSeconds || 0)
                                    : "0s"
                                font.pixelSize: Looks.dp(32)
                                font.weight: Font.Bold
                                font.family: Looks.font.family.monospace
                                color: Looks.colors.accent
                            }

                            WText {
                                text: root.currentDays <= 1
                                    ? Translation.tr("today")
                                    : Translation.tr("last %1 days").arg(root.currentDays)
                                font.pixelSize: Looks.font.pixelSize.small
                                color: Looks.colors.subfg
                            }
                        }

                        // Hourly bar chart
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Looks.dp(12)
                            Layout.rightMargin: Looks.dp(12)
                            spacing: Looks.dp(6)
                            visible: root._displayData && (root._displayData.totalSeconds || 0) > 0

                            WPanelSeparator { color: Looks.colors.bg2Hover }

                            SectionText {
                                text: Translation.tr("Hourly activity")
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Looks.dp(64)
                                Layout.leftMargin: Looks.dp(4)
                                Layout.rightMargin: Looks.dp(4)
                                clip: true

                                Row {
                                    anchors.fill: parent
                                    anchors.bottomMargin: Looks.dp(14)
                                    spacing: Looks.dp(2)

                                    Repeater {
                                        model: 24
                                        delegate: Item {
                                            required property int index
                                            width: (parent.width - 46) / 24
                                            height: parent.height

                                            property real value: {
                                                if (!root._displayData || !root._displayData.hourly) return 0
                                                return root._displayData.hourly[index] || 0
                                            }
                                            property real maxVal: {
                                                if (!root._displayData || !root._displayData.hourly) return 1
                                                let m = 0
                                                for (let i = 0; i < 24; i++) {
                                                    const v = root._displayData.hourly[i] || 0
                                                    if (v > m) m = v
                                                }
                                                return m > 0 ? m : 1
                                            }
                                            property real barH: value > 0 ? Math.max(3, (value / maxVal) * parent.height) : 2

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Math.max(parent.width - 2, 2)
                                                height: barH
                                                radius: Math.min(width, height) / 2
                                                color: value > 0 ? Looks.colors.accent : Looks.colors.subfg
                                                opacity: value > 0 ? (0.35 + (value / maxVal) * 0.65) : 0.15

                                                Behavior on height {
                                                    enabled: Looks.transition.enabled
                                                    animation: NumberAnimation {
                                                        duration: Looks.transition.duration.medium
                                                        easing.type: Easing.BezierSpline
                                                        easing.bezierCurve: Looks.transition.easing.bezierCurve.standard
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    spacing: 0

                                    Repeater {
                                        model: 4
                                        delegate: WText {
                                            required property int index
                                            width: parent.width / 4
                                            text: (index * 6) + ":00"
                                            font.pixelSize: Looks.dp(9)
                                            color: Looks.colors.subfg
                                            horizontalAlignment: index === 0 ? Text.AlignLeft : Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }

                        // App list
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Looks.dp(12)
                            Layout.rightMargin: Looks.dp(12)
                            spacing: Looks.dp(4)
                            visible: root._appList.length > 0

                            WPanelSeparator { color: Looks.colors.bg2Hover }

                            SectionText {
                                text: Translation.tr("Most used")
                            }

                            Repeater {
                                model: root._appList.slice(0, 8)
                                delegate: ColumnLayout {
                                    required property int index
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Looks.dp(4)
                                    Layout.rightMargin: Looks.dp(4)
                                    spacing: Looks.dp(2)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Looks.dp(10)

                                        Rectangle {
                                            implicitWidth: Looks.dp(6)
                                            implicitHeight: Looks.dp(6)
                                            radius: Looks.dp(3)
                                            color: Looks.colors.accent
                                            opacity: 1 - (index * 0.08)
                                        }

                                        WText {
                                            Layout.fillWidth: true
                                            text: modelData.name || modelData.id
                                            elide: Text.ElideRight
                                        }

                                        WText {
                                            text: ScreenTime.formatDuration(modelData.seconds)
                                            font.family: Looks.font.family.monospace
                                            color: Looks.colors.subfg
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: Looks.dp(2)
                                        radius: Looks.dp(1)
                                        color: Looks.colors.accent
                                        opacity: 0.12
                                        width: parent.width * (modelData.seconds / root.maxAppSeconds)

                                        Behavior on width {
                                            enabled: Looks.transition.enabled
                                            animation: NumberAnimation {
                                                duration: Looks.transition.duration.medium
                                                easing.type: Easing.BezierSpline
                                                easing.bezierCurve: Looks.transition.easing.bezierCurve.standard
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Empty state
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Looks.dp(24)
                            visible: !root._displayData || (root._displayData.totalSeconds || 0) === 0
                            spacing: Looks.dp(8)

                            FluentIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: "timer"
                                implicitSize: Looks.dp(28)
                                color: Looks.colors.subfg
                            }

                            WText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("No screen time data yet")
                                color: Looks.colors.subfg
                            }
                        }
                    }
                }
            }
        }

        WPanelSeparator {}

        FooterRectangle {}
    }
}
