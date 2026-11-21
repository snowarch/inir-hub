pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

// iRiS's welcome at startup: the ring of its mark draws itself on the dark and says good morning, then opens like an
// aperture onto the desktop, the ring riding the edge out. A key or a click opens it at once.
Scope {
    id: root

    property real veil: 0   // the dark coming in over the desktop
    property real ring: 0   // how much of the ring is drawn
    property real words: 0  // the greeting
    property real open: 0   // 0 shut, 1 the desktop whole
    property bool leaving: false

    readonly property string greeting: {
        const hour = new Date().getHours()
        if (hour < 6) return Translation.tr("Good night")
        if (hour < 12) return Translation.tr("Good morning")
        if (hour < 18) return Translation.tr("Good afternoon")
        return Translation.tr("Good evening")
    }
    readonly property string name: SystemInfo.displayName || SystemInfo.username

    function openUp(): void {
        if (root.leaving)
            return
        root.leaving = true
        timeline.stop()
        opening.start()
    }

    SequentialAnimation {
        id: timeline
        running: true
        NumberAnimation { target: root; property: "veil"; to: 1; duration: IrisStyle.duration(260); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "ring"; to: 1; duration: IrisStyle.duration(760); easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "words"; to: 1; duration: IrisStyle.duration(420); easing.type: Easing.OutCubic }
        PauseAnimation { duration: 950 }
        ScriptAction {
            script: {
                root.leaving = true
                opening.start()
            }
        }
    }

    SequentialAnimation {
        id: opening
        ParallelAnimation {
            NumberAnimation { target: root; property: "veil"; to: 1; duration: IrisStyle.duration(120) }
            NumberAnimation { target: root; property: "ring"; to: 1; duration: IrisStyle.duration(160) }
            NumberAnimation { target: root; property: "words"; to: 0; duration: IrisStyle.duration(200); easing.type: Easing.OutCubic }
            NumberAnimation {
                target: root
                property: "open"
                to: 1
                duration: IrisStyle.duration(950)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: IrisStyle.emergeCurve
            }
        }
        ScriptAction {
            script: {
                GlobalStates.bootGreetingOpen = false
                GlobalStates.bootGreetingDone = true
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
            // Opening, the desktop under it takes clicks already.
            mask: Region { item: root.leaving ? null : shade }

            Item {
                id: shade
                anchors.fill: parent
                opacity: root.veil

                readonly property real diag: Math.hypot(shade.width, shade.height)
                readonly property real mark: Math.round(Math.min(shade.width, shade.height) * 0.075)
                readonly property real cx: shade.width / 2
                readonly property real cy: shade.height / 2 - (win.primary ? shade.mark * 0.6 : 0)
                readonly property real hole: root.open <= 0 ? 0 : shade.mark + (shade.diag - shade.mark) * root.open

                // The dark with a round hole in it: a ring whose border reaches past every corner.
                Rectangle {
                    readonly property real outer: shade.hole + shade.diag
                    x: shade.cx - outer
                    y: shade.cy - outer
                    width: outer * 2
                    height: width
                    radius: outer
                    color: "transparent"
                    border.width: shade.diag
                    border.color: IrisStyle.surfaceOpaque
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: Math.max(0, 1 - root.open * 1.4)
                    ShapePath {
                        strokeColor: IrisStyle.accent
                        strokeWidth: Math.max(2, Math.round(shade.mark * 0.09))
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: shade.cx
                            centerY: shade.cy
                            radiusX: Math.max(shade.mark, shade.hole)
                            radiusY: Math.max(shade.mark, shade.hole)
                            startAngle: -90
                            sweepAngle: 360 * root.ring
                        }
                    }
                }

                // The mark's pupil, there once the ring closes, gone as it opens.
                Rectangle {
                    width: Math.round(shade.mark * 0.42)
                    height: width
                    radius: width / 2
                    x: shade.cx - width / 2
                    y: shade.cy - height / 2
                    color: IrisStyle.accent
                    scale: Math.max(0, (root.ring - 0.6) / 0.4) * (1 - root.open)
                }

                Column {
                    visible: win.primary
                    x: Math.round(shade.cx - width / 2)
                    y: Math.round(shade.cy + shade.mark + 36)
                    spacing: 6
                    opacity: root.words
                    transform: Translate { y: Math.round((1 - root.words) * 12) }

                    IrisText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: IrisText.Title
                        font.pixelSize: IrisStyle.typeDotM
                        tone: IrisStyle.text
                        text: root.greeting
                    }
                    IrisText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.name.length > 0
                        role: IrisText.Body
                        tone: IrisStyle.textSecondary
                        text: root.name
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.openUp()
                }
                Item {
                    anchors.fill: parent
                    focus: win.primary && !root.leaving
                    Keys.onPressed: event => {
                        event.accepted = true
                        root.openUp()
                    }
                }
            }
        }
    }
}
