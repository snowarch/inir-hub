pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.field as Field
import qs.modules.iris.state

PanelWindow {
    id: root
    readonly property var options: Config.options?.iris?.notifications ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barTop: String(root.barOptions?.position ?? "top") === "top"
    readonly property var popups: (Notifications.popupList ?? []).slice(-3).reverse()
    readonly property real d: IrisStyle.density
    readonly property real topOffset: (root.barTop
        ? (Number(root.barOptions?.height ?? 42) + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2) + 10) * root.d
        : 10 * root.d) + IrisFrame.musicReach("top")

    visible: root.popups.length > 0 || exitLinger.running
    onPopupsChanged: if (root.popups.length === 0) exitLinger.restart()
    Timer { id: exitLinger; interval: IrisStyle.settleDuration * 2 + 80 }
    IrisOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-notifications"
    // Keys only while a banner takes a typed reply.
    property string replyingTo: ""
    WlrLayershell.keyboardFocus: root.replyingTo.length > 0 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        left: IrisFrame.band
        right: IrisFrame.band
        top: IrisFrame.band
    }
    readonly property real popupWidth: Math.min(Math.max(260, (root.screen?.width ?? 1920) - 16),
        Math.max(340, Number(root.options?.width ?? 380) * root.d) + 16)
    implicitWidth: root.screen?.width ?? root.popupWidth
    implicitHeight: Math.min((root.screen?.height ?? 1080) * 0.8, root.topOffset + 3 * 250 * root.d)
    mask: Region { item: popupColumn }
    readonly property var island: IrisState.islandGeometry?.[root.screen?.name ?? ""] ?? null
    readonly property real bubbleSize: Math.round(44 * root.d)

    property var blurBodies: ({})
    function publishBlur(key: string, shape: var): void {
        const next = Object.assign({}, root.blurBodies)
        if (shape) next[key] = shape
        else delete next[key]
        root.blurBodies = next
    }
    Field.IrisBlurRegion {
        window: root
        shapes: root.visible ? Object.values(root.blurBodies) : []
        windowWidth: root.width
        windowHeight: root.height
    }
    // One wallpaper source for the fallback window, borrowed by all its banners.
    Field.IrisField {
        anchors.fill: parent
        framed: false
        providesBackdrop: true
        compositorAllowed: true
    }

    property real now: Date.now()
    Timer { interval: 30000; repeat: true; running: root.visible; onTriggered: root.now = Date.now() }

    function activate(notification): void {
        const actions = notification?.actions ?? []
        const preferred = actions.find(action => action.identifier === "default")
        if (preferred) {
            Notifications.attemptInvokeAction(notification.notificationId, preferred.identifier)
            return
        }
        const key = String(notification?.appName ?? "").toLowerCase()
        if (key.length > 0 && CompositorService.isNiri) {
            const window = (NiriService.windows ?? []).find(w => String(w.app_id ?? "").toLowerCase().includes(key))
            if (window) NiriService.focusWindow(window.id)
        }
        Notifications.timeoutNotification(notification.notificationId)
    }

    ListView {
        IrisScrollFeel {}
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
        remove: Transition {
            NumberAnimation {
                property: "leave"
                from: 0
                to: 1
                duration: IrisStyle.recedeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.recedeCurve
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
        }
    }

    Component {
        id: bannerComponent

        Item {
            id: banner
            required property var modelData
            readonly property var notification: banner.modelData
            readonly property var actions: (banner.notification?.actions ?? []).filter(action => action.identifier !== "default")
            readonly property bool critical: ["2", "critical"].includes(String(banner.notification?.urgency ?? "").toLowerCase()) // the enum's number, as a string
            readonly property bool hovered: bannerHover.hovered
            // Two answers, one to refuse and one to take (a call, an invite): Apple's red and green discs.
            readonly property var declineAction: banner.actions.length === 2
                ? banner.actions.find(action => /decline|reject|deny|hang|refuse|ignore|cancel|dismiss|no$|rechaz/i.test(String(action.text ?? "") + " " + action.identifier)) ?? null : null
            readonly property var acceptAction: banner.declineAction ? banner.actions.find(action => action !== banner.declineAction) ?? null : null
            readonly property bool callStyle: banner.declineAction !== null && banner.acceptAction !== null
            readonly property bool canReply: Boolean(banner.notification?.canReply)
            readonly property bool replying: root.replyingTo === String(banner.notification?.notificationId ?? "-")
            readonly property string avatar: String(banner.notification?.image ?? "")
            function answer(action): void {
                Notifications.attemptInvokeAction(banner.notification.notificationId, action.identifier)
            }
            function sendReply(): void {
                if (Notifications.replyTo(banner.notification.notificationId, replyInput.text)) {
                    replyInput.text = ""
                    root.replyingTo = ""
                    Notifications.timeoutNotification(banner.notification.notificationId)
                }
            }
            width: popupColumn.width
            height: plate.height

            onHoveredChanged: if (banner.hovered || banner.replying) Notifications.cancelTimeout(banner.notification.notificationId)
            HoverHandler { id: bannerHover }

            property real appear: 0
            property string blurKey: ""
            Component.onCompleted: {
                banner.blurKey = String(banner.notification?.notificationId ?? "")
                root.publishBlur(banner.blurKey, banner.blurShape)
                banner.appear = 1
            }
            Component.onDestruction: {
                root.publishBlur(banner.blurKey, null)
                if (banner.replying) root.replyingTo = ""
            }
            readonly property var blurShape: {
                if (!root.visible || !IrisStyle.glassCompositor || plate.opacity < 0.999) return null
                return { x: popupColumn.x + banner.x + plate.x, y: popupColumn.y + banner.y + plate.y,
                    width: plate.width, height: plate.height, radius: plate.radius }
            }
            onBlurShapeChanged: if (banner.blurKey.length > 0) root.publishBlur(banner.blurKey, banner.blurShape)
            Behavior on appear { NumberAnimation { duration: IrisStyle.emergeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.emergeCurve } }
            property real leave: 0
            readonly property bool swiped: Math.abs(banner.swipe) > 1
            readonly property real bloom: Math.min(banner.appear, banner.swiped ? 1 : 1 - banner.leave)
            readonly property bool meltsIntoIsland: root.barTop && root.island !== null
            // Measured a tick later: wrapped text re-measures inside the layout while the plate's height is read.
            readonly property real measuredHeight: content.implicitHeight + 24 * root.d
            property real fullHeight: banner.measuredHeight
            onMeasuredHeightChanged: fullSync.restart()
            Timer { id: fullSync; interval: 0; onTriggered: banner.fullHeight = banner.measuredHeight }

            property real swipe: 0
            Behavior on swipe {
                enabled: !swipeDrag.active
                NumberAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing }
            }
            // On the delegate, which never moves: inside the plate the handler would measure its
            // translation in coordinates that slide with the swipe. Nothing may take the grab mid-swipe,
            // and every end (release, cancel, a lost grab) settles the banner: gone or back home.
            function settleSwipe(): void {
                if (Math.abs(banner.swipe) > banner.width * 0.3) {
                    banner.swipe = banner.swipe > 0 ? banner.width : -banner.width
                    dismissLater.restart()
                } else {
                    banner.swipe = 0
                }
            }
            DragHandler {
                id: swipeDrag
                target: null
                xAxis.enabled: true
                yAxis.enabled: false
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                onTranslationChanged: if (active) banner.swipe = translation.x
                onActiveChanged: if (!active) banner.settleSwipe()
                onCanceled: banner.settleSwipe()
            }

            IrisBodyShadow {
                x: plate.x
                y: plate.y + 4 * root.d
                width: plate.width
                height: plate.height
                radius: plate.radius
                blur: 18 * root.d
                spread: -3 * root.d
                color: IrisStyle.shadow
                opacity: plate.opacity * IrisStyle.shadowAt(banner.bloom)
            }
            Field.IrisField {
                anchors.fill: parent
                z: -1
                framed: false
                compositorAllowed: true
                opacity: plate.opacity
                sceneOrigin: Qt.point(root.margins.left + popupColumn.x + banner.x,
                    root.margins.top + popupColumn.y + banner.y)
                sceneSize: Qt.size(root.screen?.width ?? 0, root.screen?.height ?? 0)
                shapes: plate.opacity > 0 ? [{ x: plate.x, y: plate.y, width: plate.width,
                    height: plate.height, radius: plate.radius, paints: true, fuse: 0 }] : []
            }
            ClippingRectangle {
                id: plate
                width: Math.round(root.bubbleSize + (banner.width - root.bubbleSize) * banner.bloom)
                height: Math.round(root.bubbleSize + (banner.fullHeight - root.bubbleSize) * banner.bloom)
                clip: true
                x: Math.round((banner.width - width) / 2 + banner.swipe)
                readonly property real islandLift: banner.meltsIntoIsland
                    ? (root.island.y + root.island.bubble / 2) - (popupColumn.y + banner.y + root.bubbleSize / 2) : -18 * root.d
                y: Math.round(banner.meltsIntoIsland ? plate.islandLift * (1 - banner.bloom) : (1 - banner.bloom) * -18 * root.d)
                opacity: Math.min(1, banner.bloom * 3)
                    * (1 - Math.min(1, Math.abs(banner.swipe) / (banner.width * 0.6)))
                // Apple's Island: a capsule while it is one line, a deep round once it holds more.
                radius: Math.min(height / 2, root.bubbleSize / 2 + (Math.round(30 * root.d) - root.bubbleSize / 2) * banner.bloom)
                color: IrisStyle.bodyClip
                border.width: banner.critical ? 1 : 0
                border.color: banner.critical ? IrisStyle.tintBorder(IrisStyle.danger)
                    : ColorUtils.applyAlpha(IrisStyle.border, IrisStyle.border.a * banner.bloom)

                Timer {
                    id: dismissLater
                    interval: IrisStyle.duration(180)
                    onTriggered: Notifications.timeoutNotification(banner.notification.notificationId)
                }
                TapHandler {
                    onTapped: root.activate(banner.notification)
                }

                ColumnLayout {
                    id: content
                    x: 12 * root.d
                    y: 12 * root.d
                    width: banner.width - 24 * root.d
                    spacing: 10 * root.d

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * root.d

                        IrisNotificationIcon {
                            Layout.alignment: Qt.AlignVCenter
                            transform: Translate {
                                x: ((root.bubbleSize - 44 * root.d) / 2 - 12 * root.d) * (1 - banner.bloom)
                                y: ((root.bubbleSize - 44 * root.d) / 2 - 12 * root.d) * (1 - banner.bloom)
                            }
                            size: Math.round(44 * root.d)
                            appName: String(banner.notification?.appName ?? "")
                            appIcon: String(banner.notification?.appIcon ?? "")
                            image: banner.avatar
                            summary: String(banner.notification?.summary ?? "")
                            critical: banner.critical
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            opacity: IrisStyle.contentAt(banner.bloom)
                            // The app small over the name, as a phone's call: "mobile", then who.
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8 * root.d
                                IrisText {
                                    Layout.fillWidth: true
                                    text: String(banner.notification?.appName ?? "")
                                    visible: text.length > 0 && text !== String(banner.notification?.summary ?? "")
                                    color: IrisStyle.textTertiary
                                    font.pixelSize: IrisStyle.typeFootnote
                                    font.weight: IrisStyle.weight(Font.Medium)
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
                                    color: IrisStyle.textTertiary
                                    font.pixelSize: IrisStyle.typeFootnote
                                    font.weight: IrisStyle.weight(Font.Medium)
                                    font.features: ({ "tnum": 1 })
                                }
                            }
                            IrisText {
                                Layout.fillWidth: true
                                text: String(banner.notification?.summary || banner.notification?.appName || "")
                                font.pixelSize: IrisStyle.typeBody
                                font.weight: IrisStyle.weight(Font.DemiBold)
                                elide: Text.ElideRight
                            }
                            IrisText {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: String(banner.notification?.body ?? "").replace(/<[^>]*>/g, "")
                                color: IrisStyle.textSecondary
                                font.pixelSize: banner.callStyle ? IrisStyle.typeMeta : IrisStyle.typeLabel
                                wrapMode: Text.Wrap
                                maximumLineCount: banner.hovered || banner.replying ? 8 : banner.callStyle ? 1 : 2
                                elide: Text.ElideRight
                            }
                        }

                        // Refuse and take as two discs at the end, red and green.
                        Row {
                            visible: banner.callStyle
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 10 * root.d
                            opacity: IrisStyle.contentAt(banner.bloom)
                            Disc {
                                tint: IrisStyle.identity.red
                                glyph: /call|answer|llamad/i.test(String(banner.acceptAction?.text ?? "")) ? "call_end" : "close"
                                label: String(banner.declineAction?.text ?? "")
                                onClicked: banner.answer(banner.declineAction)
                            }
                            Disc {
                                tint: IrisStyle.identity.green
                                glyph: /call|answer|llamad/i.test(String(banner.acceptAction?.text ?? "")) ? "call" : "check"
                                label: String(banner.acceptAction?.text ?? "")
                                onClicked: banner.answer(banner.acceptAction)
                            }
                        }
                    }

                    // The answers as capsules, the last one filled (Apple's "Buy"); Reply opens a field in place.
                    Flow {
                        Layout.fillWidth: true
                        Layout.leftMargin: 56 * root.d
                        visible: !banner.callStyle && !banner.replying && (banner.actions.length > 0 || banner.canReply)
                        spacing: 6 * root.d
                        opacity: IrisStyle.contentAt(banner.bloom)
                        Repeater {
                            model: banner.callStyle ? [] : banner.actions
                            Capsule {
                                required property var modelData
                                required property int index
                                label: String(modelData.text ?? "")
                                main: index === banner.actions.length - 1 && !banner.canReply
                                onClicked: banner.answer(modelData)
                            }
                        }
                        Capsule {
                            visible: banner.canReply
                            glyph: "reply"
                            label: Translation.tr("Reply")
                            main: true
                            onClicked: {
                                root.replyingTo = String(banner.notification.notificationId)
                                Notifications.cancelTimeout(banner.notification.notificationId)
                                replyInput.forceActiveFocus()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: banner.replying
                        spacing: 8 * root.d
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Math.round(38 * root.d)
                            radius: height / 2
                            color: IrisStyle.fill
                            border.width: 1
                            border.color: replyInput.activeFocus ? IrisStyle.tintBorder(IrisStyle.accent) : IrisStyle.hairline
                            TextInput {
                                id: replyInput
                                anchors.fill: parent
                                anchors.leftMargin: 16 * root.d
                                anchors.rightMargin: 16 * root.d
                                verticalAlignment: TextInput.AlignVCenter
                                color: IrisStyle.text
                                selectionColor: IrisStyle.tintFillHover(IrisStyle.accent)
                                font.family: IrisStyle.fontMain
                                font.pixelSize: IrisStyle.typeBody
                                clip: true
                                onAccepted: banner.sendReply()
                                Keys.onEscapePressed: root.replyingTo = ""
                                IrisText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: replyInput.text.length === 0
                                    text: banner.notification?.replyHint || Translation.tr("Reply")
                                    color: IrisStyle.textTertiary
                                    font.pixelSize: IrisStyle.typeBody
                                }
                            }
                        }
                        Disc {
                            size: Math.round(38 * root.d)
                            tint: IrisStyle.accent
                            glyph: "arrow_upward"
                            label: Translation.tr("Send")
                            enabled: replyInput.text.trim().length > 0
                            opacity: enabled ? 1 : 0.4
                            onClicked: banner.sendReply()
                        }
                    }
                }

                Rectangle {
                    x: 5 * root.d
                    y: 5 * root.d
                    width: Math.round(22 * root.d)
                    height: width
                    radius: IrisStyle.capsule(width)
                    color: closeArea.containsMouse ? IrisStyle.surfaceHighest : IrisStyle.surfaceHigh
                    border.width: 1
                    border.color: IrisStyle.hairlineStrong
                    opacity: banner.hovered ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
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

    component Disc: MouseArea {
        id: disc
        property color tint: IrisStyle.accent
        property string glyph: ""
        property string label: ""
        property real size: Math.round(40 * root.d)
        width: disc.size
        height: disc.size
        implicitWidth: disc.size
        implicitHeight: disc.size
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: disc.label
        scale: disc.pressed ? IrisStyle.pressScale(0.9) : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(disc.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: disc.tint
            Rectangle { anchors.fill: parent; radius: width / 2; color: IrisStyle.text; opacity: disc.containsMouse ? 0.12 : 0 }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: disc.glyph
            fill: 1
            iconSize: Math.round(disc.size * 0.5)
            color: IrisStyle.onTintFor(disc.tint)
        }
    }
    component Capsule: IrisButton {
        id: capsule
        property string glyph: ""
        property bool main: false
        property string label: ""
        implicitHeight: Math.round(32 * root.d)
        implicitWidth: capsuleRow.implicitWidth + 28 * root.d
        buttonRadius: IrisStyle.capsule(height)
        buttonRadiusPressed: IrisStyle.capsule(height)
        colBackground: capsule.main ? IrisStyle.accent : IrisStyle.fill
        colBackgroundHover: capsule.main ? IrisStyle.accent : IrisStyle.fillHover
        Accessible.name: capsule.label
        Row {
            id: capsuleRow
            anchors.centerIn: parent
            spacing: 5 * root.d
            MaterialSymbol {
                visible: capsule.glyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: capsule.glyph
                fill: 1
                iconSize: Math.round(16 * root.d)
                color: capsule.main ? IrisStyle.onTintFor(IrisStyle.accent) : IrisStyle.text
            }
            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: capsule.label
                color: capsule.main ? IrisStyle.onTintFor(IrisStyle.accent) : IrisStyle.text
                font.pixelSize: IrisStyle.typeLabel
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
        }
    }
}
