pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root
    readonly property var options: Config.options?.iris?.notifications ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barTop: String(root.barOptions?.position ?? "top") === "top"
    readonly property var popups: (Notifications.popupList ?? []).slice(-3).reverse()
    readonly property real d: IrisStyle.density
    readonly property real topOffset: root.barTop
        ? (Number(root.barOptions?.height ?? 42) + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2) + 10) * root.d
        : 10 * root.d

    visible: root.popups.length > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-notifications"
    anchors {
        top: true
        left: true
        right: true
    }
    readonly property real popupWidth: Math.min(Math.max(260, (root.screen?.width ?? 1920) - 16),
        Math.max(340, Number(root.options?.width ?? 380) * root.d) + 16)
    implicitWidth: root.screen?.width ?? root.popupWidth
    implicitHeight: root.topOffset + popupColumn.implicitHeight + 24 * root.d
    // Only the banners take input; the transparent strip beside them passes through.
    mask: Region { item: popupColumn }

    // Relative times ("now", "2m") refresh while banners are visible.
    property real now: Date.now()
    Timer { interval: 30000; repeat: true; running: root.visible; onTriggered: root.now = Date.now() }

    function activate(notification): void {
        const actions = notification?.actions ?? []
        const preferred = actions.find(action => action.identifier === "default")
        if (preferred) {
            Notifications.attemptInvokeAction(notification.notificationId, preferred.identifier)
            return
        }
        // No default action: bring the sender forward when it has a window.
        const key = String(notification?.appName ?? "").toLowerCase()
        if (key.length > 0 && CompositorService.isNiri) {
            const window = (NiriService.windows ?? []).find(w => String(w.app_id ?? "").toLowerCase().includes(key))
            if (window) NiriService.focusWindow(window.id)
        }
        Notifications.timeoutNotification(notification.notificationId)
    }

    ColumnLayout {
        id: popupColumn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.topOffset
        width: Math.min(root.popupWidth - 16, parent.width - 16)
        spacing: 8 * root.d

        Repeater {
            model: root.popups
            delegate: bannerComponent
        }
    }

    // ── Island: banners that drop from the Island ────────────────────────
    Component {
        id: bannerComponent

        Item {
            id: banner
            required property var modelData
            readonly property var notification: banner.modelData
            readonly property var actions: (banner.notification?.actions ?? []).filter(action => action.identifier !== "default")
            readonly property bool critical: String(banner.notification?.urgency ?? "") === "critical"
            readonly property bool hovered: bannerHover.hovered
            Layout.fillWidth: true
            implicitHeight: plate.height

            // Hovering keeps a banner around; it then waits to be dismissed.
            onHoveredChanged: if (banner.hovered) Notifications.cancelTimeout(banner.notification.notificationId)
            HoverHandler { id: bannerHover }

            // Drops out of the Island: short travel, slight scale, fast fade.
            property real appear: 0
            Component.onCompleted: banner.appear = 1
            Behavior on appear { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }

            // Horizontal swipe dismisses.
            property real swipe: 0
            Behavior on swipe {
                enabled: !swipeDrag.active
                NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: plate
                width: parent.width
                height: content.implicitHeight + 24 * root.d
                x: banner.swipe
                y: (1 - banner.appear) * (root.barTop ? -18 : 18) * root.d
                scale: 0.94 + 0.06 * banner.appear
                transformOrigin: root.barTop ? Item.Top : Item.Bottom
                opacity: Math.min(banner.appear * 1.4, 1) * (1 - Math.min(1, Math.abs(banner.swipe) / (banner.width * 0.6)))
                radius: Math.round(22 * root.d)
                color: IrisStyle.surface
                border.width: banner.critical ? 1 : 0
                border.color: ColorUtils.applyAlpha(IrisStyle.danger, 0.7)
                Behavior on height { NumberAnimation { duration: IrisStyle.duration(160); easing.type: Easing.OutCubic } }

                DragHandler {
                    id: swipeDrag
                    target: null
                    xAxis.enabled: true
                    yAxis.enabled: false
                    onTranslationChanged: banner.swipe = translation.x
                    onActiveChanged: {
                        if (active) return
                        if (Math.abs(banner.swipe) > banner.width * 0.3) {
                            banner.swipe = banner.swipe > 0 ? banner.width : -banner.width
                            dismissLater.restart()
                        } else {
                            banner.swipe = 0
                        }
                    }
                }
                Timer {
                    id: dismissLater
                    interval: IrisStyle.duration(180)
                    onTriggered: Notifications.timeoutNotification(banner.notification.notificationId)
                }
                TapHandler {
                    onTapped: root.activate(banner.notification)
                }

                RowLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12 * root.d
                    anchors.leftMargin: 14 * root.d
                    spacing: 12 * root.d

                    // Sender artwork: image with the app as a badge, the app icon,
                    // or an iRiS tile for senders that publish nothing usable.
                    IrisNotificationIcon {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 2 * root.d
                        size: Math.round(38 * root.d)
                        appName: String(banner.notification?.appName ?? "")
                        appIcon: String(banner.notification?.appIcon ?? "")
                        image: String(banner.notification?.image ?? "")
                        summary: String(banner.notification?.summary ?? "")
                        critical: banner.critical
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8 * root.d
                            IrisText {
                                Layout.fillWidth: true
                                text: String(banner.notification?.summary || banner.notification?.appName || "")
                                font.pixelSize: 13.5 * IrisStyle.typeScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            IrisText {
                                text: {
                                    void root.now
                                    const seconds = Math.max(0, Math.floor((root.now - Number(banner.notification?.time ?? root.now)) / 1000))
                                    return seconds < 60 ? Translation.tr("now")
                                        : seconds < 3600 ? Translation.tr("%1m").arg(Math.floor(seconds / 60))
                                        : Translation.tr("%1h").arg(Math.floor(seconds / 3600))
                                }
                                color: IrisStyle.muted
                                font.pixelSize: 11.5 * IrisStyle.typeScale
                            }
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: String(banner.notification?.body ?? "").replace(/<[^>]*>/g, "")
                            color: IrisStyle.subtext
                            font.pixelSize: 12.5 * IrisStyle.typeScale
                            wrapMode: Text.Wrap
                            // Hover reveals the rest of a long message.
                            maximumLineCount: banner.hovered ? 8 : 2
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: text.length > 0 && text !== String(banner.notification?.summary ?? "")
                            text: String(banner.notification?.appName ?? "")
                            color: IrisStyle.muted
                            font.pixelSize: 11 * IrisStyle.typeScale
                            elide: Text.ElideRight
                        }

                        Flow {
                            Layout.fillWidth: true
                            Layout.topMargin: 8 * root.d
                            visible: banner.actions.length > 0
                            spacing: 6 * root.d
                            Repeater {
                                model: banner.actions
                                IrisButton {
                                    id: actionButton
                                    required property var modelData
                                    implicitHeight: Math.round(28 * root.d)
                                    implicitWidth: actionLabel.implicitWidth + 24 * root.d
                                    buttonRadius: height / 2
                                    buttonRadiusPressed: height / 2
                                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
                                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.18)
                                    Accessible.name: String(actionButton.modelData.text ?? "")
                                    onClicked: Notifications.attemptInvokeAction(banner.notification.notificationId, actionButton.modelData.identifier)
                                    IrisText {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: String(actionButton.modelData.text ?? "")
                                        font.pixelSize: 12 * IrisStyle.typeScale
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                // Close button sits on the corner and appears with hover.
                Rectangle {
                    // Inside the plate so the input mask keeps it clickable.
                    x: 5 * root.d
                    y: 5 * root.d
                    width: Math.round(22 * root.d)
                    height: width
                    radius: width / 2
                    color: closeArea.containsMouse ? IrisStyle.surfaceHighest : IrisStyle.surfaceHigh
                    border.width: 1
                    border.color: IrisStyle.hairlineStrong
                    opacity: banner.hovered ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Math.round(13 * root.d)
                        color: IrisStyle.text
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: Translation.tr("Dismiss")
                        onClicked: Notifications.timeoutNotification(banner.notification.notificationId)
                    }
                }
            }
        }
    }

}
