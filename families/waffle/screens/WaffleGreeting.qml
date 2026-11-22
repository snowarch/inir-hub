pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Waffle's welcome at startup: your picture, your name and a ring of dots beside "Welcome" rise one after another over
// the softened wallpaper; then the wallpaper comes into focus and the desktop is there. A key or a click goes straight
// to it.
Scope {
    id: root

    property bool leaving: false
    property real reveal: 0 // 0 the welcome, 1 the wallpaper in focus and the desktop under it
    readonly property bool motion: Looks.transition.enabled
    readonly property int holdMs: 2600
    readonly property string name: SystemInfo.displayName || SystemInfo.username

    function finish(): void {
        if (root.leaving)
            return
        root.leaving = true
        hold.stop()
        gone.start()
    }

    Timer {
        id: hold
        interval: root.holdMs
        running: true
        onTriggered: root.finish()
    }

    SequentialAnimation {
        id: gone
        NumberAnimation {
            target: root
            property: "reveal"
            to: 1
            duration: root.motion ? 620 : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
        }
        ScriptAction {
            script: {
                GlobalStates.bootGreetingOpen = false
                GlobalStates.bootGreetingDone = true
            }
        }
    }

    // Each part of the greeting rises into place a beat after the one before.
    component Rise: SequentialAnimation {
        id: rise
        property Item target
        property Translate lift
        property int delay: 0
        running: true
        PauseAnimation { duration: root.motion ? rise.delay : 0 }
        ParallelAnimation {
            NumberAnimation { target: rise.target; property: "opacity"; to: 1; duration: root.motion ? 460 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
            NumberAnimation { target: rise.lift; property: "y"; to: 0; duration: root.motion ? 560 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
        }
    }

    // Five dots chase one another round a ring, each a beat behind the one before.
    component DotRing: Item {
        id: ring
        property real size: 28
        property color color: Looks.colors.fg
        width: ring.size
        height: ring.size

        Repeater {
            model: 5
            Item {
                id: orbit
                required property int index
                anchors.fill: parent
                opacity: 0

                Rectangle {
                    x: (ring.size - width) / 2
                    width: Math.max(3, Math.round(ring.size * 0.14))
                    height: width
                    radius: width / 2
                    color: ring.color
                }

                SequentialAnimation {
                    running: Looks.transition.enabled
                    loops: Animation.Infinite
                    PauseAnimation { duration: orbit.index * 110 }
                    PropertyAction { target: orbit; property: "opacity"; value: 1 }
                    RotationAnimation {
                        target: orbit
                        from: 0
                        to: 360
                        duration: 1700
                        direction: RotationAnimation.Clockwise
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.5, 0.1, 0.4, 0.9, 1, 1]
                    }
                    PropertyAction { target: orbit; property: "opacity"; value: 0 }
                    PauseAnimation { duration: (4 - orbit.index) * 110 + 260 }
                }
            }
        }

        // With motion off, the dots rest in a still arc.
        Repeater {
            model: Looks.transition.enabled ? 0 : 5
            Item {
                required property int index
                anchors.fill: parent
                rotation: index * 28
                Rectangle {
                    x: (ring.size - width) / 2
                    width: Math.max(3, Math.round(ring.size * 0.14))
                    height: width
                    radius: width / 2
                    color: ring.color
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool primary: (win.modelData?.name ?? "") === (GlobalStates.primaryScreen?.name ?? "")

            screen: win.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:boot-greeting"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: win.primary && !root.leaving && !PolkitService.active
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // Leaving, the desktop under it takes clicks already.
            mask: Region { item: root.leaving ? null : stage }

            Item {
                id: stage
                anchors.fill: parent
                // In over the desktop at once; out over the last third of the focus pull.
                opacity: Math.min(stage.arrive, 1 - Math.max(0, (root.reveal - 0.62) / 0.38))
                property real arrive: 0
                NumberAnimation on arrive {
                    to: 1
                    duration: root.motion ? Looks.transition.duration.page : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                }

                // Opaque under everything: the blur fades its edges, and the desktop must not show through them.
                Rectangle {
                    anchors.fill: parent
                    color: Looks.colors.bg0Opaque
                    opacity: 1 - root.reveal
                }
                Image {
                    id: wall
                    anchors.fill: parent
                    // The blur's soft edge stays off screen, and the picture settles onto the wallpaper as it sharpens.
                    anchors.margins: Looks.effectsEnabled ? Math.round(-64 * (1 - root.reveal)) : 0
                    source: Wallpapers.stillUrlFor(Wallpapers.desktopWallpaperPath(WallpaperListener.getMonitorName(win.modelData)))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: Math.round(win.width / 2)
                    sourceSize.height: Math.round(win.height / 2)
                    visible: !Looks.effectsEnabled
                }
                MultiEffect {
                    anchors.fill: wall
                    visible: Looks.effectsEnabled
                    source: wall
                    blurEnabled: true
                    blurMax: 64
                    blur: 1 - root.reveal
                }
                Rectangle {
                    anchors.fill: parent
                    color: Looks.colors.bg0Opaque
                    opacity: 0.5 * (1 - root.reveal)
                }

                Column {
                    id: hello
                    visible: win.primary
                    anchors.centerIn: parent
                    spacing: Looks.dp(16)
                    // Leaving, the greeting steps back first.
                    opacity: Math.max(0, 1 - root.reveal * 2.4)
                    scale: 1 - root.reveal * 0.06

                    Item {
                        id: picture
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Looks.dp(176)
                        height: width
                        opacity: 0
                        transform: Translate { id: pictureLift; y: Looks.dp(18) }
                        Rise { target: picture; lift: pictureLift; delay: 60 }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Looks.colors.bg1Base
                            WText {
                                anchors.centerIn: parent
                                text: (root.name || "?").charAt(0).toUpperCase()
                                font.pixelSize: Math.round(parent.width * 0.4)
                                font.weight: Looks.font.weight.thin
                            }
                        }
                        // With no picture of their own, their initial stands in, not a generic glyph over it.
                        WUserAvatar {
                            id: avatar
                            anchors.fill: parent
                            visible: avatar.hasPicture
                            sourceSize: Qt.size(parent.width, parent.height)
                        }
                        // A hairline round the picture keeps it apart from any wallpaper.
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.alpha(Looks.colors.fg, 0.14)
                        }
                    }

                    WText {
                        id: nameLine
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.name
                        font.pixelSize: Looks.dp(28)
                        font.weight: Looks.font.weight.regular
                        opacity: 0
                        transform: Translate { id: nameLift; y: Looks.dp(14) }
                        Rise { target: nameLine; lift: nameLift; delay: 170 }
                    }

                    Row {
                        id: status
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Looks.dp(12)
                        opacity: 0
                        transform: Translate { id: statusLift; y: Looks.dp(10) }
                        Rise { target: status; lift: statusLift; delay: 280 }

                        DotRing {
                            anchors.verticalCenter: parent.verticalCenter
                            size: Looks.dp(26)
                        }
                        WText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Welcome")
                            font.pixelSize: Looks.dp(20)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.finish()
                }
                Item {
                    anchors.fill: parent
                    focus: win.primary && !root.leaving
                    Keys.onPressed: event => {
                        event.accepted = true
                        root.finish()
                    }
                }
            }
        }
    }
}
