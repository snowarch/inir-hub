pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import "state"
import "views"

// Display Projection: how the second screen is used, picked in one click the way Win+P does it. The window exists only
// while it is open and the moment the card takes to leave; picking a mode runs niri's own output commands, and
// Duplicate starts wl-mirror.
Scope {
    id: root

    LazyLoader {
        active: Projection.alive

        PanelWindow {
            screen: Projection.screen
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "quickshell:display-projection"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Item {
                id: stage
                anchors.fill: parent
                // How far the card has arrived, 0 to 1. Opening again while it leaves turns it around from where it is.
                property real presence: 0
                readonly property bool present: Projection.open
                enabled: stage.present

                function go(): void {
                    arrive.stop()
                    leave.stop()
                    const motion = stage.present ? arrive : leave
                    motion.from = stage.presence
                    motion.start()
                    if (stage.present)
                        card.forceActiveFocus()
                }
                onPresentChanged: stage.go()
                Component.onCompleted: stage.go()

                NumberAnimation {
                    id: arrive
                    target: stage
                    property: "presence"
                    to: 1
                    duration: FamilyStyle.emergeDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: FamilyStyle.emergeCurve
                }
                NumberAnimation {
                    id: leave
                    target: stage
                    property: "presence"
                    to: 0
                    duration: FamilyStyle.recedeDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: FamilyStyle.recedeCurve
                }

                // The desktop dims a little behind the card: it is the one thing to answer now.
                Rectangle {
                    anchors.fill: parent
                    color: FamilyStyle.scrim
                    opacity: 0.5 * stage.presence
                }

                // A click beside the card closes it.
                MouseArea {
                    anchors.fill: parent
                    onClicked: Projection.hide()
                }

                // It rises from slightly smaller and goes back the same way, its shadow with it.
                Item {
                    anchors.centerIn: parent
                    width: card.implicitWidth
                    height: card.implicitHeight
                    opacity: stage.presence
                    scale: 0.96 + 0.04 * stage.presence

                    StyledRectangularShadow {
                        target: card
                        radius: card.radius
                        color: FamilyStyle.shadow
                        blur: Math.round(28 * FamilyStyle.density)
                        offset: Qt.vector2d(0, Math.round(8 * FamilyStyle.density))
                    }

                    ProjectionCard {
                        id: card
                        anchors.fill: parent
                    }
                }
            }
        }
    }

    /// Display Projection: this screen only, duplicate it, extend the desktop or the second screen only.
    ///
    /// ```kdl
    /// Mod+P { spawn "inir" "display-projection" "toggle"; }
    /// ```
    IpcHandler {
        target: "display-projection"
        /// Open or close it
        function toggle(): void { Projection.toggle() }
        /// Open it
        function open(): void { Projection.show() }
        /// Close it
        function close(): void { Projection.hide() }
        /// Put a mode on without opening it: pcOnly, duplicate, extend or secondOnly (it opens only to say what failed)
        function mode(name: string): void { Projection.apply(name) }
    }
}
