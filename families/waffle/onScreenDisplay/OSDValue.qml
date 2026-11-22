import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Waffle Next OSD: a capsule with the icon on an accent well, the name and the percent over a thick bar.
WBarAttachedPanelContent {
    id: root
    required property string iconName
    property string label: ""
    property real value
    property bool muted: false
    property bool showNumber: true
    readonly property real shown: Math.max(0, Math.min(1, root.value))

    property Timer timer: Timer {
        id: autoCloseTimer
        running: true
        interval: Config.options?.osd?.timeout ?? 3000
        repeat: false
        onTriggered: {
            root.close();
        }
    }

    contentItem: WPane {
        anchors.centerIn: parent
        radius: height / 2
        borderColor: Looks.colors.ambientShadow
        screenX: root.panelScreenX + root.visualMargin
        screenY: root.panelScreenY + root.visualMargin
        screenWidth: root._screenW
        screenHeight: root._screenH

        contentItem: Item {
            implicitWidth: Looks.dp(296)
            implicitHeight: Looks.dp(56)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Looks.dp(10)
                anchors.rightMargin: Looks.dp(22)
                spacing: Looks.dp(12)

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Looks.dp(36)
                    implicitHeight: Looks.dp(36)
                    radius: height / 2
                    color: root.muted ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.08 : 0.06) : Qt.alpha(Looks.colors.accent, Looks.dark ? 0.24 : 0.16)

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: root.iconName
                        filled: !root.muted
                        implicitSize: Looks.dp(18)
                        color: root.muted ? Looks.colors.subfg : Looks.colors.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Looks.dp(6)

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.label.length > 0 || root.showNumber
                        spacing: Looks.dp(8)

                        WText {
                            Layout.fillWidth: true
                            text: root.muted ? Translation.tr("Muted") : root.label
                            font.pixelSize: Looks.font.pixelSize.small
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.subfg
                            elide: Text.ElideRight
                        }
                        WText {
                            visible: root.showNumber
                            text: Math.round(root.value * 100) + "%"
                            font.pixelSize: Looks.font.pixelSize.small
                            font.weight: Looks.font.weight.strong
                            font.features: { "tnum": 1 }
                        }
                    }

                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        implicitHeight: Looks.dp(6)
                        radius: height / 2
                        color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.12 : 0.1)

                        Rectangle {
                            width: Math.max(height, track.width * root.shown)
                            height: parent.height
                            radius: height / 2
                            visible: root.shown > 0
                            color: root.muted ? Looks.colors.subfg : Looks.colors.accent

                            Behavior on width {
                                enabled: Looks.transition.enabled
                                NumberAnimation {
                                    duration: Looks.transition.duration.fast
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
