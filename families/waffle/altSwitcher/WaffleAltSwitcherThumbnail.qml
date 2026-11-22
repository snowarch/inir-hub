pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.state

// Waffle Next switcher card: the app and its title on top, the window itself below; the chosen card lifts on a lit
// plate with an accent ring and its picture moves.
Item {
    id: root

    required property var item
    property bool selected: false
    property int thumbnailWidth: 280
    property int thumbnailHeight: 180
    readonly property int pad: Looks.dp(8)
    readonly property int headerHeight: Looks.dp(28)

    signal clicked

    implicitWidth: thumbnailWidth + pad * 2
    implicitHeight: headerHeight + thumbnailHeight + pad * 2

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: Looks.radius.large + root.pad / 2
        color: root.selected ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.1 : 0.07)
            : mouseArea.containsMouse ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.04) : "transparent"
        border.width: root.selected ? 2 : 0
        border.color: Looks.colors.accent
        scale: mouseArea.pressed ? 0.97 : 1

        Behavior on color {
            ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0 }
        }
        Behavior on scale {
            NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.OutCubic }
        }

        RowLayout {
            id: header
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: root.pad + Looks.dp(2)
                rightMargin: root.pad + Looks.dp(2)
                topMargin: root.pad
            }
            height: root.headerHeight - Looks.dp(4)
            spacing: Looks.dp(8)

            IconImage {
                implicitSize: Looks.dp(18)
                source: root.item?.icon ?? ""
            }
            WText {
                Layout.fillWidth: true
                text: root.item?.title || root.item?.appName || ""
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: root.selected ? Looks.font.weight.strong : Looks.font.weight.regular
                elide: Text.ElideRight
            }
            Rectangle {
                visible: (root.item?.workspaceIdx ?? 0) > 0
                implicitWidth: wsLabel.implicitWidth + Looks.dp(12)
                implicitHeight: Looks.dp(18)
                radius: height / 2
                color: root.selected ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, 0.08)

                WText {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: root.item?.workspaceIdx ?? ""
                    font.pixelSize: Looks.font.pixelSize.small
                    font.weight: Looks.font.weight.strong
                    color: root.selected ? Looks.colors.accentFg : Looks.colors.subfg
                }
            }
        }

        ClippingRectangle {
            id: preview
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: root.pad
            }
            height: root.thumbnailHeight
            radius: Looks.radius.large
            color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.05 : 0.04)

            // the app, while no picture of the window is in
            IconImage {
                anchors.centerIn: parent
                implicitSize: Looks.dp(64)
                source: root.item?.icon ?? ""
                visible: !still.visible && !live.streaming
            }

            Image {
                id: still
                anchors.fill: parent
                source: WindowPreviewService.getPreviewUrl(root.item?.id ?? -1)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: root.thumbnailWidth
                sourceSize.height: root.thumbnailHeight
                visible: status === Image.Ready && !live.streaming
            }

            LiveWindowCapture {
                id: live
                anchors.fill: parent
                windowId: root.item?.id ?? -1
                active: WaffleState.altSwitcherOpen
                live: root.selected
            }

            // the cards you did not pick step back a little
            Rectangle {
                anchors.fill: parent
                color: Looks.colors.bg0Opaque
                opacity: root.selected ? 0 : 0.18

                Behavior on opacity {
                    NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0 }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
