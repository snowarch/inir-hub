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

    // A banner that leaves still animates after it has left the list: the
    // surface stays mapped until the last exit has played.
    visible: root.popups.length > 0 || exitLinger.running
    onPopupsChanged: if (root.popups.length === 0) exitLinger.restart()
    Timer { id: exitLinger; interval: IrisStyle.settleDuration * 2 + 80 }
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
    // A stable canvas tall enough for three expanded banners: the layer surface
    // never resizes as banners arrive, grow on hover or leave; input is the mask.
    implicitHeight: Math.min((root.screen?.height ?? 1080) * 0.8, root.topOffset + 3 * 250 * root.d)
    mask: Region { item: popupColumn }
    // Where a banner melts back into: the resting Island on this output, when it
    // hangs from the top edge above the banners.
    readonly property var island: GlobalStates.irisIslandGeometry?.[root.screen?.name ?? ""] ?? null
    readonly property real bubbleSize: Math.round(44 * root.d)

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

    // Banners keyed by notification: a new one never recreates the others, and a
    // leaving one keeps its delegate for the exit transition.
    ListView {
        id: popupColumn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.topOffset
        width: Math.min(root.popupWidth - 16, parent.width - 16)
        height: Math.max(1, popupColumn.contentHeight)
        spacing: 8 * root.d
        interactive: false
        model: ScriptModel {
            objectProp: "notificationId"
            values: root.popups
        }
        delegate: bannerComponent
        // Leaving: the banner folds back into its bubble, which melts into the Island.
        remove: Transition {
            NumberAnimation {
                property: "leave"
                from: 0
                to: 1
                duration: IrisStyle.settleDuration * 1.6
                easing.type: Easing.Linear
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
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
            width: popupColumn.width
            height: plate.height

            // Hovering keeps a banner around; it then waits to be dismissed.
            onHoveredChanged: if (banner.hovered) Notifications.cancelTimeout(banner.notification.notificationId)
            HoverHandler { id: bannerHover }

            // A bubble out of the Island: the sender's icon arrives as a disc under
            // it and blooms into the banner — width, height and radius on one
            // progress — with the text arriving once the shape has formed.
            property real appear: 0
            Component.onCompleted: banner.appear = 1
            Behavior on appear { NumberAnimation { duration: IrisStyle.settleDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
            readonly property real bloomIn: Math.min(1, banner.appear * 1.25)
            // Leaving (driven by the list's remove transition, 0 → 1): fold back into
            // the bubble over the first half, then rise into the Island and melt.
            property real leave: 0
            readonly property bool swiped: Math.abs(banner.swipe) > 1
            readonly property real fold: banner.swiped ? 0 : Math.min(1, banner.leave * 2)
            readonly property real rise: {
                if (banner.swiped) return 0
                const t = Math.max(0, banner.leave * 2 - 1)
                return t * t * (3 - 2 * t)
            }
            // The same front-loaded curve both ways: blooming settles into the banner,
            // folding settles into the bubble.
            readonly property real bloom: Math.min(banner.bloomIn, 1 - (1 - Math.pow(1 - banner.fold, 3)))
            readonly property bool meltsIntoIsland: root.barTop && root.island !== null
            readonly property real fullHeight: content.implicitHeight + 24 * root.d

            // Horizontal swipe dismisses.
            property real swipe: 0
            Behavior on swipe {
                enabled: !swipeDrag.active
                NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: plate
                width: Math.round(root.bubbleSize + (banner.width - root.bubbleSize) * banner.bloom)
                height: Math.round(root.bubbleSize + (banner.fullHeight - root.bubbleSize) * banner.bloom)
                clip: true
                // Centred while it is a bubble; the swipe carries the whole plate.
                x: Math.round((banner.width - width) / 2 + banner.swipe)
                // Rises from just under the Island on arrival, and back into it on leaving.
                readonly property real islandLift: banner.meltsIntoIsland
                    ? (root.island.y + root.island.bubble / 2) - (popupColumn.y + banner.y + root.bubbleSize / 2) : -18 * root.d
                y: Math.round(banner.meltsIntoIsland
                    ? plate.islandLift * Math.max(1 - Math.min(1, banner.appear * 2.2), banner.rise)
                    : (1 - banner.appear) * -18 * root.d)
                scale: 1 - 0.45 * banner.rise
                // Melts as it reaches the Island, not on the way there.
                opacity: Math.min(1, banner.appear * 3) * (1 - Math.max(0, banner.rise - 0.6) / 0.4)
                    * (1 - Math.min(1, Math.abs(banner.swipe) / (banner.width * 0.6)))
                radius: Math.min(height / 2, root.bubbleSize / 2 + (Math.round(22 * root.d) - root.bubbleSize / 2) * banner.bloom)
                color: IrisStyle.surface
                border.width: banner.critical ? 1 : 0
                border.color: ColorUtils.applyAlpha(IrisStyle.danger, 0.7)

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

                // Laid out at the banner's full width, so text never reflows while the
                // plate blooms; the plate clips it and it fades in once formed.
                RowLayout {
                    id: content
                    x: 14 * root.d
                    y: 12 * root.d
                    width: banner.width - 26 * root.d
                    spacing: 12 * root.d

                    // Sender artwork: image with the app as a badge, the app icon,
                    // or an iRiS tile for senders that publish nothing usable. It is
                    // the bubble: centred in the disc, sliding to its place as it blooms.
                    IrisNotificationIcon {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 2 * root.d
                        transform: Translate {
                            x: ((root.bubbleSize - 38 * root.d) / 2 - 14 * root.d) * (1 - banner.bloom)
                            y: ((root.bubbleSize - 38 * root.d) / 2 - 14 * root.d) * (1 - banner.bloom)
                        }
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
                        opacity: Math.max(0, Math.min(1, (banner.bloom - 0.55) / 0.45))

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
