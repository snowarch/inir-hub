pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.iris.style
import "../state"
import "../components"

Item {
    id: root
    property bool windowed: false
    property bool open: false
    readonly property alias frame: cardFrame
    readonly property real d: IrisStyle.density

    readonly property real availW: root.width > 0 ? root.width : (root.QsWindow.window?.screen?.width ?? 1920)
    readonly property real availH: root.height > 0 ? root.height : (root.QsWindow.window?.screen?.height ?? 1080)
    readonly property bool isVertical: AndroidState.verticalLayout
    property bool displayedVertical: AndroidState.verticalLayout
    property real contentProgress: 1.0

    onIsVerticalChanged: {
        if (!root.open) {
            root.displayedVertical = root.isVertical
            root.contentProgress = 1.0
            return
        }
        morphTransition.restart()
    }

    SequentialAnimation {
        id: morphTransition
        NumberAnimation {
            target: root
            property: "contentProgress"
            to: 0.0
            duration: 80
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                root.displayedVertical = root.isVertical
            }
        }
        NumberAnimation {
            target: root
            property: "contentProgress"
            to: 1.0
            duration: 240
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
        }
    }

    implicitWidth: Math.round((root.isVertical ? 440 : 640) * root.d)
    implicitHeight: Math.round(headerBar.implicitHeight + 10 * root.d + bodyCol.implicitHeight + 32 * root.d)
    readonly property int enterDuration: Appearance.animation?.elementMoveEnter?.duration ?? 400
    readonly property int exitDuration: Appearance.animation?.elementMoveExit?.duration ?? 200

    property bool armed: false
    property bool launched: false
    property int launchFrames: 0
    readonly property bool presented: root.windowed ? root.open : (root.open && root.launched)
    readonly property bool warming: !root.windowed && root.armed && !root.launched && cardFrame.progress <= 0

    function syncOpenState(): void {
        if (root.windowed) {
            root.armed = root.open
            root.launched = root.open
            return
        }
        if (root.open) {
            root.launchFrames = 0
            root.launched = false
            root.armed = true
        } else {
            root.armed = false
            root.launched = false
        }
    }

    Component.onCompleted: root.syncOpenState()
    onOpenChanged: root.syncOpenState()
    onWindowedChanged: root.syncOpenState()

    Connections {
        target: root.Window.window
        enabled: root.armed && !root.launched
        function onFrameSwapped(): void {
            if (++root.launchFrames >= 1)
                root.launched = true
        }
    }

    Timer {
        interval: 60
        running: root.armed && !root.launched
        onTriggered: root.launched = true
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open && !root.windowed
        onClicked: AndroidState.open = false
    }

    Rectangle {
        id: cardFrame
        property real progress: 0.0
        property real panelOpacity: 0.0
        property real panelTranslateY: Math.round(-24 * root.d)

        width: root.windowed ? root.availW : Math.round(Math.min((root.isVertical ? 460 : 640) * root.d, root.availW - 32 * root.d))
        readonly property real naturalHeight: headerBar.implicitHeight + Math.round(10 * root.d) + bodyCol.implicitHeight + Math.round(32 * root.d)
        readonly property real minTargetHeight: Math.round((root.isVertical ? 580 : 430) * root.d)
        height: root.windowed ? root.availH : Math.min(root.availH - Math.round(84 * root.d), Math.max(cardFrame.minTargetHeight, cardFrame.naturalHeight))
        x: root.windowed ? 0 : Math.round((root.availW - width) / 2)
        y: root.windowed ? 0 : Math.round(52 * root.d)
        radius: root.windowed ? 0 : 22
        color: Appearance.m3colors.m3surfaceContainer
        border.width: root.windowed ? 0 : 1
        border.color: Appearance.m3colors.m3outlineVariant
        opacity: root.warming ? 0.01 : cardFrame.panelOpacity
        scale: root.windowed ? 1.0 : 0.94

        transform: Translate {
            y: root.windowed ? 0 : cardFrame.panelTranslateY
        }

        states: [
            State {
                name: "open"
                when: root.presented
                PropertyChanges {
                    target: cardFrame
                    progress: 1.0
                    panelOpacity: 1.0
                    scale: 1.0
                    panelTranslateY: 0
                }
            },
            State {
                name: "closed"
                when: !root.presented
                PropertyChanges {
                    target: cardFrame
                    progress: 0.0
                    panelOpacity: 0.0
                    scale: root.windowed ? 0.96 : 0.92
                    panelTranslateY: Math.round(-24 * root.d)
                }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                enabled: Appearance.animationsEnabled
                ParallelAnimation {
                    NumberAnimation {
                        target: cardFrame
                        property: "progress"
                        from: 0.0
                        to: 1.0
                        duration: root.enterDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                    }
                    NumberAnimation {
                        target: cardFrame
                        property: "panelOpacity"
                        from: 0.0
                        to: 1.0
                        duration: Math.round(root.enterDuration * 0.7)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1]
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: cardFrame
                            property: "scale"
                            from: root.windowed ? 0.96 : 0.92
                            to: 1.018
                            duration: Math.round(root.enterDuration * 0.62)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: cardFrame
                            property: "scale"
                            to: 1.0
                            duration: Math.round(root.enterDuration * 0.38)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.expressiveEffects ?? [0.2, 0, 0, 1, 1, 1]
                        }
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: cardFrame
                            property: "panelTranslateY"
                            from: Math.round(-24 * root.d)
                            to: Math.round(6 * root.d)
                            duration: Math.round(root.enterDuration * 0.62)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: cardFrame
                            property: "panelTranslateY"
                            to: 0
                            duration: Math.round(root.enterDuration * 0.38)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.expressiveEffects ?? [0.2, 0, 0, 1, 1, 1]
                        }
                    }
                }
            },
            Transition {
                to: "closed"
                enabled: Appearance.animationsEnabled
                ParallelAnimation {
                    NumberAnimation {
                        target: cardFrame
                        property: "progress"
                        to: 0.0
                        duration: root.exitDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                    }
                    NumberAnimation {
                        target: cardFrame
                        property: "panelOpacity"
                        to: 0.0
                        duration: Math.round(root.exitDuration * 0.7)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.standardAccel ?? [0.3, 0, 1, 1, 1, 1]
                    }
                    NumberAnimation {
                        target: cardFrame
                        property: "scale"
                        to: root.windowed ? 0.96 : 0.92
                        duration: root.exitDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                    }
                    NumberAnimation {
                        target: cardFrame
                        property: "panelTranslateY"
                        to: Math.round(-24 * root.d)
                        duration: root.exitDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                    }
                }
            }
        ]

        Behavior on x {
            enabled: Appearance.animationsEnabled && !root.windowed
            NumberAnimation {
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
            }
        }

        Behavior on y {
            enabled: Appearance.animationsEnabled && !root.windowed
            NumberAnimation {
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
            }
        }

        Behavior on width {
            enabled: Appearance.animationsEnabled && !root.windowed
            NumberAnimation {
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
            }
        }

        Behavior on height {
            enabled: Appearance.animationsEnabled && !root.windowed
            NumberAnimation {
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
            }
        }

        focus: root.open
        Keys.onEscapePressed: AndroidState.open = false

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Math.round(16 * root.d)
            spacing: Math.round(10 * root.d)

            HeaderBar {
                id: headerBar
                Layout.fillWidth: true
            }

            Flickable {
                id: bodyScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: bodyCol.implicitHeight
                contentWidth: width
                contentHeight: bodyCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: bodyCol
                    width: bodyScroll.width
                    height: Math.max(bodyScroll.height, bodyCol.implicitHeight)
                    spacing: Math.round(10 * root.d)

                    DeviceSheet {
                        Layout.fillWidth: true
                    }

                    NotificationsSheet {
                        Layout.fillWidth: true
                    }

                    ShareSheet {
                        Layout.fillWidth: true
                    }

                    WirelessSheet {
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        id: contentGrid
                        columns: root.displayedVertical ? 1 : 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rowSpacing: Math.round(12 * root.d)
                        columnSpacing: Math.round(14 * root.d)
                        opacity: root.contentProgress
                        scale: 0.96 + 0.04 * root.contentProgress
                        transformOrigin: Item.Top

                        PhoneMirror {
                            id: phoneMirror
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.displayedVertical ? -1 : Math.round(230 * root.d)
                        }

                        ColumnLayout {
                            id: rightCol
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.displayedVertical ? -1 : Math.round(330 * root.d)
                            spacing: Math.round(10 * root.d)

                            StatusCards {
                                Layout.fillWidth: true
                            }

                            MediaCard {
                                visible: AndroidState.mediaVisible
                                Layout.fillWidth: true
                            }

                            QuickActions {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                Rectangle {
                    visible: bodyScroll.contentHeight > bodyScroll.height + 2
                    anchors.right: parent.right
                    y: bodyScroll.visibleArea.yPosition * bodyScroll.height
                    width: Math.round(4 * root.d)
                    height: Math.max(Math.round(24 * root.d), bodyScroll.visibleArea.heightRatio * bodyScroll.height)
                    radius: width / 2
                    color: IrisStyle.subtext
                    opacity: 0.45
                }
            }
        }
    }
}
