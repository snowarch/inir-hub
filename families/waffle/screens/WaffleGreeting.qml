pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Waffle's welcome at startup: your picture and name over the softened wallpaper, a ring of dots running beside
// "Welcome", then the desktop. A key or a click goes straight to it.
Scope {
    id: root

    property bool leaving: false
    readonly property int holdMs: 2600
    readonly property int fadeMs: Looks.transition.enabled ? Looks.transition.duration.page : 0
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

    Timer {
        id: gone
        interval: root.fadeMs + 40
        onTriggered: {
            GlobalStates.bootGreetingOpen = false
            GlobalStates.bootGreetingDone = true
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

            Item {
                id: stage
                anchors.fill: parent
                opacity: 0
                property bool armed: false
                Component.onCompleted: stage.armed = true

                states: State {
                    name: "in"
                    when: stage.armed && !root.leaving
                    PropertyChanges { target: stage; opacity: 1 }
                }
                transitions: Transition {
                    NumberAnimation {
                        property: "opacity"
                        duration: root.fadeMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.leaving ? Looks.transition.easing.bezierCurve.accelerate : Looks.transition.easing.bezierCurve.decelerate
                    }
                }

                // Opaque under everything: the blur fades its edges, and the desktop must not show through them.
                Rectangle {
                    anchors.fill: parent
                    color: Looks.colors.bg0Opaque
                }
                Image {
                    id: wall
                    anchors.fill: parent
                    anchors.margins: Looks.effectsEnabled ? -64 : 0
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
                    blur: 1
                }
                Rectangle {
                    anchors.fill: parent
                    color: Looks.colors.bg0Opaque
                    opacity: 0.5
                }

                Column {
                    id: hello
                    visible: win.primary
                    anchors.centerIn: parent
                    spacing: Looks.dp(16)
                    opacity: 0
                    transform: Translate { id: lift; y: 16 }

                    ParallelAnimation {
                        running: true
                        NumberAnimation { target: hello; property: "opacity"; to: 1; duration: Looks.transition.enabled ? 520 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
                        NumberAnimation { target: lift; property: "y"; to: 0; duration: Looks.transition.enabled ? 620 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
                    }

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Looks.dp(176)
                        height: width

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
                        WUserAvatar {
                            anchors.fill: parent
                            sourceSize: Qt.size(parent.width, parent.height)
                        }
                    }

                    WText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.name
                        font.pixelSize: Looks.dp(28)
                        font.weight: Looks.font.weight.regular
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Looks.dp(12)

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
