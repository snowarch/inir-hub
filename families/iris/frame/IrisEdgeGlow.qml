pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style

// The edge of every screen lights in the spectrum for a moment when something starts listening through the
// microphone, the way a phone shows its assistant is listening: a band of colour turning around the screen over
// everything, never taking a click, gone in three seconds.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: glow
        required property var modelData
        readonly property real radius: IrisFrame.cornerRadius
        property real turn: 0
        screen: glow.modelData
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "inir:edge-glow"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Item {
            id: light
            anchors.fill: parent
            opacity: 0
            SequentialAnimation on opacity {
                running: true
                NumberAnimation { to: 1; duration: IrisStyle.duration(420); easing.type: Easing.OutCubic }
                PauseAnimation { duration: 2100 }
                NumberAnimation { to: 0; duration: IrisStyle.duration(640); easing.type: Easing.InCubic }
            }
            NumberAnimation {
                target: glow
                property: "turn"
                running: IrisStyle.motionEnabled && light.opacity > 0
                from: 0
                to: 360
                duration: 3200
                loops: Animation.Infinite
            }
            // Wide and faint under thin and bright: the glow, then the line.
            Repeater {
                model: [{ band: 18, alpha: 0.16 }, { band: 9, alpha: 0.36 }, { band: 3.5, alpha: 1 }]
                Shape {
                    id: ring
                    required property var modelData
                    readonly property real band: Math.round(ring.modelData.band * IrisStyle.density)
                    anchors.fill: parent
                    opacity: ring.modelData.alpha
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillRule: ShapePath.OddEvenFill
                        fillGradient: ConicalGradient {
                            centerX: glow.width / 2
                            centerY: glow.height / 2
                            angle: glow.turn
                            GradientStop { position: 0.0; color: IrisStyle.identity.blue }
                            GradientStop { position: 0.17; color: IrisStyle.identity.purple }
                            GradientStop { position: 0.33; color: IrisStyle.identity.pink }
                            GradientStop { position: 0.5; color: IrisStyle.identity.orange }
                            GradientStop { position: 0.67; color: IrisStyle.identity.yellow }
                            GradientStop { position: 0.83; color: IrisStyle.identity.green }
                            GradientStop { position: 1.0; color: IrisStyle.identity.blue }
                        }
                        PathRectangle { x: 0; y: 0; width: glow.width; height: glow.height; radius: glow.radius }
                        PathRectangle {
                            x: ring.band
                            y: ring.band
                            width: Math.max(0, glow.width - 2 * ring.band)
                            height: Math.max(0, glow.height - 2 * ring.band)
                            radius: Math.max(0, glow.radius - ring.band)
                        }
                    }
                }
            }
        }
    }
}
