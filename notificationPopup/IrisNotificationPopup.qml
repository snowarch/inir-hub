pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root
    readonly property var options: Config.options?.iris?.notifications ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property var popups: (Notifications.popupList ?? []).slice(-3).reverse()
    readonly property real topOffset: String(root.barOptions?.position ?? "top") === "top"
        ? (Number(root.barOptions?.height ?? 42) + Number(root.barOptions?.margin ?? 8) * 2 + 8) * IrisStyle.density
        : 8

    visible: root.popups.length > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-notifications"
    anchors { top: true; right: !IrisStyle.island }
    implicitWidth: Math.max(260, Math.min(root.screen?.width ?? 1920,
        Math.max(340, Number(root.options?.width ?? 380) * IrisStyle.density) + 16))
    implicitHeight: root.topOffset + popupColumn.implicitHeight + 8

    ColumnLayout {
        id: popupColumn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.topOffset
        anchors.rightMargin: 8
        width: parent.width - 16
        spacing: 7 * IrisStyle.density

        Repeater {
            model: root.popups
            IrisSurface {
                id: notificationCard
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: cardContent.implicitHeight + 20 * IrisStyle.density
                raised: true

                RowLayout {
                    id: cardContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10 * IrisStyle.density
                    anchors.rightMargin: 8 * IrisStyle.density
                    spacing: 9 * IrisStyle.density

                    Rectangle {
                        visible: !IrisStyle.island
                        Layout.preferredWidth: 3 * IrisStyle.density
                        Layout.preferredHeight: Math.max(34 * IrisStyle.density, cardContent.implicitHeight - 4)
                        radius: width / 2
                        color: IrisStyle.accent
                    }

                    SmartAppIcon {
                        icon: notificationCard.modelData?.appIcon || "dialog-information"
                        fallback: "dialog-information"
                        iconSize: Math.round(25 * IrisStyle.density)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        IrisText {
                            Layout.fillWidth: true
                            text: String(notificationCard.modelData?.appName ?? "").toUpperCase()
                            visible: text.length > 0
                            role: IrisText.Eyebrow
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: notificationCard.modelData?.summary ?? notificationCard.modelData?.appName ?? ""
                            font.family: IrisStyle.fontTitle
                            font.pixelSize: 14 * IrisStyle.typeScale
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: notificationCard.modelData?.body ?? ""
                            font.pixelSize: 11 * IrisStyle.typeScale
                            color: IrisStyle.subtext
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                    IrisIconButton {
                        materialIcon: "close"
                        onClicked: Notifications.timeoutNotification(notificationCard.modelData.notificationId)
                    }
                }
            }
        }
    }
}
